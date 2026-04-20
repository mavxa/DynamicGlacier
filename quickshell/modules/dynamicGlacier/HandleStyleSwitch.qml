import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string handleStyle: "bump"
    property string batteryText: ""
    property string statusText: ""
    property string fontFamily: "Noto Sans"
    property bool showBattery: false
    property bool compact: false

    signal handleStyleRequested(string style)

    Layout.fillWidth: true
    Layout.preferredHeight: root.compact ? 12 : 14
    spacing: root.compact ? 6 : 7

    Text {
        text: "bump"
        color: root.handleStyle === "bump" ? "#d9d9d9" : "#555555"
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 8 : 9
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
        font.pixelSize: root.compact ? 8 : 9
        font.weight: Font.DemiBold
    }

    Text {
        text: "strip"
        color: root.handleStyle === "strip" ? "#d9d9d9" : "#555555"
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 8 : 9
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
            font.pixelSize: root.compact ? 8 : 9
            font.weight: Font.DemiBold
        }
    }

    Text {
        text: root.batteryText
        color: "#ececec"
        visible: root.showBattery && root.batteryText !== ""
        font.family: root.fontFamily
        font.pixelSize: root.compact ? 8 : 9
        font.weight: Font.Bold
    }
}
