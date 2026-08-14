import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string handleStyle: "bump"
    property string batteryText: ""
    property bool batteryCharging: false
    property int batteryLevel: 0
    property string statusText: ""
    property string fontFamily: "Noto Sans"
    property bool showBattery: false
    property bool compact: false

    signal handleStyleRequested(string style)
    signal batteryRequested

    Layout.fillWidth: true
    Layout.preferredHeight: root.compact ? 15 : 17
    spacing: root.compact ? 7 : 8

    // Minimalist pill toggle
    Rectangle {
        id: toggle

        Layout.preferredWidth: root.compact ? 20 : 24
        Layout.preferredHeight: root.compact ? 10 : 12
        radius: height / 2
        color: "#151515"
        border.width: 1
        border.color: "#2a2a2a"

        Rectangle {
            id: dot

            width: parent.height - 4
            height: width
            radius: width / 2
            color: root.handleStyle === "bump" ? "#d9d9d9" : "#777777"
            y: 2
            x: root.handleStyle === "bump" ? 2 : parent.width - width - 2

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: 180 }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.handleStyleRequested(root.handleStyle === "bump" ? "strip" : "bump")
        }
    }

    Item {
        Layout.fillWidth: true

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.statusText
            color: "#9c9c9c"
            visible: root.statusText !== ""
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: root.compact ? 10 : 11
            font.weight: Font.DemiBold
        }
    }

    Item {
        visible: root.showBattery && root.batteryLevel > 0
        Layout.preferredWidth: batteryRow.width
        Layout.preferredHeight: batteryRow.height

        Row {
            id: batteryRow

            spacing: 3

            MIcon {
                name: root.batteryCharging ? "bolt" : root.batteryLevel <= 20 ? "battery_alert" : "battery_full"
                size: root.compact ? 12 : 13
                color: root.batteryCharging ? "#4ade80" : root.batteryLevel <= 20 ? "#f87171" : "#ececec"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.batteryLevel + "%"
                color: batteryMouse.containsMouse ? "#ffffff" : "#ececec"
                font.family: root.fontFamily
                font.pixelSize: root.compact ? 10 : 11
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: batteryMouse

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.batteryRequested()
        }
    }
}
