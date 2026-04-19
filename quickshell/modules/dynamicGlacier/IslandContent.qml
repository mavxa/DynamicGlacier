import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string mode: "idle"
    property string appName: ""
    property string title: ""
    property string body: ""
    property string artist: ""
    property int volume: 0
    property bool muted: false
    property bool playing: false
    property bool forceExpanded: false
    property string handleStyle: "bump"
    property string fontFamily: "Noto Sans"
    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#7f7f7f"
    readonly property color accent: "#ffffff"

    Item {
        id: idleContent

        anchors.fill: parent
        opacity: root.mode === "idle" && root.forceExpanded ? 1 : 0
        visible: opacity > 0

        RowLayout {
            anchors.centerIn: parent
            width: parent.width - 24
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 8
                radius: height / 2
                color: "#151515"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Dynamic Glacier"
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: "minimal island"
                    color: root.secondaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }

        }

    }

    RowLayout {
        id: notificationContent

        anchors.fill: parent
        spacing: 12
        opacity: root.mode === "notify" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 15
            color: "#000000"
            border.width: 1
            border.color: "#202020"

            Text {
                anchors.centerIn: parent
                text: "!"
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: 22
                font.bold: true
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.appName
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.primaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.body
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 12
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }

        }

    }

    RowLayout {
        id: mediaContent

        anchors.fill: parent
        spacing: 12
        opacity: root.mode === "media" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            radius: 17
            color: "#000000"
            border.width: 1
            border.color: root.playing ? "#2a2a2a" : "#171717"

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3

                    Rectangle {
                        width: 4
                        height: root.playing ? (12 + index * 5) : 10
                        radius: 2
                        color: root.playing ? root.accent : "#4b4b4b"

                        SequentialAnimation on height {
                            running: root.mode === "media" && root.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 10 + index * 4
                                duration: 360 + index * 80
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 23 - index * 3
                                duration: 420 + index * 80
                                easing.type: Easing.InOutSine
                            }

                        }

                    }

                }

            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.playing ? "Now playing" : "Paused"
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.primaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 12
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }

        }

    }

    RowLayout {
        id: volumeContent

        anchors.fill: parent
        spacing: 12
        opacity: root.mode === "volume" ? 1 : 0
        visible: opacity > 0

        Text {
            Layout.preferredWidth: 42
            text: root.muted ? "M" : "V"
            color: root.accent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.fontFamily
            font.pixelSize: 24
            font.weight: Font.Black
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.muted ? "Muted" : "Volume"
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.muted ? "0%" : root.volume + "%"
                    color: root.secondaryText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 7
                radius: height / 2
                color: "#171717"

                Rectangle {
                    width: parent.width * (root.muted ? 0 : root.volume / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.muted ? "#3f3f3f" : root.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 170
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }

        }

    }

}
