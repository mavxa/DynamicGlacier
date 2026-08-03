import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Wi-Fi network manager popup. Anchors to a window and opens near
// whatever item passed openAt() came from (the idle Wi-Fi row).
PopupWindow {
    id: root

    property var anchorWindow: null
    property bool radioEnabled: true
    property string activeSsid: ""
    property var networks: []
    property string expandedSsid: ""
    property string passwordDraft: ""
    property string statusText: ""
    property bool connecting: false

    anchor.window: root.anchorWindow
    color: "transparent"
    implicitWidth: 300
    implicitHeight: 440
    visible: false

    function openAt(x, y) {
        root.anchor.rect.x = x;
        root.anchor.rect.y = y;
        root.expandedSsid = "";
        root.passwordDraft = "";
        root.statusText = "";
        root.visible = true;
        radioStateProc.exec(["sh", "-c", "nmcli -t -f WIFI radio"]);
        root.scan();
    }

    function close() {
        root.visible = false;
        root.expandedSsid = "";
        root.passwordDraft = "";
    }

    function scan() {
        scanProc.exec(["sh", "-c", "nmcli -t -f active,ssid,signal,security dev wifi list --rescan yes 2>/dev/null"]);
    }

    function unescapeField(value) {
        return value.replace(/\\:/g, ":");
    }

    function parseNetworks(text) {
        const lines = text.split("\n").filter(line => line.trim() !== "");
        const parsed = [];
        const seen = {};

        for (let i = 0; i < lines.length; i += 1) {
            const parts = lines[i].split(/(?<!\\):/);

            if (parts.length < 4)
                continue;

            const active = parts[0] === "yes";
            const ssid = root.unescapeField(parts[1]);
            const signal = parseInt(parts[2]) || 0;
            const security = parts.slice(3).join(":");
            const secured = security !== "" && security !== "--";

            if (ssid === "" || seen[ssid])
                continue;

            seen[ssid] = true;
            parsed.push({
                ssid: ssid,
                signal: signal,
                secured: secured,
                active: active
            });

            if (active)
                root.activeSsid = ssid;
        }

        parsed.sort((a, b) => b.signal - a.signal);
        root.networks = parsed;
    }

    function toggleRadio() {
        const nextState = !root.radioEnabled;

        root.radioEnabled = nextState;
        radioToggleProc.exec(["sh", "-c", "nmcli radio wifi " + (nextState ? "on" : "off")]);
    }

    function requestExpand(ssid) {
        root.expandedSsid = root.expandedSsid === ssid ? "" : ssid;
        root.passwordDraft = "";
        root.statusText = "";
    }

    function connectToNetwork(ssid, secured) {
        root.connecting = true;
        root.statusText = "";

        const escapedSsid = ssid.replace(/"/g, "\\\"");

        if (secured) {
            const escapedPassword = root.passwordDraft.replace(/"/g, "\\\"");
            connectProc.exec(["sh", "-c", "nmcli dev wifi connect \"" + escapedSsid + "\" password \"" + escapedPassword + "\" 2>&1"]);
        } else {
            connectProc.exec(["sh", "-c", "nmcli dev wifi connect \"" + escapedSsid + "\" 2>&1"]);
        }
    }

    function disconnectFromNetwork(ssid) {
        root.connecting = true;

        const escapedSsid = ssid.replace(/"/g, "\\\"");
        disconnectProc.exec(["sh", "-c", "nmcli con down id \"" + escapedSsid + "\" 2>&1"]);
    }

    Process {
        id: radioStateProc

        stdout: StdioCollector {
            onStreamFinished: root.radioEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: scanProc

        stdout: StdioCollector {
            onStreamFinished: root.parseNetworks(text)
        }
    }

    Process {
        id: radioToggleProc

        onExited: root.scan()
    }

    Process {
        id: connectProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false;

                if (text.toLowerCase().indexOf("error") !== -1) {
                    root.statusText = "Connection failed";
                } else {
                    root.expandedSsid = "";
                    root.passwordDraft = "";
                    root.statusText = "";
                }

                root.scan();
            }
        }
    }

    Process {
        id: disconnectProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false;
                root.expandedSsid = "";
                root.scan();
            }
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible

        onCleared: root.close()
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.visible
        onTriggered: root.scan()
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#0b0b0b"
        border.width: 1
        border.color: "#232323"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: "#3f7fe0"

                    MIcon {
                        anchors.centerIn: parent
                        name: "wifi"
                        size: 20
                        color: "#ffffff"
                        filled: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: "#f5f5f5"
                    font.family: "Noto Sans"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }

                Rectangle {
                    id: radioToggle

                    width: 46
                    height: 26
                    radius: 13
                    color: root.radioEnabled ? "#3f7fe0" : "#2a2a2a"

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#ffffff"
                        y: 3
                        x: root.radioEnabled ? parent.width - width - 3 : 3

                        Behavior on x {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleRadio()
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: networkColumn.height
                clip: true
                visible: root.radioEnabled

                ColumnLayout {
                    id: networkColumn

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.networks

                        delegate: Rectangle {
                            id: row

                            required property var modelData

                            readonly property bool expanded: root.expandedSsid === modelData.ssid

                            Layout.fillWidth: true
                            Layout.preferredHeight: expanded ? expandedContent.implicitHeight + 54 : 44
                            radius: 14
                            color: expanded ? "#1c1c1c" : (rowMouse.containsMouse ? "#161616" : "transparent")

                            Behavior on Layout.preferredHeight {
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    MIcon {
                                        name: modelData.signal >= 70 ? "wifi" : modelData.signal >= 40 ? "wifi_2_bar" : "wifi_1_bar"
                                        size: 15
                                        color: "#e5e5e5"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.ssid
                                        color: "#f2f2f2"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    MIcon {
                                        name: "lock"
                                        size: 13
                                        color: "#9c9c9c"
                                        visible: modelData.secured
                                    }

                                    MIcon {
                                        name: "check"
                                        size: 15
                                        color: "#5b9bf8"
                                        visible: modelData.active
                                    }
                                }

                                ColumnLayout {
                                    id: expandedContent

                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: row.expanded

                                    Text {
                                        visible: modelData.active
                                        text: "Disconnect from this network?"
                                        color: "#c7c7c7"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        visible: !modelData.active && modelData.secured
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 10
                                        color: "#101010"
                                        border.width: 1
                                        border.color: "#2a2a2a"

                                        TextInput {
                                            id: passwordInput

                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: Text.AlignVCenter
                                            echoMode: TextInput.Password
                                            color: "#f0f0f0"
                                            font.family: "Noto Sans"
                                            font.pixelSize: 13
                                            clip: true
                                            text: root.passwordDraft
                                            onTextChanged: root.passwordDraft = text
                                            onAccepted: root.connectToNetwork(modelData.ssid, modelData.secured)

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Password"
                                                color: "#5f5f5f"
                                                visible: passwordInput.text === ""
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
                                            }
                                        }
                                    }

                                    Text {
                                        visible: root.statusText !== "" && row.expanded
                                        text: root.statusText
                                        color: "#f0736a"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            radius: 16
                                            color: "#2a2a2a"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                color: "#e5e5e5"
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.requestExpand(modelData.ssid)
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            radius: 16
                                            color: modelData.active ? "#c0453f" : "#3f7fe0"

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.connecting ? "..." : (modelData.active ? "Disconnect" : "Connect")
                                                color: "#ffffff"
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: !root.connecting
                                                onClicked: {
                                                    if (modelData.active)
                                                        root.disconnectFromNetwork(modelData.ssid);
                                                    else
                                                        root.connectToNetwork(modelData.ssid, modelData.secured);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.requestExpand(modelData.ssid)
                            }
                        }
                    }
                }
            }

            Text {
                visible: !root.radioEnabled
                Layout.fillWidth: true
                Layout.topMargin: 20
                horizontalAlignment: Text.AlignHCenter
                text: "Wi-Fi is off"
                color: "#7f7f7f"
                font.family: "Noto Sans"
                font.pixelSize: 13
            }
        }
    }
}
