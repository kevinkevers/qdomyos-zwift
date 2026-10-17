import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0
import Qt.labs.platform 1.1
import QtMultimedia 5.15

HomeForm {
    objectName: "home"
    background: Rectangle {
        anchors.fill: parent
        width: parent.fill
        height: parent.fill
        color: settings.theme_background_color

        // VoiceOver accessibility - ignore decorative background
        Accessible.role: Accessible.Pane
        Accessible.ignored: true
    }
    signal start_clicked;
    signal stop_clicked;
    signal lap_clicked;
    signal peloton_start_workout;
    signal peloton_abort_workout;
    signal plus_clicked(string name)
    signal minus_clicked(string name)
    signal largeButton_clicked(string name)

    Settings {
        id: settings
        property real ui_zoom: 100.0
        property bool theme_tile_icon_enabled: true
        property string theme_tile_background_color: "#171B22"
        property string theme_background_color: "#0E1116"
        property bool theme_tile_shadow_enabled: true
        property string theme_tile_shadow_color: "#7C5CFF"
        property int theme_tile_secondline_textsize: 12
        property bool skipLocationServicesDialog: false
        property bool trainprogram_sound_on_segment: false
        property int dashboard_page: 0
    }

    SoundEffect {
        id: trainingProgramSegmentSound
        source: "qrc:/sounds/training-program-segment.wav"
        volume: 0.9
    }

    Connections {
        target: rootItem
        onTrainingProgramIntervalSoundRequested: trainingProgramSegmentSound.play()
    }

    MessageDialog {
        id: messagePelotonAskStart
        text: qsTr("Peloton Workout in progress")
        informativeText: qsTr("Do you want to follow the resistance? ") + rootItem.pelotonProvider
        buttons: (MessageDialog.Yes | MessageDialog.No)
        onYesClicked: {rootItem.pelotonAskStart = false; peloton_start_workout();}
        onNoClicked: {rootItem.pelotonAskStart = false; peloton_abort_workout();}
        visible: rootItem.pelotonAskStart
    }

    Popup {
        id: popupLap
         parent: Overlay.overlay

         x: Math.round((parent.width - width) / 2)
         y: Math.round((parent.height - height) / 2)
         width: 380
         height: 60
         modal: true
         focus: true
         palette.text: "white"
         closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
         enter: Transition
         {
             NumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
         }
         exit: Transition
         {
             NumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
         }
         Column {
             anchors.horizontalCenter: parent.horizontalCenter
         Label {
             anchors.horizontalCenter: parent.horizontalCenter
             text: qsTr("New lap started!")
            }
        }
    }

    MessageDialog {
        id: stopConfirmationDialog
        text: qsTr("Stop Workout")
        informativeText: qsTr("Do you really want to stop the current workout?")
        buttons: (MessageDialog.Yes | MessageDialog.No)
        onYesClicked: {
            close();
            inner_stop();
        }
        onNoClicked: close()
    }

    // Optional post-workout popup (settings.rpe_feel_popup_enabled) asking for perceived exertion
    // and how the user felt. Saving the FIT file (rootItem.finalizeFitSave) is suspended until this
    // popup is answered, so the values can be embedded in the FIT file before it's written/uploaded.
    Popup {
        id: rpeFeelPopup
        parent: Overlay.overlay

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 420
        height: 340
        modal: true
        focus: true
        palette.text: "white"
        closePolicy: Popup.NoAutoClose

        property int selectedRpe: 5
        property int selectedFeel: 50
        readonly property var rpeLabels: [
            qsTr("Rest"), qsTr("Very Light"), qsTr("Light"), qsTr("Moderate"),
            qsTr("Somewhat Hard"), qsTr("Hard"), qsTr("Harder"), qsTr("Very Hard"),
            qsTr("Very Very Hard"), qsTr("Extremely Hard"), qsTr("Maximum Effort")
        ]

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Label {
                text: qsTr("How was this workout?")
                font.bold: true
                font.pixelSize: 18
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Label {
                text: qsTr("Perceived Exertion (RPE): ") + rpeFeelPopup.selectedRpe + " - " + rpeFeelPopup.rpeLabels[rpeFeelPopup.selectedRpe]
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Slider {
                id: rpeSlider
                width: parent.width
                from: 0
                to: 10
                stepSize: 1
                value: rpeFeelPopup.selectedRpe
                onValueChanged: rpeFeelPopup.selectedRpe = value
            }

            Label {
                text: qsTr("How did you feel?")
                width: parent.width
                wrapMode: Text.WordWrap
            }

            UiComboBox {
                id: feelCombo
                width: parent.width
                model: [qsTr("Very Bad"), qsTr("Bad"), qsTr("OK"), qsTr("Good"), qsTr("Very Good")]
                currentIndex: 2
                onCurrentIndexChanged: rpeFeelPopup.selectedFeel = currentIndex * 25
            }

            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: qsTr("Skip")
                    onClicked: {
                        rpeFeelPopup.close();
                        rootItem.finalizeFitSave(-1, -1);
                        finish_stop();
                    }
                }

                Button {
                    text: qsTr("Save")
                    highlighted: true
                    onClicked: {
                        rpeFeelPopup.close();
                        rootItem.finalizeFitSave(rpeFeelPopup.selectedRpe, rpeFeelPopup.selectedFeel);
                        finish_stop();
                    }
                }
            }
        }
    }

    Timer {
        id: popupLapAutoClose
        interval: 2000; running: false; repeat: false
        onTriggered: popupLap.close();
    }

    Timer {
        id: searchStatusTimer
        // Always running: rootItem.device blinks while no device is connected (it drives the icon),
        // and bluetoothSearchStatus() is empty once a device is connected
        interval: 1000; repeat: true; triggeredOnStart: true; running: true
        onTriggered: searchStatus = rootItem.bluetoothSearchStatus()
    }

    Timer {
        id: checkStartStopFromWeb
        interval: 200; running: true; repeat: true
        onTriggered: {if(rootItem.stopRequested) {rootItem.stopRequested = false; inner_stop(); }}
    }

    property bool locationServiceRequsted: false
    // Bluetooth and Location as Android reports them now, not only at app start: switched on from
    // the quick settings, the questions about them go away.
    // Home.qml is created before homeform sets rootItem: until then assume "on", so the question
    // doesn't flash at start; setting rootItem re-evaluates the binding with the real value
    property bool locationServicesOn: typeof rootItem === "undefined" || rootItem.locationServices()
    // "No" answered: not asked again until the next start
    property bool locationServicesDeclined: false

    Timer {
        interval: 2000; repeat: true
        // only while a question about them is open: devices without GPS never report Location on
        running: !locationServicesOn && (locationServicesDialog.visible || locationServiceRequsted)
        onTriggered: locationServicesOn = rootItem.refreshLocationServices()
    }

    MessageDialog {
        id: locationServicesDialog
        text: qsTr("Permissions Required")
        informativeText: qsTr("QZ requires both Bluetooth and Location Services to be enabled.\nLocation Services are necessary on Android to allow the app to find Bluetooth devices.\nThe GPS will not be used.\n\nWould you like to enable them?")
        buttons: (MessageDialog.Yes | MessageDialog.No)
        onYesClicked: {
            locationServiceRequsted = true
            rootItem.enableLocationServices()
        }
        onNoClicked: {
            locationServicesDeclined = true
            remindLocationServicesDialog.visible = true
        }
        visible: !locationServicesOn && !locationServiceRequsted && !locationServicesDeclined && !settings.skipLocationServicesDialog
    }

    MessageDialog {
        id: remindLocationServicesDialog
        text: qsTr("Reminder Preference")
        informativeText: qsTr("Would you like to be reminded about enabling Location Services next time?")
        buttons: (MessageDialog.Yes | MessageDialog.No)
        onYesClicked: settings.skipLocationServicesDialog = false
        onNoClicked: settings.skipLocationServicesDialog = true
        visible: false
    }

    MessageDialog {
        text: qsTr("Restart the app")
        informativeText: qsTr("To apply the changes, you need to restart the app.\nWould you like to do that now?")
        buttons: (MessageDialog.Yes | MessageDialog.No)
        onYesClicked: Qt.callLater(Qt.quit)
        onNoClicked: this.visible = false;
        visible: locationServiceRequsted && !locationServicesOn
    }

    Timer {
        interval: 200; running: true; repeat: false
        onTriggered: {
            if(rootItem.firstRun()) {
                stackView.push("Wizard.qml")
            }
        }
    }

    function inner_stop() {
        stop_clicked();
        if (rootItem.rpeFeelPopupEnabled()) {
            rpeFeelPopup.selectedRpe = 5;
            rpeFeelPopup.selectedFeel = 50;
            rpeFeelPopup.open();
        } else {
            finish_stop();
        }
    }

    function finish_stop() {
        rootItem.save_screenshot();
        if(CHARTJS)
            stackView.push("ChartJsTest.qml")
        else
            stackView.push("ChartsEndWorkout.qml")
    }

    start.onClicked: { start_clicked(); }
    stop.onClicked: {
        if (rootItem.confirmStopEnabled()) {
            stopConfirmationDialog.open();
        } else {
            inner_stop();
        }
    }
    lap.onClicked: { lap_clicked(); popupLap.open(); popupLapAutoClose.running = true; }

    Component.onCompleted: {
        console.log("home.qml completed");
    }

    dashboardTiles: typeof rootItem === "undefined" || !rootItem ? ({}) : rootItem.dashboardTiles
    speedMinus.onClicked: minus_clicked("speed_minus")
    speedPlus.onClicked: plus_clicked("speed_plus")
    inclineMinus.onClicked: minus_clicked("inclination_minus")
    inclinePlus.onClicked: plus_clicked("inclination_plus")

    Connections {
        target: window
        function onLockTilesChanged() {
            if (window.lockTiles)
                swipeView.currentIndex = swipeView.count - 1
        }
    }

    SwipeView {
        id: swipeView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomBar.top
        clip: true
        interactive: !window.lockTiles
        currentIndex: settings.dashboard_page
        onCurrentIndexChanged: settings.dashboard_page = currentIndex

        DashboardMainPage {
            tiles: dashboardTiles
            accent: settings.theme_tile_shadow_color
            onPlusClicked: plus_clicked(name)
            onMinusClicked: minus_clicked(name)
        }
        DashboardTrackPage {
            tiles: dashboardTiles
            accent: settings.theme_tile_shadow_color
            miles: typeof rootItem !== "undefined" && rootItem ? rootItem.miles_unit : false
        }
        DashboardChartsPage {
            tiles: dashboardTiles
        }
        DashboardProfilePage {
            tiles: dashboardTiles
            accent: settings.theme_tile_shadow_color
        }

        Item {
            id: gridPage

            GridView {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // The tiles stretch to fill the row: the space left over by a whole number of columns
                // is shared between the columns, up to a quarter of the tile width, and what remains
                // centres the grid. Measured on the page, so the Android insets are excluded.
                // The grid is exactly as wide as its columns and centred by the anchor above, not
                // by leftMargin: Qt 5.15 does not recount the columns when leftMargin changes, so
                // after a resize a row could come out one column short
                readonly property real tileBaseWidth: 175 * settings.ui_zoom / 100
                readonly property int tileColumns: Math.max(1, Math.floor(parent.width / tileBaseWidth))
                cellWidth: Math.floor(Math.min(parent.width / tileColumns, tileBaseWidth * 1.25))
                width: tileColumns * cellWidth
                // Every tile is narrower than its cell by tileGap and sits at the cell's left edge, so the
                // last column ends with the gap: the grid is shifted by half the gap, so the outer margins
                // are equal
                readonly property real tileGap: 5 * settings.ui_zoom / 100
                anchors.horizontalCenterOffset: tileGap / 2
                cellHeight: 130 * settings.ui_zoom / 100
                focus: true
                model: appModel
                anchors.topMargin: 8
                interactive: !window.lockTiles
                id: gridView
                objectName: "gridview"
                onMovementEnded: { headerToolbar.visible = (contentY == 0) || window.lockTiles; }
                Screen.orientationUpdateMask:  Qt.LandscapeOrientation | Qt.PortraitOrientation | Qt.InvertedLandscapeOrientation | Qt.InvertedPortraitOrientation
                Screen.onPrimaryOrientationChanged:{
                    // Nothing to recompute: cellWidth and the grid width follow the page width
                }

                Accessible.ignored: true

                delegate: Item {
                    id: id1
                    width: gridView.cellWidth - gridView.tileGap
                    height: 125 * settings.ui_zoom / 100

                    readonly property real zoom: settings.ui_zoom / 100
                    readonly property color tileColor: settings.theme_tile_background_color
                    readonly property color accentColor: settings.theme_tile_shadow_color
                    readonly property color mutedTextColor: Qt.rgba(1, 1, 1, 0.55)
                    readonly property bool showIcon: settings.theme_tile_icon_enabled && !largeButton
                    readonly property real stepperSize: 40 * zoom
                    readonly property real edgePadding: 12 * zoom

                    visible: visibleItem
                    Component.onCompleted: console.log("completed " + objectName)

                    // VoiceOver accessibility support
                    Accessible.role: largeButton ? Accessible.Button : (writable ? Accessible.Pane : Accessible.StaticText)
                    Accessible.name: name + (largeButton ? "" : (": " + value))
                    Accessible.description: largeButton ? largeButtonLabel : (secondLine !== "" ? secondLine : (writable ? qsTr("Adjustable. Current value: ") + value : qsTr("Current value: ") + value))
                    Accessible.focusable: true


                    SequentialAnimation on rotation {
                        NumberAnimation { to:  2; duration: 60 }
                        NumberAnimation { to: -2; duration: 120 }
                        NumberAnimation { to:  0; duration: 60 }
                        running: loc.currentId !== -1 && id1.state !== "active" && window.lockTiles
                        loops: Animation.Infinite; alwaysRunToEnd: true
                    }

                    states: State {
                        name: "active"; when: loc.currentId === gridId && window.lockTiles
                        PropertyChanges { target: id1; opacity: 0.3 }
                    }

                    transitions: Transition { NumberAnimation { property: "opacity"; duration: 200} }

                    DropShadow {
                        visible: settings.theme_tile_shadow_enabled
                        anchors.fill: rect
                        cached: true
                        horizontalOffset: 0
                        verticalOffset: 6 * zoom
                        radius: 18
                        samples: 37
                        color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22)
                        source: rect
                    }

                    Rectangle {
                        width: id1.width - 2 * zoom
                        height: 123 * zoom
                        radius: 14 * zoom
                        border.width: 1
                        border.color: settings.theme_tile_shadow_enabled
                                      ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.45)
                                      : Qt.rgba(1, 1, 1, 0.08)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(id1.tileColor, 1.18) }
                            GradientStop { position: 1.0; color: id1.tileColor }
                        }
                        id: rect

                        // Ignore for VoiceOver - decorative background only
                        Accessible.ignored: true
                    }

                    Timer {
                        id: toggleIconTimer
                        interval: 500; running: true; repeat: true
                        onTriggered: { if(identificator === "inclination" && rootItem.autoInclinationEnabled()) myIcon.visible = !myIcon.visible; else myIcon.visible = showIcon; }
                    }

                    Image {
                        id: myIcon
                        anchors {
                            left: parent.left
                            top: parent.top
                            leftMargin: edgePadding
                            topMargin: 10 * zoom
                        }
                        width: 20 * zoom
                        height: 20 * zoom
                        source: icon
                        visible: showIcon
                        smooth: true
                        mipmap: true
                        opacity: 0.9

                        // Ignore for VoiceOver - decorative only
                        Accessible.ignored: true
                    }
                    Text {
                        id: myText
                        anchors {
                            verticalCenter: myIcon.verticalCenter
                            left: showIcon ? myIcon.right : parent.left
                            right: parent.right
                            leftMargin: showIcon ? 7 * zoom : edgePadding
                            rightMargin: edgePadding
                        }
                        font.bold: true
                        font.pointSize: Math.max(9, labelFontSize - 2) * zoom
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2 * zoom
                        fontSizeMode: Text.HorizontalFit
                        minimumPointSize: 7
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: mutedTextColor
                        text: name
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        visible: !largeButton

                        // Ignore for VoiceOver - parent Item handles accessibility
                        Accessible.ignored: true
                    }
                    Text {
                        objectName: "value"
                        id: myValue
                        color: valueFontColor
                        anchors {
                            top: parent.top
                            topMargin: 32 * zoom
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: value
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: Math.max(50, parent.width - (writable ? 2 * (stepperSize + 10 * zoom) : 2 * edgePadding))
                        height: 58 * zoom
                        font.pointSize: valueFontSize * zoom
                        font.letterSpacing: -0.5 * zoom
                        fontSizeMode: Text.Fit
                        minimumPointSize: 10
                        font.bold: true
                        visible: !largeButton

                        // Ignore for VoiceOver - parent Item handles accessibility
                        Accessible.ignored: true
                    }
                    Text {
                        objectName: "secondLine"
                        id: secondLineText
                        color: mutedTextColor
                        anchors {
                            top: myValue.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: secondLine
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: Math.max(50, parent.width - 2 * edgePadding)
                        height: 24 * zoom
                        font.pointSize: settings.theme_tile_secondline_textsize * zoom
                        fontSizeMode: Text.Fit
                        minimumPointSize: 7
                        font.bold: false
                        visible: !largeButton

                        // Ignore for VoiceOver - parent Item handles accessibility
                        Accessible.ignored: true
                    }
                    RoundButton {
                        objectName: minusName
                        autoRepeat: true
                        text: "−"
                        onClicked: minus_clicked(objectName)
                        visible: writable && !largeButton
                        anchors.verticalCenter: myValue.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * zoom
                        width: stepperSize
                        height: stepperSize
                        flat: true
                        font.pointSize: 16 * zoom
                        font.bold: true
                        Material.foreground: Qt.lighter(accentColor, 1.35)
                        background: Rectangle {
                            radius: width / 2
                            color: parent.down ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35) : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)
                        }

                        // VoiceOver accessibility
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Decrease ") + name
                        Accessible.description: qsTr("Decrease the value of ") + name
                        Accessible.focusable: true
                        Accessible.onPressAction: { minus_clicked(objectName) }
                    }
                    RoundButton {
                        autoRepeat: true
                        objectName: plusName
                        text: "+"
                        onClicked: plus_clicked(objectName)
                        visible: writable && !largeButton
                        anchors.verticalCenter: myValue.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * zoom
                        width: stepperSize
                        height: stepperSize
                        flat: true
                        font.pointSize: 16 * zoom
                        font.bold: true
                        Material.foreground: Qt.lighter(accentColor, 1.35)
                        background: Rectangle {
                            radius: width / 2
                            color: parent.down ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35) : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)
                        }

                        // VoiceOver accessibility
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Increase ") + name
                        Accessible.description: qsTr("Increase the value of ") + name
                        Accessible.focusable: true
                        Accessible.onPressAction: { plus_clicked(objectName) }
                    }
                    RoundButton {
                        autoRepeat: true
                        objectName: identificator
                        text: largeButtonLabel
                        onClicked: largeButton_clicked(objectName)
                        visible: largeButton
                        anchors.fill: rect
                        Material.foreground: "white"
                        background: Rectangle {
                            color: parent.down ? Qt.darker(largeButtonColor, 1.2) : largeButtonColor
                            radius: 14 * zoom
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.12)
                        }
                        font.pointSize: 20 * zoom
                        font.bold: true

                        // VoiceOver accessibility
                        Accessible.role: Accessible.Button
                        Accessible.name: largeButtonLabel
                        Accessible.description: name + ": " + largeButtonLabel
                        Accessible.focusable: true
                        Accessible.onPressAction: { largeButton_clicked(objectName) }
                    }
                }
            }

            Item {
                id: ghostTile
                visible: loc.currentId !== -1 && window.lockTiles
                x: loc.mouseX - width / 2
                y: loc.mouseY - height / 2
                width: 85 * settings.ui_zoom / 100
                height: 63 * settings.ui_zoom / 100
                z: 200

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: settings.theme_tile_background_color
                    opacity: 0.9
                    border.width: 2
                    border.color: settings.theme_tile_shadow_color

                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        text: loc.tileName
                        font.pointSize: 10 * settings.ui_zoom / 100
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 8
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Timer {
                id: autoScrollTimer
                interval: 50
                repeat: true
                running: false
                property real scrollSpeed: 15
                onTriggered: {
                    if (loc.currentId === -1) { running = false; return; }
                    var edgeZone = 80
                    if (loc.mouseY > gridView.height - edgeZone) {
                        var factor = (loc.mouseY - (gridView.height - edgeZone)) / edgeZone
                        gridView.contentY = Math.min(
                            gridView.contentHeight - gridView.height,
                            gridView.contentY + scrollSpeed * (1 + factor * 2)
                        )
                    } else if (loc.mouseY < edgeZone) {
                        var factor2 = (edgeZone - loc.mouseY) / edgeZone
                        gridView.contentY = Math.max(0, gridView.contentY - scrollSpeed * (1 + factor2 * 2))
                    } else {
                        running = false
                    }
                }
            }

            MouseArea {
                property int currentId: -1
                property int newIndex
                property int startIndex: -1
                property string tileName: ""
                property real lastScrollY: 0
                property bool isSwiping: false

                function indexAtMouse(mx, my) {
                    var cols = gridView.tileColumns
                    var adjustedY = my + gridView.contentY
                    var col = Math.floor((mx - gridView.x) / gridView.cellWidth)
                    if (col < 0 || col >= cols) return -1
                    var row = Math.floor(adjustedY / gridView.cellHeight)
                    var idx = row * cols + col
                    if (idx < 0 || idx >= appModel.count) return -1
                    return idx
                }

                id: loc
                enabled: window.lockTiles
                anchors.fill: parent

                onPressed: {
                    lastScrollY = mouseY
                    isSwiping = false
                }

                onPressAndHold: {
                    if (isSwiping) return
                    var idx = indexAtMouse(mouseX, mouseY)
                    if (idx !== -1) {
                        startIndex = idx
                        newIndex = idx
                        currentId = appModel[idx].gridId
                        tileName = appModel[idx].name
                    } else {
                        currentId = -1
                        tileName = ""
                    }
                }

                onReleased: {
                    autoScrollTimer.running = false
                    if (currentId !== -1) {
                        var idx = indexAtMouse(mouseX, mouseY)
                        if (idx !== -1 && idx !== startIndex)
                            rootItem.moveTile(tileName, idx, startIndex)
                    }
                    currentId = -1
                    startIndex = -1
                    tileName = ""
                    isSwiping = false
                }

                onPositionChanged: {
                    if (currentId === -1) {
                        // No drag in progress: scroll the grid like a normal flick
                        var dy = mouseY - lastScrollY
                        if (Math.abs(dy) > 5) isSwiping = true
                        gridView.contentY = Math.max(0,
                            Math.min(gridView.contentHeight - gridView.height,
                                     gridView.contentY - dy))
                        lastScrollY = mouseY
                        return
                    }
                    var edgeZone = 80
                    if (mouseY > gridView.height - edgeZone || mouseY < edgeZone)
                        autoScrollTimer.running = true
                    else
                        autoScrollTimer.running = false

                    var idx = indexAtMouse(mouseX, mouseY)
                    if (idx !== -1 && idx !== newIndex) newIndex = idx
                }
            }
        }
    }

    PageIndicator {
        anchors.bottom: swipeView.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        count: swipeView.count
        currentIndex: swipeView.currentIndex
        interactive: true
        onCurrentIndexChanged: swipeView.currentIndex = currentIndex
    }

    footer: Item {
        id: footerItem
        width: parent.width
        height: footerHeight
        property real footerHeight: (rootItem.chartFooterVisible ? parent.height / 4 : parent.height / 2)
        property real minHeight: parent.height / 4
        property real maxHeight: parent.height * 3 / 4
        anchors.bottom: parent.bottom
        clip: true
        visible: rootItem.chartFooterVisible || rootItem.videoVisible

        Rectangle {
            id: dragHandle
            width: parent.width / 5
            height: 10
            color: settings.theme_tile_shadow_color
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: rootItem.chartFooterVisible || rootItem.videoVisible

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.strokeStyle = "#FFFFFF";
                    ctx.lineWidth = 2;

                    for (var i = 0; i < 3; i++) {
                        ctx.beginPath();
                        ctx.moveTo(0, (i + 1) * parent.height / 4);
                        ctx.lineTo(parent.width, (i + 1) * parent.height / 4);
                        ctx.stroke();
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor

                property real startY: 0
                property real startHeight: 0

                onPressed: {
                    startY = mouseY
                    startHeight = footerItem.height
                }

                onMouseYChanged: {
                    if (pressed) {
                        var newHeight = Math.max(footerItem.minHeight, Math.min(footerItem.maxHeight, startHeight + startY - mouseY))
                        footerItem.footerHeight = newHeight
                    }
                }
            }
        }

        Rectangle {
            id: chartFooterRectangle
            visible: rootItem.chartFooterVisible
            anchors.top: dragHandle.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            ChartFooter {
                anchors.fill: parent
                visible: rootItem.chartFooterVisible
            }
        }

        Rectangle {
            objectName: "footerrectangle"
            visible: rootItem.videoVisible
            anchors.top: dragHandle.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            onVisibleChanged: {
                if(visible === true) {
                    console.log("mediaPlayer onCompleted: " + rootItem.videoPath)
                    console.log("videoRate: " + rootItem.videoRate)
                    videoPlaybackHalf.source = rootItem.videoPath
                    videoPlaybackHalf.seek(rootItem.videoPosition)
                    videoPlaybackHalf.play()
                    videoPlaybackHalf.muted = rootItem.currentCoordinateValid
                } else {
                    videoPlaybackHalf.stop()
                }
            }

            MediaPlayer {
                id: videoPlaybackHalf
                objectName: "videoplaybackhalf"
                autoPlay: false
                playbackRate: rootItem.videoRate

                onError: {
                    if (videoPlaybackHalf.NoError !== error) {
                        console.log("[qmlvideo] VideoItem.onError error " + error + " errorString " + errorString)
                    }
                }
            }

            VideoOutput {
                id: videoPlayer
                anchors.fill: parent
                source: videoPlaybackHalf
            }
        }
    }

}
