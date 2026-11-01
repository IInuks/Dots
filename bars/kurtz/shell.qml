//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "services"
import "modules/bar"
import "modules/popups"

// kurtz -- a Kurzgesagt-flavoured Quickshell desktop shell for mango.
// See README.md for the tour, the style rules and the IPC commands.
ShellRoot {
    id: shell
    property int _demoId: 900000

    // The screen that gets popups opened from the keyboard (IPC): the one
    // mango reports as active, else the first one.
    function focusedScreen() {
        const m = Tags.monitors.find(x => x.active);
        return m ? m.name : (Quickshell.screens[0] ? Quickshell.screens[0].name : "");
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }
    Variants {
        model: Quickshell.screens
        delegate: Overlay {}
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            Notifs.receive(n);
            n.closed.connect(() => Notifs.forget(n.id));
        }
    }

    // ---------------------------------------------------------------- IPC
    //   qs -p <kurtz> ipc call panel toggle launcher
    IpcHandler {
        target: "panel"
        function toggle(id: string): void { Popups.toggle(id, shell.focusedScreen(), -1); }
        function open(id: string): void { Popups.open(id, shell.focusedScreen(), -1); }
        function close(): void { Popups.close(); }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Popups.toggle("launcher", shell.focusedScreen(), -1); }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { Popups.toggle("session", shell.focusedScreen(), -1); }
    }
    IpcHandler {
        target: "config"
        // qs ipc call config set accent magenta   (numbers/bools are parsed)
        function set(key: string, value: string): string {
            if (!(key in Config.defaults))
                return "unknown key: " + key;
            let v = value;
            if (typeof Config.defaults[key] === "boolean")
                v = value === "true" || value === "1" || value === "on";
            else if (typeof Config.defaults[key] === "number")
                v = Number(value);
            Config.set(key, v);
            return key + " = " + JSON.stringify(v);
        }
        function toggle(key: string): string {
            Config.toggle(key);
            return key + " = " + Config.s[key];
        }
        function reset(): void { Config.reset(); }
    }
    IpcHandler {
        target: "theme"
        // Re-read the wallpaper and rerun matugen (sky/accent "wallpaper").
        function regen(): void { Wallpaper.regenerate(); }
        function wallpaper(): string { return Wallpaper.path; }
    }
    IpcHandler {
        target: "notify"
        // Local test notification that does not need DBus:
        //   qs ipc call notify demo "Hallo" "Text" 1
        function demo(summary: string, body: string, urgency: int): void {
            shell._demoId += 1;
            Notifs.receive({
                id: shell._demoId,
                appName: "kurtz",
                summary: summary,
                body: body,
                urgency: urgency,
                image: "",
                appIcon: "",
                actions: [],
                dismiss: function () {}
            });
        }
        function dnd(): void { Config.toggle("dnd"); }
        function clear(): void { Notifs.clearAll(); }
    }
    IpcHandler {
        target: "debug"
        function shot(name: string, path: string): string { return Shots.shot(name, path); }
        function items(): string { return Object.keys(Shots.items).join("\n"); }
    }
}
