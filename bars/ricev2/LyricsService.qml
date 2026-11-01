pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

// Bar prompt section 6's synced lyric line -- player selection, fetch,
// LRC parsing and drift-corrected position sync all live here so
// Bar/lyrics/LyricsIsland.qml only has to render `currentText`/
// `previousText`/`progress`.
//
// Lyrics source: lrclib.net's public API (no key, GET /api/get then
// /api/search fallback), not the real skwd-bar's own path. Checked
// against the actual skwd-bar + skwd-daemon repos (github.com/liixini/
// skwd, github.com/liixini/skwd-daemon -- the bar prompt explicitly says
// to clone and read these if unsure) rather than guessed: skwd-bar's
// LyricsService.qml doesn't talk to any lyrics API itself, it calls
// "lyrics.peek"/"lyrics.get" over a unix socket to a separate Rust
// skwd-daemon process (crates/daemon/src/lyrics/providers.rs), which
// tries Musixmatch first (an unofficial, reverse-engineered private API
// requiring a scraped device token -- not something to reimplement here),
// then lrclib.net, then a Netease Music internal endpoint. ricev2 has no
// daemon anywhere else in this build (every other stage talks to its
// data source directly from QML, e.g. WeatherService.qml -> Open-Meteo),
// so this singleton reimplements only the lrclib.net path -- the one
// legitimate, purpose-built public API for open-source synced-lyrics
// clients among the three, and the actual daemon's own fallback once
// Musixmatch fails anyway.
//
// LRC parsing (regular + "enhanced"/word-timestamp) and the wall-clock
// drift-correction sync loop below are a direct port of skwd-daemon's
// crates/daemon/src/lyrics/parse.rs and skwd-bar's own
// LyricsIslandService.qml launchSync()/estimatedTrackMs() -- the
// mechanics the bar prompt has no way to specify itself, so implemented
// against the real reference per the prompt's own instruction rather than
// invented. Word-level highighting is used only when the fetched LRC
// happens to carry inline <mm:ss.xx> word tags (rare even from lrclib);
// the bar prompt's own karaoke spec only asks for a single width-scaled
// clip reveal driven by one 0..1 "Fortschritt" value, so a plain-LRC line
// with no word tags falls back to linear duration-based progress -- both
// paths feed the exact same `progress` property.
QtObject {
    id: root

    // -- Active player (same pattern as bars/lucid/Panels/MediaPanel.qml
    // and skwd-bar's own LyricsService.qml: preferred-by-identity playing
    // player, else the first playing player, else none) -----------------
    readonly property var player: {
        if (!Mpris.players)
            return null;
        const list = Mpris.players.values;
        const preferred = Config.preferredPlayer.toLowerCase();
        let preferredPlaying = null;
        let anyPlaying = null;
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            if (!p)
                continue;
            const id = (p.identity || "").toLowerCase();
            if (preferred && id.indexOf(preferred) !== -1 && p.isPlaying)
                preferredPlaying = p;
            if (p.isPlaying && !anyPlaying)
                anyPlaying = p;
        }
        return preferredPlaying || anyPlaying || null;
    }
    readonly property bool playing: root.player !== null

    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    // Leading "Artist - " stripped, per bar prompt section 6 ("Ein
    // führendes 'Interpret - ' wird entfernt").
    readonly property string title: {
        if (!root.player)
            return "";
        let t = root.player.trackTitle || "";
        const a = root.artist;
        if (a && t.toLowerCase().indexOf(a.toLowerCase() + " - ") === 0)
            t = t.substring(a.length + 3);
        return t;
    }

    // -- Lyrics data ------------------------------------------------------
    property string state: "idle" // idle | searching | nolyrics | haslyrics
    property var lines: []
    property bool enhanced: false
    property string _lastKey: ""

    onArtistChanged: root._maybeRefetch()
    onTitleChanged: root._maybeRefetch()
    onPlayingChanged: root._maybeRefetch()

    function _maybeRefetch() {
        if (!root.playing || !root.artist || !root.title) {
            if (root._lastKey !== "") {
                root._lastKey = "";
                root.state = "idle";
                root.lines = [];
                root.enhanced = false;
                root._resetSync();
            }
            return;
        }
        const key = root.artist + "|||" + root.title;
        if (key === root._lastKey)
            return;
        root._lastKey = key;
        root.state = "searching";
        root.lines = [];
        root.enhanced = false;
        root._resetSync();
        root._fetch(root.artist, root.title, key);
    }

    function _fetch(artist, title, key) {
        const url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artist) + "&track_name=" + encodeURIComponent(title);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._lastKey !== key)
                return;
            if (xhr.status === 200) {
                let data = null;
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (e) {
                    data = null;
                }
                const synced = data && data.syncedLyrics;
                if (synced) {
                    root._applyLrc(synced, key);
                    return;
                }
            }
            root._searchFallback(artist, title, key);
        };
        xhr.open("GET", url);
        try {
            xhr.setRequestHeader("User-Agent", "ricev2-bar/1.0 (+quickshell, github.com/liixini/skwd Nachbau)");
        } catch (e) {
            // lrclib.net asks for a descriptive User-Agent as a courtesy,
            // not a requirement -- if this QML XHR can't set it, the
            // request still goes out.
        }
        xhr.send();
    }

    function _searchFallback(artist, title, key) {
        const url = "https://lrclib.net/api/search?q=" + encodeURIComponent(artist + " " + title);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._lastKey !== key)
                return;
            if (xhr.status !== 200) {
                root._notFound(key);
                return;
            }
            let data = null;
            try {
                data = JSON.parse(xhr.responseText);
            } catch (e) {
                data = null;
            }
            if (!Array.isArray(data)) {
                root._notFound(key);
                return;
            }
            let bestSynced = null;
            let bestEnhanced = null;
            for (const item of data) {
                const s = item && item.syncedLyrics;
                if (!s)
                    continue;
                if (!bestSynced)
                    bestSynced = s;
                if (!bestEnhanced && root._isEnhancedLrc(s))
                    bestEnhanced = s;
            }
            const lrc = bestEnhanced || bestSynced;
            if (!lrc) {
                root._notFound(key);
                return;
            }
            root._applyLrc(lrc, key);
        };
        xhr.open("GET", url);
        try {
            xhr.setRequestHeader("User-Agent", "ricev2-bar/1.0 (+quickshell, github.com/liixini/skwd Nachbau)");
        } catch (e) {
        }
        xhr.send();
    }

    function _applyLrc(lrcText, key) {
        if (root._lastKey !== key)
            return;
        const parsed = root._parseLrc(lrcText);
        if (!parsed.lines || parsed.lines.length === 0) {
            root._notFound(key);
            return;
        }
        root.lines = parsed.lines;
        root.enhanced = parsed.enhanced;
        root.state = "haslyrics";
        root._resetSync();
        root._launchSync();
    }

    function _notFound(key) {
        if (root._lastKey !== key)
            return;
        root.state = "nolyrics";
        root.lines = [];
        root.enhanced = false;
    }

    // -- LRC parsing (regular + word-timestamp "enhanced") --------------
    // Direct port of skwd-daemon's crates/daemon/src/lyrics/parse.rs.
    function _parseTimestampMs(s) {
        const m = /^(\d+):(\d+(?:\.\d+)?)$/.exec(s.trim());
        if (!m)
            return null;
        return Math.round((parseInt(m[1], 10) * 60 + parseFloat(m[2])) * 1000);
    }

    function _parseLrcLineStart(line) {
        const l = line.trim();
        if (!l.startsWith("["))
            return null;
        const close = l.indexOf("]");
        if (close === -1)
            return null;
        const ts = l.slice(1, close);
        if (root._parseTimestampMs(ts) === null)
            return null;
        return { ts: ts, rest: l.slice(close + 1) };
    }

    function _extractWordTimestamps(text) {
        const result = [];
        let rest = text;
        while (true) {
            const open = rest.indexOf("<");
            if (open === -1)
                break;
            rest = rest.slice(open + 1);
            const close = rest.indexOf(">");
            if (close === -1)
                break;
            const ts = rest.slice(0, close);
            if (root._parseTimestampMs(ts) === null) {
                rest = rest.slice(close + 1);
                continue;
            }
            rest = rest.slice(close + 1);
            const nextOpen = rest.indexOf("<");
            const wordEnd = nextOpen === -1 ? rest.length : nextOpen;
            const word = rest.slice(0, wordEnd).trim();
            if (word.length > 0)
                result.push([ts, word]);
            rest = rest.slice(wordEnd);
        }
        return result;
    }

    function _isEnhancedLrc(text) {
        return root._extractWordTimestamps(text).length > 0;
    }

    function _stripWordTimestamps(text) {
        let result = "";
        let rest = text;
        while (true) {
            const open = rest.indexOf("<");
            if (open === -1) {
                result += rest;
                break;
            }
            result += rest.slice(0, open);
            rest = rest.slice(open + 1);
            const close = rest.indexOf(">");
            if (close === -1) {
                result += "<";
                break;
            }
            const inner = rest.slice(0, close);
            if (root._parseTimestampMs(inner) === null)
                result += "<" + inner + ">";
            rest = rest.slice(close + 1);
        }
        return result.trim();
    }

    function _parseRegularLrc(text) {
        const result = [];
        for (const raw0 of text.split(/\r?\n/)) {
            const raw = raw0.trim();
            if (!raw)
                continue;
            const start = root._parseLrcLineStart(raw);
            if (!start)
                continue;
            const lineStart = root._parseTimestampMs(start.ts);
            const lineText = start.rest.trim();
            if (!lineText)
                continue;
            result.push({ text: lineText, start: lineStart, end: lineStart + 3000, words: [] });
        }
        for (let i = 0; i < result.length - 1; i++)
            result[i].end = result[i + 1].start;
        return result;
    }

    function _parseEnhancedLrc(text) {
        const result = [];
        for (const raw0 of text.split(/\r?\n/)) {
            const raw = raw0.trim();
            if (!raw)
                continue;
            const start = root._parseLrcLineStart(raw);
            if (!start)
                continue;
            const lineStart = root._parseTimestampMs(start.ts);
            const rest = start.rest.trim();
            if (!rest)
                continue;
            const wordMatches = root._extractWordTimestamps(rest);
            if (wordMatches.length > 0) {
                const fullText = root._stripWordTimestamps(rest);
                const words = [];
                let searchFrom = 0;
                for (let i = 0; i < wordMatches.length; i++) {
                    const wTs = wordMatches[i][0];
                    const w = wordMatches[i][1];
                    const wStart = root._parseTimestampMs(wTs);
                    const wEnd = i + 1 < wordMatches.length ? root._parseTimestampMs(wordMatches[i + 1][0]) : wStart + Math.max(200, w.length * 80);
                    let charStart, charEnd;
                    const pos = fullText.indexOf(w, searchFrom);
                    if (pos !== -1) {
                        charStart = pos;
                        charEnd = pos + w.length;
                    } else {
                        charStart = searchFrom;
                        charEnd = searchFrom + w.length;
                    }
                    searchFrom = charEnd;
                    words.push({ word: w, start: wStart, end: wEnd, charStart: charStart, charEnd: charEnd });
                }
                const lineEnd = words.length > 0 ? words[words.length - 1].end : lineStart + 3000;
                result.push({ text: fullText, start: lineStart, end: lineEnd, words: words });
            } else {
                result.push({ text: rest, start: lineStart, end: lineStart + 3000, words: [] });
            }
        }
        for (let i = 0; i < result.length - 1; i++) {
            const nextStart = result[i + 1].start;
            if (result[i].words.length > 0)
                result[i].words[result[i].words.length - 1].end = nextStart;
            result[i].end = nextStart;
        }
        return result;
    }

    function _parseLrc(text) {
        if (root._isEnhancedLrc(text))
            return { lines: root._parseEnhancedLrc(text), enhanced: true };
        return { lines: root._parseRegularLrc(text), enhanced: false };
    }

    // -- Drift-corrected sync (port of skwd-bar's LyricsIslandService.qml
    // launchSync()/estimatedTrackMs()) -----------------------------------
    property real _syncWallTime: 0
    property real _syncTrackMs: 0

    property int currentIndex: -1
    property string currentText: ""
    property string previousText: ""
    property real progress: 0

    function _resetSync() {
        root._syncWallTime = 0;
        root._syncTrackMs = 0;
        root.currentIndex = -1;
        root.currentText = "";
        root.previousText = "";
        root.progress = 0;
    }

    function _estimatedTrackMs() {
        if (root._syncWallTime <= 0)
            return 0;
        return root._syncTrackMs + (Date.now() - root._syncWallTime);
    }

    function _launchSync() {
        const p = root.player;
        // positionSupported (same Quickshell Mpris property
        // bars/lucid/Panels/MediaPanel.qml already gates its seek bar on)
        // -- without it `position` is meaningless, so don't anchor sync to
        // it at all rather than pin the display to a false 0:00.
        if (!p || p.positionSupported === false)
            return;
        const posMs = p.position * 1000;
        const wallNow = Date.now();
        if (root._syncWallTime <= 0) {
            root._syncTrackMs = posMs;
            root._syncWallTime = wallNow;
            return;
        }
        const estimate = root._syncTrackMs + (wallNow - root._syncWallTime);
        const drift = posMs - estimate;
        if (Math.abs(drift) >= 5000) {
            root._syncTrackMs = posMs;
            root._syncWallTime = wallNow;
        } else if (drift > 50) {
            root._syncTrackMs = estimate + drift * 0.4;
            root._syncWallTime = wallNow;
        } else if (drift < -50) {
            let corrected = estimate + drift * 0.15;
            const idx = root.currentIndex;
            if (idx >= 0 && idx < root.lines.length && corrected < root.lines[idx].start)
                corrected = root.lines[idx].start;
            root._syncTrackMs = corrected;
            root._syncWallTime = wallNow;
        }
    }

    property Timer _syncTimer: Timer {
        interval: 5000
        repeat: true
        running: root.lines.length > 0
        onTriggered: root._launchSync()
    }

    property Timer _animTimer: Timer {
        interval: 33
        repeat: true
        running: root.lines.length > 0 && root._syncWallTime > 0
        onTriggered: root._tick()
    }

    function _tick() {
        const posMs = root._estimatedTrackMs();
        const lines = root.lines;
        let newIdx = -1;
        for (let i = lines.length - 1; i >= 0; i--) {
            if (posMs >= lines[i].start) {
                newIdx = i;
                break;
            }
        }
        if (newIdx < 0)
            return;
        const line = lines[newIdx];
        if (newIdx !== root.currentIndex) {
            root.previousText = root.currentText;
            root.currentText = line.text;
            root.currentIndex = newIdx;
        }
        if (posMs > line.end) {
            root.progress = 1.0;
        } else if (line.words && line.words.length > 0) {
            const totalChars = line.text.length;
            let charsHighlighted = 0;
            for (let w = 0; w < line.words.length; w++) {
                const word = line.words[w];
                if (posMs < word.start) {
                    break;
                } else if (posMs >= word.end) {
                    charsHighlighted = (w < line.words.length - 1) ? line.words[w + 1].charStart : word.charEnd;
                } else {
                    const wp = (posMs - word.start) / (word.end - word.start);
                    charsHighlighted = word.charStart + word.word.length * wp;
                    break;
                }
            }
            root.progress = totalChars > 0 ? Math.max(0, Math.min(1, charsHighlighted / totalChars)) : 1.0;
        } else {
            const duration = line.end - line.start;
            root.progress = duration > 0 ? Math.max(0, Math.min(1, (posMs - line.start) / duration)) : 1.0;
        }
    }
}
