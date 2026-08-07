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
    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#7f7f7f"
    readonly property color accent: "#ffffff"
    readonly property int mediaHorizontalPadding: 24
    readonly property real normalizedMediaPosition: root.normalizedSeconds(mediaPosition)
    readonly property real normalizedMediaLength: root.normalizedSeconds(mediaLength)
    readonly property real mediaProgress: normalizedMediaLength > 0 ? Math.max(0, Math.min(1, normalizedMediaPosition / normalizedMediaLength)) : 0

    property bool wifiRadioEnabled: true
    property var wifiNetworks: []
    property string wifiExpandedSsid: ""
    property string wifiPasswordDraft: ""
    property string wifiStatusText: ""
    property bool wifiConnecting: false

    // 0 = island surface content, 1 = Wi-Fi manager. Driven by the surface morph transition.
    property real wifiMorph: 0
    property int wifiMaxPanelHeight: 420

    // Wi-Fi panel metrics — kept as tokens so the surface can size itself to the list.
    readonly property int wifiPanelPadding: 14
    readonly property int wifiHeaderHeight: 30
    readonly property int wifiSectionSpacing: 10
    readonly property int wifiRowHeight: 36
    readonly property int wifiRowSpacing: 4
    readonly property int wifiPlaceholderHeight: 58
    readonly property real wifiBodyHeight: root.wifiRadioEnabled && root.wifiNetworks.length > 0 ? wifiNetworkColumn.implicitHeight : root.wifiPlaceholderHeight
    readonly property real wifiContentHeight: Math.min(root.wifiMaxPanelHeight, root.wifiPanelPadding * 2 + root.wifiHeaderHeight + root.wifiSectionSpacing + root.wifiBodyHeight)

    property var favoriteAppEntries: []
    property var favoriteAppIds: []
    property var appsPickerEntries: []
    property bool appsPickerOpen: false
    property string appsSearchDraft: ""
    property string appsStatusText: ""
    property int appsFavoriteSlots: 8

    // 0 = island surface content, 1 = favorites dock. Driven by the surface morph transition.
    property real appsMorph: 0
    property int appsMaxPanelHeight: 470

    // Favorites dock metrics — same token style as the Wi-Fi panel, so the surface
    // can size itself to the grid plus whatever the picker drawer is showing.
    readonly property int appsPanelPadding: 14
    readonly property int appsHeaderHeight: 30
    readonly property int appsSectionSpacing: 10
    readonly property int appsGridSpacing: 8
    readonly property int appsGridColumns: 4
    readonly property int appsGridRows: 2
    readonly property int appsTileHeight: 62
    readonly property int appsGridHeight: root.appsTileHeight * root.appsGridRows + root.appsGridSpacing * (root.appsGridRows - 1)
    readonly property int appsPickerToggleHeight: 30
    readonly property int appsPickerRowHeight: 34
    readonly property int appsPickerRowSpacing: 3
    readonly property int appsPickerMaxHeight: 190
    readonly property real appsPickerListHeight: root.appsPickerOpen ? Math.min(root.appsPickerMaxHeight, Math.max(root.appsPickerRowHeight, root.appsPickerEntries.length * (root.appsPickerRowHeight + root.appsPickerRowSpacing) - root.appsPickerRowSpacing)) : 0
    readonly property real appsContentHeight: Math.min(root.appsMaxPanelHeight, root.appsPanelPadding * 2 + root.appsHeaderHeight + root.appsSectionSpacing + root.appsGridHeight + root.appsSectionSpacing + root.appsPickerToggleHeight + (root.appsPickerOpen ? root.appsSectionSpacing + root.appsPickerListHeight : 0))

    // 0 = island surface content, 1 = volume HUD. Driven by the surface morph transition.
    property real volumeMorph: 0
    property string volumeKind: "audio"

    readonly property real volumeProgress: root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100))
    readonly property real volumeHudProgress: Math.max(0, Math.min(1, (root.volumeMorph - 0.15) / 0.85))
    readonly property string volumeGlyph: {
        if (root.volumeKind === "brightness")
            return root.volume >= 50 ? "brightness_high" : "brightness_low";

        if (root.muted)
            return "volume_off";

        if (root.volume <= 0)
            return "volume_mute";

        return root.volume < 50 ? "volume_down" : "volume_up";
    }

    readonly property int favoriteAppCount: root.favoriteAppIds.length

    // Only one panel morph is ever non-zero, so the peek can react to whichever is running.
    readonly property real panelMorph: Math.max(root.wifiMorph, root.appsMorph)

    // The peek stays mounted through the morph so it can fade/shrink into the panel.
    readonly property bool peekVisible: (root.mode === "idle" && root.forceExpanded) || root.mode === "wifi" || root.mode === "apps"
    readonly property real peekMorphOpacity: 1 - Math.min(1, root.panelMorph / 0.45)
    readonly property real wifiPanelProgress: Math.max(0, Math.min(1, (root.wifiMorph - 0.22) / 0.78))
    readonly property real appsPanelProgress: Math.max(0, Math.min(1, (root.appsMorph - 0.22) / 0.78))

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
        id: collapsedBumpMedia

        anchors.fill: parent
        opacity: root.mode === "idle" && !root.forceExpanded && root.handleStyle === "bump" ? 1 : 0
        visible: opacity > 0

        Rectangle {
            id: collapsedCover

            x: 9
            y: 4
            width: 14
            height: 14
            radius: 5
            color: "#060606"
            border.width: 1
            border.color: "#242424"
            clip: true
            visible: root.mediaAvailable

            Image {
                id: collapsedCoverSource

                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: collapsedCoverSource
                visible: root.artUrl !== "" && collapsedCoverSource.status === Image.Ready

                maskSource: Rectangle {
                    width: collapsedCover.width
                    height: collapsedCover.height
                    radius: collapsedCover.radius
                }
            }

            Row {
                id: collapsedEqualizer

                anchors.centerIn: parent
                spacing: 1
                visible: root.artUrl === "" || collapsedCoverSource.status !== Image.Ready

                Repeater {
                    model: 3

                    Rectangle {
                        width: 2
                        height: root.playing ? (5 + index * 2) : 4
                        radius: 1
                        color: root.playing ? "#f1f1f1" : "#666666"

                        // Gate on the bars' own effective visibility, not just the
                        // container's. `visible` folds in every ancestor, so this
                        // also covers collapsedCover (visible: mediaAvailable).
                        //
                        // This used to be `collapsedBumpMedia.visible && root.playing`,
                        // and `playing` defaults to true and is never cleared when
                        // there is no player — syncMediaFields() returns early on a
                        // null player. So with no media at all, three infinite
                        // animations ran from startup on invisible bars, which keeps
                        // Qt's animation driver ticking and the render thread waking
                        // at the refresh rate for as long as the shell is up.
                        SequentialAnimation on height {
                            running: collapsedEqualizer.visible && root.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 4 + index
                                duration: 280 + index * 70
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 8 - index
                                duration: 320 + index * 70
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            x: collapsedCover.x - 1
            y: collapsedCover.y + collapsedCover.height + 1
            width: collapsedCover.width + 2
            height: 2
            radius: 1
            color: "#1d1d1d"
            visible: root.mediaAvailable

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.playing ? parent.width : 6
                height: parent.height
                radius: parent.radius
                color: root.playing ? "#f2f2f2" : "#5f5f5f"

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            anchors.left: root.mediaAvailable ? collapsedCover.right : parent.left
            anchors.leftMargin: root.mediaAvailable ? 9 : 0
            anchors.right: parent.right
            anchors.rightMargin: root.mediaAvailable ? 9 : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText
            color: root.primaryText
            horizontalAlignment: root.mediaAvailable ? Text.AlignLeft : Text.AlignHCenter
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: idleContent

        anchors.fill: parent
        opacity: root.peekVisible ? root.peekMorphOpacity : 0
        visible: opacity > 0
        scale: 1 - 0.05 * root.panelMorph
        transformOrigin: Item.Top

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 7
            spacing: 2

            HandleStyleSwitch {
                handleStyle: root.handleStyle
                batteryCharging: root.batteryCharging
                batteryLevel: root.batteryLevel
                fontFamily: root.fontFamily
                showBattery: true
                onHandleStyleRequested: style => root.handleStyleRequested(style)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.timeText
                        color: root.primaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dateText
                        color: "#b8b8b8"
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 5

                    // WiFi
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: wifiRow.width
                        Layout.preferredHeight: wifiRow.height

                        Row {
                            id: wifiRow
                            spacing: 4

                            MIcon {
                                name: root.wifiConnected ? (root.wifiSignal >= 70 ? "wifi" : root.wifiSignal >= 40 ? "wifi_2_bar" : "wifi_1_bar") : "wifi_off"
                                size: 13
                                color: root.wifiConnected ? "#f0f0f0" : "#555555"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.wifiConnected ? root.wifiSsid : "Off"
                                color: root.wifiConnected ? "#c8c8c8" : "#555555"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiSettingsRequested()
                        }
                    }

                    // Bluetooth
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: btRow.width
                        Layout.preferredHeight: btRow.height

                        Row {
                            id: btRow
                            spacing: 4

                            MIcon {
                                name: "bluetooth"
                                size: 13
                                color: root.btConnected ? "#5b9bf8" : (root.btEnabled ? "#f0f0f0" : "#555555")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.btConnected ? (root.btBattery >= 0 ? root.btDeviceName + " " + root.btBattery + "%" : root.btDeviceName) : (root.btEnabled ? "On" : "Off")
                                color: root.btConnected ? "#c8c8c8" : "#555555"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.btSettingsRequested()
                        }
                    }

                    // Favorite apps dock
                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: favoritesRow.width
                        Layout.preferredHeight: favoritesRow.height

                        Row {
                            id: favoritesRow
                            spacing: 4

                            MIcon {
                                name: "star"
                                size: 13
                                filled: root.favoriteAppCount > 0
                                color: root.favoriteAppCount > 0 ? "#f2c14b" : "#555555"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.favoriteAppCount > 0 ? root.favoriteAppCount + " pinned" : "Favorites"
                                color: root.favoriteAppCount > 0 ? "#c8c8c8" : "#555555"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appsSettingsRequested()
                        }
                    }
                }
            }
        }

        // The morph drives opacity directly; only plain show/hide is eased here.
        Behavior on opacity {
            enabled: root.panelMorph <= 0.001

            NumberAnimation {
                duration: 160
            }
        }
    }

    Item {
        id: wifiContent

        anchors.fill: parent
        opacity: root.wifiPanelProgress
        visible: opacity > 0.001
        scale: 0.94 + 0.06 * root.wifiPanelProgress
        transformOrigin: Item.Top

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.wifiPanelPadding
            spacing: root.wifiSectionSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.wifiHeaderHeight
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: root.wifiHeaderHeight
                    Layout.preferredHeight: root.wifiHeaderHeight
                    radius: 11
                    color: "#090909"
                    border.width: 1
                    border.color: "#232323"

                    MIcon {
                        anchors.centerIn: parent
                        name: root.wifiRadioEnabled ? "wifi" : "wifi_off"
                        size: 15
                        color: root.wifiRadioEnabled ? root.primaryText : "#555555"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                        color: root.primaryText
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !root.wifiRadioEnabled ? "Off" : (root.wifiConnected ? root.wifiSsid : "Not connected")
                        color: root.wifiConnected ? "#c8c8c8" : "#555555"
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
                    color: root.wifiRadioEnabled ? "#f0f0f0" : "#0a0a0a"
                    border.width: 1
                    border.color: root.wifiRadioEnabled ? "#f0f0f0" : "#232323"

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        y: 3
                        x: root.wifiRadioEnabled ? parent.width - width - 3 : 3
                        color: root.wifiRadioEnabled ? "#000000" : "#4b4b4b"

                        Behavior on x {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wifiToggleRadioRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: wifiCloseMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                    border.width: 1
                    border.color: "#232323"

                    MIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 12
                        color: "#999999"
                    }

                    MouseArea {
                        id: wifiCloseMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wifiCloseRequested()
                    }
                }
            }

            Flickable {
                id: wifiListFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: contentHeight > height
                contentHeight: wifiNetworkColumn.height
                boundsBehavior: Flickable.StopAtBounds
                visible: root.wifiRadioEnabled && root.wifiNetworks.length > 0

                ColumnLayout {
                    id: wifiNetworkColumn

                    width: wifiListFlick.width
                    spacing: root.wifiRowSpacing

                    Repeater {
                        model: root.wifiNetworks

                        delegate: Rectangle {
                            id: wifiRowItem

                            required property var modelData
                            required property int index

                            readonly property bool expanded: root.wifiExpandedSsid === modelData.ssid
                            // Rows stagger in off the shared morph progress instead of their own
                            // timers. The delay is capped so every row still reaches full opacity
                            // at wifiMorph 1, including ones that arrive after the morph finished.
                            readonly property real appear: Math.max(0, Math.min(1, (root.wifiMorph - Math.min(index, 6) * 0.045) / 0.55))

                            Layout.fillWidth: true
                            Layout.preferredHeight: root.wifiRowHeight + (expanded ? wifiExpandedContent.implicitHeight + 10 : 0)
                            radius: 13
                            color: expanded ? "#0a0a0a" : (wifiRowMouse.containsMouse ? "#101010" : "transparent")
                            border.width: 1
                            border.color: expanded ? "#232323" : "transparent"
                            opacity: appear

                            transform: Translate {
                                y: (1 - wifiRowItem.appear) * 12
                            }

                            Behavior on Layout.preferredHeight {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.bottomMargin: wifiRowItem.expanded ? 10 : 0
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.wifiRowHeight
                                    spacing: 8

                                    MIcon {
                                        name: wifiRowItem.modelData.signal >= 70 ? "wifi" : wifiRowItem.modelData.signal >= 40 ? "wifi_2_bar" : "wifi_1_bar"
                                        size: 13
                                        color: wifiRowItem.modelData.active ? root.primaryText : "#c8c8c8"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: wifiRowItem.modelData.ssid
                                        color: root.primaryText
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: wifiRowItem.modelData.signal + "%"
                                        color: "#6d6d6d"
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    // Fixed slots so the trailing column stays aligned
                                    // whether or not a row is secured or active.
                                    Item {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "lock"
                                            size: 11
                                            color: "#9c9c9c"
                                            visible: wifiRowItem.modelData.secured
                                        }
                                    }

                                    Item {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "check"
                                            size: 13
                                            color: "#5b9bf8"
                                            visible: wifiRowItem.modelData.active
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: wifiExpandedContent

                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: wifiRowItem.expanded

                                    Text {
                                        Layout.fillWidth: true
                                        visible: wifiRowItem.modelData.active
                                        text: "Disconnect from this network?"
                                        color: root.secondaryText
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        visible: !wifiRowItem.modelData.active && wifiRowItem.modelData.secured
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 10
                                        color: "#090909"
                                        border.width: 1
                                        border.color: wifiPasswordInput.activeFocus ? "#3a3a3a" : "#232323"

                                        TextInput {
                                            id: wifiPasswordInput

                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: Text.AlignVCenter
                                            echoMode: TextInput.Password
                                            color: root.primaryText
                                            font.family: root.fontFamily
                                            font.pixelSize: 12
                                            clip: true
                                            text: root.wifiPasswordDraft
                                            onTextChanged: root.wifiPasswordChanged(text)
                                            onAccepted: root.wifiConnectRequested(wifiRowItem.modelData.ssid, wifiRowItem.modelData.secured)

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Password"
                                                color: "#5f5f5f"
                                                visible: wifiPasswordInput.text === ""
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: root.wifiStatusText !== ""
                                        text: root.wifiStatusText
                                        color: "#f0736a"
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28
                                            radius: 10
                                            color: wifiCancelMouse.containsMouse ? "#151515" : "#090909"
                                            border.width: 1
                                            border.color: "#232323"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                color: "#e5e5e5"
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: wifiCancelMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.wifiRowRequested(wifiRowItem.modelData.ssid)
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28
                                            radius: 10
                                            color: wifiRowItem.modelData.active ? "#1a0f0f" : (root.wifiConnecting ? "#8a8a8a" : "#f0f0f0")
                                            border.width: 1
                                            border.color: wifiRowItem.modelData.active ? "#3d1f1f" : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.wifiConnecting ? "..." : (wifiRowItem.modelData.active ? "Disconnect" : "Connect")
                                                color: wifiRowItem.modelData.active ? "#f0736a" : "#000000"
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: !root.wifiConnecting
                                                onClicked: {
                                                    if (wifiRowItem.modelData.active)
                                                        root.wifiDisconnectRequested(wifiRowItem.modelData.ssid);
                                                    else
                                                        root.wifiConnectRequested(wifiRowItem.modelData.ssid, wifiRowItem.modelData.secured);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: wifiRowMouse

                                anchors.fill: parent
                                anchors.bottomMargin: wifiRowItem.expanded ? parent.height - root.wifiRowHeight : 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.wifiRowRequested(wifiRowItem.modelData.ssid)
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !wifiListFlick.visible

                Text {
                    anchors.centerIn: parent
                    text: root.wifiRadioEnabled ? "No networks found" : "Wi-Fi is off"
                    color: root.secondaryText
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Item {
        id: appsContent

        anchors.fill: parent
        opacity: root.appsPanelProgress
        visible: opacity > 0.001
        scale: 0.94 + 0.06 * root.appsPanelProgress
        transformOrigin: Item.Top

        // The dock is only built while it is on screen or morphing. It used
        // to be instantiated for the lifetime of the shell, which put a grid of
        // eight tiles, a search row and a ListView into every relayout the
        // island did — in every mode, on every frame of every animation.
        // appsContentHeight is derived from tokens on root rather than from
        // this subtree, so the surface still sizes itself while this is
        // unloaded.
        Loader {
            anchors.fill: parent
            anchors.margins: root.appsPanelPadding
            active: root.mode === "apps" || root.appsMorph > 0

            sourceComponent: ColumnLayout {
                spacing: root.appsSectionSpacing

                // The three rows below are pinned at every size so the drawer stays the
                // only flexible one — otherwise slack is handed to whichever rows can
                // stretch and the panel gaps open up mid-animation.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.appsHeaderHeight
                    Layout.minimumHeight: root.appsHeaderHeight
                    Layout.maximumHeight: root.appsHeaderHeight
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: root.appsHeaderHeight
                        Layout.preferredHeight: root.appsHeaderHeight
                        radius: 11
                        color: "#090909"
                        border.width: 1
                        border.color: "#232323"

                        MIcon {
                            anchors.centerIn: parent
                            name: "star"
                            size: 15
                            filled: root.favoriteAppCount > 0
                            color: root.favoriteAppCount > 0 ? "#f2c14b" : "#555555"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: "Favorites"
                            color: root.primaryText
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.appsStatusText !== "" ? root.appsStatusText : root.favoriteAppCount + " of " + root.appsFavoriteSlots + " pinned"
                            color: root.appsStatusText !== "" ? "#f0736a" : (root.favoriteAppCount > 0 ? "#c8c8c8" : "#555555")
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: 10
                        color: appsCloseMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                        border.width: 1
                        border.color: "#232323"

                        MIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 12
                            color: "#999999"
                        }

                        MouseArea {
                            id: appsCloseMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appsCloseRequested()
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.appsGridHeight
                    Layout.minimumHeight: root.appsGridHeight
                    Layout.maximumHeight: root.appsGridHeight
                    columns: root.appsGridColumns
                    columnSpacing: root.appsGridSpacing
                    rowSpacing: root.appsGridSpacing

                    Repeater {
                        model: root.favoriteAppEntries

                        delegate: Rectangle {
                            id: appTile

                            required property var modelData
                            required property int index

                            // Tiles stagger in off the shared morph progress, same as the
                            // Wi-Fi rows, so both panels unfold with one rhythm.
                            readonly property real appear: Math.max(0, Math.min(1, (root.appsMorph - appTile.index * 0.035) / 0.6))

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: root.appsTileHeight
                            Layout.maximumHeight: root.appsTileHeight
                            radius: 14
                            color: appTile.modelData.filled ? (appTileMouse.containsMouse ? "#161616" : "#0a0a0a") : (appTileMouse.containsMouse ? "#0e0e0e" : "transparent")
                            border.width: 1
                            border.color: appTile.modelData.filled ? "#232323" : "#191919"
                            opacity: appTile.appear
                            scale: 0.88 + 0.12 * appTile.appear

                            transform: Translate {
                                y: (1 - appTile.appear) * 10
                            }

                            MouseArea {
                                id: appTileMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appTile.modelData.filled)
                                        root.appsLaunchRequested(appTile.modelData.id);
                                    else if (!root.appsPickerOpen)
                                        root.appsPickerToggleRequested();
                                }
                            }

                            // Empty slot: a plus sign marks where an app can go.
                            MIcon {
                                anchors.centerIn: parent
                                name: "add"
                                size: 22
                                color: appTileMouse.containsMouse ? "#8a8a8a" : "#3d3d3d"
                                visible: !appTile.modelData.filled
                            }

                            Image {
                                id: appTileIcon

                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 11
                                width: 26
                                height: 26
                                source: appTile.modelData.filled ? appTile.modelData.iconSource : ""
                                sourceSize.width: 52
                                sourceSize.height: 52
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                visible: appTile.modelData.filled && status === Image.Ready
                            }

                            MIcon {
                                x: appTileIcon.x
                                y: appTileIcon.y
                                width: appTileIcon.width
                                height: appTileIcon.height
                                name: "terminal"
                                size: 22
                                color: "#9c9c9c"
                                visible: appTile.modelData.filled && appTileIcon.status !== Image.Ready
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 5
                                anchors.rightMargin: 5
                                anchors.top: appTileIcon.bottom
                                anchors.topMargin: 5
                                text: appTile.modelData.name
                                color: "#c8c8c8"
                                visible: appTile.modelData.filled
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.family: root.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            // Quick unpin, revealed on hover so the resting grid stays clean.
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 4
                                width: 16
                                height: 16
                                radius: 8
                                color: appTileRemoveMouse.containsMouse ? "#2a1212" : "#151515"
                                border.width: 1
                                border.color: appTileRemoveMouse.containsMouse ? "#5c2020" : "#282828"
                                opacity: appTile.modelData.filled && (appTileMouse.containsMouse || appTileRemoveMouse.containsMouse) ? 1 : 0
                                visible: opacity > 0.001

                                MIcon {
                                    anchors.centerIn: parent
                                    name: "close"
                                    size: 10
                                    color: appTileRemoveMouse.containsMouse ? "#f0736a" : "#9c9c9c"
                                }

                                MouseArea {
                                    id: appTileRemoveMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.appsFavoriteToggleRequested(appTile.modelData.id)
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }

                // Doubles as the drawer handle and, once open, the search field.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.appsPickerToggleHeight
                    Layout.minimumHeight: root.appsPickerToggleHeight
                    Layout.maximumHeight: root.appsPickerToggleHeight
                    radius: 12
                    color: appsPickerToggleMouse.containsMouse && !root.appsPickerOpen ? "#151515" : "#090909"
                    border.width: 1
                    border.color: appsSearchInput.activeFocus ? "#3a3a3a" : "#232323"

                    MouseArea {
                        id: appsPickerToggleMouse

                        anchors.fill: parent
                        enabled: !root.appsPickerOpen
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.appsPickerToggleRequested()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8

                        MIcon {
                            name: root.appsPickerOpen ? "search" : "apps"
                            size: 14
                            color: "#9c9c9c"
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.appsPickerOpen
                            text: "Choose apps"
                            color: "#c8c8c8"
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        TextInput {
                            id: appsSearchInput

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.appsPickerOpen
                            verticalAlignment: Text.AlignVCenter
                            color: root.primaryText
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            clip: true
                            // Deliberately not bound to appsSearchDraft. The first
                            // keystroke would break such a binding anyway, leaving the
                            // field silently detached from the property it looks bound
                            // to. The field owns the text; the draft follows it.
                            onTextChanged: root.appsSearchChanged(text)
                            onAccepted: root.appsSearchAccepted()
                            // Escape closes the drawer, which also drops the keyboard
                            // grab the compositor handed us on click.
                            Keys.onEscapePressed: root.appsPickerToggleRequested()
                            onVisibleChanged: {
                                if (!visible) {
                                    // Release both the text and the focus, so a hidden
                                    // input can never keep hold of the keyboard.
                                    appsSearchInput.text = "";
                                    appsSearchInput.focus = false;
                                    return;
                                }

                                appsSearchInput.text = root.appsSearchDraft;
                                appsSearchInput.forceActiveFocus();
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search apps"
                                color: "#5f5f5f"
                                visible: appsSearchInput.text === ""
                                font.family: root.fontFamily
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: appsPickerChevronMouse.containsMouse ? "#1a1a1a" : "transparent"

                            MIcon {
                                anchors.centerIn: parent
                                name: root.appsPickerOpen ? "expand_less" : "expand_more"
                                size: 16
                                color: "#9c9c9c"
                            }

                            MouseArea {
                                id: appsPickerChevronMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.appsPickerToggleRequested()
                            }
                        }
                    }
                }

                // The drawer. A ListView rather than a Repeater so a few hundred
                // installed apps still scroll without instantiating every row.
                //
                // Visibility keys off the open flag rather than this item's own height:
                // a hidden layout item is assigned height 0, so a height-derived
                // `visible` could never turn itself back on. It is also the only
                // flexible row here, so it absorbs the shortfall while the island is
                // still animating open and the layout is briefly too short.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: root.appsPickerListHeight
                    Layout.maximumHeight: root.appsPickerListHeight
                    visible: root.appsPickerOpen
                    clip: true

                    // A collapsed layout item still holds a real ListView, and cacheBuffer
                    // is measured in pixels beyond the viewport — so a zero-height view was
                    // still building rows, each loading an icon off disk, for a drawer that
                    // had never been opened.
                    Loader {
                        anchors.fill: parent
                        active: root.appsPickerOpen

                        sourceComponent: ListView {
                            id: appsPickerList

                            model: root.appsPickerEntries
                            spacing: root.appsPickerRowSpacing
                            clip: true
                            interactive: contentHeight > height
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: 240

                            delegate: Rectangle {
                                id: appsPickerRow

                                required property var modelData
                                required property int index

                                readonly property bool selected: root.favoriteAppIds.indexOf(appsPickerRow.modelData.id) !== -1

                                width: ListView.view.width
                                height: root.appsPickerRowHeight
                                radius: 12
                                color: appsPickerRowMouse.containsMouse ? "#101010" : (appsPickerRow.selected ? "#0a0a0a" : "transparent")
                                border.width: 1
                                border.color: appsPickerRow.selected ? "#232323" : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Item {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18

                                        Image {
                                            id: appsPickerRowIcon

                                            anchors.fill: parent
                                            source: appsPickerRow.modelData.iconSource
                                            sourceSize.width: 36
                                            sourceSize.height: 36
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            smooth: true
                                            visible: status === Image.Ready
                                        }

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "terminal"
                                            size: 15
                                            color: "#9c9c9c"
                                            visible: appsPickerRowIcon.status !== Image.Ready
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: appsPickerRow.modelData.name
                                        color: appsPickerRow.selected ? root.primaryText : "#c8c8c8"
                                        elide: Text.ElideRight
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        radius: 9
                                        color: appsPickerRow.selected ? "#f0f0f0" : "transparent"
                                        border.width: 1
                                        border.color: appsPickerRow.selected ? "#f0f0f0" : "#2c2c2c"

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 160
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        MIcon {
                                            anchors.centerIn: parent
                                            name: "check"
                                            size: 12
                                            color: "#000000"
                                            visible: appsPickerRow.selected
                                        }
                                    }
                                }

                                MouseArea {
                                    id: appsPickerRowMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.appsFavoriteToggleRequested(appsPickerRow.modelData.id)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No apps match"
                        color: root.secondaryText
                        visible: root.appsPickerEntries.length === 0
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // Volume / brightness HUD. One capsule that fills from the left with the glyph
    // riding inside it, iOS-style: the glyph is drawn twice and the bright copy is
    // clipped to the fill, so it inverts as the level sweeps past it.
    Item {
        id: volumeContent

        anchors.fill: parent
        opacity: root.volumeHudProgress
        visible: opacity > 0.001
        scale: 0.92 + 0.08 * root.volumeHudProgress

        Item {
            id: volumeBar

            anchors.centerIn: parent
            width: Math.max(0, parent.width - 32)
            height: Math.min(26, Math.max(10, parent.height - 16))

            readonly property real glyphLeft: 9
            readonly property real fillWidth: volumeBar.width * root.volumeProgress

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#26ffffff"
            }

            // Dim glyph sits on the empty track; the fill paints straight over it
            // and the bright copy inside the fill takes its place.
            MIcon {
                x: volumeBar.glyphLeft
                anchors.verticalCenter: parent.verticalCenter
                name: root.volumeGlyph
                size: 15
                filled: true
                color: "#8b8b90"
            }

            // Clip container, so the fill keeps the capsule's rounded caps instead
            // of ending in a square edge as it grows.
            Item {
                width: volumeBar.fillWidth
                height: parent.height
                clip: true

                Rectangle {
                    width: volumeBar.width
                    height: volumeBar.height
                    radius: height / 2
                    color: "#fafafa"
                }

                MIcon {
                    x: volumeBar.glyphLeft
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.volumeGlyph
                    size: 15
                    filled: true
                    color: "#0b0b0d"
                }

                // Level changes slide the fill instead of snapping, so holding a
                // volume key reads as one continuous sweep.
                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

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
                id: mediaEqualizer

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

                        // Same reasoning as the collapsed equalizer: these bars are
                        // hidden whenever there is cover art to show, so keying off
                        // the mode alone kept them animating behind the artwork.
                        SequentialAnimation on height {
                            running: mediaEqualizer.visible && root.playing
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
                batteryCharging: root.batteryCharging
                batteryLevel: root.batteryLevel
                statusText: root.dateText
                fontFamily: root.fontFamily
                compact: true
                showBattery: true
                onHandleStyleRequested: style => root.handleStyleRequested(style)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.timeText
                    color: "#f0f0f0"
                    visible: root.timeText !== ""
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: dismissMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                    border.width: 1
                    border.color: "#232323"

                    MIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 12
                        color: "#999999"
                    }

                    MouseArea {
                        id: dismissMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissRequested()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                visible: root.mediaLength > 0

                Text {
                    text: root.formatTime(root.mediaPosition)
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 10
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
                    font.pixelSize: 10
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
                    color: shuffleMouse.containsMouse && root.shuffleSupported ? "#151515" : (root.shuffleActive ? "#202020" : "#090909")
                    border.width: 1
                    border.color: root.shuffleActive ? "#f0f0f0" : (root.shuffleSupported ? "#232323" : "#111111")
                    opacity: root.shuffleSupported ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: "shuffle"
                        size: 14
                        color: root.shuffleActive ? "#ffffff" : root.primaryText
                    }

                    MouseArea {
                        id: shuffleMouse

                        anchors.fill: parent
                        enabled: root.shuffleSupported
                        hoverEnabled: true
                        cursorShape: root.shuffleSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.shuffleRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: previousMouse.containsMouse && root.canGoPrevious ? "#151515" : "#090909"
                    border.width: 1
                    border.color: root.canGoPrevious ? "#232323" : "#111111"
                    opacity: root.canGoPrevious ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: "skip_previous"
                        size: 16
                        color: root.primaryText
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

                    MIcon {
                        anchors.centerIn: parent
                        name: root.playing ? "pause" : "play_arrow"
                        size: 18
                        color: root.primaryText
                        filled: true
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

                    MIcon {
                        anchors.centerIn: parent
                        name: "skip_next"
                        size: 16
                        color: root.primaryText
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

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: loopMouse.containsMouse && root.loopSupported ? "#151515" : (root.loopActive ? "#202020" : "#090909")
                    border.width: 1
                    border.color: root.loopActive ? "#f0f0f0" : (root.loopSupported ? "#232323" : "#111111")
                    opacity: root.loopSupported ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: root.loopStateText === "ONE" ? "repeat_one" : "repeat"
                        size: 14
                        color: root.loopActive ? "#ffffff" : root.primaryText
                    }

                    MouseArea {
                        id: loopMouse

                        anchors.fill: parent
                        enabled: root.loopSupported
                        hoverEnabled: true
                        cursorShape: root.loopSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.loopRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: favoriteMouse.containsMouse ? "#151515" : "#090909"
                    border.width: 1
                    border.color: "#232323"

                    MIcon {
                        anchors.centerIn: parent
                        name: "favorite"
                        size: 14
                        color: root.primaryText
                        filled: false
                    }

                    MouseArea {
                        id: favoriteMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.favoriteRequested()
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