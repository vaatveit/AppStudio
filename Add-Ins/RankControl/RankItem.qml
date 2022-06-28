/* Copyright 2020 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQml 2.12
import QtQml.Models 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

MouseArea {
    id: dragArea
    
    //--------------------------------------------------------------------------

    property bool isDragging
    property DelegateModelGroup items
    property font font
    property var palette
    property alias layoutDirection: layout.layoutDirection
    property bool isNull
    
    //--------------------------------------------------------------------------

    signal moved()

    //--------------------------------------------------------------------------

    implicitHeight: content.height

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.SizeVerCursor
    
    drag {
        target: isDragging ? content : undefined
        axis: Drag.YAxis
    }

    //--------------------------------------------------------------------------

    onPressed: {
        isDragging = true;
    }
    
    onReleased: {
        isDragging = false;
        moved();
    }
    
    //--------------------------------------------------------------------------

    onDoubleClicked: {
        if (mouse.button === Qt.LeftButton && DelegateModel.itemsIndex > 0) {
            items.move(DelegateModel.itemsIndex, 0);
            moved();
        } else if (mouse.button === Qt.RightButton && DelegateModel.itemsIndex < DelegateModel.model.count - 1) {
            items.move(DelegateModel.itemsIndex, DelegateModel.model.count - 1);
            moved();
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: content
        
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        
        width: dragArea.width
        implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
        
        border {
            width: 1
            color: dragArea.isDragging
                   ? palette.highlight
                   : palette.mid
        }
        
        color: dragArea.isDragging
               ? palette.light
               : palette.base

        radius: 3
        
        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
        
        Drag.active: dragArea.isDragging
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        
        states: State {
            when: dragArea.isDragging
            
            ParentChange {
                target: content
                parent: app
            }
            
            AnchorChanges {
                target: content
                
                anchors {
                    horizontalCenter: undefined
                    verticalCenter: undefined
                }
            }
        }
        
        RowLayout {
            id: layout
            
            anchors {
                fill: parent
                margins: 6 * AppFramework.displayScaleFactor
            }

            spacing: 5 * AppFramework.displayScaleFactor

            Text {
                id: orderText

                Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 30 * AppFramework.displayScaleFactor

                text: dragArea.DelegateModel.itemsIndex + 1

                font: dragArea.font
                color: dragArea.isDragging
                       ? palette.brightText
                       : palette.text

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                visible: !isNull
                //opacity: isNull ? 0 : 1
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: -layout.anchors.margins
                Layout.bottomMargin: -layout.anchors.margins

                visible: orderText.visible
                color: dragArea.isDragging
                       ? palette.highlight
                       : palette.mid
            }

            Image {
                id: image

                Layout.preferredHeight: 30 * AppFramework.displayScaleFactor
                Layout.preferredWidth: 30 * AppFramework.displayScaleFactor

                visible: source > ""
                source: model.image
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 30 * AppFramework.displayScaleFactor

                text: model.label
                font: dragArea.font
                color: dragArea.isDragging
                       ? palette.brightText
                       : palette.text

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Item {
                Layout.preferredHeight: image.Layout.preferredHeight
                Layout.preferredWidth: image.Layout.preferredWidth

                visible: image.visible
            }
        }
    }
    
    //--------------------------------------------------------------------------

    DropArea {
        anchors {
            fill: parent
            margins: 10 * AppFramework.displayScaleFactor
        }
        
        onEntered: {
            var fromIndex = drag.source.DelegateModel.itemsIndex;
            var toIndex = dragArea.DelegateModel.itemsIndex;

            if (fromIndex !== toIndex) {
                items.move(fromIndex, toIndex);
            }
        }
    }

    //--------------------------------------------------------------------------
}
