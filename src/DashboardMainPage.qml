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

        DashboardMetric {
            id: speedCard
            Layout.fillWidth: !page.landscape
            Layout.fillHeight: page.landscape
            Layout.preferredWidth: page.landscape ? (page.width - 44) * 0.58 : -1
            Layout.preferredHeight: page.landscape ? -1 : (page.height - 44) * 0.4
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
                tile: page.tiles.datetime
                accent: page.accent
            }
            DashboardMetric {
                Layout.fillWidth: true
                Layout.fillHeight: true
                tile: page.tiles.elevation
                accent: page.accent
            }
        }
    }
}
