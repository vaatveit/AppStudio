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
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../XForms/Singletons"
import "../XForms/MapControls"
import "../XForms/XFormGeometry.js" as Geometry
import "SurveyHelper.js" as Helper
import "../Controls"
import "../Controls/Singletons"
import "Singletons"

Item {
    id: collectOverlay

    //--------------------------------------------------------------------------

    property XFormMap map: parent
    property string geometryType

    property bool isCollecting: false

    //--------------------------------------------------------------------------

    signal collect(var geometry)

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        
        enabled: isCollecting
        visible: enabled
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            var coordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y));
            map.center = coordinate;
        }
    }

    //--------------------------------------------------------------------------

    MapCrosshairs {
        visible: isCollecting
    }

    ButtonBar {
        id: toolBar

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            margins: 10 * AppFramework.displayScaleFactor
        }

        palette {
            button: Survey.kColorCollect
            buttonText: "white"
        }

        fader {
            enabled: !isCollecting
        }

        StyledImageButton {
            implicitWidth: toolBar.buttonSize
            implicitHeight: toolBar.buttonSize

            padding: 4 * AppFramework.displayScaleFactor
            visible: isCollecting
            source: Icons.icon("x")
            color: toolBar.palette.buttonText

            onClicked: {
                isCollecting = false;
            }
        }

        StyledImageButton {
            id: collectButton

            implicitWidth: toolBar.buttonSize
            implicitHeight: toolBar.buttonSize

            enabled: !isCollecting
            source: Icons.icon(isCollecting ? "pin" : "pin-plus")
            color: toolBar.palette.buttonText

            onClicked: {
                isCollecting = true;
            }
        }

        StyledImageButton {
            implicitWidth: toolBar.buttonSize
            implicitHeight: toolBar.buttonSize

            visible: isCollecting
            source: Icons.icon("check")
            color: toolBar.palette.buttonText

            onClicked: {
                isCollecting = false;

                var geometry = {
                    x: map.center.longitude,
                    y: map.center.latitude
                }

                collect(geometry);
            }
        }
    }

    //--------------------------------------------------------------------------

    PulseAnimation {
        target: collectButton
        running: isCollecting
    }

    //--------------------------------------------------------------------------
}
