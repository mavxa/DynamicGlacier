import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string handleStyle: "bump"
    property string batteryText: ""
    property string fontFamily: "Noto Sans"
    property bool showBattery: false
    property bool compact: false

    signal handleStyleRequested(string style)

    Layout.fillWidth: true
    Layout.preferredHeight: root.compact ? 10 : 12
    spacing: root.compact ? 6 : 7

    Text {
        text: "bump"
        color: root.handleStyle === "bump" ? "#d9d9d9" : "#555555"
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 7 : 8
        font.weight: root.handleStyle === "bump" ? Font.DemiBold : Font.Medium

        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.handleStyleRequested("bump")
        }
    }

    Text {
        text: "/"
        color: "#303030"
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 7 : 8
        font.weight: Font.DemiBold
    }

    Text {
        text: "strip"
        color: root.handleStyle === "strip" ? "#d9d9d9" : "#555555"
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 7 : 8
        font.weight: root.handleStyle === "strip" ? Font.DemiBold : Font.Medium

        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.handleStyleRequested("strip")
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Text {
        text: root.batteryText
        color: "#666666"
        visible: root.showBattery && root.batteryText !== ""
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 7 : 8
        font.weight: Font.DemiBold
    }
}
