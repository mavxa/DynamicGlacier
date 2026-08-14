import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: root

    property bool radioEnabled: false
    property bool discovering: false
    property var devices: []
    property string connectedDeviceName: ""
    property string statusText: ""
    property string fontFamily: "Noto Sans"
    property real morph: 0
    property int maxPanelHeight: 420

    readonly property color primaryText: "#f7f7f7"
    readonly property int panelPadding: 14
    readonly property int headerHeight: 30
    readonly property int sectionSpacing: 10
    readonly property int rowHeight: 42
    readonly property int rowSpacing: 4
    readonly property int placeholderHeight: 58
    readonly property real bodyHeight: root.radioEnabled && root.devices.length > 0 ? deviceColumn.implicitHeight : root.placeholderHeight
    readonly property real contentHeight: Math.min(root.maxPanelHeight, root.panelPadding * 2 + root.headerHeight + root.sectionSpacing + root.bodyHeight)
    readonly property real panelProgress: Math.max(0, Math.min(1, (root.morph - 0.22) / 0.78))

    signal closeRequested
    signal toggleRadioRequested
    signal refreshRequested
    signal deviceRequested(var device)

    function deviceName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown device";
    }

    function deviceGlyph(device) {
        const icon = (device?.icon || "").toLowerCase();

        if (icon.indexOf("head") !== -1 || icon.indexOf("audio") !== -1)
            return "headphones";
        if (icon.indexOf("keyboard") !== -1)
            return "keyboard";
        if (icon.indexOf("mouse") !== -1 || icon.indexOf("input-gaming") !== -1)
            return "mouse";
        if (icon.indexOf("phone") !== -1)
            return "smartphone";

        return "bluetooth";
    }

    function deviceStatus(device) {
        if (device?.pairing)
            return "Pairing…";
        if (device?.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device?.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";

        let status = device?.connected ? "Connected" : (device?.paired ? "Paired" : "Available");

        if (device?.batteryAvailable)
            status += "  ·  " + Math.round(device.battery * 100) + "%";

        return status;
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
                    name: "bluetooth"
                    size: 15
                    color: root.radioEnabled ? root.primaryText : "#555555"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: !root.radioEnabled ? "Off" : (root.connectedDeviceName !== "" ? root.connectedDeviceName : (root.discovering ? "Looking for devices" : "Not connected"))
                    color: root.connectedDeviceName !== "" ? "#c8c8c8" : "#555555"
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 22
                radius: 11
                color: root.radioEnabled ? "#f0f0f0" : "#0a0a0a"
                border.width: 1
                border.color: root.radioEnabled ? "#f0f0f0" : "#232323"

                Behavior on color {
                    ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    y: 3
                    x: root.radioEnabled ? parent.width - width - 3 : 3
                    color: root.radioEnabled ? "#000000" : "#4b4b4b"

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleRadioRequested()
                }
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: refreshMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                border.width: 1
                border.color: "#232323"
                opacity: root.radioEnabled ? 1 : 0.35

                MIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 12
                    color: "#999999"
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    enabled: root.radioEnabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.refreshRequested()
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

        Flickable {
            id: deviceList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: contentHeight > height
            contentHeight: deviceColumn.height
            boundsBehavior: Flickable.StopAtBounds
            visible: root.radioEnabled && root.devices.length > 0

            ColumnLayout {
                id: deviceColumn

                width: deviceList.width
                spacing: root.rowSpacing

                Repeater {
                    model: root.devices

                    delegate: Rectangle {
                        id: deviceRow

                        required property var modelData
                        required property int index

                        readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                        readonly property real appear: Math.max(0, Math.min(1, (root.morph - Math.min(index, 6) * 0.045) / 0.55))

                        Layout.fillWidth: true
                        Layout.preferredHeight: root.rowHeight
                        radius: 13
                        color: modelData.connected ? "#0a0a0a" : (deviceMouse.containsMouse ? "#101010" : "transparent")
                        border.width: 1
                        border.color: modelData.connected ? "#232323" : "transparent"
                        opacity: appear

                        transform: Translate { y: (1 - deviceRow.appear) * 12 }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 9

                            MIcon {
                                name: root.deviceGlyph(deviceRow.modelData)
                                size: 16
                                color: deviceRow.modelData.connected ? "#5b9bf8" : "#d0d0d0"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceName(deviceRow.modelData)
                                    color: root.primaryText
                                    elide: Text.ElideRight
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceStatus(deviceRow.modelData)
                                    color: deviceRow.modelData.connected ? "#8eb7f2" : "#666666"
                                    elide: Text.ElideRight
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }

                            MIcon {
                                name: deviceRow.busy ? "hourglass_top" : (deviceRow.modelData.connected ? "link_off" : "link")
                                size: 14
                                color: deviceRow.modelData.connected ? "#d0d0d0" : "#777777"
                            }
                        }

                        MouseArea {
                            id: deviceMouse

                            anchors.fill: parent
                            enabled: !deviceRow.busy
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.WaitCursor
                            onClicked: root.deviceRequested(deviceRow.modelData)
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.radioEnabled || root.devices.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 4

                MIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: root.radioEnabled ? "bluetooth_searching" : "bluetooth_disabled"
                    size: 20
                    color: "#555555"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.radioEnabled ? "Bluetooth is off" : (root.discovering ? "Looking for devices…" : "No devices found")
                    color: "#666666"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.statusText !== ""
            text: root.statusText
            color: "#d18b8b"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }
}
