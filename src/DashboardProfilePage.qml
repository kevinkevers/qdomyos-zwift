import QtQuick 2.12

Item {
    id: page
    property var tiles: ({})
    property color accent: "#7C5CFF"

    property var steps: []
    property int elapsedSeconds: 0
    readonly property int totalSeconds: {
        var t = 0
        for (var i = 0; i < steps.length; i++)
            t += steps[i].seconds
        return t
    }

    function refresh() {
        if (typeof rootItem === "undefined" || !rootItem)
            return
        steps = rootItem.trainProgramProfile()
        elapsedSeconds = rootItem.trainProgramElapsedSeconds()
        profile.requestPaint()
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.visible
        triggeredOnStart: true
        onTriggered: page.refresh()
    }

    Text {
        anchors.centerIn: parent
        visible: page.totalSeconds === 0
        text: qsTr("No workout loaded")
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 22
    }

    Row {
        id: header
        visible: page.totalSeconds > 0
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 32

        Repeater {
            model: [
                { label: qsTr("Next step in"), tile: "remainingtimetrainprogramrow" },
                { label: qsTr("Target speed"), tile: "target_speed" },
                { label: qsTr("Target incline"), tile: "target_inclination" }
            ]
            delegate: Column {
                Text {
                    text: modelData.label.toUpperCase()
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                Text {
                    text: page.tiles[modelData.tile] ? page.tiles[modelData.tile].value : "-"
                    color: "white"
                    font.pixelSize: 30
                    font.bold: true
                }
            }
        }
    }

    Canvas {
        id: profile
        visible: page.totalSeconds > 0
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 16 }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (page.totalSeconds === 0)
                return
            var maxSpeed = 1
            var minIncline = 0
            var maxIncline = 1
            for (var i = 0; i < page.steps.length; i++) {
                maxSpeed = Math.max(maxSpeed, page.steps[i].speed)
                if (page.steps[i].inclination > -100) {
                    minIncline = Math.min(minIncline, page.steps[i].inclination)
                    maxIncline = Math.max(maxIncline, page.steps[i].inclination)
                }
            }
            var scale = width / page.totalSeconds
            var x = 0
            var doneColor = "rgba(" + Math.round(page.accent.r * 255) + ", " + Math.round(page.accent.g * 255) + ", "
                    + Math.round(page.accent.b * 255) + ", 0.35)"
            ctx.beginPath()
            for (var j = 0; j < page.steps.length; j++) {
                var s = page.steps[j]
                var w = s.seconds * scale
                var done = x + w <= page.elapsedSeconds * scale
                var h = s.speed > 0 ? s.speed / maxSpeed * height * 0.9 : 4
                ctx.fillStyle = done ? doneColor : page.accent
                ctx.fillRect(x + 1, height - h, Math.max(1, w - 2), h)
                var inc = s.inclination > -100 ? s.inclination : 0
                var iy = height - (inc - minIncline) / (maxIncline - minIncline) * height * 0.9
                if (j === 0)
                    ctx.moveTo(x, iy)
                else
                    ctx.lineTo(x, iy)
                ctx.lineTo(x + w, iy)
                x += w
            }
            ctx.lineWidth = 3
            ctx.strokeStyle = "#2EC4B6"
            ctx.stroke()

            var cx = page.elapsedSeconds * scale
            ctx.fillStyle = "white"
            ctx.fillRect(cx - 1.5, 0, 3, height)
        }
    }
}
