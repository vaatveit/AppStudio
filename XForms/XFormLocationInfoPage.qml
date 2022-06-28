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

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtSensors 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "MapControls"

XFormPage {
    id: page

    //--------------------------------------------------------------------------

    default property alias contentData: tabView.contentItemData

    property string fontFamily: xform.style.fontFamily
    readonly property bool isLandscape: width > height

    property XFormPositionSourceManager positionSourceManager
    property alias positionSourceConnection: positionSourceConnection
    property bool isValidLocation

    readonly property bool showCompassData: positionSourceConnection.compassEnabled

    property bool debug: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: page.positionSourceManager
        listener: "XFormLocationInfoPage"

        onNewPosition: {
            isValidLocation = !!position.coordinate && position.coordinate.isValid;
        }
    }

    //--------------------------------------------------------------------------

    Row {
        anchors.fill: parent

        spacing: 0

        SwipeTabView {
            id: tabView

            width: mapView.visible ? parent.width / 2 : parent.width
            height: parent.height

            font.family: page.fontFamily
            interactive: false

            footerBackground {
                color: app.backgroundColor
            }

            footerSeparator {
                visible: true
                color: xform.style.titleBackgroundColor
            }

            tabs {
                interactive: true
                selectedTextColor: Colors.contrastColor(footerBackground.color)
                textColor: Colors.contrastColor(footerBackground.color, "#888", "#eee")
                showWhenOne: true
            }

            clip: true
        }

        Item {
            id: mapView

            width: parent.width / 2
            height: parent.height

            visible: isLandscape && isValidLocation

            LocationMap {
                anchors.fill: parent

                positionSourceConnection: page.positionSourceConnection
            }

            VerticalSeparator {
                anchors {
                    right: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
