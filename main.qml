import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    title: "Quiz App - تجربة أولى"

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            text: "مرحباً 👋 النافذة تعمل بنجاح"
            font.pixelSize: 24
            color: "white"
        }
    }
}