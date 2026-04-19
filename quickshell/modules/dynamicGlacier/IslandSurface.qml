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
    property string fontFamily: "Noto Sans"
    readonly property bool expanded: mode !== "idle" || forceExpanded
    readonly property real bottomRadius: height / 2

    transformOrigin: Item.Top

    Rectangle {
        id: shadow

        anchors.fill: bodyShape
        anchors.topMargin: 8
        radius: root.bottomRadius
        color: "#000000"
        opacity: 0
        scale: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        id: outerGlow

        anchors.fill: bodyShape
        anchors.margins: -1
        radius: root.bottomRadius + 1
        color: "transparent"
        border.width: 1
        border.color: "#000000"
        opacity: 0
    }

    Item {
        id: bodyShape

        anchors.fill: parent
        clip: true

        Rectangle {
            z: 1
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: Math.ceil(parent.height / 2)
            color: "#000000"
        }

        Rectangle {
            z: 0
            anchors.fill: parent
            radius: root.bottomRadius
            color: "#000000"
        }

        Rectangle {
            id: coldSheen

            x: parent.width * 0.08
            y: 3
            width: parent.width * 0.84
            height: Math.max(6, parent.height * 0.32)
            radius: height / 2
            opacity: 0

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#00243a00"
                }

                GradientStop {
                    position: 0.34
                    color: "#55d7ff"
                }

                GradientStop {
                    position: 0.68
                    color: "#d6fbff"
                }

                GradientStop {
                    position: 1
                    color: "#00243a00"
                }

            }

        }

        Rectangle {
            id: leftCore

            width: root.expanded ? 84 : 42
            height: width
            radius: width / 2
            x: -width * 0.38
            y: -width * 0.18
            color: "#000000"
            opacity: 0
        }

        Rectangle {
            id: rightCore

            width: root.expanded ? 96 : 48
            height: width
            radius: width / 2
            x: parent.width - width * 0.58
            y: parent.height - width * 0.68
            color: "#000000"
            opacity: 0
        }

        IslandContent {
            z: 10
            anchors.fill: parent
            anchors.margins: root.expanded ? 12 : 0
            mode: root.mode
            forceExpanded: root.forceExpanded
            appName: root.appName
            title: root.title
            body: root.body
            artist: root.artist
            volume: root.volume
            muted: root.muted
            playing: root.playing
            fontFamily: root.fontFamily
        }

    }

    Behavior on width {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }

    }

    Behavior on height {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }

    }

    Behavior on y {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }

    }

}
