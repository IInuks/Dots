pragma Singleton
import QtQuick
import Quickshell

// The greeter's layouts. Each one is a complete login screen in styles/,
// loaded by components/Greeter.qml, and gets two properties:
//   ctl      -- the Greeter (user/session state, submit(), power(), openStyles())
//   preview  -- true for the live miniatures in the style menu (no focus, no input)
// and must provide focusField(). All colors come from Theme, so every style
// follows the wallpaper.
Singleton {
    readonly property var list: [
        { id: "glass",    file: "GlassStyle.qml",    name: "Glass",    glyph: "󰂵", blurb: "Centered card on the blurred wallpaper" },
        { id: "sidebar",  file: "SidebarStyle.qml",  name: "Sidebar",  glyph: "󰕰", blurb: "Frosted side panel, wallpaper stays sharp" },
        { id: "terminal", file: "TerminalStyle.qml", name: "Terminal", glyph: "", blurb: "A tty login on a CRT that powers on" },
        { id: "minimal",  file: "MinimalStyle.qml",  name: "Minimal",  glyph: "󰘷", blurb: "Just a big clock -- the rest appears when you move" },
        { id: "tiles",    file: "TilesStyle.qml",    name: "Tiles",    glyph: "󰕮", blurb: "User tiles below a glass top bar" }
    ]
    readonly property string fallback: "glass"

    function indexOf(id) {
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id) return i;
        return -1;
    }
    function url(id) {
        const i = indexOf(id);
        return Qt.resolvedUrl("styles/" + list[i < 0 ? 0 : i].file);
    }
}
