import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

Scope {
    id: root

    property string mode: "idle"
    property string appName: "Dynamic Glacier"
    property string title: "Ready"
    property string body: "Waiting for a signal"
    property string artist: ""
    property string artUrl: ""
    property int volume: 42
    property bool muted: false
    property bool volumeIndicatorVisible: false
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool pinnedOpen: false
    property bool liveLinksEnabled: true
    property bool liveLinksPrimed: false
    property bool privacyDebugEnabled: false
    property bool debugMicrophoneActive: false
    property bool debugCameraActive: false
    property bool polledMicrophoneActive: false
    property bool polledCameraActive: false
    property date currentDateTime: new Date()
    property string handleStyle: "bump"
    property var activePlayer: null
    property string lastTrackKey: ""
    property real lastSinkVolume: -1
    property bool lastSinkMuted: false
    property int lastBatteryLevel: -1
    property bool lastBatteryPluggedIn: false
    property int lastBrightnessLevel: -1
    property int demoStep: 0

    readonly property bool interactionOpen: root.mode === "idle" && (root.pointerInside || root.pinnedOpen)
    readonly property bool hoverMediaMode: root.liveLinksEnabled && root.mode === "idle" && root.interactionOpen && root.hasActiveMedia()
    readonly property string visualMode: root.hoverMediaMode ? "media" : root.mode
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: root.handleStyle === "strip" ? 0 : 24
    readonly property int windowHeight: 136
    readonly property int bumpWidth: 104
    readonly property int bumpHeight: 24
    readonly property int stripWidth: 98
    readonly property int stripHeight: 4
    readonly property int peekWidth: 340
    readonly property int peekHeight: 120
    readonly property int notifyWidth: 438
    readonly property int notifyHeight: 74
    readonly property int mediaWidth: 420
    readonly property int mediaHeight: 132
    readonly property string fontFamily: "Noto Sans"
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool mediaCanGoPrevious: root.activePlayer?.canGoPrevious ?? false
    readonly property bool mediaCanTogglePlaying: (root.activePlayer?.canTogglePlaying ?? false) || (root.activePlayer?.canPause ?? false) || (root.activePlayer?.canPlay ?? false)
    readonly property bool mediaCanGoNext: root.activePlayer?.canGoNext ?? false
    readonly property real mediaPosition: Math.max(0, root.activePlayer?.position ?? 0)
    readonly property real mediaLength: Math.max(0, root.activePlayer?.length ?? 0)
    readonly property bool mediaShuffleSupported: root.activePlayer?.shuffleSupported ?? false
    readonly property bool mediaShuffleActive: root.activePlayer?.shuffle ?? false
    readonly property bool mediaLoopSupported: root.activePlayer?.loopSupported ?? false
    readonly property var mediaLoopState: root.activePlayer?.loopState ?? MprisLoopState.None
    readonly property bool mediaLoopActive: root.mediaLoopState !== MprisLoopState.None
    readonly property string mediaLoopStateText: root.mediaLoopState === MprisLoopState.Track ? "ONE" : (root.mediaLoopState === MprisLoopState.Playlist ? "ALL" : "RPT")
    readonly property bool microphoneActive: root.privacyDebugEnabled ? root.debugMicrophoneActive : root.liveLinksEnabled && (root.detectMicrophoneActivity() || root.polledMicrophoneActive)
    readonly property bool cameraActive: root.privacyDebugEnabled ? root.debugCameraActive : root.liveLinksEnabled && (root.detectVideoActivity() || root.polledCameraActive)
    readonly property bool privacyActive: root.microphoneActive || root.cameraActive
    readonly property bool compactPrivacyIndicators: root.handleStyle === "strip" && root.visualMode === "idle" && !root.interactionOpen
    readonly property color microphoneIndicatorColor: "#ff9f1a"
    readonly property color cameraIndicatorColor: "#35ff72"
    readonly property string batteryHoverText: root.batteryAvailable() ? (root.batteryPluggedIn() ? "CHG " : "BAT ") + root.batteryLevel() + "%" : ""
    readonly property string hoverTimeText: root.formatClockTime(root.currentDateTime)
    readonly property string hoverDateText: root.formatClockDate(root.currentDateTime)
    readonly property bool mediaAvailable: root.liveLinksEnabled && root.hasActiveMedia()
    readonly property bool mediaCanSeek: (root.activePlayer?.canSeek ?? false) && (root.activePlayer?.positionSupported ?? false) && root.mediaLength > 0

    function targetWidth() {
        switch (root.visualMode) {
        case "notify":
            return root.notifyWidth;
        case "media":
            return root.mediaWidth;
        default:
            if (root.interactionOpen)
                return root.peekWidth;
            return root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth;
        }
    }

    function targetHeight() {
        switch (root.visualMode) {
        case "notify":
            return root.notifyHeight;
        case "media":
            return root.mediaHeight;
        default:
            if (root.interactionOpen)
                return root.peekHeight;
            return root.handleStyle === "strip" ? root.stripHeight : root.bumpHeight;
        }
    }

    function targetY() {
        return root.visualMode === "idle" && !root.interactionOpen ? root.idleTopMargin : root.expandedTopMargin;
    }

    function hold(milliseconds) {
        collapseTimer.interval = milliseconds;
        collapseTimer.restart();
    }

    function keepInteractionOpen(prepareMedia) {
        hoverLeaveTimer.stop();
        root.pointerInside = true;

        if (prepareMedia)
            root.prepareHoverMedia();
    }

    function scheduleInteractionClose() {
        if (!root.pinnedOpen)
            hoverLeaveTimer.restart();
    }

    function boolFromIpc(value) {
        return value === true || value === "true" || value === "1" || value === "on" || value === "yes";
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatClockTime(value) {
        const date = new Date(value);

        return root.pad2(date.getHours()) + ":" + root.pad2(date.getMinutes());
    }

    function formatClockDate(value) {
        const date = new Date(value);
        const shortDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        const day = date.getDay();

        return root.pad2(date.getDate()) + "." + root.pad2(date.getMonth() + 1) + "." + date.getFullYear() + ", " + shortDays[day];
    }

    function showIdle() {
        collapseTimer.stop();
        root.mode = "idle";
        root.pinnedOpen = false;
        root.title = "Ready";
        root.body = "Waiting for a signal";

        if (root.liveLinksEnabled) {
            root.chooseActivePlayer(null);
            if (root.hasActiveMedia())
                root.syncMediaFields(root.activePlayer);
        }
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
        root.artUrl = "";
        root.mode = "notify";
        root.hold(5200);
    }

    function showMedia(trackTitle, trackArtist, isPlaying, trackArtUrl) {
        root.title = trackTitle || "Unknown track";
        root.artist = trackArtist || "Unknown artist";
        root.artUrl = trackArtUrl || "";
        root.playing = isPlaying;
        root.mode = "media";
        root.hold(6200);
    }

    function showVolume(level, isMuted) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = isMuted;
        root.title = root.muted ? "Muted" : "Volume";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function showBrightness(level) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = false;
        root.title = "Brightness";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function trackTitle(player) {
        return player?.trackTitle || "Unknown track";
    }

    function trackArtist(player) {
        return player?.trackArtist || player?.identity || "Unknown artist";
    }

    function trackArtUrl(player) {
        return player?.trackArtUrl || "";
    }

    function trackKey(player) {
        if (!player)
            return "";

        return [player.uniqueId || player.dbusName || "", root.trackTitle(player), root.trackArtist(player), player.isPlaying ? "playing" : "paused"].join("|");
    }

    function syncMediaFields(player) {
        if (!player)
            return;

        root.title = root.trackTitle(player);
        root.artist = root.trackArtist(player);
        root.artUrl = root.trackArtUrl(player);
        root.playing = player.isPlaying;
    }

    function hasActiveMedia() {
        const player = root.activePlayer;

        if (!player)
            return false;

        return player.isPlaying || root.trackTitle(player) !== "Unknown track";
    }

    function chooseActivePlayer(preferredPlayer) {
        const players = Mpris.players.values;

        if (preferredPlayer) {
            root.activePlayer = preferredPlayer;
            return;
        }

        for (let i = 0; i < players.length; i += 1) {
            if (players[i].isPlaying) {
                root.activePlayer = players[i];
                return;
            }
        }

        root.activePlayer = players.length > 0 ? players[0] : null;
    }

    function prepareHoverMedia() {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
    }

    function mediaPrevious() {
        if (root.activePlayer?.canGoPrevious)
            root.activePlayer.previous();
    }

    function mediaTogglePlaying() {
        const player = root.activePlayer;

        if (!player)
            return;

        if (player.canTogglePlaying) {
            player.togglePlaying();
        } else if (player.isPlaying && player.canPause) {
            player.pause();
        } else if (!player.isPlaying && player.canPlay) {
            player.play();
        }
    }

    function mediaNext() {
        if (root.activePlayer?.canGoNext)
            root.activePlayer.next();
    }

    function mediaToggleShuffle() {
        const player = root.activePlayer;

        if (!player || !player.shuffleSupported)
            return;

        player.shuffle = !player.shuffle;
    }

    function mediaCycleLoop() {
        const player = root.activePlayer;

        if (!player || !player.loopSupported)
            return;

        if (player.loopState === MprisLoopState.None) {
            player.loopState = MprisLoopState.Track;
        } else if (player.loopState === MprisLoopState.Track) {
            player.loopState = MprisLoopState.Playlist;
        } else {
            player.loopState = MprisLoopState.None;
        }
    }

    function maybeShowMediaFromPlayer(preferredPlayer, force) {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(preferredPlayer);
        const player = root.activePlayer;
        const key = root.trackKey(player);

        if (!player || !key)
            return;

        const keepMediaFieldsFresh = root.mode === "idle" || root.hoverMediaMode;

        if (keepMediaFieldsFresh)
            root.syncMediaFields(player);

        if (!root.liveLinksPrimed) {
            root.lastTrackKey = key;
            return;
        }

        if (force || key !== root.lastTrackKey) {
            root.lastTrackKey = key;
            if (keepMediaFieldsFresh)
                root.syncMediaFields(player);
        }
    }

    function mediaSeek(position) {
        const player = root.activePlayer;

        if (!player || !root.mediaCanSeek)
            return;

        player.position = Math.max(0, Math.min(root.mediaLength, Number(position)));
    }

    function sinkVolumePercent() {
        const rawVolume = root.audioSink?.audio?.volume ?? 0;
        return Math.max(0, Math.min(100, Math.round(rawVolume * 100)));
    }

    function sinkMuted() {
        return root.audioSink?.audio?.muted ?? false;
    }

    function pipewireLinkGroups() {
        return Pipewire.linkGroups?.values ?? [];
    }

    function nodeHasType(node, type) {
        return node && node.type !== undefined && (node.type === type || (node.type & type) === type);
    }

    function nodePropertyText(node) {
        const properties = node?.properties ?? {};

        return [properties["media.class"] ?? "", properties["node.name"] ?? "", properties["node.description"] ?? "", properties["node.nick"] ?? "", properties["application.name"] ?? "", node?.name ?? "", node?.description ?? "", node?.nickname ?? ""].join(" ").toLowerCase();
    }

    function textHasAny(text, needles) {
        for (let i = 0; i < needles.length; i += 1) {
            if (text.indexOf(needles[i]) !== -1)
                return true;
        }

        return false;
    }

    function nodeLooksLikeVideoSource(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.VideoSource) || (root.nodeHasType(node, PwNodeType.Video) && root.nodeHasType(node, PwNodeType.Source)) || text.indexOf("video/source") !== -1 || text.indexOf("video source") !== -1 || text.indexOf("v4l2") !== -1 || text.indexOf("camera") !== -1;
    }

    function nodeLooksLikeMicrophoneSource(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.AudioSource) || (root.nodeHasType(node, PwNodeType.Audio) && root.nodeHasType(node, PwNodeType.Source)) || text.indexOf("audio/source") !== -1 || text.indexOf("audio source") !== -1 || text.indexOf("alsa_input") !== -1 || root.textHasAny(text, ["microphone", "mic", "input"]);
    }

    function nodeLooksLikeAudioInputStream(node) {
        const text = root.nodePropertyText(node);

        return root.nodeHasType(node, PwNodeType.AudioInStream) || (root.nodeHasType(node, PwNodeType.Audio) && root.nodeHasType(node, PwNodeType.Stream)) || text.indexOf("stream/input/audio") !== -1 || text.indexOf("audio/input") !== -1 || text.indexOf("input audio") !== -1 || text.indexOf("source-output") !== -1 || text.indexOf("capture") !== -1;
    }

    function updatePolledPrivacy(text) {
        const parts = text.trim().split(/\s+/);

        if (parts.length < 2)
            return;

        root.polledMicrophoneActive = parts[0] === "1";
        root.polledCameraActive = parts[1] === "1";
    }

    function updatePolledBrightness(text) {
        const rawLevel = Number(text.trim());

        if (!isFinite(rawLevel) || rawLevel < 0)
            return;

        const nextLevel = Math.max(0, Math.min(100, Math.round(rawLevel)));

        if (root.lastBrightnessLevel < 0) {
            root.lastBrightnessLevel = nextLevel;
            return;
        }

        if (nextLevel !== root.lastBrightnessLevel) {
            root.lastBrightnessLevel = nextLevel;
            root.showBrightness(nextLevel);
        }
    }

    function detectVideoActivity() {
        const groups = root.pipewireLinkGroups();

        for (let i = 0; i < groups.length; i += 1) {
            const group = groups[i];

            if (root.nodeLooksLikeVideoSource(group?.source) || root.nodeLooksLikeVideoSource(group?.target))
                return true;
        }

        return false;
    }

    function detectMicrophoneActivity() {
        const groups = root.pipewireLinkGroups();

        for (let i = 0; i < groups.length; i += 1) {
            const group = groups[i];
            const sourceIsMic = root.nodeLooksLikeMicrophoneSource(group?.source);
            const targetIsMic = root.nodeLooksLikeMicrophoneSource(group?.target);
            const sourceIsStream = root.nodeLooksLikeAudioInputStream(group?.source);
            const targetIsStream = root.nodeLooksLikeAudioInputStream(group?.target);

            if ((sourceIsMic && (targetIsStream || !targetIsMic)) || (targetIsMic && (sourceIsStream || !sourceIsMic)))
                return true;
        }

        return false;
    }

    function maybeShowVolumeFromSink() {
        if (!root.liveLinksEnabled)
            return;

        const nextVolume = root.sinkVolumePercent();
        const nextMuted = root.sinkMuted();

        if (!root.liveLinksPrimed) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            return;
        }

        if (nextVolume !== root.lastSinkVolume || nextMuted !== root.lastSinkMuted) {
            root.lastSinkVolume = nextVolume;
            root.lastSinkMuted = nextMuted;
            root.showVolume(nextVolume, nextMuted);
        }
    }

    function batteryAvailable() {
        return UPower.displayDevice?.isLaptopBattery ?? false;
    }

    function batteryLevel() {
        return Math.max(0, Math.min(100, Math.round((UPower.displayDevice?.percentage ?? 1) * 100)));
    }

    function batteryPluggedIn() {
        const chargeState = UPower.displayDevice?.state;
        return chargeState === UPowerDeviceState.Charging || chargeState === UPowerDeviceState.PendingCharge;
    }

    function maybeShowBattery(forceStateEvent) {
        if (!root.liveLinksEnabled || !root.batteryAvailable())
            return;

        const nextLevel = root.batteryLevel();
        const nextPluggedIn = root.batteryPluggedIn();

        if (!root.liveLinksPrimed) {
            root.lastBatteryLevel = nextLevel;
            root.lastBatteryPluggedIn = nextPluggedIn;
            return;
        }

        if (forceStateEvent && nextPluggedIn !== root.lastBatteryPluggedIn) {
            root.showNotification(nextPluggedIn ? "Charging" : "On battery", nextLevel + "%", "Battery");
        } else if (!nextPluggedIn && root.lastBatteryLevel > 20 && nextLevel <= 20) {
            root.showNotification("Low battery", nextLevel + "% remaining", "Battery");
        } else if (!nextPluggedIn && root.lastBatteryLevel > 10 && nextLevel <= 10) {
            root.showNotification("Critical battery", nextLevel + "% remaining", "Battery");
        } else if (nextPluggedIn && root.lastBatteryLevel < 95 && nextLevel >= 95) {
            root.showNotification("Battery almost full", nextLevel + "%", "Battery");
        }

        root.lastBatteryLevel = nextLevel;
        root.lastBatteryPluggedIn = nextPluggedIn;
    }

    function primeLiveLinks() {
        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
        root.lastTrackKey = root.trackKey(root.activePlayer);
        root.lastSinkVolume = root.sinkVolumePercent();
        root.lastSinkMuted = root.sinkMuted();

        if (root.batteryAvailable()) {
            root.lastBatteryLevel = root.batteryLevel();
            root.lastBatteryPluggedIn = root.batteryPluggedIn();
        }

        root.liveLinksPrimed = true;
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
        id: hoverLeaveTimer
        interval: 140
        repeat: false
        onTriggered: root.pointerInside = false
    }

    Timer {
        id: demoLoopTimer
        interval: 2600
        repeat: true
        running: root.demoRunning
        onTriggered: root.demo()
    }

    Timer {
        id: volumeIndicatorTimer
        interval: 1800
        repeat: false
        onTriggered: root.volumeIndicatorVisible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentDateTime = new Date()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visualMode === "media" && root.activePlayer !== null
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();
            root.syncMediaFields(root.activePlayer);
        }
    }

    Timer {
        id: liveLinkPrimeTimer
        interval: 900
        repeat: false
        running: true
        onTriggered: root.primeLiveLinks()
    }

    Timer {
        interval: 1200
        repeat: true
        running: root.liveLinksEnabled && !root.privacyDebugEnabled
        triggeredOnStart: true
        onTriggered: {
            if (!privacyPollProc.running)
                privacyPollProc.exec(["sh", "-c", "mic=0; cam=0; if command -v pactl >/dev/null 2>&1; then [ -n \"$(pactl list source-outputs short 2>/dev/null)\" ] && mic=1; fi; if command -v fuser >/dev/null 2>&1; then for dev in /dev/video*; do [ -e \"$dev\" ] || continue; fuser \"$dev\" >/dev/null 2>&1 && cam=1; done; fi; printf '%s %s\\n' \"$mic\" \"$cam\""]);
        }
    }

    Timer {
        interval: 700
        repeat: true
        running: root.liveLinksEnabled
        triggeredOnStart: true
        onTriggered: {
            if (!brightnessPollProc.running)
                brightnessPollProc.exec(["sh", "-c", "level=-1; for dev in /sys/class/backlight/*; do [ -r \"$dev/brightness\" ] && [ -r \"$dev/max_brightness\" ] || continue; b=$(cat \"$dev/brightness\" 2>/dev/null); m=$(cat \"$dev/max_brightness\" 2>/dev/null); [ \"$m\" -gt 0 ] 2>/dev/null || continue; level=$(( (b * 100 + m / 2) / m )); break; done; printf '%s\\n' \"$level\""]);
        }
    }

    Process {
        id: privacyPollProc

        stdout: StdioCollector {
            onStreamFinished: root.updatePolledPrivacy(text)
        }
    }

    Process {
        id: brightnessPollProc

        stdout: StdioCollector {
            onStreamFinished: root.updatePolledBrightness(text)
        }
    }

    PwObjectTracker {
        objects: [root.audioSink]
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: root.maybeShowMediaFromPlayer(modelData, false)

            function onPlaybackStateChanged() {
                root.maybeShowMediaFromPlayer(modelData, false);
            }

            function onPostTrackChanged() {
                root.maybeShowMediaFromPlayer(modelData, true);
            }
        }
    }

    Connections {
        target: root.audioSink?.audio ?? null

        function onVolumeChanged() {
            root.maybeShowVolumeFromSink();
        }

        function onMutedChanged() {
            root.maybeShowVolumeFromSink();
        }
    }

    Connections {
        target: UPower.displayDevice ?? null

        function onPercentageChanged() {
            root.maybeShowBattery(false);
        }

        function onStateChanged() {
            root.maybeShowBattery(true);
        }
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
            item: interactionMask
        }

        Item {
            anchors.fill: parent

            Item {
                id: interactionMask

                readonly property real maskPadding: 8
                readonly property bool privacyVisible: root.privacyActive && !root.interactionOpen
                readonly property real islandRightEdge: island.x + island.width
                readonly property real islandBottomEdge: island.y + island.height
                readonly property real privacyRightEdge: privacyVisible ? privacyIndicators.x + privacyIndicators.width : islandRightEdge
                readonly property real privacyBottomEdge: privacyVisible ? privacyIndicators.y + privacyIndicators.height : islandBottomEdge
                readonly property real rightEdge: Math.max(islandRightEdge, privacyRightEdge)
                readonly property real bottomEdge: Math.max(islandBottomEdge, privacyBottomEdge)

                x: Math.max(0, Math.min(island.x, privacyVisible ? privacyIndicators.x : island.x) - maskPadding)
                y: Math.max(0, island.y - maskPadding)
                width: Math.min(parent.width - x, rightEdge - x + maskPadding)
                height: Math.min(parent.height - y, bottomEdge - y + maskPadding)
            }

            IslandSurface {
                id: island

                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                width: root.targetWidth()
                height: root.targetHeight()
                mode: root.visualMode
                handleStyle: root.handleStyle
                forceExpanded: root.interactionOpen
                appName: root.appName
                title: root.title
                body: root.body
                artist: root.artist
                artUrl: root.artUrl
                volume: root.volume
                muted: root.muted
                volumeIndicatorVisible: root.volumeIndicatorVisible
                playing: root.playing
                canGoPrevious: root.mediaCanGoPrevious
                canTogglePlaying: root.mediaCanTogglePlaying
                canGoNext: root.mediaCanGoNext
                canSeek: root.mediaCanSeek
                shuffleActive: root.mediaShuffleActive
                shuffleSupported: root.mediaShuffleSupported
                loopStateText: root.mediaLoopStateText
                loopActive: root.mediaLoopActive
                loopSupported: root.mediaLoopSupported
                mediaPosition: root.mediaPosition
                mediaLength: root.mediaLength
                mediaAvailable: root.mediaAvailable
                fontFamily: root.fontFamily
                batteryHoverText: root.batteryHoverText
                timeText: root.hoverTimeText
                dateText: root.hoverDateText
                onPreviousRequested: root.mediaPrevious()
                onPlayPauseRequested: root.mediaTogglePlaying()
                onNextRequested: root.mediaNext()
                onShuffleRequested: root.mediaToggleShuffle()
                onLoopRequested: root.mediaCycleLoop()
                onSeekRequested: position => root.mediaSeek(position)
                onHandleStyleRequested: style => root.setHandleStyle(style)
            }

            Item {
                id: privacyIndicators

                readonly property int dotSize: root.compactPrivacyIndicators ? 4 : 9
                readonly property int itemSize: root.compactPrivacyIndicators ? dotSize : 16
                readonly property int dotSpacing: root.compactPrivacyIndicators ? 3 : 5
                readonly property int haloSize: root.compactPrivacyIndicators ? 0 : 16
                readonly property int islandGap: root.compactPrivacyIndicators ? 4 : 8

                z: 35
                x: island.x + island.width + privacyIndicators.islandGap
                y: island.y + Math.max(0, island.height / 2 - height / 2)
                width: (root.microphoneActive ? privacyIndicators.itemSize : 0) + (root.cameraActive ? privacyIndicators.itemSize : 0) + (root.microphoneActive && root.cameraActive ? privacyIndicators.dotSpacing : 0)
                height: privacyIndicators.itemSize
                opacity: visible ? 1 : 0
                visible: root.privacyActive && !root.interactionOpen
                transformOrigin: Item.Center

                Row {
                    anchors.centerIn: parent
                    spacing: privacyIndicators.dotSpacing

                    Item {
                        width: root.microphoneActive ? privacyIndicators.itemSize : 0
                        height: privacyIndicators.itemSize
                        visible: root.microphoneActive

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.haloSize
                            height: privacyIndicators.haloSize
                            radius: width / 2
                            color: root.microphoneIndicatorColor
                            opacity: 0.2
                            visible: privacyIndicators.haloSize > 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.dotSize
                            height: privacyIndicators.dotSize
                            radius: width / 2
                            color: root.microphoneIndicatorColor
                            border.width: root.compactPrivacyIndicators ? 0 : 1
                            border.color: "#000000"
                        }
                    }

                    Item {
                        width: root.cameraActive ? privacyIndicators.itemSize : 0
                        height: privacyIndicators.itemSize
                        visible: root.cameraActive

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.haloSize
                            height: privacyIndicators.haloSize
                            radius: width / 2
                            color: root.cameraIndicatorColor
                            opacity: 0.18
                            visible: privacyIndicators.haloSize > 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: privacyIndicators.dotSize
                            height: privacyIndicators.dotSize
                            radius: width / 2
                            color: root.cameraIndicatorColor
                            border.width: root.compactPrivacyIndicators ? 0 : 1
                            border.color: "#000000"
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: islandHitbox

                z: 20
                anchors.horizontalCenter: island.horizontalCenter
                y: island.y
                width: island.width
                height: root.mode === "idle" && !root.interactionOpen ? Math.max(root.reservedZone, island.height) : island.height
                hoverEnabled: true
                acceptedButtons: root.visualMode === "media" || root.interactionOpen ? Qt.NoButton : Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onEntered: root.keepInteractionOpen(true)
                onExited: root.scheduleInteractionClose()
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

        function live(enabled: string): void {
            root.liveLinksEnabled = root.boolFromIpc(enabled);
        }

        function privacy(micActive: string, cameraActive: string): void {
            root.privacyDebugEnabled = true;
            root.debugMicrophoneActive = root.boolFromIpc(micActive);
            root.debugCameraActive = root.boolFromIpc(cameraActive);
        }

        function privacyLive(): void {
            root.privacyDebugEnabled = false;
            root.debugMicrophoneActive = false;
            root.debugCameraActive = false;
        }

        function notify(summary: string, message: string, app: string): void {
            root.showNotification(summary, message, app);
        }

        function media(trackTitle: string, trackArtist: string, isPlaying: string, artUrl: string): void {
            root.showMedia(trackTitle, trackArtist, root.boolFromIpc(isPlaying) || isPlaying === "playing", artUrl);
        }

        function volume(level: int, isMuted: string): void {
            root.showVolume(level, isMuted === "true" || isMuted === "muted" || isMuted === "1");
        }

        function brightness(level: int): void {
            root.showBrightness(level);
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
