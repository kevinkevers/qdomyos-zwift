import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

Page {

    title: qsTr("QZ Fitness")
    id: page

    // VoiceOver accessibility - ignore Page itself, only children are accessible
    Accessible.ignored: true

    property alias start: start
    property alias stop: stop
    property alias lap: lap
    property alias row: row
    // Search for the equipment ("Next search in 12 s"), set by Home.qml while no device is connected
    property string searchStatus: ""

    Settings {
	     id: settings
		  property real ui_zoom: 100.0
		  property bool theme_tile_icon_enabled: true
		  property string theme_background_color: "#0E1116"
		}

    property alias bottomBar: bottomBar
    // Speed and incline steppers in the bottom bar, wired to the tile signals by Home.qml
    property alias speedMinus: speedMinus
    property alias speedPlus: speedPlus
    property alias inclineMinus: inclineMinus
    property alias inclinePlus: inclinePlus
    property var dashboardTiles: ({})

    Label {
        id: lblHelp
        z: 10
        width: parent.width
        padding: window.contentSideMargin
        anchors.top: parent.top
        background: Rectangle { color: settings.theme_background_color; opacity: 0.95 }
        text: qsTr("This app should automatically connect to your bike/treadmill/rower. <b>If it doesn't, please check</b>:<br>1) your Echelon/Domyos App MUST be closed while qdomyos-zwift is running;<br>2) both Bluetooth and Bluetooth permissions MUST be enabled<br>3) your bike/treadmill/rower should be turned on BEFORE starting this app<br>4) try to restart your device<br><br>If your bike/treadmill disconnects every 30 seconds try to disable the 'virtual device' setting on the left bar.<br><br>In case of issues, please feel free to contact me at roberto.viola83@gmail.com.<br><br><b>Have a nice ride!</b><br/ ><i>QZ specifically disclaims liability for<br>incidental or consequential damages and assumes<br>no responsibility or liability for any loss<br>or damage suffered by any person as a result of<br>the use or misuse of the app.</i><br><br>Roberto Viola")
        wrapMode: Label.WordWrap
        visible: rootItem.labelHelp
    }

    Rectangle {
        id: bottomBar
        z: 5
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: window.lockTiles ? 0 : 64
        visible: !window.lockTiles
        color: Qt.darker(settings.theme_background_color, 1.25)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        Row {
            id: statusRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // The carousel takes the swipe from the left edge that used to open the menu
            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                text: "☰"
                font.pixelSize: 22
                Material.background: "#171B22"
                Material.foreground: "white"
                onClicked: drawer.open()

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Menu")
                Accessible.focusable: true
            }

            Item {
                width: 30
                height: 30
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: treadmill_connection
                    anchors.fill: parent
                    source: "icons/icons/bluetooth-icon.png"
                    enabled: rootItem.device
                    smooth: true
                    mipmap: true

                    Accessible.role: Accessible.Indicator
                    Accessible.name: qsTr("Bluetooth connection")
                    Accessible.description: rootItem.device ? qsTr("Device connected") : qsTr("Device not connected")
                    Accessible.focusable: true
                }
                ColorOverlay {
                    anchors.fill: treadmill_connection
                    source: treadmill_connection
                    color: treadmill_connection.enabled ? "#00000000" : "#B0D3d3d3"
                }
                // No device yet: a tap searches right away instead of waiting for the next search
                // (with a device connected bluetoothSearchNow() does nothing)
                MouseArea {
                    anchors.fill: parent
                    onClicked: rootItem.bluetoothSearchNow()
                }
            }
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                source: rootItem.signal
                smooth: true
                Accessible.ignored: true
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, bottomBar.width / 2 - row.width / 2 - 126)
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: Qt.rgba(1, 1, 1, 0.6)
                text: page.searchStatus !== "" ? page.searchStatus : rootItem.info
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            height: 48
            spacing: 8

            RoundButton {
                id: start
                height: parent.height
                width: 110
                icon.source: rootItem.startIcon
                icon.width: 22
                icon.height: 22
                text: rootItem.startText
                font.bold: true
                Material.background: rootItem.startColor === "red" ? "#C0392B" : "#171B22"
                Material.foreground: "white"

                Accessible.role: Accessible.Button
                Accessible.name: rootItem.startText
                Accessible.description: qsTr("Start workout")
                Accessible.focusable: true
            }
            RoundButton {
                id: stop
                height: parent.height
                width: 110
                icon.source: rootItem.stopIcon
                icon.width: 22
                icon.height: 22
                text: rootItem.stopText
                font.bold: true
                Material.background: rootItem.stopColor === "red" ? "#C0392B" : "#171B22"
                Material.foreground: "white"

                Accessible.role: Accessible.Button
                Accessible.name: rootItem.stopText
                Accessible.description: qsTr("Stop workout")
                Accessible.focusable: true
            }
            RoundButton {
                id: lap
                height: parent.height
                width: parent.height
                icon.source: "icons/icons/lap.png"
                icon.width: 24
                icon.height: 24
                enabled: rootItem.lap
                Material.background: "#171B22"

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Lap")
                Accessible.description: qsTr("Record a new lap")
                Accessible.focusable: true
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            RoundButton { id: speedMinus; text: "−"; width: 44; height: 44; autoRepeat: true; font.bold: true }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 15
                text: (page.dashboardTiles.speed ? page.dashboardTiles.speed.value : "-") + "\n" + qsTr("speed")
            }
            RoundButton { id: speedPlus; text: "+"; width: 44; height: 44; autoRepeat: true; font.bold: true }
            Item { width: 12; height: 1 }
            RoundButton { id: inclineMinus; text: "−"; width: 44; height: 44; autoRepeat: true; font.bold: true }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 15
                text: (page.dashboardTiles.inclination ? page.dashboardTiles.inclination.value : "-") + "\n" + qsTr("incline")
            }
            RoundButton { id: inclinePlus; text: "+"; width: 44; height: 44; autoRepeat: true; font.bold: true }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;formeditorZoom:0.6600000262260437;height:480;width:640}
}
##^##*/

