import QtQuick
import Quickshell
import Quickshell.Io

// Bescherung: jede Anzeige ist ein Geschenk. Beim Start packt sich die
// Leiste selbst aus, Popups springen wie Springteufel heraus, und jeden Tag
// liegt ein neues Paeckchen in der Mitte.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    LazyLoader {
        active: Popups.popup === "surprise"
        JackBox {
            cardWidth: 400
            cardHeight: surprise.implicitHeight + 56
            SurpriseCard {
                id: surprise
            }
        }
    }
    LazyLoader {
        active: Popups.popup === "power"
        JackBox {
            cardWidth: 340
            cardHeight: power.implicitHeight + 56
            PowerCard {
                id: power
            }
        }
    }
    // Eigener Loader pro Oeffnen: mango gibt einer On-Demand-Ebene nur beim
    // ersten Commit Tastaturfokus, also braucht jedes Oeffnen eine frische
    // Surface.
    LazyLoader {
        active: Popups.popup === "launcher"
        JackBox {
            keyboard: true
            cardWidth: 440
            cardHeight: 480
            Launcher {}
        }
    }

    //   qs -p <bar> ipc call bescherung launcher
    IpcHandler {
        target: "bescherung"
        function launcher(): void {
            Popups.toggleFocused("launcher", 5);
        }
        function power(): void {
            Popups.toggleFocused("power", 6);
        }
        function tagesgeschenk(): void {
            Surprises.open();
            Popups.toggleFocused("surprise", Surprises.paper);
        }
        function nochmal(): void {
            Popups.bescherungRequested();
        }
        function zukleben(): void {
            Surprises.reset();
        }
        function shot(name: string, path: string): string {
            return Shots.shot(name, path);
        }
    }
}
