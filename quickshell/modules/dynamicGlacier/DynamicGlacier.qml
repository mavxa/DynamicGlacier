import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property string mode: "idle"
    property string appName: "Dynamic Glacier"
    property string title: "Ready"
    property string body: "Waiting for a signal"
    property string artist: ""
    property int volume: 42
    property bool muted: false
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool pinnedOpen: false
    property string handleStyle: "bump"
    property int demoStep: 0

    readonly property bool interactionOpen: root.mode === "idle" && (root.pointerInside || root.pinnedOpen)
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: 16
    readonly property int windowHeight: 112
    readonly property int bumpWidth: 76
    readonly property int bumpHeight: 16
    readonly property int stripWidth: 168
    readonly property int stripHeight: 4
    readonly property int peekWidth: 292
    readonly property int peekHeight: 48
    readonly property int notifyWidth: 438
    readonly property int notifyHeight: 74
    readonly property int mediaWidth: 398
    readonly property int mediaHeight: 70
    readonly property int volumeWidth: 276
    readonly property int volumeHeight: 58
    readonly property string fontFamily: "Noto Sans"

    function targetWidth() {
        switch (root.mode) {
        case "notify":
            return root.notifyWidth;
        case "media":
            return root.mediaWidth;
        case "volume":
            return root.volumeWidth;
        default:
            if (root.interactionOpen)
                return root.peekWidth;
            return root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth;
        }
    }

    function targetHeight() {
        switch (root.mode) {
        case "notify":
            return root.notifyHeight;
        case "media":
            return root.mediaHeight;
        case "volume":
            return root.volumeHeight;
        default:
            if (root.interactionOpen)
                return root.peekHeight;
            return root.handleStyle === "strip" ? root.stripHeight : root.bumpHeight;
        }
    }

    function targetY() {
        return root.mode === "idle" && !root.interactionOpen ? root.idleTopMargin : root.expandedTopMargin;
    }

    function hold(milliseconds) {
        collapseTimer.interval = milliseconds;
        collapseTimer.restart();
    }

    function showIdle() {
        collapseTimer.stop();
        root.mode = "idle";
        root.pinnedOpen = false;
        root.title = "Ready";
        root.body = "Waiting for a signal";
    }

    function setHandleStyle(style) {
        if (style === "strip" || style === "bump")
            root.handleStyle = style;
    }

    function toggleHandleStyle() {
        root.handleStyle = root.handleStyle === "strip" ? "bump" : "strip";
    }

    function showNotification(summary, message, app) {
        root.appName = app || "Notification";
        root.title = summary || "New notification";
        root.body = message || "";
        root.mode = "notify";
        root.hold(5200);
    }

    function showMedia(trackTitle, trackArtist, isPlaying) {
        root.title = trackTitle || "Unknown track";
        root.artist = trackArtist || "Unknown artist";
        root.playing = isPlaying;
        root.mode = "media";
        root.hold(6200);
    }

    function showVolume(level, isMuted) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = isMuted;
        root.title = root.muted ? "Muted" : "Volume";
        root.mode = "volume";
        root.hold(1700);
    }

    function demo() {
        const step = root.demoStep % 4;
        root.demoStep += 1;

        if (step === 0) {
            root.showNotification("Build finished", "Dynamic Glacier rendered its first island.", "Codex");
        } else if (step === 1) {
            root.showMedia("Subzero Signal", "Glacier FM", true);
        } else if (step === 2) {
            root.showVolume(68, false);
        } else {
            root.showIdle();
        }
    }

    function focusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;

        if (focusedMonitor) {
            for (let i = 0; i < Quickshell.screens.length; i += 1) {
                if (Quickshell.screens[i].name === focusedMonitor.name)
                    return Quickshell.screens[i];
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Timer {
        id: collapseTimer
        repeat: false
        onTriggered: root.showIdle()
    }

    Timer {
        id: demoLoopTimer
        interval: 2600
        repeat: true
        running: root.demoRunning
        onTriggered: root.demo()
    }

    PanelWindow {
        id: islandWindow

        screen: root.focusedScreen()
        color: "transparent"
        exclusiveZone: root.reservedZone
        exclusionMode: ExclusionMode.Normal
        implicitHeight: root.windowHeight
        visible: true

        WlrLayershell.namespace: "dynamic-glacier"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            item: island
        }

        Item {
            anchors.fill: parent

            IslandSurface {
                id: island

                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                width: root.targetWidth()
                height: root.targetHeight()
                mode: root.mode
                handleStyle: root.handleStyle
                forceExpanded: root.interactionOpen
                appName: root.appName
                title: root.title
                body: root.body
                artist: root.artist
                volume: root.volume
                muted: root.muted
                playing: root.playing
                fontFamily: root.fontFamily
            }

            MouseArea {
                id: islandHitbox

                z: 20
                anchors.horizontalCenter: island.horizontalCenter
                y: island.y
                width: island.width
                height: root.mode === "idle" && !root.interactionOpen ? Math.max(root.reservedZone, island.height) : island.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.pointerInside = true
                onExited: root.pointerInside = false
                onClicked: {
                    if (root.mode === "idle")
                        root.pinnedOpen = !root.pinnedOpen;
                    else
                        root.showIdle();
                }
            }
        }
    }

    IpcHandler {
        target: "dynamicGlacier"

        function idle(): void {
            root.showIdle();
        }

        function handle(style: string): void {
            root.setHandleStyle(style);
        }

        function toggleHandle(): void {
            root.toggleHandleStyle();
        }

        function notify(summary: string, message: string, app: string): void {
            root.showNotification(summary, message, app);
        }

        function media(trackTitle: string, trackArtist: string, isPlaying: string): void {
            root.showMedia(trackTitle, trackArtist, isPlaying === "true" || isPlaying === "playing" || isPlaying === "1");
        }

        function volume(level: int, isMuted: string): void {
            root.showVolume(level, isMuted === "true" || isMuted === "muted" || isMuted === "1");
        }

        function demo(): void {
            root.demo();
        }

        function demoLoop(): void {
            root.demoRunning = !root.demoRunning;
            if (root.demoRunning)
                root.demo();
        }
    }
}
