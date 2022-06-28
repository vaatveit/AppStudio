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

import "../Controls"
import "../Controls/Singletons"
import "MapControls"

import "XForm.js" as XFormJS
import "XFormGeometry.js" as Geometry

XFormButtonBarLayout {
    id: buttonBar

    //--------------------------------------------------------------------------

    property Map map: null
    property XFormMapSettings mapSettings
    property XFormPositionSourceConnection positionSourceConnection

    property real size: 40
    property real zoomRatio: 2
    property real zoomStep: 0.5

    readonly property int buttonSize: xform.style.buttonBarSize

    property alias homeButton: homeButton
    property alias positionButton: positionButton
    property alias zoomToButton: zoomToButton

    property Component mapTypesPopup: defaultMapTypesPopup
    property Item popupParent: buttonBar.map.parent

    property bool showZoomLevel: false
    property bool showZoomTo: false
    property bool showPositionInfo: true
    property int positionInfo: XFormMapControls.PositionInfo.Accuracy

    property bool azimuthValid
    property alias minimumPositionMode: positionButton.minimumPositionMode
    property alias maximumPositionMode: positionButton.maximumPositionMode

    //--------------------------------------------------------------------------

    enum PositionInfo {
        Accuracy = 0,
        Speed = 1,

        Count = 2
    }

    //--------------------------------------------------------------------------

    signal positionRequested()
    signal homeRequested()
    signal scaleRequested()
    signal mapTypeChanged(MapType mapType)
    signal zoomTo()

    //--------------------------------------------------------------------------

    orientation: Qt.Vertical
    spacing: 15 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            positionButton.position = position;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize * 0.75
        Layout.preferredHeight: Layout.preferredWidth
        Layout.topMargin: 10 * AppFramework.displayScaleFactor

        icon.name: "basemap"

        onClicked: {
            fader.start();

            var popup = mapTypesPopup.createObject(buttonBar);
            popup.open();
        }

        onPressAndHold: {
            showZoomLevel = !showZoomLevel;

            fader.start();
        }
    }

    //--------------------------------------------------------------------------

    Text {
        Layout.preferredWidth: buttonSize

        visible: showZoomLevel
        text: "%1".arg(Math.round(map.zoomLevel * 10) / 10)

        color: xform.style.buttonColor
        fontSizeMode: Text.HorizontalFit
        font {
            pointSize: 16
            bold: true
            family: xform.style.fontFamily
        }
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onClicked: {
                fader.start();
                scaleRequested();
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        icon.name: "plus"
        enabled: map.zoomLevel < map.maximumZoomLevel

        onClicked: {
            fader.start();
            //map.zoomToScale (map.mapScale / zoomRatio);
            map.zoomLevel += zoomStep;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: homeButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize * 0.8
        Layout.preferredHeight: Layout.preferredWidth

        icon.name: "home"
        visible: mapSettings.homeCoordinate.isValid

        onClicked: {
            fader.start();

            map.positionMode = XFormMap.PositionMode.On;

            if (mapSettings.homeZoomLevel > 0) {
                console.log(logCategory, "Home zoom level:", mapSettings.homeZoomLevel);
                map.zoomLevel = mapSettings.homeZoomLevel;
            } else if (map.zoomLevel < mapSettings.defaultZoomLevel) {
                console.log(logCategory, "Home zoom to default level:", mapSettings.defaultZoomLevel);
                map.zoomLevel = mapSettings.defaultZoomLevel;
            }

            if (mapSettings.homeCoordinate.isValid) {
                console.log(logCategory, "Home zoom to:", mapSettings.homeCoordinate);
                map.panTo(mapSettings.homeCoordinate);
            }

            homeRequested();
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: zoomToButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize * 0.8
        Layout.preferredHeight: Layout.preferredWidth

        icon.name:  "zoom-to-object"

        visible: showZoomTo

        onClicked: {
            fader.start();
            zoomTo();
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        icon.name: "minus"
        enabled: map.zoomLevel > map.minimumZoomLevel

        onClicked: {
            fader.start();

            //            map.zoomToScale (map.mapScale * zoomRatio);
            map.zoomLevel -= zoomStep;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: positionButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        property bool isActive: positionSourceConnection && positionSourceConnection.active
        property int minimumPositionMode: XFormMap.PositionMode.On
        property int maximumPositionMode: azimuthValid
                                          ? XFormMap.PositionMode.AutoPanAzimuthUp
                                          : XFormMap.PositionMode.AutoPanDirectionUp

        property var position: ({})
        property var coordinate: mapSettings.homeCoordinate
        property real minimumZoomLevel: 3

        visible: positionSourceConnection && positionSourceConnection.valid

        icon.name: modeIconName(isActive ? map.positionMode : XFormMap.PositionMode.Off)
        padding: modePadding(isActive ? map.positionMode : XFormMap.PositionMode.Off)

        onPositionChanged: {
            coordinate = Geometry.cloneCoordinate(position.coordinate);
        }

        onPressAndHold: {
            if (positionSourceConnection.active) {
                positionSourceConnection.stop();
            }

            fader.start();
            map.bearing = 0;
        }

        onClicked: {
            positionRequested();

            if (positionSourceConnection.active) {
                var mode = map.positionMode + 1;
                if (mode > maximumPositionMode) {
                    map.positionMode = minimumPositionMode;
                } else {
                    map.positionMode = mode;

                    if (coordinate.isValid) {
                        map.center = coordinate;
                    }

                    if (map.zoomLevel < minimumZoomLevel) {
                        map.zoomLevel = minimumZoomLevel;
                    }
                }
            } else {
                map.positionMode = XFormMap.PositionMode.AutoPan;
                map.bearing = 0;

                if (coordinate.isValid) {
                    map.center = coordinate;
                }

                if (map.zoomLevel < minimumZoomLevel) {
                    map.zoomLevel = minimumZoomLevel;
                }

                position = {};
                positionSourceConnection.start();
            }

            fader.start();
        }

        PulseAnimation {
            target: positionButton
            running: positionButton.isActive
                     && !positionButton.position.coordinate
        }

        function modeIconName(mode) {
            switch (mode) {
            case XFormMap.PositionMode.Off :
                return "gps-off";

            case XFormMap.PositionMode.On :
                return "gps-on";

            case XFormMap.PositionMode.AutoPan :
                return "gps-on-f";

            case XFormMap.PositionMode.AutoPanDirectionUp :
                return "compass";

            case XFormMap.PositionMode.AutoPanAzimuthUp :
                return "compass-needle";
            }
        }

        function modePadding(mode) {
            switch (mode) {
            case XFormMap.PositionMode.Off :
            case XFormMap.PositionMode.On :
                return 2 * AppFramework.displayScaleFactor;

            default:
                return 4 * AppFramework.displayScaleFactor;
            }
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(buttonBar, true)
    }

    //--------------------------------------------------------------------------

    Text {
        Layout.preferredWidth: buttonSize
        Layout.topMargin: -buttonBar.spacing
        Layout.bottomMargin: buttonBar.spacing * 0.75

        property alias position: positionButton.position

        visible: showPositionInfo
                 && positionButton.isActive
                 && positionInfo === XFormMapControls.PositionInfo.Accuracy
                 && map.positionMode >= XFormMap.PositionMode.On
                 && !!position.horizontalAccuracyValid
                 && position.horizontalAccuracy > 0
                 && !!text

        text: isFinite(position.horizontalAccuracy)
              ? /*±*/ "%1 m".arg(XFormJS.round(position.horizontalAccuracy, position.horizontalAccuracy < 1
                                               ? mapSettings.horizontalAccuracyPrecisionHigh
                                               : mapSettings.horizontalAccuracyPrecisionLow))
              : ""

        color: xform.style.buttonColor
        fontSizeMode: Text.HorizontalFit
        minimumPointSize: 8
        font {
            pointSize: 12
            bold: true
            family: xform.style.fontFamily
        }
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onPressAndHold: {
                positionInfo = (positionInfo + 1) % XFormMapControls.PositionInfo.Count;
            }
        }
    }

    //--------------------------------------------------------------------------

    Text {
        Layout.preferredWidth: buttonSize
        Layout.topMargin: -buttonBar.spacing
        Layout.bottomMargin: buttonBar.spacing * 0.75

        property alias position: positionButton.position

        visible: showPositionInfo
                 && positionButton.isActive
                 && positionInfo === XFormMapControls.PositionInfo.Speed
                 && map.positionMode >= XFormMap.PositionMode.On
                 && !!position.speedValid
                 && !!text

        text: isFinite(position.speed)
              ? XFormJS.toLocaleSpeedString(position.speed, xform.localeProperties.numberLocale)
              : ""

        color: xform.style.buttonColor
        fontSizeMode: Text.HorizontalFit
        minimumPointSize: 8
        font {
            pointSize: 12
            bold: true
            family: xform.style.fontFamily
        }

        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onPressAndHold: {
                positionInfo = (positionInfo + 1) % XFormMapControls.PositionInfo.Count;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: defaultMapTypesPopup

        MapTypesPopup {
            parent: popupParent

            map: buttonBar.map

            onMapTypeChanged: {
                buttonBar.mapTypeChanged(mapType);
            }
        }
    }

    //--------------------------------------------------------------------------
}
