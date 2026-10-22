import QtQuick 2.12

Item {
    id: page
    property var tiles: ({})
    property color accent: "#36F08F"
    property bool miles: false

    readonly property real lapMeters: 400
    readonly property real odometerValue: tiles.odometer ? parseFloat(tiles.odometer.value) || 0 : 0
    readonly property real meters: odometerValue * (miles ? 1609.344 : 1000)
    readonly property int laps: Math.floor(meters / lapMeters)
    readonly property real lapProgress: (meters % lapMeters) / lapMeters

    onLapProgressChanged: track.requestPaint()
    onAccentChanged: track.requestPaint()

    Canvas {
        id: track
        anchors.fill: parent
        anchors.margins: 24
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        // Stadium shape: two straights joined by half circles, the runner starts at the bottom of the
        // left end of the lower straight and runs counter-clockwise like on a real track
        function pointAt(progress, cx, cy, straight, r) {
            var curve = Math.PI * r
            var total = 2 * straight + 2 * curve
            var d = progress * total
            if (d < straight)
                return { x: cx - straight / 2 + d, y: cy + r }
            d -= straight
            if (d < curve) {
                var a = Math.PI / 2 - d / r
                return { x: cx + straight / 2 + r * Math.cos(a), y: cy + r * Math.sin(a) }
            }
            d -= curve
            if (d < straight)
                return { x: cx + straight / 2 - d, y: cy - r }
            d -= straight
            var b = -Math.PI / 2 - d / r
            return { x: cx - straight / 2 + r * Math.cos(b), y: cy + r * Math.sin(b) }
        }

        function stadium(ctx, cx, cy, straight, r) {
            ctx.beginPath()
            ctx.moveTo(cx - straight / 2, cy + r)
            ctx.lineTo(cx + straight / 2, cy + r)
            ctx.arc(cx + straight / 2, cy, r, Math.PI / 2, -Math.PI / 2, true)
            ctx.lineTo(cx - straight / 2, cy - r)
            ctx.arc(cx - straight / 2, cy, r, -Math.PI / 2, Math.PI / 2, true)
            ctx.closePath()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var lane = Math.min(width, height) * 0.09
            var r = Math.min(height / 2 - lane, width / 4)
            var straight = Math.max(0, width - 2 * r - 2 * lane)
            var cx = width / 2
            var cy = height / 2

            ctx.lineWidth = lane
            ctx.strokeStyle = "#B4492F"
            stadium(ctx, cx, cy, straight, r)
            ctx.stroke()

            ctx.lineWidth = 1.5
            ctx.strokeStyle = "rgba(255, 255, 255, 0.35)"
            stadium(ctx, cx, cy, straight, r - lane / 2)
            ctx.stroke()
            stadium(ctx, cx, cy, straight, r + lane / 2)
            ctx.stroke()

            ctx.lineWidth = 3
            ctx.strokeStyle = "white"
            ctx.beginPath()
            ctx.moveTo(cx - straight / 2, cy + r - lane / 2)
            ctx.lineTo(cx - straight / 2, cy + r + lane / 2)
            ctx.stroke()

            ctx.fillStyle = "rgba(50, 140, 75, 0.35)"
            stadium(ctx, cx, cy, straight, r - lane / 2 - 2)
            ctx.fill()

            var p = pointAt(page.lapProgress, cx, cy, straight, r)
            ctx.fillStyle = page.accent
            ctx.beginPath()
            ctx.arc(p.x, p.y, lane * 0.45, 0, 2 * Math.PI)
            ctx.fill()
            ctx.lineWidth = 3
            ctx.strokeStyle = "white"
            ctx.stroke()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("LAP %1").arg(page.laps + 1)
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: Math.max(14, page.height * 0.05)
            font.bold: true
            font.letterSpacing: 2
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(page.meters % page.lapMeters) + " / " + page.lapMeters + " m"
            color: "white"
            font.pixelSize: Math.max(20, page.height * 0.1)
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (page.tiles.odometer ? page.tiles.odometer.value : "0") + (page.miles ? " mi" : " km")
                  + "   ·   " + (page.tiles.speed ? page.tiles.speed.value : "0") + (page.miles ? " mph" : " km/h")
            color: Qt.rgba(1, 1, 1, 0.75)
            font.pixelSize: Math.max(14, page.height * 0.05)
        }
    }
}
