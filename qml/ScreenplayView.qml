/****************************************************************************
**
** Copyright (C) TERIFLIX Entertainment Spaces Pvt. Ltd. Bengaluru
** Author: Prashanth N Udupa (prashanth.udupa@teriflix.com)
**
** This code is distributed under GPL v3. Complete text of the license
** can be found here: https://www.gnu.org/licenses/gpl-3.0.txt
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

import QtQuick 2.13
import QtQuick.Controls 2.13
import Scrite 1.0

Item {
    id: screenplayView
    signal requestEditor()

    clip: true

    property real zoomLevel: 1
    property color dropAreaHighlightColor: "#cfd8dc"
    property string dropAreaKey: "scrite/sceneID"
    property real preferredHeight: screenplayToolsLayout.height
    property bool showNotesIcon: false
    property bool enableDragDrop: !scriteDocument.readOnly

    Connections {
        target: scriteDocument.screenplay
        onCurrentElementIndexChanged: {
            if(!scriteDocument.loading) {
                app.execLater(screenplayElementList, 150, function() {
                    if(screenplayElementList.currentIndex === 0)
                        screenplayElementList.positionViewAtBeginning()
                    else if(screenplayElementList.currentIndex === screenplayElementList.count-1)
                        screenplayElementList.positionViewAtEnd()
                    else
                        screenplayElementList.positionViewAtIndex(scriteDocument.screenplay.currentElementIndex, ListView.Contain)
                })
            }
        }
    }

    Item {
        id: screenplayTools
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: 60
        z: 1

        ScrollView {
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: screenplayToolsLayout.width
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Column {
                id: screenplayToolsLayout
                width: 40

                ToolButton3 {
                    iconSource: "../icons/content/clear_all.png"
                    ToolTip.text: "Clear the screenplay, while retaining the scenes."
                    enabled: !scriteDocument.readOnly
                    suggestedWidth: 30; suggestedHeight: 30
                    onClicked: {
                        askQuestion({
                            "question": "Are you sure you want to clear the screenplay?",
                            "okButtonText": "Yes",
                            "cancelButtonText": "No",
                            "callback": function(val) {
                                if(val) {
                                    screenplayElementList.forceActiveFocus()
                                    scriteDocument.screenplay.clearElements()
                                }
                            }
                        }, this)
                    }
                }

                ToolButton3 {
                    iconSource: "../icons/navigation/zoom_in.png"
                    ToolTip.text: "Increase size of blocks in this view."
                    onClicked: {
                        zoomLevel = Math.min(zoomLevel * 1.1, 4.0)
                        screenplayElementList.updateCacheBuffer()
                    }
                    autoRepeat: true
                    suggestedWidth: 30; suggestedHeight: 30
                }

                ToolButton3 {
                    iconSource: "../icons/navigation/zoom_out.png"
                    ToolTip.text: "Decrease size of blocks in this view."
                    onClicked: {
                        zoomLevel = Math.max(zoomLevel * 0.9, screenplayElementList.perElementWidth/screenplayElementList.minimumDelegateWidth)
                        screenplayElementList.updateCacheBuffer()
                    }
                    autoRepeat: true
                    suggestedWidth: 30; suggestedHeight: 30
                }

                ToolButton3 {
                    iconSource: "../icons/content/add_box.png"
                    ToolTip.text: "Add a act, chapter or interval break."
                    autoRepeat: false
                    suggestedWidth: 30; suggestedHeight: 30
                    enabled: !scriteDocument.readOnly &&
                             (scriteDocument.screenplay.elementCount === 0 ||
                             scriteDocument.screenplay.currentElementIndex >= 0)
                    onClicked: breakElementMenu.popup(width,height/2)
                    down: breakElementMenu.visible

                    Menu2 {
                        id: breakElementMenu

                        Repeater {
                            model: app.enumerationModel(scriteDocument.screenplay, "BreakType")

                            MenuItem2 {
                                text: modelData.key
                                onClicked: scriteDocument.screenplay.insertBreakElement(modelData.value, scriteDocument.screenplay.currentElementIndex+1)
                            }
                        }
                    }
                }
            }
        }
    }

    DropArea {
        anchors.fill: parent
        keys: [dropAreaKey]
        enabled: screenplayElementList.count === 0 && enableDragDrop

        onEntered: {
            screenplayElementList.forceActiveFocus()
            screenplayElementList.footerItem.highlightAsDropArea = true
        }

        onExited: {
            screenplayElementList.footerItem.highlightAsDropArea = false
        }

        onDropped: {
            screenplayElementList.footerItem.highlightAsDropArea = false
            dropSceneAt(drop.source, -1)
            drop.acceptProposedAction()
        }
    }

    Flickable {
        id: screenplayTracksFlick
        anchors.left: screenplayElementList.left
        anchors.top: parent.top
        anchors.right: screenplayElementList.right
        height: contentHeight
        contentWidth: screenplayTracksFlickContent.width
        contentHeight: screenplayTracksFlickContent.height
        interactive: false
        contentX: screenplayElementList.contentX - screenplayElementList.originX
        clip: true

        EventFilter.events: [31]
        EventFilter.onFilter: {
            EventFilter.forwardEventTo(screenplayElementList)
            result.filter = true
            result.accepted = true
        }

        Item {
            id: screenplayTracksFlickContent
            width: screenplayElementList.contentWidth
            height: screenplayTracks.trackCount * (minimumAppFontMetrics.height + 10)

            Repeater {
                model: screenplayTracks

                Rectangle {
                    readonly property var trackData: modelData
                    width: screenplayTracksFlickContent.width
                    height: minimumAppFontMetrics.height + 8
                    y: index * (minimumAppFontMetrics.height + 10)
                    color: app.translucent( border.color, 0.1 )
                    border.color: Qt.tint(app.pickStandardColor(index), "#80000000")
                    border.width: 0.5

                    MouseArea {
                        id: trackMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onMouseXChanged: maybeTooltip()
                        onMouseYChanged: maybeTooltip()
                        onContainsMouseChanged: maybeTooltip()

                        function maybeTooltip() {
                            if(containsMouse) {
                                toolTipItem.x = mouseX
                                toolTipItem.y = mouseY
                                toolTipItem.ToolTip.text = "'" + trackData.category + "' Track"
                                toolTipItem.ToolTip.visible = true
                                toolTipItem.source = trackMouseArea
                            } else if(toolTipItem.source === trackMouseArea) {
                                toolTipItem.ToolTip.visible = false
                                toolTipItem.source = null
                            }
                        }
                    }

                    Repeater {
                        model: trackData.tracks

                        Rectangle {
                            readonly property var groupData: trackData.tracks[index]
                            readonly property var groupExtents: screenplayElementList.extents(groupData.startIndex, groupData.endIndex)
                            color: parent.border.color
                            border.color: app.translucent(app.textColorFor(color), 0.25)
                            border.width: 0.5
                            x: groupExtents.from
                            width: groupExtents.to - groupExtents.from
                            height: parent.height-4
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                font: minimumAppFontMetrics.font
                                text: groupData.group
                                width: parent.width-10
                                horizontalAlignment: Text.AlignHCenter
                                anchors.centerIn: parent
                                elide: Text.ElideMiddle
                                color: app.textColorFor(parent.color)
                            }

                            MouseArea {
                                id: groupMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onMouseXChanged: maybeTooltip()
                                onMouseYChanged: maybeTooltip()
                                onContainsMouseChanged: maybeTooltip()

                                function maybeTooltip() {
                                    if(containsMouse) {
                                        toolTipItem.x = mouseX + parent.x
                                        toolTipItem.y = mouseY
                                        toolTipItem.ToolTip.text = trackData.category + " > " + groupData.group
                                        toolTipItem.ToolTip.visible = true
                                        toolTipItem.source = groupMouseArea
                                    } else if(toolTipItem.source === groupMouseArea) {
                                        toolTipItem.ToolTip.visible = false
                                        toolTipItem.source = null
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: toolTipItem
                property MouseArea source: null
            }
        }
    }

    TrackerPack {
        TrackProperty {
            target: screenplayTracks
            property: "trackCount"
        }

        TrackProperty {
            target: scriteDocument.screenplay
            property: "elementCount"
        }

        onTracked: screenplayElementList.updateCacheBuffer()
    }

    ListView {
        id: screenplayElementList
        anchors.left: screenplayTools.right
        anchors.right: parent.right
        anchors.top: screenplayTracksFlick.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 3
        anchors.bottomMargin: 0
        clip: true
        property bool somethingIsBeingDropped: false
        // visible: count > 0 || somethingIsBeingDropped
        model: scriteDocument.loading ? null : scriteDocument.screenplay
        property real minimumDelegateWidth: 100
        property real breakDelegateWidth: 70
        property real perElementWidth: 2.5
        property bool moveMode: false
        orientation: Qt.Horizontal
        currentIndex: scriteDocument.screenplay.currentElementIndex
        Keys.onRightPressed: scriteDocument.screenplay.currentElementIndex = scriteDocument.screenplay.currentElementIndex+1
        Keys.onLeftPressed: scriteDocument.screenplay.currentElementIndex = scriteDocument.screenplay.currentElementIndex-1

        property bool scrollBarRequired: screenplayElementList.width < screenplayElementList.contentWidth
        ScrollBar.horizontal: ScrollBar {
            policy: screenplayElementList.scrollBarRequired ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            minimumSize: 0.1
            opacity: active ? 1 : 0.5
            Behavior on opacity {
                enabled: screenplayEditorSettings.enableAnimations
                NumberAnimation { duration: 250 }
            }
        }

        FocusTracker.window: qmlWindow
        FocusTracker.indicator.target: mainUndoStack
        FocusTracker.indicator.property: "timelineEditorActive"

        Transition {
            id: moveAndDisplace
            NumberAnimation { properties: "x,y"; duration: 250 }
        }

        moveDisplaced: moveAndDisplace
        move: moveAndDisplace

        EventFilter.active: app.isWindowsPlatform || app.isLinuxPlatform
        EventFilter.events: [31]
        EventFilter.onFilter: {
            if(event.delta < 0)
                contentX = Math.min(contentX+20, contentWidth-width)
            else
                contentX = Math.max(contentX-20, 0)
            result.acceptEvent = true
            result.filter = true
        }

        footer: Item {
            property bool highlightAsDropArea: false
            width: screenplayElementList.minimumDelegateWidth
            height: screenplayElementList.height

            Rectangle {
                width: 5
                height: parent.height
                color: parent.highlightAsDropArea ? dropAreaHighlightColor : Qt.rgba(0,0,0,0)
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 7.5
                anchors.rightMargin: 2.5
                anchors.bottomMargin: screenplayElementList.scrollBarRequired ? 20 : 0
                color: primaryColors.button.background
                border.color: primaryColors.borderColor
                border.width: 1
                opacity: parent.highlightAsDropArea ? 0.75 : 0.5
                visible: scriteDocument.structure.elementCount > 0 && enableDragDrop

                Text {
                    anchors.fill: parent
                    anchors.margins: 5
                    font.pointSize: app.idealFontPointSize-2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: screenplayElementList.count === 0 ? "Drop the first scene here." : "Drop the last scene here."
                }
            }

            DropArea {
                anchors.fill: parent
                keys: [dropAreaKey]
                enabled: enableDragDrop

                onEntered: {
                    screenplayElementList.forceActiveFocus()
                    parent.highlightAsDropArea = true
                }

                onExited: {
                    parent.highlightAsDropArea = false
                }

                onDropped: {
                    screenplayElementList.footerItem.highlightAsDropArea = false
                    dropSceneAt(drop.source, -1)
                    drop.acceptProposedAction()
                }
            }
        }

        highlight: Item {
            Item {
                anchors.leftMargin: 7.5
                anchors.rightMargin: 2.5
                anchors.bottomMargin: screenplayElementList.scrollBarRequired ? 20 : 10
                anchors.fill: parent

                BoxShadow {
                    anchors.fill: parent
                }
            }
        }
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 0
        highlightResizeDuration: 0

        property bool mutiSelectionMode: false

        function updateCacheBuffer() {
            if(screenplayTracks.trackCount > 0)
                cacheBuffer = extents(count-1, count-1).to + 20
            else
                cacheBuffer = 0
        }

        function extents(startIndex, endIndex) {
            var x = 0;
            var ret = { "from": 0, "to": 0 }
            if(startIndex < 0 || endIndex < 0)
                return ret;

            var idx = -1
            var nrElements = scriteDocument.screenplay.elementCount
            for(var i=0; i<nrElements; i++) {
                var element = scriteDocument.screenplay.elementAt(i)
                if(element.elementType === ScreenplayElement.SceneElementType)
                    ++idx
                if(idx === startIndex)
                    ret.from = x+7.5
                if(element.elementType === ScreenplayElement.BreakElementType)
                    x += breakDelegateWidth
                else {
                    var sceneElementCount = element.scene ? element.scene.elementCount : 1
                    x += Math.max(minimumDelegateWidth, sceneElementCount*perElementWidth*zoomLevel)
                }
                if(idx === endIndex)
                    break
            }
            ret.to = x-2.5
            return ret
        }

        delegate: Item {
            id: elementItemDelegate
            property ScreenplayElement element: screenplayElement
            property bool isBreakElement: element.elementType === ScreenplayElement.BreakElementType
            property bool active: element.scene ? scriteDocument.screenplay.activeScene === element.scene : false
            property int sceneElementCount: element.scene ? element.scene.elementCount : 1
            property string sceneTitle: element.scene ? "[" + element.resolvedSceneNumber + "]: " + (element.scene.title === "" ? (element.scene.heading.enabled ? element.scene.heading.text : "NO SCENE HEADING") : element.scene.title) : element.breakTitle
            property color sceneColor: element.scene ? element.scene.color : "white"
            width: isBreakElement ? screenplayElementList.breakDelegateWidth :
                   Math.max(screenplayElementList.minimumDelegateWidth, sceneElementCount*screenplayElementList.perElementWidth*zoomLevel)
            height: screenplayElementList.height

            Rectangle {
                visible: element.selected
                anchors.fill: elementItemBox
                anchors.margins: -5
                color: accentColors.a700.background
            }

            Loader {
                id: elementItemBox
                anchors.fill: parent
                anchors.leftMargin: 7.5
                anchors.rightMargin: 2.5
                anchors.bottomMargin: screenplayElementList.scrollBarRequired ? 20 : 0
                active: element !== null // && (isBreakElement || element.scene !== null)
                enabled: !dragArea.containsDrag
                sourceComponent: Rectangle {
                    color: Qt.tint(sceneColor, "#C0FFFFFF")
                    border.color: color === Qt.rgba(1,1,1,1) ? "black" : sceneColor
                    border.width: elementItemDelegate.active ? 2 : 1
                    Behavior on border.width {
                        enabled: screenplayEditorSettings.enableAnimations
                        NumberAnimation { duration: 400 }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: dragTriggerButton.top
                        anchors.topMargin: notesIconLoader.active ? 30 : 5
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5

                        Text {
                            lineHeight: 1.25
                            text: sceneTitle
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            font.bold: isBreakElement
                            transformOrigin: Item.Center
                            verticalAlignment: Text.AlignTop
                            rotation: isBreakElement ? -90 : 0
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: isBreakElement ? 1 : 4
                            font.pointSize: isBreakElement ? (minFontSize*1.25) : minFontSize
                            visible: isBreakElement ? true : width >= 80
                            wrapMode: isBreakElement ? Text.NoWrap : Text.Wrap
                            font.capitalization: isBreakElement ? Font.AllUppercase : Font.MixedCase
                            width: elementItemDelegate.isBreakElement ? parent.height : parent.width
                            height: elementItemDelegate.isBreakElement ? contentHeight : parent.height
                            readonly property real minFontSize: scriteDocument.formatting.screen.devicePixelRatio > 1 ? 13 : 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: isBreakElement ? Qt.RightButton : Qt.LeftButton|Qt.RightButton
                        onClicked: {
                            if(!isBreakElement) {
                                parent.forceActiveFocus()
                                screenplayElementList.mutiSelectionMode = mouse.modifiers & Qt.ControlModifier
                                if(screenplayElementList.mutiSelectionMode)
                                    elementItemDelegate.element.toggleSelection()
                                else
                                    scriteDocument.screenplay.clearSelection()
                                scriteDocument.screenplay.currentElementIndex = index
                                requestEditorLater()
                            }

                            if(mouse.button === Qt.RightButton) {
                                elementItemMenu.element = element
                                elementItemMenu.popup(this)
                            }
                        }
                    }

                    // Drag to timeline support
                    Drag.active: dragMouseArea.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.MoveAction
                    Drag.hotSpot.x: width/2
                    Drag.hotSpot.y: height/2
                    Drag.source: elementItemDelegate.element
                    Drag.mimeData: {
                        "scrite/sceneID": element.sceneID
                    }
                    Drag.onActiveChanged: {
                        if(!isBreakElement)
                            scriteDocument.screenplay.currentElementIndex = index
                        screenplayElementList.moveMode = Drag.active
                    }

                    Loader {
                        id: notesIconLoader
                        active: showNotesIcon && (elementItemDelegate.element.scene && elementItemDelegate.element.scene.noteCount >= 1)
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 5
                        width: 24; height: 24
                        opacity: 0.4
                        sourceComponent: Image {
                            source: "../icons/content/bookmark_outline.png"
                        }
                    }

                    SceneTypeImage {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        width: 24; height: 24
                        opacity: 0.5
                        showTooltip: false
                        sceneType: elementItemDelegate.element.scene ? elementItemDelegate.element.scene.type : Scene.Standard
                    }

                    Image {
                        id: dragTriggerButton
                        source: "../icons/action/view_array.png"
                        width: 24; height: 24
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        anchors.rightMargin: 5
                        opacity: dragMouseArea.containsMouse ? 1 : 0.1
                        scale: dragMouseArea.containsMouse ? 2 : 1
                        visible: !scriteDocument.readOnly && enableDragDrop
                        enabled: visible
                        Behavior on scale {
                            enabled: screenplayEditorSettings.enableAnimations
                            NumberAnimation { duration: 250 }
                        }

                        MouseArea {
                            id: dragMouseArea
                            hoverEnabled: true
                            anchors.fill: parent
                            drag.target: parent
                            cursorShape: Qt.SizeAllCursor
                            enabled: enableDragDrop
                            onPressed: {
                                elementItemDelegate.grabToImage(function(result) {
                                    elementItemDelegate.Drag.imageSource = result.url
                                })
                            }
                        }
                    }
                }
            }

            DropArea {
                id: dragArea
                anchors.fill: parent
                keys: [dropAreaKey]

                onEntered: {
                    screenplayElementList.forceActiveFocus()
                    drag.accepted = true
                    dropAreaIndicator.highlightAsDropArea = true
                }

                onExited: {
                    drag.accepted = true
                    dropAreaIndicator.highlightAsDropArea = false
                }

                onDropped: {
                    dropAreaIndicator.highlightAsDropArea = false
                    dropSceneAt(drop.source, index)
                    drop.acceptProposedAction()
                    if(!screenplayElementList.moveMode)
                        screenplayElementList.positionViewAtIndex(index,ListView.Contain)
                }
            }

            Rectangle {
                id: dropAreaIndicator
                width: 5
                height: parent.height
                anchors.left: parent.left

                property bool highlightAsDropArea: false
                color: highlightAsDropArea ? dropAreaHighlightColor : Qt.rgba(0,0,0,0)
            }
        }
    }

    Loader {
        active: enableDragDrop && scriteDocument.screenplay.elementCount === 0
        width: parent.width*0.5
        anchors.centerIn: parent
        sourceComponent: Text {
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            // renderType: Text.NativeRendering
            font.pixelSize: 30
            enabled: false
            color: primaryColors.c800.background
            text: "Drag scenes on the structure canvas from their bottom right corner to this timeline view here."
        }
    }

    Menu2 {
        id: elementItemMenu
        property ScreenplayElement element

        onClosed: element = null

        ColorMenu {
            title: "Color"
            enabled: elementItemMenu.element !== null
            onMenuItemClicked: {
                elementItemMenu.element.scene.color = color
                elementItemMenu.close()
            }
        }

        Menu2 {
            title: "Mark Scene As"

            Repeater {
                model: elementItemMenu.element ? app.enumerationModelForType("Scene", "Type") : 0

                MenuItem2 {
                    text: modelData.key
                    font.bold: elementItemMenu.element.scene.type === modelData.value
                    onTriggered: {
                        elementItemMenu.element.scene.type = modelData.value
                        elementItemMenu.close()
                    }
                }
            }
        }

        StructureGroupsMenu {
            sceneGroup: SceneGroup {
                structure: scriteDocument.structure
            }
            onAboutToShow: {
                sceneGroup.clearScenes()
                if(elementItemMenu.element)
                    sceneGroup.addScene(elementItemMenu.element.scene)
            }
            onClosed: sceneGroup.clearScenes()
        }

        MenuSeparator { }

        MenuItem2 {
            text: "Remove"
            enabled: !scriteDocument.readOnly
            onClicked: {
                scriteDocument.screenplay.removeElement(elementItemMenu.element)
                elementItemMenu.close()
            }
        }
    }

    function dropSceneAt(source, index) {
        if(source === null)
            return

        var sourceType = app.typeName(source)

        if(sourceType === "ScreenplayElement") {
            var fromIndex = scriteDocument.screenplay.indexOfElement(source)
            if(fromIndex < index)
                --index
            if(screenplayElementList.mutiSelectionMode)
                app.execLater(screenplayElementList, 100, function() {
                    scriteDocument.screenplay.moveSelectedElements(index)
                })
            else
                scriteDocument.screenplay.moveElement(source, index)
            return
        }

        var sceneID = source.id
        if(sceneID.length === 0)
            return

        var scene = scriteDocument.structure.findElementBySceneID(sceneID)
        if(scene === null)
            return

        var element = screenplayElementComponent.createObject()
        element.sceneID = sceneID
        scriteDocument.screenplay.insertElementAt(element, index)
        requestEditorLater()
    }

    Component {
        id: screenplayElementComponent

        ScreenplayElement {
            screenplay: scriteDocument.screenplay
        }
    }

    function requestEditorLater() {
        app.execLater(screenplayView, 100, function() { requestEditor() })
    }
}
