import QtQuick 2.12

Rectangle {
    id: card
    property var tile
    property string label: tile ? tile.name : ""
    property string value: tile ? tile.value : "-"
    property string caption: tile ? tile.secondLine : ""
    property color valueColor: tile && tile.valueFontColor !== "" ? tile.valueFontColor : "white"
    property real valueScale: 0.42
    property color accent: "#7C5CFF"
    property real valueSideInset: 0

    radius: 18
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.35)

    Text {
        id: labelText
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        text: card.label
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: Math.max(12, card.height * 0.08)
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.5
        elide: Text.ElideRight
    }

    Text {
        anchors { left: parent.left; right: parent.right; top: labelText.bottom; bottom: captionText.top; margins: 8 }
        anchors.leftMargin: 8 + card.valueSideInset
        anchors.rightMargin: 8 + card.valueSideInset
        text: card.value
        color: card.valueColor
        font.pixelSize: card.height * card.valueScale
        font.bold: true
        font.letterSpacing: -1
        fontSizeMode: Text.Fit
        minimumPixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: captionText
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
        height: text === "" ? 0 : implicitHeight
        text: card.caption
        color: Qt.rgba(1, 1, 1, 0.55)
        font.pixelSize: Math.max(11, card.height * 0.07)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
