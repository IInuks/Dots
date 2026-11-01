pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tab logic for the menu window. Seven tabs at the bottom, "Editor",
// "Bars", "Launcher", "Blob", "Widgets", "Blur" and "Server", switched by click or ←/→ (shell.qml). Every tab is its own file
// in steps/, listed here -- shell.qml renders the tab bar and the page
// stack from this list.
//
// Opening the menu lands on the tab used last (remembered across restarts
// in ~/.local/state/quickshell/menu-last-tab; "Bars" the very first time),
// with the active bar / its launcher selected.
// Enter / double-click / "Anwenden" switches to the selected bar
// (SwitchState runs switch-bar.sh, progress shows in the bottom row).
// In "Launcher" the same assigns the selected launcher to the active bar
// (LauncherStore runs set-launcher.sh); other bars get theirs through the
// chips in that tab. "Blob" (settings of ~/quickdots/blobball) has no
// apply step -- every change goes live right away (BlobStore). "Widgets"
// (desktop widgets of bars/salbei) and "Blur" (mango's global blur,
// BlurStore) work the same way. "Server" is a read-only dashboard of the
// remote server over Tailscale + SSH (ServerStore).
QtObject {
    id: root

    readonly property var tabs: [
        { id: "custom", label: "Editor", icon: "", file: "CustomStep.qml" },
        { id: "bar", label: "Bars", icon: "", file: "BarStep.qml" },
        { id: "launcher", label: "Launcher", icon: "\uf135", file: "LauncherStep.qml" },
        { id: "blob", label: "Blob", icon: "\uf118", file: "BlobStep.qml" },
        { id: "widgets", label: "Widgets", icon: "\uf009", file: "WidgetsStep.qml" },
        { id: "blur", label: "Blur", icon: "\uf0c2", file: "BlurStep.qml" },
        { id: "server", label: "Server", icon: "\uf233", file: "ServerStep.qml" }
    ]
    readonly property int barTab: tabs.findIndex(t => t.id === "bar")

    property int currentTab: barTab
    onCurrentTabChanged: if (_lastTabFile.ready) _lastTabFile.setText(tabs[currentTab].id)

    // Last used tab, by id (survives tabs being reordered).
    property FileView _lastTabFile: FileView {
        property bool ready: false
        path: Quickshell.env("HOME") + "/.local/state/quickshell/menu-last-tab"
        watchChanges: false
        atomicWrites: true
        printErrors: false
        onLoaded: {
            const i = root.tabs.findIndex(t => t.id === text().trim());
            if (i >= 0 && !MenuState.visible) root.currentTab = i;
            ready = true;
        }
        onLoadFailed: ready = true
    }
    // +1 to the right, -1 to the left: picks the slide direction of the
    // page transition.
    property int direction: 1

    // The bar chosen in the "Bars" tab. Seeded with the active bar on open.
    property string selectedBar: ""

    // The launcher chosen in the "Launcher" tab. Seeded with the active
    // bar's launcher on open.
    property string selectedLauncher: ""

    readonly property string currentId: tabs[currentTab].id

    // No second switch/assignment while switch-bar.sh or set-launcher.sh
    // is running.
    readonly property bool locked: SwitchState.running || LauncherStore.running

    readonly property bool canApply: {
        if (locked) return false;
        if (currentId === "bar")
            return selectedBar.length > 0 && selectedBar !== BarsModel.activeBar;
        if (currentId === "launcher")
            return selectedLauncher.length > 0
                && selectedLauncher !== LauncherStore.effective(BarsModel.activeBar);
        return false;
    }

    function goTo(i: int): void {
        if (i < 0 || i >= tabs.length || i === currentTab) return;
        direction = i > currentTab ? 1 : -1;
        currentTab = i;
    }

    function nextTab(): void { goTo(currentTab + 1); }
    function prevTab(): void { goTo(currentTab - 1); }

    function apply(): void {
        if (!canApply) return;
        if (currentId === "bar") SwitchState.switchTo(selectedBar);
        else LauncherStore.assign(BarsModel.activeBar, selectedLauncher);
    }

    // "Ausprobieren": close the menu first (it holds the keyboard
    // exclusively), then open the selected launcher once it's unmapped.
    function tryLauncher(): void {
        if (!selectedLauncher.length) return;
        _tryId = selectedLauncher;
        close();
        _tryTimer.restart();
    }
    property string _tryId: ""
    property Timer _tryTimer: Timer {
        interval: 260
        onTriggered: LauncherStore.tryOut(root._tryId)
    }

    // Open the menu directly on a tab (ipc call wizard blob, CTRL+Shift_R).
    // Already open: just switch to it.
    function openAt(id: string): void {
        const i = tabs.findIndex(t => t.id === id);
        if (i < 0) return;
        if (MenuState.visible) { goTo(i); return; }
        _openTab = i;
        MenuState.open();
    }
    property int _openTab: -1

    function handleOpen(): void {
        direction = 1;
        if (_openTab >= 0) currentTab = _openTab;
        _openTab = -1;
        if (!locked) {
            selectedBar = BarsModel.activeBar;
            selectedLauncher = LauncherStore.effective(BarsModel.activeBar);
            SwitchState.clear();
            LauncherStore.handleOpen();
        }
    }

    // While switch-bar.sh runs, closing only hides the window -- the switch
    // can't be interrupted halfway, reopening shows its progress.
    function close(): void {
        MenuState.close();
    }
}
