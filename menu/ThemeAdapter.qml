pragma Singleton
import QtQuick

// The menu's own live theme: always mirrors whichever bar is currently
// active (BarsModel.activeBar), so it updates the instant a switch
// completes and BarsModel.activeBar changes.
BarTheme {
    barName: BarsModel.activeBar
}
