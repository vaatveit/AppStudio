/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Layouts 1.3
import ArcGIS.AppFramework 1.0

Item {
    id: button

    property alias source: image.source
    property color color: checkable ? checked ? checkedColor : uncheckedColor : "transparent"
    property color checkedColor: "black"
    property color uncheckedColor: "#c0c0c0"

    property bool hasDropdown: false

    property bool checkable
    property bool checked

    signal clicked(var mouse);
    signal pressAndHold(var mouse);

    ColumnLayout {
        anchors.fill: parent
        spacing: 1 * AppFramework.displayScaleFactor
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            StyledImage {
                id: image
                color: button.color
                anchors.fill: parent
            }
        }
        Item {
            visible: hasDropdown
            Layout.fillWidth: true
            Layout.preferredHeight: (10 * AppFramework.displayScaleFactor) * xform.style.textScaleFactor
            Layout.maximumHeight: 16 * AppFramework.displayScaleFactor
            Layout.minimumHeight: 10 * AppFramework.displayScaleFactor
            StyledImage {
                id: drowdownArrow
                color: button.color
                anchors.fill: parent
                source: "images/caret.png"
                rotation: 90
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            button.clicked(mouse);
        }

        onPressAndHold: {
            button.pressAndHold(mouse);
        }
    }
}
