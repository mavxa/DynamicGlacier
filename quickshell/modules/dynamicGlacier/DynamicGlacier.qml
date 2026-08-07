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
    // "audio" or "brightness" — the HUD is the same pill, only the glyph differs.
    property string volumeKind: "audio"
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool pinnedOpen: false
    property bool mediaHoverSuppressed: false
    property bool liveLinksEnabled: true
    property bool liveLinksPrimed: false
    property bool privacyDebugEnabled: false
    property bool debugMicrophoneActive: false
    property bool debugCameraActive: false
    property bool polledCameraActive: false
    // Empty when the machine has no backlight, which disables the poll.
    property string backlightPath: ""
    property int backlightMaxRaw: 0
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
    property bool trayBatteryDismissed: false
    property bool trayMediaDismissed: false

    readonly property bool interactionOpen: root.mode === "idle" && (root.pointerInside || root.pinnedOpen)
    readonly property bool trayVisible: root.handleStyle === "bump" && !root.interactionOpen && root.visualMode === "idle"
    readonly property bool hoverMediaMode: root.liveLinksEnabled && root.mode === "idle" && root.interactionOpen && !root.mediaHoverSuppressed && root.hasActiveMedia()
    // The volume HUD is a transient morph, so it only takes over the idle shape —
    // a notification, the media card or an open panel all outrank it.
    readonly property bool volumeHudMode: root.volumeIndicatorVisible && root.mode === "idle"
    readonly property string visualMode: root.volumeHudMode ? "volume" : (root.hoverMediaMode ? "media" : root.mode)
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: root.handleStyle === "strip" ? 0 : 24
    readonly property int windowHeight: 136
    readonly property int bumpWidth: 104
    readonly property int bumpHeight: 24
    readonly property int stripWidth: 98
    readonly property int stripHeight: 4
    readonly property int peekWidth: 340
    readonly property int peekHeight: 132
    readonly property int notifyWidth: 438
    readonly property int notifyHeight: 74
    readonly property int mediaWidth: 380
    readonly property int mediaHeight: 132
    readonly property int volumeWidth: 244
    readonly property int volumeHeight: 48
    readonly property int wifiWidth: 340
    // Floor for the Wi-Fi panel; the island grows past it to fit the network list,
    // up to wifiMaxPanelHeight.
    readonly property int wifiMinHeight: 132
    readonly property int wifiMaxPanelHeight: 420
    readonly property int appsWidth: 340
    readonly property int appsMinHeight: 132
    readonly property int appsMaxPanelHeight: 470
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
    readonly property bool microphoneActive: root.privacyDebugEnabled ? root.debugMicrophoneActive : root.liveLinksEnabled && root.detectMicrophoneActivity()
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

    // WiFi
    property string wifiSsid: ""
    property int wifiSignal: 0
    readonly property bool wifiConnected: root.wifiSsid !== ""

    // WiFi manager panel (morphs the island into mode "wifi")
    property bool wifiRadioEnabled: true
    property var wifiNetworks: []
    property string wifiExpandedSsid: ""
    property string wifiPasswordDraft: ""
    property string pendingWifiPassword: ""
    property string wifiStatusText: ""
    property bool wifiConnecting: false
    property double lastWifiScanAt: 0

    // Bluetooth
    property string btDeviceName: ""
    property int btBattery: -1
    readonly property bool btEnabled: true
    readonly property bool btConnected: root.btDeviceName !== ""

    // App favorites dock (morphs the island into mode "apps")
    readonly property int appsFavoriteSlots: 8
    readonly property string favoritesPath: Quickshell.statePath("favorites.json")
    readonly property string favoritesDir: root.parentDirectory(root.favoritesPath)
    property var favoriteAppIds: []
    property bool appsPickerOpen: false
    property string appsSearchDraft: ""
    property string appsStatusText: ""
    // Every installed launcher entry, name-sorted, with its icon already resolved.
    readonly property var appEntries: root.buildAppEntries()
    readonly property var appsPickerEntries: root.filterAppEntries()
    // Always appsFavoriteSlots long, so the grid can render empty slots as "add here".
    readonly property var favoriteAppEntries: root.buildFavoriteEntries()

    function targetWidth() {
        switch (root.visualMode) {
        case "notify":
            return root.notifyWidth;
        case "media":
            return root.mediaWidth;
        case "volume":
            return root.volumeWidth;
        case "wifi":
            return root.wifiWidth;
        case "apps":
            return root.appsWidth;
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
        case "volume":
            return root.volumeHeight;
        case "wifi":
            return root.wifiMinHeight;
        case "apps":
            return root.appsMinHeight;
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
        // The picker owns the only focused text field in the island. Leaving it
        // flagged open while the island collapses would keep a hidden TextInput
        // holding the keyboard.
        root.appsPickerOpen = false;
        root.appsSearchDraft = "";
        root.appsStatusText = "";

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

    // The HUD no longer borrows `title` — it morphs into its own pill, and writing
    // the title here would have leaked "Volume" into a notification sitting behind it.
    function showVolume(level, isMuted) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = isMuted;
        root.volumeKind = "audio";
        root.volumeIndicatorVisible = true;
        volumeIndicatorTimer.restart();
    }

    function showBrightness(level) {
        root.volume = Math.max(0, Math.min(100, Number(level)));
        root.muted = false;
        root.volumeKind = "brightness";
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

    function mediaToggleFavorite() {
        // MPRIS does not expose a standard "favorite" method.
        // Placeholder for future player-specific integration (e.g. Spotify DBus).
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
            root.trayMediaDismissed = false;
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
        root.polledCameraActive = text.trim() === "1";
    }

    // Raw sysfs value in, percentage out. The mic/max scaling the old shell
    // pipeline did with integer arithmetic now happens here.
    function updateRawBrightness(raw) {
        if (!isFinite(raw) || raw < 0 || root.backlightMaxRaw <= 0)
            return;

        root.updatePolledBrightness(raw * 100 / root.backlightMaxRaw);
    }

    function updatePolledBrightness(rawLevel) {
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
            root.trayBatteryDismissed = false;
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

    // Morphs the island into the Wi-Fi manager, or collapses it back to
    // idle if it is already showing.
    function toggleWifiPanel() {
        if (root.mode === "wifi") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.mode = "wifi";
        root.wifiExpandedSsid = "";
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
        root.refreshWifiRadioState();
        root.scanWifiNetworks();
    }

    function refreshWifiRadioState() {
        wifiRadioStateProc.exec(["nmcli", "-t", "-f", "WIFI", "radio"]);
    }

    function scanWifiNetworks() {
        root.lastWifiScanAt = Date.now();
        wifiScanProc.exec(["nmcli", "-t", "-f", "active,ssid,signal,security", "dev", "wifi", "list", "--rescan", "yes"]);
    }

    // Warms the network list while the island is merely open, so the Wi-Fi panel
    // has something to show — and can size itself correctly — the instant it opens.
    function prewarmWifiNetworks() {
        if (Date.now() - root.lastWifiScanAt < 10000)
            return;

        root.refreshWifiRadioState();
        root.scanWifiNetworks();
    }

    function splitNmcliLine(line) {
        const parts = [];
        let current = "";
        let i = 0;

        while (i < line.length) {
            const ch = line[i];

            if (ch === "\\" && i + 1 < line.length) {
                current += line[i + 1];
                i += 2;
                continue;
            }

            if (ch === ":") {
                parts.push(current);
                current = "";
                i += 1;
                continue;
            }

            current += ch;
            i += 1;
        }

        parts.push(current);
        return parts;
    }

    function parseWifiNetworks(text) {
        const lines = text.split("\n").filter(line => line.trim() !== "");
        const parsed = [];
        const seen = {};

        for (let i = 0; i < lines.length; i += 1) {
            const parts = root.splitNmcliLine(lines[i]);

            if (parts.length < 4)
                continue;

            const active = parts[0] === "yes";
            const ssid = parts[1];
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
        }

        parsed.sort((a, b) => b.signal - a.signal);
        root.wifiNetworks = parsed;
    }

    function toggleWifiRadio() {
        const nextState = !root.wifiRadioEnabled;

        root.wifiRadioEnabled = nextState;
        wifiRadioToggleProc.exec(["nmcli", "radio", "wifi", nextState ? "on" : "off"]);
    }

    function requestWifiExpand(ssid) {
        root.wifiExpandedSsid = root.wifiExpandedSsid === ssid ? "" : ssid;
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
    }

    function connectToWifiNetwork(ssid, secured) {
        if (secured && root.wifiPasswordDraft === "") {
            root.wifiStatusText = "Password required";
            return;
        }

        root.wifiConnecting = true;
        root.wifiStatusText = "";

        const command = ["nmcli"];

        if (secured) {
            root.pendingWifiPassword = root.wifiPasswordDraft;
            command.push("--ask");
        }

        command.push("dev", "wifi", "connect", ssid);

        // Process executes this list directly, so SSIDs and passwords never pass
        // through a shell. Secured networks receive the password over stdin, which
        // also keeps it out of the process list.
        wifiConnectProc.exec(command);
    }

    function disconnectFromWifiNetwork(ssid) {
        root.wifiConnecting = true;
        root.wifiStatusText = "";
        wifiDisconnectProc.exec(["nmcli", "con", "down", "id", ssid]);
    }

    function parseActiveWifi(text) {
        const lines = text.split("\n");

        for (let i = 0; i < lines.length; i += 1) {
            if (lines[i] === "")
                continue;

            const parts = root.splitNmcliLine(lines[i]);

            if (parts.length >= 3 && parts[0] === "yes") {
                root.wifiSsid = parts[1] === "--" ? "" : parts[1];
                root.wifiSignal = parseInt(parts[2]) || 0;
                return;
            }
        }

        root.wifiSsid = "";
        root.wifiSignal = 0;
    }

    function parentDirectory(path) {
        const separator = path.lastIndexOf("/");

        return separator > 0 ? path.slice(0, separator) : ".";
    }

    // `check` makes a missing icon resolve to "" instead of a broken image URL,
    // so the tile falls through to its glyph placeholder without a load warning.
    function appIconSource(iconName) {
        if (iconName === "")
            return "";

        return Quickshell.iconPath(iconName, true);
    }

    function buildAppEntries() {
        const entries = DesktopEntries.applications?.values ?? [];
        const list = [];

        for (let i = 0; i < entries.length; i += 1) {
            const entry = entries[i];

            if (!entry || entry.noDisplay)
                continue;

            list.push({
                id: entry.id,
                name: entry.name || entry.id,
                iconSource: root.appIconSource(entry.icon || "")
            });
        }

        list.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
        return list;
    }

    function filterAppEntries() {
        const query = root.appsSearchDraft.trim().toLowerCase();

        if (query === "")
            return root.appEntries;

        return root.appEntries.filter(entry => entry.name.toLowerCase().indexOf(query) !== -1 || entry.id.toLowerCase().indexOf(query) !== -1);
    }

    function findAppEntry(id) {
        const entries = root.appEntries;

        for (let i = 0; i < entries.length; i += 1) {
            if (entries[i].id === id)
                return entries[i];
        }

        return null;
    }

    // Pads the saved id list out to a fixed slot count so the grid always draws
    // 4x2. Slots the user has not filled come back with `filled: false`.
    function buildFavoriteEntries() {
        const slots = [];
        // Read up front rather than only inside the filled branch below. QML
        // captures binding dependencies from the properties an evaluation
        // actually touches, so with an empty dock this never looked at
        // appEntries and the grid would not refresh when the desktop entries
        // finished loading after favorites.json.
        const entries = root.appEntries;

        for (let i = 0; i < root.appsFavoriteSlots; i += 1) {
            const id = root.favoriteAppIds[i];

            if (!id) {
                slots.push({
                    filled: false,
                    id: "",
                    name: "",
                    iconSource: ""
                });
                continue;
            }

            const entry = root.findAppEntry(id);

            slots.push({
                filled: true,
                id: id,
                name: entry ? entry.name : id,
                iconSource: entry ? entry.iconSource : root.appIconSource("")
            });
        }

        return slots;
    }

    function isFavoriteApp(id) {
        return root.favoriteAppIds.indexOf(id) !== -1;
    }

    // Morphs the island into the favorites dock, or collapses it back to idle
    // if it is already showing.
    function toggleAppsPanel() {
        if (root.mode === "apps") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.mode = "apps";
        root.appsPickerOpen = false;
        root.appsSearchDraft = "";
        root.appsStatusText = "";
    }

    function toggleAppsPicker() {
        root.appsPickerOpen = !root.appsPickerOpen;
        root.appsSearchDraft = "";
        root.appsStatusText = "";
    }

    function toggleFavoriteApp(id) {
        if (id === "")
            return;

        const list = root.favoriteAppIds.slice();
        const index = list.indexOf(id);

        if (index !== -1) {
            list.splice(index, 1);
        } else if (list.length >= root.appsFavoriteSlots) {
            root.appsStatusText = "All " + root.appsFavoriteSlots + " slots are full";
            appsStatusTimer.restart();
            return;
        } else {
            list.push(id);
        }

        root.appsStatusText = "";
        root.favoriteAppIds = list;
        root.saveFavorites();
    }

    function launchFavoriteApp(id) {
        const entry = DesktopEntries.byId(id);

        if (!entry)
            return;

        entry.execute();
        root.showIdle();
    }

    // Enter in the search field launches whatever is at the top of the filtered
    // list, so the picker doubles as a keyboard launcher.
    function launchTopSearchMatch() {
        const entries = root.appsPickerEntries;

        if (root.appsSearchDraft.trim() === "" || entries.length === 0)
            return;

        root.launchFavoriteApp(entries[0].id);
    }

    function applyFavoritesJson(text) {
        try {
            const parsed = JSON.parse(text);

            if (!Array.isArray(parsed))
                return;

            root.favoriteAppIds = parsed.filter(id => typeof id === "string" && id !== "").slice(0, root.appsFavoriteSlots);
        } catch (error) {
        // No saved favorites yet, or the file was hand-edited into something
        // unparseable — either way, start from an empty dock.
        }
    }

    function saveFavorites() {
        favoritesFile.setText(JSON.stringify(root.favoriteAppIds));
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

    // Camera only. The microphone half of this poll used to shell out to
    // `pactl list source-outputs` on the same tick, which is redundant —
    // detectMicrophoneActivity() already derives that from the Pipewire graph
    // for free, and microphoneActive ORs the two together anyway. Cameras still
    // need the fallback because an app that opens /dev/video0 directly, rather
    // than through the portal, never shows up as a Pipewire node.
    Timer {
        interval: 3000
        repeat: true
        running: root.liveLinksEnabled && !root.privacyDebugEnabled
        triggeredOnStart: true
        onTriggered: {
            if (!privacyPollProc.running)
                privacyPollProc.exec(["sh", "-c", "cam=0; if command -v fuser >/dev/null 2>&1; then for dev in /dev/video*; do [ -e \"$dev\" ] || continue; fuser \"$dev\" >/dev/null 2>&1 && cam=1 && break; done; fi; printf '%s\\n' \"$cam\""]);
        }
    }

    // Locating the backlight is a one-shot glob, not something to redo twice a
    // second. Machines without one (desktops) leave backlightPath empty, which
    // switches the poll below off entirely instead of forking a shell forever to
    // compute a value that updatePolledBrightness discards.
    Process {
        id: backlightProbeProc

        running: true
        command: ["sh", "-c", "for dev in /sys/class/backlight/*; do [ -r \"$dev/brightness\" ] && [ -r \"$dev/max_brightness\" ] || continue; printf '%s\\n' \"$dev\"; break; done"]

        stdout: StdioCollector {
            onStreamFinished: root.backlightPath = text.trim()
        }
    }

    // sysfs reads through FileView cost a read(2) each, with no process spawn.
    Timer {
        interval: 700
        repeat: true
        running: root.liveLinksEnabled && root.backlightPath !== ""
        triggeredOnStart: true
        onTriggered: {
            backlightMaxFile.reload();
            backlightFile.reload();
        }
    }

    FileView {
        id: backlightMaxFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/max_brightness"
        printErrors: false
        onLoaded: root.backlightMaxRaw = Number(backlightMaxFile.text().trim())
    }

    FileView {
        id: backlightFile

        path: root.backlightPath === "" ? "" : root.backlightPath + "/brightness"
        printErrors: false
        onLoaded: root.updateRawBrightness(Number(backlightFile.text().trim()))
    }

    Process {
        id: privacyPollProc

        stdout: StdioCollector {
            onStreamFinished: root.updatePolledPrivacy(text)
        }
    }

    Process {
        id: btSettingsProc
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.mode === "wifi"
        onTriggered: root.scanWifiNetworks()
    }

    Process {
        id: wifiRadioStateProc

        stdout: StdioCollector {
            onStreamFinished: root.wifiRadioEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiScanProc

        stdout: StdioCollector {
            onStreamFinished: root.parseWifiNetworks(text)
        }
    }

    Process {
        id: wifiRadioToggleProc

        onExited: root.scanWifiNetworks()
    }

    Process {
        id: wifiConnectProc

        stdinEnabled: true
        onStarted: {
            if (root.pendingWifiPassword !== "") {
                wifiConnectProc.write(root.pendingWifiPassword + "\n");
                root.pendingWifiPassword = "";
                root.wifiPasswordDraft = "";
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.wifiConnecting = false;
            root.pendingWifiPassword = "";

            if (exitCode === 0) {
                root.wifiExpandedSsid = "";
                root.wifiPasswordDraft = "";
                root.wifiStatusText = "";
            } else {
                root.wifiStatusText = "Connection failed";
            }

            root.scanWifiNetworks();
        }
    }

    Process {
        id: wifiDisconnectProc

        onExited: (exitCode, exitStatus) => {
            root.wifiConnecting = false;

            if (exitCode === 0) {
                root.wifiExpandedSsid = "";
                root.wifiStatusText = "";
            } else {
                root.wifiStatusText = "Disconnect failed";
            }

            root.scanWifiNetworks();
        }
    }

    Timer {
        id: appsStatusTimer

        interval: 2400
        repeat: false
        onTriggered: root.appsStatusText = ""
    }

    // The shell state dir usually exists already, but setText() will not create it
    // on a first run, so make sure of it before anything tries to save.
    Process {
        id: favoritesDirProc

        running: true
        command: ["mkdir", "-p", root.favoritesDir]
    }

    FileView {
        id: favoritesFile

        path: root.favoritesPath
        preload: true
        printErrors: false
        onLoaded: root.applyFavoritesJson(favoritesFile.text())
    }

    Process {
        id: wifiPollProc

        stdout: StdioCollector {
            onStreamFinished: root.parseActiveWifi(text)
        }
    }

    Process {
        id: btPollProc

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\t");
                root.btDeviceName = parts[0] || "";
                root.btBattery = parts.length > 1 ? parseInt(parts[1]) || -1 : -1;
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.liveLinksEnabled
        triggeredOnStart: true
        onTriggered: {
            if (!wifiPollProc.running)
                wifiPollProc.exec(["nmcli", "-t", "-f", "active,ssid,signal", "dev", "wifi"]);
            if (!btPollProc.running)
                btPollProc.exec(["sh", "-c", "dev=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-); [ -z \"$dev\" ] && printf '\\t\\n' && exit 0; bat=$(bluetoothctl info 2>/dev/null | sed -n 's/.*Battery Percentage: 0x[0-9a-f]* (\\([0-9]*\\)).*/\\1/p'); printf '%s\\t%s\\n' \"$dev\" \"$bat\""]);
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

            Component.onCompleted: {
                root.trayMediaDismissed = false;
                root.maybeShowMediaFromPlayer(modelData, false);
            }

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

    onInteractionOpenChanged: {
        if (root.interactionOpen)
            root.prewarmWifiNetworks();
    }

    onMediaAvailableChanged: {
        if (root.mediaAvailable)
            root.trayMediaDismissed = false;
    }

    PanelWindow {
        id: islandWindow

        screen: root.focusedScreen()
        color: "transparent"
        exclusiveZone: root.reservedZone
        exclusionMode: ExclusionMode.Normal
        // Tall enough for the tallest expanded panel so the morph never clips.
        // The surface is transparent and input is limited to `mask`, so the extra
        // room costs nothing.
        implicitHeight: Math.max(root.windowHeight, root.wifiMaxPanelHeight + 32, root.appsMaxPanelHeight + 32)
        visible: true

        WlrLayershell.namespace: "dynamic-glacier"
        WlrLayershell.layer: WlrLayer.Top
        // Layer surfaces get no keyboard by default, so every TextInput in here
        // was inert: forceActiveFocus() moved Qt's internal focus (which is why
        // the field highlighted) but the compositor never routed a single key
        // press to the surface. OnDemand hands us the keyboard while the pointer
        // has clicked into the island and gives it straight back on click-away —
        // Exclusive would hold it for as long as the bar is mapped, i.e. always.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

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
                readonly property bool trayLeftVisible: trayLeft.visible && trayLeft.opacity > 0
                readonly property bool trayRightVisible: trayRight.visible && trayRight.opacity > 0
                readonly property real islandRightEdge: island.x + island.width
                readonly property real islandBottomEdge: island.y + island.height
                readonly property real privacyRightEdge: privacyVisible ? privacyIndicators.x + privacyIndicators.width : islandRightEdge
                readonly property real privacyBottomEdge: privacyVisible ? privacyIndicators.y + privacyIndicators.height : islandBottomEdge
                readonly property real trayLeftEdge: trayLeftVisible ? trayLeft.x : island.x
                readonly property real trayRightEdge: trayRightVisible ? trayRight.x + trayRight.width : islandRightEdge
                readonly property real leftEdge: Math.min(island.x, trayLeftEdge, privacyVisible ? privacyIndicators.x : island.x)
                readonly property real rightEdge: Math.max(islandRightEdge, privacyRightEdge, trayRightEdge)
                readonly property real bottomEdge: Math.max(islandBottomEdge, privacyBottomEdge)

                x: Math.max(0, leftEdge - maskPadding)
                y: Math.max(0, island.y - maskPadding)
                width: Math.min(parent.width - x, rightEdge - x + maskPadding)
                height: Math.min(parent.height - y, bottomEdge - y + maskPadding)
            }

            IslandSurface {
                id: island

                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                targetW: root.targetWidth()
                targetH: root.targetHeight()
                wifiMaxPanelHeight: root.wifiMaxPanelHeight
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
                volumeKind: root.volumeKind
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
                batteryCharging: root.batteryPluggedIn()
                batteryLevel: root.batteryLevel()
                wifiConnected: root.wifiConnected
                wifiSsid: root.wifiSsid
                wifiSignal: root.wifiSignal
                btEnabled: root.btEnabled
                btConnected: root.btConnected
                btDeviceName: root.btDeviceName
                btBattery: root.btBattery
                timeText: root.hoverTimeText
                dateText: root.hoverDateText
                wifiRadioEnabled: root.wifiRadioEnabled
                wifiNetworks: root.wifiNetworks
                wifiExpandedSsid: root.wifiExpandedSsid
                wifiPasswordDraft: root.wifiPasswordDraft
                wifiStatusText: root.wifiStatusText
                wifiConnecting: root.wifiConnecting
                appsMaxPanelHeight: root.appsMaxPanelHeight
                favoriteAppEntries: root.favoriteAppEntries
                favoriteAppIds: root.favoriteAppIds
                appsPickerEntries: root.appsPickerEntries
                appsPickerOpen: root.appsPickerOpen
                appsSearchDraft: root.appsSearchDraft
                appsStatusText: root.appsStatusText
                appsFavoriteSlots: root.appsFavoriteSlots
                onPreviousRequested: root.mediaPrevious()
                onPlayPauseRequested: root.mediaTogglePlaying()
                onNextRequested: root.mediaNext()
                onShuffleRequested: root.mediaToggleShuffle()
                onLoopRequested: root.mediaCycleLoop()
                onFavoriteRequested: root.mediaToggleFavorite()
                onDismissRequested: {
                    root.mediaHoverSuppressed = true;
                    root.showIdle();
                }
                onWifiSettingsRequested: root.toggleWifiPanel()
                onWifiCloseRequested: root.showIdle()
                onWifiToggleRadioRequested: root.toggleWifiRadio()
                onWifiRowRequested: ssid => root.requestWifiExpand(ssid)
                onWifiConnectRequested: (ssid, secured) => root.connectToWifiNetwork(ssid, secured)
                onWifiDisconnectRequested: ssid => root.disconnectFromWifiNetwork(ssid)
                onWifiPasswordChanged: text => root.wifiPasswordDraft = text
                onAppsSettingsRequested: root.toggleAppsPanel()
                onAppsCloseRequested: root.showIdle()
                onAppsPickerToggleRequested: root.toggleAppsPicker()
                onAppsSearchChanged: text => root.appsSearchDraft = text
                onAppsSearchAccepted: root.launchTopSearchMatch()
                onAppsFavoriteToggleRequested: id => root.toggleFavoriteApp(id)
                onAppsLaunchRequested: id => root.launchFavoriteApp(id)
                onBtSettingsRequested: btSettingsProc.exec(["bluedevil-wizard"])
                onSeekRequested: position => root.mediaSeek(position)
                onHandleStyleRequested: style => root.setHandleStyle(style)
            }

            // Tray: left side (battery — only when charging, circular)
            Row {
                id: trayLeft

                z: 30
                x: island.x - width - 8
                y: island.y + Math.max(0, (island.height - height) / 2)
                spacing: 6
                opacity: root.trayVisible ? 1 : 0
                visible: opacity > 0

                TrayIndicator {
                    icon: "bolt"
                    iconSize: 11
                    iconColor: "#4ade80"
                    circular: true
                    active: root.trayVisible && root.batteryAvailable() && root.batteryPluggedIn()
                    dismissed: root.trayBatteryDismissed
                    onClicked: root.trayBatteryDismissed = true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Tray: right side (audio activity, notifications)
            Row {
                id: trayRight

                z: 30
                x: island.x + island.width + 8
                y: island.y + Math.max(0, (island.height - height) / 2)
                spacing: 6
                opacity: root.trayVisible ? 1 : 0
                visible: opacity > 0

                AudioIndicator {
                    active: root.trayVisible && root.mediaAvailable
                    playing: root.playing
                    dismissed: root.trayMediaDismissed
                    onClicked: root.trayMediaDismissed = true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Item {
                id: privacyIndicators

                readonly property int dotSize: root.compactPrivacyIndicators ? 4 : 9
                readonly property int itemSize: root.compactPrivacyIndicators ? dotSize : 16
                readonly property int dotSpacing: root.compactPrivacyIndicators ? 3 : 5
                readonly property int haloSize: root.compactPrivacyIndicators ? 0 : 16
                readonly property int islandGap: root.compactPrivacyIndicators ? 4 : 8
                readonly property real anchorX: trayRight.visible && trayRight.opacity > 0 ? trayRight.x + trayRight.width + privacyIndicators.islandGap : island.x + island.width + privacyIndicators.islandGap

                z: 35
                x: privacyIndicators.anchorX
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
                acceptedButtons: root.visualMode === "media" || root.visualMode === "wifi" || root.visualMode === "apps" || root.interactionOpen ? Qt.NoButton : Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onEntered: root.keepInteractionOpen(true)
                onExited: {
                    root.mediaHoverSuppressed = false;
                    root.scheduleInteractionClose();
                }
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

        function apps(): void {
            root.toggleAppsPanel();
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
