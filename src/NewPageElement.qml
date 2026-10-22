import QtQuick 2.7
import QtQuick.Layouts 1.3

ColumnLayout {
    id: rootElement
    property bool isOpen: false
    property string title: ""
    property alias color: accordionHeader.color
    property alias textColor: accordionText.color
    property alias textFont: accordionText.font.family
    property alias textFontSize: accordionText.font.pixelSize
    property alias indicatRectColor: indicatRect.color
    property string accordionContent: ""
    spacing: 0

    Layout.fillWidth: true;

    Rectangle {
        id: accordionHeader
        color: "red"
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true;
        height: 56

        Accessible.role: Accessible.Button 
        Accessible.name: title 
        Accessible.description: expanded ? "Expanded" : "Collapsed"
        Accessible.onPressAction: toggle()

        Rectangle {
            id: indicatRect
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 4; height: 20
            radius: 2
            color: "white"
        }

        Text {
            id: accordionText
            x: 32
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - 56
            elide: Text.ElideRight
            color: "#FFFFFF"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            text: rootElement.title
        }

        Text {
            id: indicatImg
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "\u203A"
            color: "#8A94A6"
            font.pixelSize: 28
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                stackView.push(accordionContent)
            }
        }
    }
}
