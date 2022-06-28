/* Copyright 2019 Esri
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

import QtQuick 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: delegate

    //--------------------------------------------------------------------------

    property var listTabView

    property string fontFamily: app.fontFamily
    property color iconColor: app.textColor
    property color textColor: app.textColor
    property color hoverBackgroundColor: "#e1f0fb"

    //--------------------------------------------------------------------------

    width: ListView.view.width
    height: visible ? rowLayout.height + rowLayout.anchors.margins * 2 : 0

    visible: modelData.enabled
    color: mouseArea.containsMouse ? hoverBackgroundColor : "transparent"

    //--------------------------------------------------------------------------

    RowLayout {
        id: rowLayout

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        IconImage {
            id: iconImage

            Layout.preferredWidth: 45 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            icon {
                name: modelData.icon.name
                source: modelData.icon.source
                color: iconColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 3 * AppFramework.displayScaleFactor

            Text {
                Layout.fillWidth: true

                text: modelData.title
                color: textColor

                font {
                    pointSize: 16
                    family: fontFamily
                    bold: true
                }

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
            }

            Text {
                Layout.fillWidth: true

                text: modelData.description
                color: textColor
                visible: text > ""

                font {
                    pointSize: 12
                    family: fontFamily
                }

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
            }
        }

        IconImage {
            Layout.preferredWidth: 25 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            icon {
                name: "chevron-right"
                color: iconColor
            }
        }
    }

    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            listTabView.selected(modelData);
        }
    }

    //--------------------------------------------------------------------------
}

