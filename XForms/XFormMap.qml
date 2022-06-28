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
import QtLocation 5.13
import QtPositioning 5.13
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "MapControls"
import "XFormGeometry.js" as Geometry

Map {
    id: map

    //--------------------------------------------------------------------------

    property XFormPositionSourceConnection positionSourceConnection
    property int positionMode: XFormMap.PositionMode.On

    property alias positionIndicator: positionIndicator
    property alias mapControls: mapControls

    property XFormMapSettings mapSettings

    property color backgroundColor: "#e6e6e6"
    property alias skyColor: skyGradientStop.color

    property LocaleProperties localeProperties: xform.localeProperties

    property alias scaleBar: scaleBar
    property alias northArrow: northArrow

    property bool animationEnabled: true
    property real panAnimationThreshold: 100000

    readonly property real compassAzimuth: positionSourceConnection
                                    ? positionSourceConnection.compassTrueAzimuth
                                    : Number.NaN
    readonly property bool compassAzimuthValid: isFinite(compassAzimuth)

    property bool debug: false

    //--------------------------------------------------------------------------

    enum PositionMode {
        Off = 0,
        On = 1,
        AutoPan = 2,
        AutoPanDirectionUp = 3,
        AutoPanAzimuthUp = 4
    }

    //--------------------------------------------------------------------------

    signal mapTypeChanged(var mapType)

    //--------------------------------------------------------------------------

    gesture {
        //activeGestures: MapGestureArea.ZoomGesture | MapGestureArea.PanGesture
        enabled: true
    }
    
    color: tilt > 0 ? "transparent" : backgroundColor

    //--------------------------------------------------------------------------

    gesture.onPinchStarted: {
        positionMode = XFormMap.PositionMode.On;
    }

    gesture.onPanStarted: {
        positionMode = XFormMap.PositionMode.On;
    }

    gesture.onFlickStarted: {
        positionMode = XFormMap.PositionMode.On;
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        mapSourcesParameter.bind(mapSettings);
    }

    //--------------------------------------------------------------------------

    onCopyrightLinkActivated: {
        Qt.openUrlExternally(link);
    }

    //--------------------------------------------------------------------------

    onActiveMapTypeChanged: { // TODO Remove force update of min/max zoom levels
        minimumZoomLevel = -1;
        maximumZoomLevel = 9999;
    }

    //--------------------------------------------------------------------------

    onPositionModeChanged: {
        if (positionMode === XFormMap.PositionMode.AutoPanAzimuthUp) {
            map.bearing = Qt.binding(function () {
                return compassAzimuthValid
                        ? Math.round(compassAzimuth)
                        : 0;
            });
        } else {
            map.bearing = 0;
        }
    }

    //--------------------------------------------------------------------------

    Behavior on zoomLevel {
        id: zoomLevelBehaviour

        enabled: animationEnabled && map.mapReady

        NumberAnimation {
            easing.type: Easing.OutQuad
            duration: 250
        }
    }

    Behavior on center {
        id: centerBehavior

        enabled: animationEnabled && map.mapReady

        CoordinateAnimation {
            duration: positionMode >= XFormMap.PositionMode.AutoPan
                      ? 1000
                      : 250
            //easing.type: Easing.OutCubic
        }
    }

    Behavior on tilt {
        enabled: animationEnabled

        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on bearing {
        enabled: animationEnabled

        RotationAnimation {
            duration: positionMode >= XFormMap.PositionMode.AutoPan
                      ? 1000
                      : 250

            direction: RotationAnimation.Shortest
            easing.type: Easing.InOutQuad
        }
    }

    //--------------------------------------------------------------------------

    function delayAnimation(delay) {
        animationEnabled = false;
        Global.setTimeout(() => {
                              animationEnabled = true;
                          },
                          delay > 0 ? delay : 250);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(map, true)
    }

    //--------------------------------------------------------------------------

    XFormMapSourcesParameter {
        id: mapSourcesParameter
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            if (positionMode >= XFormMap.PositionMode.AutoPan) {
                panTo(position.coordinate);

                if (positionMode === XFormMap.PositionMode.AutoPanDirectionUp) {
                    if (position.directionValid) {
                        map.bearing = position.direction;
                    } else {
                        map.bearing = 0;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    RadialGradient {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: map.tilt / 90 * parent.height

        visible: map.tilt > 0
        angle: 270
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(skyGradientStop.color, 1.5)
            }

            GradientStop {
                id: skyGradientStop
                position: 0.5
                color: "#91c7e9"
            }
        }

        z: parent.z - 1
    }

    //--------------------------------------------------------------------------

    XFormMapControls {
        id: mapControls
        
        anchors {
            left: localeProperties.layoutDirection == Qt.RightToLeft ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.LeftToRight ? parent.right : undefined
            margins: 10 * AppFramework.displayScaleFactor
            verticalCenter: parent.verticalCenter
        }
        
        map: parent
        mapSettings: parent.mapSettings
        positionSourceConnection: map.positionSourceConnection
        z: 9999
        azimuthValid: map.compassAzimuthValid

        onMapTypeChanged: {
            map.mapTypeChanged(mapType);
        }

        onScaleRequested: {
            scaleBar.visible = !scaleBar.visible;
        }
    }

    //--------------------------------------------------------------------------

    NorthArrow {
        id: northArrow

        anchors {
            left: localeProperties.layoutDirection == Qt.LeftToRight ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.RightToLeft ? parent.right : undefined
            top: parent.top
            margins: 5 * AppFramework.displayScaleFactor
        }

        onClicked: {
            if (positionMode > XFormMap.PositionMode.AutoPan) {
                positionMode = XFormMap.PositionMode.AutoPan;
            }

            map.bearing = 0;
        }
    }

    //--------------------------------------------------------------------------

    MapScaleBar {
        id: scaleBar

        anchors {
            left: localeProperties.layoutDirection == Qt.LeftToRight ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.RightToLeft ? parent.right : undefined
            bottom: parent.bottom
            margins: 25 * AppFramework.displayScaleFactor
        }

        visible: false
    }

    //--------------------------------------------------------------------------

    XFormMapPositionIndicator {
        id: positionIndicator

        positionSourceConnection: map.positionSourceConnection
        mapBearing: map.bearing
        azimuth: Math.round(compassAzimuth)
    }

    //--------------------------------------------------------------------------

    function zoomToDefault() {
        if (mapSettings.zoomLevel > 0) {
            console.log(logCategory, arguments.callee.name, "homeZoomLevel:", mapSettings.homeZoomLevel);
            map.zoomLevel = mapSettings.zoomLevel;
        } else if (map.zoomLevel < mapSettings.defaultZoomLevel) {
            console.log(logCategory, arguments.callee.name, "defaultZoomLevel:", mapSettings.defaultZoomLevel);
            map.zoomLevel = mapSettings.defaultZoomLevel;
        }

        if (mapSettings.homeCoordinate.isValid) {
            console.log(logCategory, arguments.callee.name, "homeCoordinate:", mapSettings.homeCoordinate);
            panTo(mapSettings.homeCoordinate);
        }
    }

    //--------------------------------------------------------------------------

    function zoomToRectangle(rectangle, centerZoomLevel) {
        rectangle = Geometry.cloneRectangle(rectangle);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "rectangle:", rectangle, "zoomLevel:", centerZoomLevel);
        }

        function doZoom() {

            if (rectangle.width > 0 && rectangle.height > 0) {
                if (map.center.distanceTo(rectangle.center) > panAnimationThreshold) {
                    delayAnimation();
                }

                if (debug) {
                    console.log(logCategory, arguments.callee.name, "rectangle:", rectangle);
                }

                rectangle.width *= 1.1;
                rectangle.height *= 1.1;

                visibleRegion = rectangle;
            } else if (rectangle.center.isValid) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "center:", rectangle.center, "zoomLevel:", centerZoomLevel);
                }

                panTo(rectangle.center);
                map.zoomLevel = centerZoomLevel;
            }
        }

        Qt.callLater(doZoom);
    }

    //--------------------------------------------------------------------------

    function zoomToCoordinate(coordinate, zoomLevel) {
        if (!coordinate || !coordinate.isValid) {
            return;
        }

        if (typeof zoomLevel === "undefined") {
            if (mapSettings.previewZoomLevel) {
                zoomLevel = mapSettings.previewZoomLevel;
            }
        }

        function doZoom() {
            panTo(coordinate, zoomLevel);
        }

        Qt.callLater(doZoom);
    }

    //--------------------------------------------------------------------------

    function panTo(coordinate, zoomLevel) {
        if (!coordinate || !coordinate.isValid) {
            return;
        }

        if (map.center.distanceTo(coordinate) > panAnimationThreshold) {
            delayAnimation();
        }

        map.center = coordinate;

        if (zoomLevel !== undefined) {
            map.zoomLevel = zoomLevel;
        }
    }

    //--------------------------------------------------------------------------
}
