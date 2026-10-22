import QtQuick 2.12

Item {
    id: page
    property var tiles: ({})

    readonly property int maxSamples: 900
    property var series: [
        { key: "speed", label: qsTr("Speed"), color: "#36F08F", values: [] },
        { key: "inclination", label: qsTr("Incline"), color: "#2EC4B6", values: [] },
        { key: "heart", label: qsTr("Heart"), color: "#FF5C7A", values: [] }
    ]

    Connections {
        target: page.tiles.elapsed ? page.tiles.elapsed : null
        // The elapsed tile only ticks while the workout runs, so paused time leaves no flat line
        function onValueChanged() {
            if (page.tiles.elapsed.value === "0:00:00") {
                for (var j = 0; j < page.series.length; j++)
                    page.series[j].values = []
            } else {
                for (var i = 0; i < page.series.length; i++) {
                    var s = page.series[i]
                    var tile = page.tiles[s.key]
                    s.values.push(tile ? parseFloat(tile.value) || 0 : 0)
                    if (s.values.length > page.maxSamples)
                        s.values.shift()
                }
            }
            if (page.visible)
                repeater.repaintAll()
        }
    }

    onVisibleChanged: if (visible) repeater.repaintAll()

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Repeater {
            id: repeater
            model: page.series.length

            function repaintAll() {
                for (var i = 0; i < count; i++)
                    if (itemAt(i))
                        itemAt(i).canvas.requestPaint()
            }

            delegate: Rectangle {
                readonly property var serie: page.series[index]
                property alias canvas: chart
                width: parent.width
                height: (parent.height - 24) / 3
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors { left: parent.left; top: parent.top; margins: 10 }
                    text: serie.label.toUpperCase()
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                Text {
                    anchors { right: parent.right; top: parent.top; margins: 8 }
                    text: page.tiles[serie.key] ? page.tiles[serie.key].value : "-"
                    color: serie.color
                    font.pixelSize: 22
                    font.bold: true
                }

                Canvas {
                    id: chart
                    anchors { fill: parent; topMargin: 36; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var v = serie.values
                        if (v.length < 2)
                            return
                        var lo = Math.min.apply(null, v)
                        var hi = Math.max.apply(null, v)
                        if (hi - lo < 1) { hi += 0.5; lo -= 0.5 }
                        var step = width / (page.maxSamples - 1)
                        var x0 = width - (v.length - 1) * step
                        function y(val) { return height - (val - lo) / (hi - lo) * height }

                        ctx.beginPath()
                        ctx.moveTo(x0, height)
                        for (var i = 0; i < v.length; i++)
                            ctx.lineTo(x0 + i * step, y(v[i]))
                        ctx.lineTo(width, height)
                        ctx.closePath()
                        ctx.globalAlpha = 0.18
                        ctx.fillStyle = serie.color
                        ctx.fill()

                        ctx.globalAlpha = 1
                        ctx.beginPath()
                        ctx.moveTo(x0, y(v[0]))
                        for (var k = 1; k < v.length; k++)
                            ctx.lineTo(x0 + k * step, y(v[k]))
                        ctx.lineWidth = 2.5
                        ctx.strokeStyle = serie.color
                        ctx.stroke()
                    }
                }
            }
        }
    }
}
