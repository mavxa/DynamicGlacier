import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

Scope {
    id: root

    // Register a narrow compositor rule at runtime so the glass works from the
    // packaged launcher as well as from an end-4 config. The global guard keeps
    // QML hot reloads from accumulating duplicate rules on Hyprland 0.55+.
    Process {
        id: compositorGlassRuleProc

        running: true
        command: [
            "hyprctl",
            "eval",
            "if rawget(_G, 'dynamic_glacier_glass_rule') == nil then _G.dynamic_glacier_glass_rule = hl.layer_rule({ name = 'dynamic-glacier-glass', match = { namespace = '^quickshell:dynamic-glacier$' }, blur = true, ignore_alpha = 0.18, xray = false }) end"
        ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                legacyCompositorGlassRuleProc.running = true;
        }
    }

    // Hyprland <= 0.54 has no Lua `eval`; keep the same package usable there
    // through the former runtime layer-rule syntax.
    Process {
        id: legacyCompositorGlassRuleProc

        running: false
        command: [
            "hyprctl",
            "--batch",
            "keyword layerrule blur,quickshell:dynamic-glacier ; keyword layerrule ignorealpha 0.18,quickshell:dynamic-glacier ; keyword layerrule xray 0,quickshell:dynamic-glacier"
        ]
    }

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
    property bool liquidGlassEnabled: false
    property int peekWidth: 340
    property int peekHeight: 132
    property bool exitPreviewActive: false
    property int exitPreviewWidth: 340
    property bool visualSettingsLoaded: false
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

    readonly property bool interactionOpen: root.mode === "idle" && (root.pointerInside || root.pinnedOpen || root.exitPreviewActive)
    readonly property bool trayVisible: root.handleStyle === "bump" && !root.interactionOpen && root.visualMode === "idle"
    readonly property bool hoverMediaMode: root.liveLinksEnabled && root.mode === "idle" && root.interactionOpen && !root.exitPreviewActive && !root.mediaHoverSuppressed && root.hasActiveMedia()
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
    readonly property int notifyWidth: 438
    readonly property int notifyHeight: 74
    readonly property int mediaWidth: 380
    readonly property int mediaHeight: 132
    readonly property int volumeWidth: 244
    readonly property int volumeHeight: 48
    readonly property int wifiWidth: 500
    // Floor for the Wi-Fi panel; the island grows past it to fit the network list,
    // up to wifiMaxPanelHeight.
    readonly property int wifiMinHeight: 132
    readonly property int wifiMaxPanelHeight: 440
    readonly property int btWidth: 500
    readonly property int btMinHeight: 132
    readonly property int btMaxPanelHeight: 440
    readonly property int batteryWidth: 500
    readonly property int batteryMinHeight: 132
    readonly property int settingsWidth: 500
    readonly property int settingsMinHeight: 132
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
    property string pendingWifiSsid: ""
    property bool pendingWifiSecured: false
    property bool pendingWifiUsedPassword: false
    property string wifiStatusText: ""
    property bool wifiConnecting: false
    property double lastWifiScanAt: 0

    // Bluetooth manager. Quickshell talks to BlueZ directly, so the panel and
    // compact status stay reactive without polling bluetoothctl through a shell.
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btDevices: root.sortedBluetoothDevices()
    readonly property var btConnectedDevice: root.btDevices.find(device => device.connected) ?? null
    readonly property bool btEnabled: root.btAdapter?.enabled ?? false
    readonly property bool btConnected: root.btConnectedDevice !== null
    readonly property string btDeviceName: root.btConnectedDevice?.name || root.btConnectedDevice?.deviceName || ""
    readonly property int btBattery: root.btConnectedDevice?.batteryAvailable ? Math.round(root.btConnectedDevice.battery * 100) : -1
    readonly property bool btDiscovering: root.btAdapter?.discovering ?? false
    property string btStatusText: ""

    // Detailed battery telemetry combines reactive UPower state with values that
    // are only exposed by the kernel power_supply interface on this machine.
    readonly property var batteryDevice: UPower.devices.values.find(device => device.isLaptopBattery && (device.nativePath ?? "") !== "") ?? UPower.displayDevice
    readonly property string batterySysfsPath: (root.batteryDevice?.nativePath ?? "") !== "" ? "/sys/class/power_supply/" + root.batteryDevice.nativePath : ""
    readonly property int batteryCycles: root.fileNumber(batteryCycleFile, -1)
    readonly property real batteryFullCharge: root.fileNumber(batteryFullFile, -1)
    readonly property real batteryDesignCharge: root.fileNumber(batteryDesignFile, -1)
    readonly property real batteryDesignVoltage: root.fileNumber(batteryDesignVoltageFile, -1)
    readonly property real batteryVoltage: root.fileNumber(batteryVoltageFile, -1) / 1000000
    readonly property real batteryCurrent: root.fileNumber(batteryCurrentFile, -1) / 1000000
    readonly property real batteryFullCapacityWh: root.batteryFullCharge >= 0 && root.batteryDesignVoltage > 0 ? root.batteryFullCharge * root.batteryDesignVoltage / 1000000000000 : -1
    readonly property real batteryDesignCapacityWh: root.batteryDesignCharge >= 0 && root.batteryDesignVoltage > 0 ? root.batteryDesignCharge * root.batteryDesignVoltage / 1000000000000 : -1
    readonly property real batteryHealth: root.batteryFullCharge >= 0 && root.batteryDesignCharge > 0 ? Math.min(100, root.batteryFullCharge / root.batteryDesignCharge * 100) : -1
    readonly property real batteryPower: root.batteryVoltage >= 0 && root.batteryCurrent >= 0 ? Math.abs(root.batteryVoltage * root.batteryCurrent) : -1
    readonly property string batteryStatus: root.fileText(batteryStatusFile, "")
    readonly property string batteryModel: root.fileText(batteryModelFile, "")
    readonly property string batteryDbusPath: (root.batteryDevice?.nativePath ?? "") !== "" ? "/org/freedesktop/UPower/devices/battery_" + root.batteryDevice.nativePath.replace(/[^A-Za-z0-9_]/g, "_") : ""
    property bool batteryThresholdSupported: false
    property bool batteryThresholdEnabled: false
    property bool batteryThresholdBusy: false
    property bool pendingBatteryThresholdEnabled: false
    property int batteryThresholdStart: -1
    property int batteryThresholdEnd: -1
    property string batteryThresholdStatusText: ""
    property bool powerProfilesAvailable: false
    property var availablePowerProfiles: []
    property string activePowerProfile: ""
    property bool powerProfileBusy: false
    property string pendingPowerProfile: ""
    property string powerProfileStatusText: ""
    property string performanceDegraded: ""
    property string performanceInhibited: ""

    // App favorites dock (morphs the island into mode "apps")
    readonly property int appsFavoriteSlots: 8
    readonly property string favoritesPath: Quickshell.statePath("favorites.json")
    readonly property string visualSettingsPath: Quickshell.statePath("settings.json")
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
        case "bluetooth":
            return root.btWidth;
        case "battery":
            return root.batteryWidth;
        case "settings":
            return root.settingsWidth;
        case "apps":
            return root.appsWidth;
        default:
            if (root.interactionOpen)
                return root.exitPreviewActive ? Math.max(root.peekWidth, root.exitPreviewWidth) : root.peekWidth;
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
        case "bluetooth":
            return root.btMinHeight;
        case "battery":
            return root.batteryMinHeight;
        case "settings":
            return root.settingsMinHeight;
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
        // Detail panels are hover-owned even when the idle island was pinned.
        // Keeping the pinned state only applies to the compact idle peek.
        if (root.mode === "wifi" || root.mode === "bluetooth" || root.mode === "battery" || root.mode === "settings" || root.mode === "apps" || !root.pinnedOpen)
            hoverLeaveTimer.restart();
    }

    function boolFromIpc(value) {
        return value === true || value === "true" || value === "1" || value === "on" || value === "yes";
    }

    function fileText(fileView, fallback) {
        if (!fileView?.loaded)
            return fallback;

        const value = fileView.text().trim();
        return value !== "" ? value : fallback;
    }

    function fileNumber(fileView, fallback) {
        const text = root.fileText(fileView, "");

        if (text === "")
            return fallback;

        const value = Number(text);
        return isFinite(value) ? value : fallback;
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

    function showIdle(preserveExitPreview) {
        const keepExitPreview = preserveExitPreview === true;

        if (root.mode === "bluetooth" && root.btAdapter?.discovering)
            root.btAdapter.discovering = false;

        collapseTimer.stop();
        root.mode = "idle";
        root.pinnedOpen = false;
        if (!keepExitPreview)
            root.exitPreviewActive = false;
        root.title = "Ready";
        root.body = "Waiting for a signal";
        // The picker owns the only focused text field in the island. Leaving it
        // flagged open while the island collapses would keep a hidden TextInput
        // holding the keyboard.
        root.appsPickerOpen = false;
        root.appsSearchDraft = "";
        root.appsStatusText = "";
        root.wifiExpandedSsid = "";
        root.wifiPasswordDraft = "";
        root.wifiStatusText = "";
        root.btStatusText = "";

        if (root.liveLinksEnabled) {
            root.chooseActivePlayer(null);
            if (root.hasActiveMedia())
                root.syncMediaFields(root.activePlayer);
        }
    }

    function closePanelToWideIdle(panelWidth) {
        root.exitPreviewWidth = Math.max(root.peekWidth, panelWidth);
        root.exitPreviewActive = true;
        root.pointerInside = true;
        root.showIdle(true);
    }

    function maybeFinishExitPreview(localX, areaWidth) {
        if (!root.exitPreviewActive)
            return;

        const normalWidth = Math.min(root.peekWidth, areaWidth);
        const normalLeft = (areaWidth - normalWidth) / 2;

        if (localX >= normalLeft && localX <= normalLeft + normalWidth) {
            root.exitPreviewActive = false;
            root.pointerInside = true;
        }
    }

    function setHandleStyle(style) {
        if (style === "strip" || style === "bump") {
            root.handleStyle = style;
            root.saveVisualSettings();
        }
    }

    function toggleHandleStyle() {
        root.handleStyle = root.handleStyle === "strip" ? "bump" : "strip";
        root.saveVisualSettings();
    }

    function setLiquidGlassEnabled(enabled) {
        root.liquidGlassEnabled = enabled === true;
        root.saveVisualSettings();
    }

    function setIdleWidth(width) {
        const numericWidth = Number(width);

        if (isFinite(numericWidth)) {
            root.peekWidth = Math.max(300, Math.min(520, Math.round(numericWidth / 10) * 10));
            root.saveVisualSettings();
        }
    }

    function setIdleHeight(height) {
        const numericHeight = Number(height);

        if (isFinite(numericHeight)) {
            root.peekHeight = Math.max(112, Math.min(180, Math.round(numericHeight / 4) * 4));
            root.saveVisualSettings();
        }
    }

    function resetVisualSettings() {
        root.liquidGlassEnabled = false;
        root.peekWidth = 340;
        root.peekHeight = 132;
        root.saveVisualSettings();
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
        root.exitPreviewActive = false;
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
        if (root.wifiConnecting)
            return;

        root.wifiConnecting = true;
        root.wifiStatusText = "";
        root.pendingWifiSsid = ssid;
        root.pendingWifiSecured = secured;
        root.pendingWifiUsedPassword = root.wifiPasswordDraft !== "";

        const command = ["nmcli"];

        if (root.pendingWifiUsedPassword) {
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

    function bluetoothDeviceName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown device";
    }

    function sortedBluetoothDevices() {
        const devices = root.btAdapter?.devices.values ?? [];

        return devices.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;

            return root.bluetoothDeviceName(a).localeCompare(root.bluetoothDeviceName(b));
        });
    }

    function toggleBluetoothPanel() {
        if (root.mode === "bluetooth") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "bluetooth";
        root.btStatusText = root.btAdapter ? "" : "No Bluetooth adapter";

        if (root.btEnabled)
            root.btAdapter.discovering = true;
    }

    function toggleBluetoothRadio() {
        if (!root.btAdapter) {
            root.btStatusText = "No Bluetooth adapter";
            return;
        }

        const nextState = !root.btAdapter.enabled;
        root.btStatusText = "";
        root.btAdapter.enabled = nextState;
        root.btAdapter.discovering = nextState;
    }

    function refreshBluetoothDevices() {
        if (!root.btAdapter || !root.btAdapter.enabled)
            return;

        root.btStatusText = "";
        root.btAdapter.discovering = true;
    }

    function toggleBluetoothDevice(device) {
        if (!device)
            return;

        root.btStatusText = "";

        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    function refreshBatteryTelemetry() {
        if (root.batterySysfsPath === "")
            return;

        batteryCycleFile.reload();
        batteryFullFile.reload();
        batteryDesignFile.reload();
        batteryDesignVoltageFile.reload();
        batteryVoltageFile.reload();
        batteryCurrentFile.reload();
        batteryStatusFile.reload();
        batteryModelFile.reload();
        batteryThresholdFile.reload();
    }

    function parseBusctlValue(line) {
        const separator = line.indexOf(" ");
        return separator >= 0 ? line.slice(separator + 1).trim() : "";
    }

    function parseBatteryThresholdState(text) {
        const lines = text.trim().split("\n").filter(line => line.trim() !== "");

        if (lines.length < 4)
            return;

        const start = Number(root.parseBusctlValue(lines[0]));
        const end = Number(root.parseBusctlValue(lines[1]));

        root.batteryThresholdStart = isFinite(start) ? start : -1;
        root.batteryThresholdEnd = isFinite(end) ? end : -1;
        root.batteryThresholdEnabled = root.parseBusctlValue(lines[2]) === "true";
        root.batteryThresholdSupported = root.parseBusctlValue(lines[3]) === "true";
    }

    function refreshBatteryThresholdState() {
        if (root.batteryDbusPath === "" || batteryThresholdStateProc.running)
            return;

        batteryThresholdStateProc.exec([
            "busctl", "get-property",
            "org.freedesktop.UPower",
            root.batteryDbusPath,
            "org.freedesktop.UPower.Device",
            "ChargeStartThreshold",
            "ChargeEndThreshold",
            "ChargeThresholdEnabled",
            "ChargeThresholdSupported"
        ]);
    }

    function setBatteryThreshold(enabled) {
        if (!root.batteryThresholdSupported || root.batteryThresholdBusy || root.batteryDbusPath === "")
            return;

        root.pendingBatteryThresholdEnabled = enabled;
        root.batteryThresholdBusy = true;
        root.batteryThresholdStatusText = "";
        batteryThresholdToggleProc.exec([
            "busctl", "call",
            "org.freedesktop.UPower",
            root.batteryDbusPath,
            "org.freedesktop.UPower.Device",
            "EnableChargeThreshold",
            "b",
            root.pendingBatteryThresholdEnabled ? "true" : "false"
        ]);
    }

    function toggleBatteryThreshold() {
        root.setBatteryThreshold(!root.batteryThresholdEnabled);
    }

    function parseBusctlString(line) {
        const value = root.parseBusctlValue(line);

        if (value.length >= 2 && value.charAt(0) === "\"" && value.charAt(value.length - 1) === "\"")
            return value.slice(1, -1);

        return value;
    }

    function parsePowerProfileState(text) {
        const lines = text.trim().split("\n").filter(line => line.trim() !== "");

        if (lines.length < 4)
            return;

        const profilesLine = lines[1];
        const knownProfiles = ["power-saver", "balanced", "performance"];
        const profiles = knownProfiles.filter(profile => profilesLine.indexOf("\"" + profile + "\"") !== -1);
        const active = root.parseBusctlString(lines[0]);

        root.availablePowerProfiles = profiles;
        root.activePowerProfile = active;
        root.performanceDegraded = root.parseBusctlString(lines[2]);
        root.performanceInhibited = root.parseBusctlString(lines[3]);
        root.powerProfilesAvailable = profiles.length > 0 && profiles.indexOf(active) !== -1;
    }

    function refreshPowerProfileState() {
        if (powerProfileStateProc.running)
            return;

        powerProfileStateProc.exec([
            "busctl", "get-property",
            "org.freedesktop.UPower.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.UPower.PowerProfiles",
            "ActiveProfile",
            "Profiles",
            "PerformanceDegraded",
            "PerformanceInhibited"
        ]);
    }

    function setPowerProfile(profile) {
        if (!root.powerProfilesAvailable || root.powerProfileBusy || root.availablePowerProfiles.indexOf(profile) === -1 || profile === root.activePowerProfile)
            return;

        root.pendingPowerProfile = profile;
        root.powerProfileBusy = true;
        root.powerProfileStatusText = "";
        powerProfileSetProc.exec([
            "busctl", "set-property",
            "org.freedesktop.UPower.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.UPower.PowerProfiles",
            "ActiveProfile",
            "s",
            profile
        ]);
    }

    function toggleBatteryPanel() {
        if (root.mode === "battery") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "battery";
        root.refreshBatteryTelemetry();
        root.refreshBatteryThresholdState();
        root.refreshPowerProfileState();
    }

    function toggleSettingsPanel() {
        if (root.mode === "settings") {
            root.showIdle();
            return;
        }

        collapseTimer.stop();
        root.exitPreviewActive = false;
        root.mode = "settings";
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
        root.exitPreviewActive = false;
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

    function applyVisualSettingsJson(text) {
        try {
            const parsed = JSON.parse(text);

            root.handleStyle = parsed.handleStyle === "strip" ? "strip" : "bump";
            root.liquidGlassEnabled = parsed.liquidGlassEnabled === true;
            root.peekWidth = Math.max(300, Math.min(520, Math.round((Number(parsed.idleWidth) || 340) / 10) * 10));
            root.peekHeight = Math.max(112, Math.min(180, Math.round((Number(parsed.idleHeight) || 132) / 4) * 4));
        } catch (error) {
            // Keep the built-in defaults if the file is empty or hand-edited
            // into invalid JSON. The next UI change rewrites a valid file.
        }

        root.visualSettingsLoaded = true;
    }

    function saveVisualSettings() {
        if (!root.visualSettingsLoaded)
            return;

        visualSettingsFile.setText(JSON.stringify({
            handleStyle: root.handleStyle,
            liquidGlassEnabled: root.liquidGlassEnabled,
            idleWidth: root.peekWidth,
            idleHeight: root.peekHeight
        }, null, 2) + "\n");
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
        onTriggered: {
            root.pointerInside = false;

            if (root.exitPreviewActive || root.mode === "wifi" || root.mode === "bluetooth" || root.mode === "battery" || root.mode === "settings" || root.mode === "apps")
                root.showIdle();
        }
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

    FileView {
        id: batteryCycleFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/cycle_count" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryFullFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_full" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryDesignFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_full_design" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryDesignVoltageFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/voltage_min_design" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryVoltageFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/voltage_now" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryCurrentFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/current_now" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryStatusFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/status" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryModelFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/model_name" : ""
        preload: true
        printErrors: false
    }

    FileView {
        id: batteryThresholdFile
        path: root.batterySysfsPath !== "" ? root.batterySysfsPath + "/charge_control_end_threshold" : ""
        preload: true
        printErrors: false
        onLoaded: {
            if (root.batteryThresholdEnd < 0)
                root.batteryThresholdEnd = root.fileNumber(batteryThresholdFile, -1);
        }
    }

    Process {
        id: batteryThresholdStateProc

        stdout: StdioCollector {
            onStreamFinished: root.parseBatteryThresholdState(text)
        }
    }

    Process {
        id: batteryThresholdToggleProc

        onExited: (exitCode, exitStatus) => {
            root.batteryThresholdBusy = false;

            if (exitCode === 0) {
                root.batteryThresholdStatusText = root.pendingBatteryThresholdEnabled ? "Charge limit enabled" : "Charge limit disabled";
                root.batteryThresholdEnabled = root.pendingBatteryThresholdEnabled;
            } else {
                root.batteryThresholdStatusText = "Could not change charge limit";
            }

            root.refreshBatteryTelemetry();
            root.refreshBatteryThresholdState();
            batteryThresholdStatusTimer.restart();
        }
    }

    Timer {
        id: batteryThresholdStatusTimer

        interval: 2600
        repeat: false
        onTriggered: root.batteryThresholdStatusText = ""
    }

    Process {
        id: powerProfileStateProc

        stdout: StdioCollector {
            onStreamFinished: root.parsePowerProfileState(text)
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.powerProfilesAvailable = false;
                root.availablePowerProfiles = [];
                root.activePowerProfile = "";
                root.performanceDegraded = "";
                root.performanceInhibited = "";
            }
        }
    }

    Process {
        id: powerProfileSetProc

        onExited: (exitCode, exitStatus) => {
            const requestedProfile = root.pendingPowerProfile;

            root.powerProfileBusy = false;
            root.pendingPowerProfile = "";

            if (exitCode === 0) {
                root.activePowerProfile = requestedProfile;
                root.powerProfileStatusText = "Power mode changed";
            } else {
                root.powerProfileStatusText = "Could not change power mode";
            }

            root.refreshPowerProfileState();
            powerProfileStatusTimer.restart();
        }
    }

    Timer {
        id: powerProfileStatusTimer

        interval: 2600
        repeat: false
        onTriggered: root.powerProfileStatusText = ""
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.mode === "battery" && root.powerProfilesAvailable
        onTriggered: root.refreshPowerProfileState()
    }

    Process {
        id: privacyPollProc

        stdout: StdioCollector {
            onStreamFinished: root.updatePolledPrivacy(text)
        }
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
            const attemptedSsid = root.pendingWifiSsid;
            const secured = root.pendingWifiSecured;
            const usedPassword = root.pendingWifiUsedPassword;

            root.wifiConnecting = false;
            root.pendingWifiPassword = "";
            root.pendingWifiSsid = "";
            root.pendingWifiSecured = false;
            root.pendingWifiUsedPassword = false;

            if (exitCode === 0) {
                root.wifiExpandedSsid = "";
                root.wifiPasswordDraft = "";
                root.wifiStatusText = "";
            } else if (secured && !usedPassword) {
                // `nmcli device wifi connect` reuses a matching saved profile.
                // Only fall back to asking for a secret when that direct attempt
                // could not activate the secured network.
                root.wifiExpandedSsid = attemptedSsid;
                root.wifiPasswordDraft = "";
                root.wifiStatusText = "Password required";
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

    FileView {
        id: visualSettingsFile

        path: root.visualSettingsPath
        preload: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.applyVisualSettingsJson(visualSettingsFile.text())
        onLoadFailed: {
            root.visualSettingsLoaded = true;
            visualSettingsInitialSaveTimer.restart();
        }
    }

    Timer {
        id: visualSettingsInitialSaveTimer

        interval: 180
        repeat: false
        onTriggered: root.saveVisualSettings()
    }

    Process {
        id: wifiPollProc

        stdout: StdioCollector {
            onStreamFinished: root.parseActiveWifi(text)
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
        implicitHeight: Math.max(root.windowHeight, root.wifiMaxPanelHeight + 32, root.btMaxPanelHeight + 32, root.settingsMinHeight + 180, root.appsMaxPanelHeight + 32)
        visible: true

        // end-4 already enables compositor blur for `quickshell:*` surfaces.
        // Other Hyprland setups can target this stable namespace explicitly.
        WlrLayershell.namespace: "quickshell:dynamic-glacier"
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
                btMaxPanelHeight: root.btMaxPanelHeight
                mode: root.visualMode
                handleStyle: root.handleStyle
                liquidGlassEnabled: root.liquidGlassEnabled
                idleWidth: root.peekWidth
                idleHeight: root.peekHeight
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
                batteryAvailable: root.batteryAvailable()
                batteryHealth: root.batteryHealth
                batteryCycles: root.batteryCycles
                batteryFullCapacityWh: root.batteryFullCapacityWh
                batteryDesignCapacityWh: root.batteryDesignCapacityWh
                batteryVoltage: root.batteryVoltage
                batteryPower: root.batteryPower
                batteryStatus: root.batteryStatus
                batteryModel: root.batteryModel
                batteryThresholdSupported: root.batteryThresholdSupported
                batteryThresholdEnabled: root.batteryThresholdEnabled
                batteryThresholdBusy: root.batteryThresholdBusy
                batteryThresholdStart: root.batteryThresholdStart
                batteryThresholdEnd: root.batteryThresholdEnd
                batteryThresholdStatusText: root.batteryThresholdStatusText
                powerProfilesAvailable: root.powerProfilesAvailable
                availablePowerProfiles: root.availablePowerProfiles
                activePowerProfile: root.activePowerProfile
                powerProfileBusy: root.powerProfileBusy
                powerProfileStatusText: root.powerProfileStatusText
                performanceDegraded: root.performanceDegraded
                performanceInhibited: root.performanceInhibited
                wifiConnected: root.wifiConnected
                wifiSsid: root.wifiSsid
                wifiSignal: root.wifiSignal
                btEnabled: root.btEnabled
                btConnected: root.btConnected
                btDeviceName: root.btDeviceName
                btBattery: root.btBattery
                btDiscovering: root.btDiscovering
                btDevices: root.btDevices
                btStatusText: root.btStatusText
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
                onWifiCloseRequested: root.closePanelToWideIdle(root.wifiWidth)
                onWifiToggleRadioRequested: root.toggleWifiRadio()
                onWifiRowRequested: ssid => root.requestWifiExpand(ssid)
                onWifiConnectRequested: (ssid, secured) => root.connectToWifiNetwork(ssid, secured)
                onWifiDisconnectRequested: ssid => root.disconnectFromWifiNetwork(ssid)
                onWifiPasswordChanged: text => root.wifiPasswordDraft = text
                onBtCloseRequested: root.closePanelToWideIdle(root.btWidth)
                onBtToggleRadioRequested: root.toggleBluetoothRadio()
                onBtRefreshRequested: root.refreshBluetoothDevices()
                onBtDeviceRequested: device => root.toggleBluetoothDevice(device)
                onBatteryRequested: root.toggleBatteryPanel()
                onBatteryCloseRequested: root.closePanelToWideIdle(root.batteryWidth)
                onBatteryToggleThresholdRequested: root.toggleBatteryThreshold()
                onPowerProfileRequested: profile => root.setPowerProfile(profile)
                onAppsSettingsRequested: root.toggleAppsPanel()
                onGlacierSettingsRequested: root.toggleSettingsPanel()
                onSettingsCloseRequested: root.closePanelToWideIdle(root.settingsWidth)
                onLiquidGlassRequested: enabled => root.setLiquidGlassEnabled(enabled)
                onIdleWidthRequested: width => root.setIdleWidth(width)
                onIdleHeightRequested: height => root.setIdleHeight(height)
                onSettingsResetRequested: root.resetVisualSettings()
                onAppsCloseRequested: root.closePanelToWideIdle(root.appsWidth)
                onAppsPickerToggleRequested: root.toggleAppsPicker()
                onAppsSearchChanged: text => root.appsSearchDraft = text
                onAppsSearchAccepted: root.launchTopSearchMatch()
                onAppsFavoriteToggleRequested: id => root.toggleFavoriteApp(id)
                onAppsLaunchRequested: id => root.launchFavoriteApp(id)
                onBtSettingsRequested: root.toggleBluetoothPanel()
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
                    onClicked: {
                        root.trayBatteryDismissed = true;
                        root.toggleBatteryPanel();
                    }
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
                acceptedButtons: root.visualMode === "media" || root.visualMode === "wifi" || root.visualMode === "bluetooth" || root.visualMode === "battery" || root.visualMode === "settings" || root.visualMode === "apps" || root.interactionOpen ? Qt.NoButton : Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onEntered: root.keepInteractionOpen(true)
                onPositionChanged: mouse => root.maybeFinishExitPreview(mouse.x, width)
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

        function wifi(): void {
            root.toggleWifiPanel();
        }

        function bluetooth(): void {
            root.toggleBluetoothPanel();
        }

        function battery(): void {
            root.toggleBatteryPanel();
        }

        function settings(): void {
            root.toggleSettingsPanel();
        }

        function liquidGlass(enabled: string): void {
            root.setLiquidGlassEnabled(root.boolFromIpc(enabled));
        }

        function idleSize(width: int, height: int): void {
            root.setIdleWidth(width);
            root.setIdleHeight(height);
        }

        function batteryLimit(enabled: string): void {
            root.setBatteryThreshold(root.boolFromIpc(enabled));
        }

        function powerProfile(profile: string): void {
            root.setPowerProfile(profile);
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
