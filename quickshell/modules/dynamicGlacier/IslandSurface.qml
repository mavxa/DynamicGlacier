import QtQuick
import QtQuick.Layouts

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
    property bool volumeIndicatorVisible: false
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
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: "Noto Sans"
    readonly property bool expanded: mode !== "idle" || forceExpanded
    readonly property real bottomRadius: Math.max(1, Math.min(height / 2, expanded ? Math.min(height * 0.28, 24) : Math.min(height * 0.42, 8)))
    readonly property color surfaceColor: !expanded && handleStyle === "strip" ? "#0c0c0c" : "#000000"

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal shuffleRequested
    signal loopRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)

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

        Canvas {
            id: volumeTrace

            z: 8
            anchors.fill: parent
            opacity: root.volumeIndicatorVisible ? 1 : 0

            function perimeterPoints() {
                const inset = Math.max(1.5, Math.min(4, height * 0.22, width * 0.08));
                const left = inset;
                const right = Math.max(left + 1, width - inset);
                const openTop = Math.min(height - inset - 1, Math.max(inset + 1, height * 0.18));
                const bottom = Math.max(openTop + 1, height - inset);
                const radius = Math.max(0, Math.min(root.bottomRadius - inset, (right - left) / 2));
                const arcSteps = 10;
                const points = [
                    {
                        x: left,
                        y: openTop
                    },
                    {
                        x: left,
                        y: bottom - radius
                    }
                ];

                for (let i = 0; i <= arcSteps; i += 1) {
                    const angle = Math.PI - i / arcSteps * Math.PI / 2;
                    points.push({
                        x: left + radius + Math.cos(angle) * radius,
                        y: bottom - radius + Math.sin(angle) * radius
                    });
                }

                points.push({
                    x: right - radius,
                    y: bottom
                });

                for (let i = 0; i <= arcSteps; i += 1) {
                    const angle = Math.PI / 2 - i / arcSteps * Math.PI / 2;
                    points.push({
                        x: right - radius + Math.cos(angle) * radius,
                        y: bottom - radius + Math.sin(angle) * radius
                    });
                }

                points.push({
                    x: right,
                    y: openTop
                });
                return points;
            }

            function distance(a, b) {
                const dx = b.x - a.x;
                const dy = b.y - a.y;

                return Math.sqrt(dx * dx + dy * dy);
            }

            function tracePath(ctx, progress) {
                const points = perimeterPoints();
                let total = 0;

                for (let i = 1; i < points.length; i += 1)
                    total += distance(points[i - 1], points[i]);

                ctx.beginPath();
                ctx.moveTo(points[0].x, points[0].y);

                if (total <= 0 || progress <= 0)
                    return;

                const target = total * Math.max(0, Math.min(1, progress));
                let walked = 0;

                for (let i = 1; i < points.length; i += 1) {
                    const previous = points[i - 1];
                    const current = points[i];
                    const segment = distance(previous, current);

                    if (walked + segment >= target) {
                        const t = segment === 0 ? 0 : (target - walked) / segment;

                        ctx.lineTo(previous.x + (current.x - previous.x) * t, previous.y + (current.y - previous.y) * t);
                        return;
                    }

                    ctx.lineTo(current.x, current.y);
                    walked += segment;
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                const progress = root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100));

                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                ctx.strokeStyle = "rgba(190, 190, 190, 0.22)";
                tracePath(ctx, 1);
                ctx.stroke();

                if (progress > 0) {
                    ctx.strokeStyle = "rgba(245, 245, 245, 0.92)";
                    tracePath(ctx, progress);
                    ctx.stroke();
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: requestPaint()
            Connections {
                target: root

                function onVolumeChanged() {
                    volumeTrace.requestPaint();
                }

                function onMutedChanged() {
                    volumeTrace.requestPaint();
                }

                function onVolumeIndicatorVisibleChanged() {
                    volumeTrace.requestPaint();
                }
            }
        }

        IslandContent {
            z: 10
            anchors.fill: parent
            anchors.margins: root.expanded ? (root.mode === "media" ? 10 : 12) : 0
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
            timeText: root.timeText
            dateText: root.dateText
            onPreviousRequested: root.previousRequested()
            onPlayPauseRequested: root.playPauseRequested()
            onNextRequested: root.nextRequested()
            onShuffleRequested: root.shuffleRequested()
            onLoopRequested: root.loopRequested()
            onSeekRequested: position => root.seekRequested(position)
            onHandleStyleRequested: style => root.handleStyleRequested(style)
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
