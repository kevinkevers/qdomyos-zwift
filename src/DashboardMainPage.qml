import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.3

Item {
    id: page
    property var tiles: ({})
    property color accent: "#7C5CFF"
    signal plusClicked(string name)
    signal minusClicked(string name)

    readonly property bool landscape: width >= height

    GridLayout {
        anchors.fill: parent
        anchors.margins: 16
        columns: page.landscape ? 2 : 1
        rowSpacing: 12
        columnSpacing: 12

        ColumnLayout {
            Layout.fillWidth: !page.landscape
            Layout.fillHeight: page.landscape
            Layout.preferredWidth: page.landscape ? (page.width - 44) * 0.58 : -1
            Layout.preferredHeight: page.landscape ? -1 : (page.height - 44) * 0.5
            spacing: 12

            DashboardMetric {
                id: speedCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                tile: page.tiles.speed
                accent: page.accent
                valueScale: 0.5
                readonly property real bigButtonSize: Math.min(width * 0.2, height * 0.45, 140)
                valueSideInset: bigButtonSize + 16

                Repeater {
                    model: [{ text: "−", name: "speed_minus", left: true }, { text: "+", name: "speed_plus", left: false }]
                    delegate: RoundButton {
                        anchors.verticalCenter: parent.verticalCenter
                        x: modelData.left ? 16 : speedCard.width - width - 16
                        width: speedCard.bigButtonSize
                        height: speedCard.bigButtonSize
                        text: modelData.text
                        font.pixelSize: width * 0.5
                        font.bold: true
                        autoRepeat: true
                        Material.foreground: "white"
                        background: Rectangle {
                            radius: width / 2
                            color: parent.down ? page.accent : Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.25)
                            border.width: 2
                            border.color: page.accent
                        }
                        onClicked: modelData.left ? page.minusClicked(modelData.name) : page.plusClicked(modelData.name)

                        Accessible.name: modelData.left ? qsTr("Decrease speed") : qsTr("Increase speed")
                    }
                }

                Row {
                    anchors { right: parent.right; top: parent.top; margins: 12 }
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("FAN") + "  " + (page.tiles.fan ? page.tiles.fan.value : "-")
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 15
                        font.bold: true
                    }
                    RoundButton {
                        text: "−"
                        width: 34; height: 34
                        flat: true
                        autoRepeat: true
                        onClicked: page.minusClicked("fan_minus")
                    }
                    RoundButton {
                        text: "+"
                        width: 34; height: 34
                        flat: true
                        autoRepeat: true
                        onClicked: page.plusClicked("fan_plus")
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(72, page.height * 0.13)
                spacing: 8

                Repeater {
                    model: [10, 11, 12, 13, 14, 15, 16, 17, 18]
                    delegate: Button {
                        readonly property bool current: page.tiles.speed
                                                        && Math.abs(parseFloat(page.tiles.speed.value) - modelData) < 0.05
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData
                        font.pixelSize: Math.min(height * 0.42, 26)
                        font.bold: true
                        Material.foreground: "white"
                        background: Rectangle {
                            radius: 12
                            color: parent.down || parent.current ? page.accent : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(page.accent.r, page.accent.g, page.accent.b, 0.6)
                        }
                        onClicked: rootItem.setTreadmillSpeed(modelData)

                        Accessible.name: qsTr("Speed %1").arg(modelData)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            DashboardMetric {
                Layout.fillWidth: true
                Layout.fillHeight: true
                tile: page.tiles.elapsed
                accent: page.accent
            }
            DashboardMetric {
                Layout.fillWidth: true
                Layout.fillHeight: true
                tile: page.tiles.heart
                accent: page.accent
            }
            RowLayout {
                id: distanceRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                DashboardMetric {
                    Layout.fillHeight: true
                    Layout.preferredWidth: (distanceRow.width - distanceRow.spacing) * 2 / 3
                    tile: page.tiles.odometer
                    label: tile ? tile.name.replace("Odometer", qsTr("Distance")) : ""
                    accent: page.accent
                }
                DashboardMetric {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tile: page.tiles.elevation
                    accent: page.accent
                    valueScale: 0.3
                }
            }
        }
    }
}
