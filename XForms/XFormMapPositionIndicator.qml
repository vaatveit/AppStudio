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
import QtLocation 5.12
import QtPositioning 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"
import "Singletons"

MapItemGroup{
    id: positionIndicator

    //--------------------------------------------------------------------------

    property XFormPositionSourceConnection positionSourceConnection
    property real horizontalAccuracy: 0
    property bool horizontalAccuracyValid
    property alias showCrosshairs: crosshairs.visible

    property var coordinate: QtPositioning.coordinate()
    property real mapBearing
    property real direction
    property bool directionValid
    property real azimuth: Number.NaN
    property bool azimuthValid: isFinite(azimuth)

    property string markerFontFamily: MapSymbols.icons.font.family
    property string kGlyphCompassNorth: MapSymbols.icons.glyphChar("compass-north-f")
    property string kGlyphCircle: MapSymbols.icons.glyphChar("circle-filled")

    property real markerSize: 20 * AppFramework.displayScaleFactor
    property real ringSize: 30 * AppFramework.displayScaleFactor

    property int animationDuration: 1000
    property int animationEasingType: Easing.Linear

    //--------------------------------------------------------------------------

    visible: positionSourceConnection.active

    //--------------------------------------------------------------------------

    MapCircle {
        visible: horizontalAccuracyValid

        center: positionIndicator.coordinate
        radius: horizontalAccuracy

        color: "#00b2ff"
        border {
            color: "transparent"
            width: 0
        }
        opacity: 0.1

        Behavior on center {
            CoordinateAnimation {
                duration: animationDuration
                easing.type: animationEasingType
            }
        }
    }

    //--------------------------------------------------------------------------

    MapQuickItem {
        visible: positionSourceConnection.active && azimuthValid
        coordinate: positionIndicator.coordinate

        anchorPoint {
            x: azimuthItem.width / 2
            y: azimuthItem.height / 2
        }

        sourceItem: Item {
            id: azimuthItem

            width: markerSize * 4
            height: width

            Image {
                anchors.fill: parent

                source: "MapControls/images/compass-view.png"
                rotation: azimuthValid ? (azimuth - mapBearing + 720) % 360 : 0
                asynchronous: true

                Behavior on rotation {
                    enabled: false
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                    }
                }
            }
        }

        Behavior on coordinate {
            CoordinateAnimation {
                duration: animationDuration
                easing.type: animationEasingType
            }
        }
    }

    //--------------------------------------------------------------------------

    MapQuickItem {
        visible: positionSourceConnection.active
        coordinate: positionIndicator.coordinate

        anchorPoint {
            x: ringItem.width / 2
            y: ringItem.height / 2
        }

        sourceItem: Rectangle {
            id: ringItem

            width: ringSize
            height: width

            color: "transparent"
            radius: height / 2
            border {
                color: "#00b2ff" //"#468df5"
                width: 1//2 * AppFramework.displayScaleFactor
            }

            SequentialAnimation on width {
                loops: Animation.Infinite

                PropertyAnimation {
                    id: outAnimation

                    from: ringSize
                    to: ringSize * 2
                    duration: 1500
                }

                PropertyAnimation {
                    from: outAnimation.to
                    to: outAnimation.from
                    duration: outAnimation.duration
                }
            }
        }

        Behavior on coordinate {
            CoordinateAnimation {
                duration: animationDuration
                easing.type: animationEasingType
            }
        }
    }

    //--------------------------------------------------------------------------

    MapQuickItem {
        visible: positionSourceConnection.active
        coordinate: positionIndicator.coordinate

        anchorPoint {
            x: markerItem.width / 2
            y: markerItem.height / 2
        }

        sourceItem: Item {
            id: markerItem

            width: markerSize
            height: width

            Text {
                anchors.centerIn: parent

                text: directionValid ? kGlyphCompassNorth : kGlyphCircle
                color: "#3378bb"
                rotation: directionValid ? (direction - mapBearing + 720) % 360 : 0
                font {
                    family: markerFontFamily
                    pixelSize: markerItem.height
                }
                style: Text.Outline
                styleColor: "white"

                Behavior on rotation {
                    enabled: false
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                    }
                }
            }
        }

        Behavior on coordinate {
            CoordinateAnimation {
                duration: animationDuration
                easing.type: animationEasingType
            }
        }
    }

    //--------------------------------------------------------------------------

    MapQuickItem {
        id: crosshairs

        visible: false
        coordinate: positionIndicator.coordinate

        anchorPoint {
            x: crosshairsItem.width / 2
            y: crosshairsItem.height / 2
        }

        sourceItem: Item {
            id: crosshairsItem

            width: 15 * AppFramework.displayScaleFactor
            height: width

            Glow {
                anchors.fill: parent
                source: crosshairsImage

                color: "white"
                radius: 6 * AppFramework.displayScaleFactor
            }

            Item {
                id: crosshairsImage

                anchors.fill: parent

                Rectangle {
                    anchors.centerIn: parent

                    width: parent.width
                    height: 1 * AppFramework.displayScaleFactor
                    color: "black"
                }

                Rectangle {
                    anchors.centerIn: parent

                    width: 1 * AppFramework.displayScaleFactor
                    height: parent.height
                    color: "black"
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            positionIndicator.coordinate = position.coordinate;

            directionValid = position.directionValid;
            if (directionValid) {
                direction = position.direction;
            }

            horizontalAccuracyValid = position.horizontalAccuracyValid;
            if (horizontalAccuracyValid) {
                horizontalAccuracy = position.horizontalAccuracy;
            } else {
                horizontalAccuracy = -1;
            }
        }
    }

    //--------------------------------------------------------------------------
}
