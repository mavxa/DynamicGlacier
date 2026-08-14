import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool available: false
    property int level: 0
    property bool charging: false
    property real health: -1
    property int cycles: -1
    property real fullCapacityWh: -1
    property real designCapacityWh: -1
    property real voltage: -1
    property real power: -1
    property string status: ""
    property string model: ""
    property bool thresholdSupported: false
    property bool thresholdEnabled: false
    property bool thresholdBusy: false
    property int thresholdStart: -1
    property int thresholdEnd: -1
    property string thresholdStatusText: ""
    property string fontFamily: "Noto Sans"
    property real morph: 0

    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#777777"
    readonly property int panelPadding: 16
    readonly property int headerHeight: 32
    readonly property int overviewHeight: 70
    readonly property int tileHeight: 54
    readonly property int footerHeight: 12
    readonly property int sectionSpacing: 10
    readonly property int gridSpacing: 6
    readonly property real contentHeight: root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.overviewHeight + root.sectionSpacing + root.tileHeight + root.sectionSpacing + root.footerHeight
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal toggleThresholdRequested

    function formattedNumber(value, digits, suffix, fallback) {
        return value >= 0 && isFinite(value) ? value.toFixed(digits) + suffix : fallback;
    }

    function healthColor() {
        if (root.health < 0)
            return "#777777";
        if (root.health >= 85)
            return "#4ade80";
        if (root.health >= 70)
            return "#f2c14b";
        return "#f87171";
    }

    opacity: root.panelProgress
    visible: opacity > 0.001
    scale: 0.94 + 0.06 * root.panelProgress
    transformOrigin: Item.Top

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: root.sectionSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 10

            Rectangle {
                Layout.preferredWidth: root.headerHeight
                Layout.preferredHeight: root.headerHeight
                radius: 11
                color: "#090909"
                border.width: 1
                border.color: "#232323"

                MIcon {
                    anchors.centerIn: parent
                    name: root.charging ? "battery_charging_full" : "battery_full"
                    size: 15
                    color: root.charging ? "#4ade80" : root.primaryText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Battery"
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.model !== "" ? root.model : (root.available ? "Laptop battery" : "Not available")
                    color: root.secondaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                border.width: 1
                border.color: "#232323"

                MIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 12
                    color: "#999999"
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.overviewHeight
            radius: 16
            color: "#080808"
            border.width: 1
            border.color: "#202020"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 14

                ColumnLayout {
                    Layout.preferredWidth: 64
                    spacing: -2

                    Text {
                        text: root.level + "%"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 24
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.status !== "" ? root.status : (root.charging ? "Charging" : "Battery")
                        color: root.charging ? "#4ade80" : root.secondaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "Battery health"
                            color: "#bdbdbd"
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.health >= 0 ? root.health.toFixed(1) + "%" : "—"
                            color: root.healthColor()
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: height / 2
                        color: "#1a1a1a"

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.health / 100))
                            height: parent.height
                            radius: height / 2
                            color: root.healthColor()

                            Behavior on width {
                                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            columnSpacing: root.gridSpacing
            rowSpacing: root.gridSpacing

            Repeater {
                model: [
                    {
                        icon: "cached",
                        label: "Cycles",
                        value: root.cycles >= 0 ? String(root.cycles) : "—"
                    },
                    {
                        icon: "battery_5_bar",
                        label: "Full capacity",
                        value: root.formattedNumber(root.fullCapacityWh, 1, " Wh", "—")
                    },
                    {
                        icon: "electric_bolt",
                        label: "Voltage",
                        value: root.formattedNumber(root.voltage, 2, " V", "—")
                    },
                    {
                        icon: "battery_saver",
                        label: root.thresholdSupported && root.thresholdStart >= 0 && root.thresholdEnd > 0 ? "Limit · " + root.thresholdStart + "→" + root.thresholdEnd : "Charge limit",
                        value: root.thresholdSupported && root.thresholdEnd > 0 ? root.thresholdEnd + "% " + (root.thresholdEnabled ? "on" : "off") : "Unsupported",
                        action: "threshold"
                    }
                ]

                delegate: Rectangle {
                    id: infoTile

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.tileHeight
                    radius: 13
                    color: tileMouse.containsMouse && modelData.action === "threshold" && root.thresholdSupported ? "#101010" : "#080808"
                    border.width: 1
                    border.color: "#1c1c1c"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        MIcon {
                            name: modelData.icon
                            size: 15
                            color: modelData.action === "threshold" && root.thresholdEnabled ? "#4ade80" : "#8d8d8d"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: root.primaryText
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: root.secondaryText
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse

                        anchors.fill: parent
                        enabled: modelData.action === "threshold" && root.thresholdSupported && !root.thresholdBusy
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.toggleThresholdRequested()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.footerHeight
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.thresholdStatusText !== "" ? root.thresholdStatusText : (root.designCapacityWh > 0 ? "Designed for " + root.designCapacityWh.toFixed(1) + " Wh" : "")
                visible: text !== ""
                color: root.thresholdStatusText !== "" ? "#8eb7f2" : "#555555"
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 9
                font.weight: Font.Medium
            }

            Text {
                text: root.power >= 0.05 ? root.power.toFixed(1) + " W" : ""
                visible: text !== ""
                color: "#666666"
                font.family: root.fontFamily
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }
    }
}
