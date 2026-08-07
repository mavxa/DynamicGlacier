import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

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
    property string volumeKind: "audio"
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property bool shuffleActive: false
    property bool shuffleSupported: false
    property string loopStateText: "OFF"
    property bool loopActive: false
    property bool loopSupported: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool forceExpanded: false
    property bool mediaAvailable: false
    property string handleStyle: "bump"
    property string batteryHoverText: ""
    property bool batteryCharging: false
    property int batteryLevel: 0
    property bool wifiConnected: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool btEnabled: false
    property bool btConnected: false
    property string btDeviceName: ""
    property int btBattery: -1
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: "Noto Sans"

    // Geometry the shell asks for. The surface owns the actual width/height so the
    // morph between shapes can be expressed as States + Transitions.
    property real targetW: 0
    property real targetH: 0
    property int wifiMaxPanelHeight: 420
    property int appsMaxPanelHeight: 470

    // 0 = island, 1 = Wi-Fi manager. Animated by the morph transition and shared
    // with the content layer so shape and contents move as one.
    property real wifiMorph: 0
    readonly property real wifiPanelHeight: islandContent.wifiContentHeight

    // Same idea for the favorites dock. Only one of the two morphs is ever
    // non-zero, since the island can only be in one panel mode at a time.
    property real appsMorph: 0
    readonly property real appsPanelHeight: islandContent.appsContentHeight

    // 0 = island, 1 = volume HUD. Same mechanism as the two panels above, so the
    // pill grows out of the handle instead of being painted on top of it.
    property real volumeMorph: 0

    readonly property bool expanded: mode !== "idle" || forceExpanded
    // The volume pill rounds all the way to a capsule as it morphs in; every other
    // expanded shape keeps the softer island corner.
    readonly property real expandedBottomRadius: {
        const islandRadius = Math.min(height * 0.28, 24);

        return islandRadius + (height / 2 - islandRadius) * root.volumeMorph;
    }
    readonly property real bottomRadius: Math.max(1, Math.min(height / 2, expanded ? expandedBottomRadius : Math.min(height * 0.42, 8)))
    readonly property color surfaceColor: !expanded && handleStyle === "strip" ? "#0c0c0c" : "#000000"
    readonly property real antiCornerRadius: root.expanded || handleStyle === "strip" ? Math.min(3, height * 0.6) : Math.min(2.5, height * 0.12)

    property bool wifiRadioEnabled: true
    property var wifiNetworks: []
    property string wifiExpandedSsid: ""
    property string wifiPasswordDraft: ""
    property string wifiStatusText: ""
    property bool wifiConnecting: false

    property var favoriteAppEntries: []
    property var favoriteAppIds: []
    property var appsPickerEntries: []
    property bool appsPickerOpen: false
    property string appsSearchDraft: ""
    property string appsStatusText: ""
    property int appsFavoriteSlots: 8

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal shuffleRequested
    signal loopRequested
    signal favoriteRequested
    signal dismissRequested
    signal wifiSettingsRequested
    signal wifiCloseRequested
    signal wifiToggleRadioRequested
    signal wifiRowRequested(string ssid)
    signal wifiConnectRequested(string ssid, bool secured)
    signal wifiDisconnectRequested(string ssid)
    signal wifiPasswordChanged(string text)
    signal appsSettingsRequested
    signal appsCloseRequested
    signal appsPickerToggleRequested
    signal appsSearchChanged(string text)
    signal appsSearchAccepted
    signal appsFavoriteToggleRequested(string id)
    signal appsLaunchRequested(string id)
    signal btSettingsRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)

    transformOrigin: Item.Top

    // Anti-corner left: smooth concave curve merging island into screen edge
    Shape {
        id: antiCornerLeft

        x: -antiCornerLeft.width
        y: 0
        width: root.antiCornerRadius
        height: root.antiCornerRadius * 0.65
        opacity: root.antiCornerRadius > 0 ? 1 : 0
        visible: opacity > 0
        antialiasing: true

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: "transparent"
            startX: antiCornerLeft.width
            startY: 0
            PathLine {
                x: antiCornerLeft.width
                y: antiCornerLeft.height
            }
            PathCubic {
                x: 0; y: 0
                control1X: antiCornerLeft.width * 0.45
                control1Y: antiCornerLeft.height
                control2X: 0
                control2Y: antiCornerLeft.height * 0.3
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
    }

    // Anti-corner right: smooth concave curve merging island into screen edge
    Shape {
        id: antiCornerRight

        x: root.width
        y: 0
        width: root.antiCornerRadius
        height: root.antiCornerRadius * 0.65
        opacity: root.antiCornerRadius > 0 ? 1 : 0
        visible: opacity > 0
        antialiasing: true

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: 0
                y: antiCornerRight.height
            }
            PathCubic {
                x: antiCornerRight.width; y: 0
                control1X: antiCornerRight.width * 0.55
                control1Y: antiCornerRight.height
                control2X: antiCornerRight.width
                control2Y: antiCornerRight.height * 0.3
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 360; easing.type: Easing.OutCubic }
        }
    }

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
            color: root.surfaceColor
        }

        Rectangle {
            z: 0
            anchors.fill: parent
            radius: root.bottomRadius
            color: root.surfaceColor
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
            id: islandContent

            z: 10
            anchors.fill: parent
            // Padding relaxes to zero as a panel takes over — panels bring their own.
            anchors.margins: root.expanded ? (root.mode === "media" ? 10 : 12) * (1 - root.wifiMorph) * (1 - root.appsMorph) * (1 - root.volumeMorph) : 0
            wifiMorph: root.wifiMorph
            wifiMaxPanelHeight: root.wifiMaxPanelHeight
            appsMorph: root.appsMorph
            appsMaxPanelHeight: root.appsMaxPanelHeight
            volumeMorph: root.volumeMorph
            volumeKind: root.volumeKind
            mode: root.mode
            handleStyle: root.handleStyle
            forceExpanded: root.forceExpanded
            appName: root.appName
            title: root.title
            body: root.body
            artist: root.artist
            artUrl: root.artUrl
            volume: root.volume
            muted: root.muted
            playing: root.playing
            canGoPrevious: root.canGoPrevious
            canTogglePlaying: root.canTogglePlaying
            canGoNext: root.canGoNext
            canSeek: root.canSeek
            shuffleActive: root.shuffleActive
            shuffleSupported: root.shuffleSupported
            loopStateText: root.loopStateText
            loopActive: root.loopActive
            loopSupported: root.loopSupported
            mediaPosition: root.mediaPosition
            mediaLength: root.mediaLength
            mediaAvailable: root.mediaAvailable
            fontFamily: root.fontFamily
            batteryHoverText: root.batteryHoverText
            batteryCharging: root.batteryCharging
            batteryLevel: root.batteryLevel
            wifiConnected: root.wifiConnected
            wifiSsid: root.wifiSsid
            wifiSignal: root.wifiSignal
            btEnabled: root.btEnabled
            btConnected: root.btConnected
            btDeviceName: root.btDeviceName
            btBattery: root.btBattery
            timeText: root.timeText
            dateText: root.dateText
            wifiRadioEnabled: root.wifiRadioEnabled
            wifiNetworks: root.wifiNetworks
            wifiExpandedSsid: root.wifiExpandedSsid
            wifiPasswordDraft: root.wifiPasswordDraft
            wifiStatusText: root.wifiStatusText
            wifiConnecting: root.wifiConnecting
            favoriteAppEntries: root.favoriteAppEntries
            favoriteAppIds: root.favoriteAppIds
            appsPickerEntries: root.appsPickerEntries
            appsPickerOpen: root.appsPickerOpen
            appsSearchDraft: root.appsSearchDraft
            appsStatusText: root.appsStatusText
            appsFavoriteSlots: root.appsFavoriteSlots
            onPreviousRequested: root.previousRequested()
            onPlayPauseRequested: root.playPauseRequested()
            onNextRequested: root.nextRequested()
            onShuffleRequested: root.shuffleRequested()
            onLoopRequested: root.loopRequested()
            onFavoriteRequested: root.favoriteRequested()
            onDismissRequested: root.dismissRequested()
            onWifiSettingsRequested: root.wifiSettingsRequested()
            onWifiCloseRequested: root.wifiCloseRequested()
            onWifiToggleRadioRequested: root.wifiToggleRadioRequested()
            onWifiRowRequested: ssid => root.wifiRowRequested(ssid)
            onWifiConnectRequested: (ssid, secured) => root.wifiConnectRequested(ssid, secured)
            onWifiDisconnectRequested: ssid => root.wifiDisconnectRequested(ssid)
            onWifiPasswordChanged: text => root.wifiPasswordChanged(text)
            onAppsSettingsRequested: root.appsSettingsRequested()
            onAppsCloseRequested: root.appsCloseRequested()
            onAppsPickerToggleRequested: root.appsPickerToggleRequested()
            onAppsSearchChanged: text => root.appsSearchChanged(text)
            onAppsSearchAccepted: root.appsSearchAccepted()
            onAppsFavoriteToggleRequested: id => root.appsFavoriteToggleRequested(id)
            onAppsLaunchRequested: id => root.appsLaunchRequested(id)
            onBtSettingsRequested: root.btSettingsRequested()
            onSeekRequested: position => root.seekRequested(position)
            onHandleStyleRequested: style => root.handleStyleRequested(style)
        }
    }

    // Height is a plain binding, not part of the state, so it can re-target while
    // the morph is still running — the network list usually lands mid-transition,
    // and the app picker drawer opens long after the morph has settled.
    height: root.mode === "wifi" ? Math.max(root.targetH, root.wifiPanelHeight) : (root.mode === "apps" ? Math.max(root.targetH, root.appsPanelHeight) : root.targetH)

    state: root.mode !== "idle" ? root.mode : (root.forceExpanded ? "peek" : "collapsed")

    states: [
        State {
            name: "collapsed"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 0
                root.volumeMorph: 0
            }
        },
        State {
            name: "peek"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 0
                root.volumeMorph: 0
            }
        },
        State {
            name: "notify"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 0
                root.volumeMorph: 0
            }
        },
        State {
            name: "media"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 0
                root.volumeMorph: 0
            }
        },
        State {
            name: "volume"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 0
                root.volumeMorph: 1
            }
        },
        State {
            name: "wifi"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 1
                root.appsMorph: 0
                root.volumeMorph: 0
            }
        },
        State {
            name: "apps"

            PropertyChanges {
                root.width: root.targetW
                root.wifiMorph: 0
                root.appsMorph: 1
                root.volumeMorph: 0
            }
        }
    ]

    transitions: [
        // Morph into the Wi-Fi manager: the shape widens first, then unfolds
        // downward with a slight overshoot while the contents cross-fade.
        Transition {
            to: "wifi"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 340
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.7
                }

                NumberAnimation {
                    property: "wifiMorph"
                    duration: 440
                    easing.type: Easing.OutCubic
                }
            }
        },
        // Morph back: fold the height away first, then settle the width.
        Transition {
            from: "wifi"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 300
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    property: "wifiMorph"
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        },
        // Morph into the favorites dock. Same choreography as Wi-Fi so the two
        // panels feel like the same gesture: widen with a small overshoot while
        // the grid unfolds and the peek cross-fades out.
        Transition {
            to: "apps"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 340
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.7
                }

                NumberAnimation {
                    property: "appsMorph"
                    duration: 440
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "apps"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 300
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    property: "appsMorph"
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        },
        // Volume HUD: the handle springs out sideways and the bar is already
        // there by the time the width settles, so the pill reads as one gesture
        // rather than a shape that fills in afterwards.
        Transition {
            to: "volume"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.9
                }

                NumberAnimation {
                    property: "volumeMorph"
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "volume"

            ParallelAnimation {
                NumberAnimation {
                    property: "width"
                    duration: 300
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    property: "volumeMorph"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            NumberAnimation {
                property: "width"
                duration: 360
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                properties: "wifiMorph,appsMorph,volumeMorph"
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    ]

    // Height is never animated by a transition, so this Behavior owns every height
    // change: the morph itself, networks arriving, and rows expanding.
    Behavior on width {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 300
            // Only the volume pill drops in with a bounce; panels stay damped so a
            // network list arriving mid-morph doesn't wobble the whole surface.
            easing.type: root.mode === "volume" ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 0.9
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }
    }
}
