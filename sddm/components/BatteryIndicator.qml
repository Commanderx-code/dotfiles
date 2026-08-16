import QtQuick

Item {
    id: root

    property int capacity: 0
    property string status: "Unknown"

    width: batteryRow.implicitWidth
    height: batteryRow.implicitHeight

    function updateBattery() {
        var cap = new XMLHttpRequest()
        cap.open("GET", "file:///sys/class/power_supply/BAT0/capacity")
        cap.onreadystatechange = function() {
            if (cap.readyState === XMLHttpRequest.DONE &&
                (cap.status === 0 || cap.status === 200)) {
                root.capacity = parseInt(cap.responseText.trim())
                }
        }
        cap.send()

        var stat = new XMLHttpRequest()
        stat.open("GET", "file:///sys/class/power_supply/BAT0/status")
        stat.onreadystatechange = function() {
            if (stat.readyState === XMLHttpRequest.DONE &&
                (stat.status === 0 || stat.status === 200)) {
                root.status = stat.responseText.trim()
                }
        }
        stat.send()
    }

    property color batteryColor: capacity <= 20 ? "#ff5555" : "#FFFFFF"
    property bool charging: status === "Charging"

    Row {
        id: batteryRow
        spacing: 7

        anchors.verticalCenter: parent.verticalCenter

        Item {
            width: 21
            height: 14

            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: batteryBody

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: 17
                height: 10
                radius: 2

                color: "transparent"
                border.color: root.batteryColor
                border.width: 1

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter

                    width: Math.max(
                        1,
                        Math.round((root.capacity / 100.0) * 13)
                    )

                    height: 6
                    radius: 1
                    color: root.batteryColor
                }
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: 1
                anchors.verticalCenter: batteryBody.verticalCenter

                width: 2
                height: 5
                radius: 1
                color: root.batteryColor
            }

            Text {
                visible: root.charging

                anchors.centerIn: batteryBody

                text: "⚡"
                color: "#FFFFFF"
                font.pixelSize: 9
                font.bold: true
            }
        }

        Text {
            id: batteryText

            anchors.verticalCenter: parent.verticalCenter

            text: root.capacity + "%"
            color: root.batteryColor

            font.pixelSize: 16
            font.bold: true
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: root.updateBattery()
    }
}
