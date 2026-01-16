import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 1920
    height: 1080
    color: "transparent"  // Transparent to let overlay plane show through

    // Simple UI overlay
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        color: "#AA000000"  // Semi-transparent black bar

        Text {
            anchors.centerIn: parent
            text: "Qt UI Overlay - Video on DRM Plane"
            color: "white"
            font.pixelSize: 32
        }
    }

    // Clock widget in corner
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 200
        height: 60
        radius: 10
        color: "#AA000000"

        Text {
            id: clock
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 28
            text: Qt.formatTime(new Date(), "hh:mm:ss")
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm:ss")
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
            Qt.quit()
        }
    }

    Component.onCompleted: {
        root.requestActivate()
    }
}
