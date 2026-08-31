//@ pragma UseQApplication
// ^ required for QsMenuAnchor (tray right-click menus) — without it
//   open() errors: "quickshell was not started in QApplication mode"

import Quickshell
import "overlays"

ShellRoot {
    TopBar {}
    BottomBar {}
    Overlays {}
}
