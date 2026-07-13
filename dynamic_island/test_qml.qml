import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Process {
        id: proc
        command: ["sh", "-c", "printf '%s\\n' \"$@\" > test_out.txt", "arg0", "line 1", "line 2"]
        Component.onCompleted: proc.start()
    }
    Timer {
        interval: 1000
        running: true
        onTriggered: Qt.quit()
    }
}
