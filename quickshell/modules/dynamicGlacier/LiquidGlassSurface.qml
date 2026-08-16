import QtQuick

Canvas {
    id: root

    property bool active: false
    property real bottomRadius: 8
    property color fallbackColor: "#000000"
    property real glassAmount: active ? 1 : 0

    antialiasing: true

    function traceBody(context, inset) {
        const left = inset;
        const top = inset;
        const right = Math.max(left, width - inset);
        const bottom = Math.max(top, height - inset);
        const radius = Math.max(0, Math.min(root.bottomRadius - inset,
                                            (right - left) / 2,
                                            (bottom - top) / 2));

        context.beginPath();
        context.moveTo(left, top);
        context.lineTo(right, top);
        context.lineTo(right, bottom - radius);
        context.quadraticCurveTo(right, bottom, right - radius, bottom);
        context.lineTo(left + radius, bottom);
        context.quadraticCurveTo(left, bottom, left, bottom - radius);
        context.closePath();
    }

    function traceLowerEdge(context, inset) {
        const left = inset;
        const top = inset;
        const right = Math.max(left, width - inset);
        const bottom = Math.max(top, height - inset);
        const radius = Math.max(0, Math.min(root.bottomRadius - inset,
                                            (right - left) / 2,
                                            (bottom - top) / 2));

        context.beginPath();
        context.moveTo(left, top);
        context.lineTo(left, bottom - radius);
        context.quadraticCurveTo(left, bottom, left + radius, bottom);
        context.lineTo(right - radius, bottom);
        context.quadraticCurveTo(right, bottom, right, bottom - radius);
        context.lineTo(right, top);
    }

    function paintFallback(context) {
        if (root.glassAmount >= 0.999)
            return;

        context.save();
        root.traceBody(context, 0);
        context.globalAlpha = 1 - root.glassAmount;
        context.fillStyle = root.fallbackColor;
        context.fill();
        context.restore();
    }

    function paintGlass(context) {
        if (root.glassAmount <= 0.001)
            return;

        context.save();
        root.traceBody(context, 0);
        context.clip();
        context.globalAlpha = root.glassAmount;

        // The pane stays mostly opaque. Its only variation is neutral alpha:
        // Hyprland supplies the pixels and blur underneath this surface.
        const body = context.createLinearGradient(0, 0, width, height);
        body.addColorStop(0, "rgba(5, 5, 6, 0.88)");
        body.addColorStop(0.48, "rgba(3, 3, 4, 0.84)");
        body.addColorStop(1, "rgba(7, 7, 8, 0.87)");
        context.fillStyle = body;
        context.fillRect(0, 0, width, height);

        // Remove alpha from a broad inner edge. With Hyprland's ignore-alpha
        // threshold this exposes a sharper copy of the real background beside
        // the blurred centre, which reads as a curved, thicker rim.
        context.globalCompositeOperation = "destination-out";
        root.traceLowerEdge(context, 3.1);
        context.lineWidth = 6.2;
        context.strokeStyle = "rgba(0, 0, 0, 0.22)";
        context.stroke();

        // A second, narrow cut keeps the transition visible on dark wallpaper
        // without making the whole island transparent.
        root.traceLowerEdge(context, 1.25);
        context.lineWidth = 1.7;
        context.strokeStyle = "rgba(0, 0, 0, 0.12)";
        context.stroke();

        context.globalCompositeOperation = "source-over";

        // Neutral Fresnel reflections only outline the places where a curved
        // surface would catch light. There is deliberately no coloured tint.
        root.traceLowerEdge(context, 0.7);
        context.lineWidth = 1.1;
        const rim = context.createLinearGradient(0, 0, width, height);
        rim.addColorStop(0, "rgba(255, 255, 255, 0.38)");
        rim.addColorStop(0.32, "rgba(255, 255, 255, 0.10)");
        rim.addColorStop(0.68, "rgba(255, 255, 255, 0.025)");
        rim.addColorStop(1, "rgba(255, 255, 255, 0.18)");
        context.strokeStyle = rim;
        context.stroke();

        root.traceLowerEdge(context, 4.6);
        context.lineWidth = 1.0;
        const depth = context.createLinearGradient(0, 0, width, height);
        depth.addColorStop(0, "rgba(255, 255, 255, 0.07)");
        depth.addColorStop(0.55, "rgba(0, 0, 0, 0.03)");
        depth.addColorStop(1, "rgba(0, 0, 0, 0.32)");
        context.strokeStyle = depth;
        context.stroke();

        context.restore();
    }

    onPaint: {
        const context = getContext("2d");

        context.reset();
        context.clearRect(0, 0, width, height);
        root.paintFallback(context);
        root.paintGlass(context);
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onBottomRadiusChanged: requestPaint()
    onFallbackColorChanged: requestPaint()
    onGlassAmountChanged: requestPaint()

    Behavior on glassAmount {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
}
