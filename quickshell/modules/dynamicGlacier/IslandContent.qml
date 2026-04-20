import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string mode: "idle"
    property string appName: ""
    property string title: ""
    property string body: ""
    property string artist: ""
    property string artUrl: ""
    property int volume: 0
    property bool muted: false
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool forceExpanded: false
    property string handleStyle: "bump"
    property string batteryHoverText: ""
    property string fontFamily: "Noto Sans"
    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#7f7f7f"
    readonly property color accent: "#ffffff"
    readonly property int mediaHorizontalPadding: 24
    readonly property real normalizedMediaPosition: root.normalizedSeconds(mediaPosition)
    readonly property real normalizedMediaLength: root.normalizedSeconds(mediaLength)
    readonly property real mediaProgress: normalizedMediaLength > 0 ? Math.max(0, Math.min(1, normalizedMediaPosition / normalizedMediaLength)) : 0

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)

    function normalizedSeconds(value) {
        if (!isFinite(value) || value <= 0)
            return 0;

        return value > 86400 ? value / 1000000 : value;
    }

    function formatTime(seconds) {
        const normalized = root.normalizedSeconds(seconds);

        if (normalized <= 0)
            return "0:00";

        const safeSeconds = Math.floor(normalized);
        const minutes = Math.floor(safeSeconds / 60);
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        const remainingSeconds = safeSeconds % 60;
        const secondText = remainingSeconds < 10 ? "0" + remainingSeconds : String(remainingSeconds);

        if (hours > 0) {
            const minuteText = remainingMinutes < 10 ? "0" + remainingMinutes : String(remainingMinutes);

            return hours + ":" + minuteText + ":" + secondText;
        }

        return minutes + ":" + secondText;
    }

    Item {
        id: idleContent

        anchors.fill: parent
        opacity: root.mode === "idle" && root.forceExpanded ? 1 : 0
        visible: opacity > 0

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 7
            spacing: 2

            HandleStyleSwitch {
                handleStyle: root.handleStyle
                batteryText: root.batteryHoverText
                fontFamily: root.fontFamily
                showBattery: true
                onHandleStyleRequested: style => root.handleStyleRequested(style)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "minimal island"
                        color: root.secondaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 9
                    }
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
        anchors.leftMargin: root.mediaHorizontalPadding
        anchors.rightMargin: root.mediaHorizontalPadding
        spacing: 24
        opacity: root.mode === "media" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            id: mediaArtwork

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 18
            color: "#000000"
            border.width: 1
            border.color: root.playing ? "#2a2a2a" : "#171717"
            clip: true

            Image {
                id: mediaCoverSource

                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: mediaCoverSource
                visible: root.artUrl !== "" && mediaCoverSource.status === Image.Ready

                maskSource: Rectangle {
                    width: mediaArtwork.width
                    height: mediaArtwork.height
                    radius: mediaArtwork.radius
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 3
                visible: root.artUrl === "" || mediaCoverSource.status !== Image.Ready

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
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 2

            HandleStyleSwitch {
                handleStyle: root.handleStyle
                batteryText: root.batteryHoverText
                fontFamily: root.fontFamily
                compact: true
                showBattery: true
                onHandleStyleRequested: style => root.handleStyleRequested(style)
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.primaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 11
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                visible: root.mediaLength > 0

                Text {
                    text: root.formatTime(root.mediaPosition)
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: mediaProgressTrack

                    Layout.fillWidth: true
                    Layout.preferredHeight: 3
                    radius: height / 2
                    color: "#151515"

                    Rectangle {
                        width: parent.width * root.mediaProgress
                        height: parent.height
                        radius: parent.radius
                        color: "#d8d8d8"

                        Behavior on width {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        enabled: root.canSeek
                        hoverEnabled: true
                        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                        function seekToX(x) {
                            const progress = Math.max(0, Math.min(1, x / Math.max(1, mediaProgressTrack.width)));
                            root.seekRequested(root.mediaLength * progress);
                        }

                        onPressed: event => seekToX(event.x)
                        onPositionChanged: event => {
                            if (pressed)
                                seekToX(event.x);
                        }
                    }
                }

                Text {
                    text: root.formatTime(root.mediaLength)
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 1
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: previousMouse.containsMouse && root.canGoPrevious ? "#151515" : "#090909"
                    border.width: 1
                    border.color: root.canGoPrevious ? "#232323" : "#111111"
                    opacity: root.canGoPrevious ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: "<<"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent
                        enabled: root.canGoPrevious
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.previousRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 12
                    color: playPauseMouse.containsMouse && root.canTogglePlaying ? "#191919" : "#0b0b0b"
                    border.width: 1
                    border.color: root.canTogglePlaying ? "#2b2b2b" : "#111111"
                    opacity: root.canTogglePlaying ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: root.playing ? "||" : ">"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: root.playing ? 11 : 13
                        font.weight: Font.Black
                    }

                    MouseArea {
                        id: playPauseMouse

                        anchors.fill: parent
                        enabled: root.canTogglePlaying
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playPauseRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: nextMouse.containsMouse && root.canGoNext ? "#151515" : "#090909"
                    border.width: 1
                    border.color: root.canGoNext ? "#232323" : "#111111"
                    opacity: root.canGoNext ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: ">>"
                        color: root.primaryText
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        enabled: root.canGoNext
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextRequested()
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }
        }
    }
}
