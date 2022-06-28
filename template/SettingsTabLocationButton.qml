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

import QtQuick 2.9
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: control

    //--------------------------------------------------------------------------

    property string text

    property string fontFamily: app.fontFamily
    property color iconColor: app.textColor
    property color textColor: app.textColor
    property color hoverBackgroundColor: "#e1f0fb"
    property color backgroundColor: "#FAFAFA"

    //--------------------------------------------------------------------------

    signal clicked();

    //--------------------------------------------------------------------------

    color: mouseArea.containsMouse ? hoverBackgroundColor : backgroundColor

    //--------------------------------------------------------------------------

    RowLayout {
        id: rowLayout

        anchors.fill: parent

        Item {
            Layout.preferredWidth: 10 * AppFramework.displayScaleFactor
            Layout.fillHeight: true
        }

        IconImage {
            id: iconImage

            Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            icon {
                name: "plus"
                color: iconColor
            }
        }

        Text {
            Layout.fillWidth: true

            text: control.text
            color: textColor

            font {
                pointSize: 16
                family: fontFamily
                bold: false
            }

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        IconImage {
            Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            icon {
                name: "chevron-right"
                color: iconColor
            }
        }

        Item {
            Layout.preferredWidth: 10 * AppFramework.displayScaleFactor
            Layout.fillHeight: true
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            control.clicked();
        }
    }

    //--------------------------------------------------------------------------
}

