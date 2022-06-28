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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "Singletons"

AbstractButton {
    id: control

    //--------------------------------------------------------------------------

    property var fromPosition
    readonly property var fromCoordinate: fromPosition ? fromPosition.coordinate : null
    property var toCoordinate
    property bool isValid: !!fromCoordinate
                           && !!toCoordinate
                           && fromCoordinate.isValid
                           && toCoordinate.isValid
    readonly property double distance: isValid ? Math.round(fromCoordinate.distanceTo(toCoordinate) * 10) / 10 : Number.NaN
    readonly property double azimuth: isValid ? fromCoordinate.azimuthTo(toCoordinate) : Number.NaN
    readonly property bool directionValid: !!fromPosition && !!fromPosition.directionValid
    readonly property double direction: directionValid ? fromPosition.direction : 0
    property int measurementSystem
    property int iconSize: 25 * AppFramework.displayScaleFactor
    property real shortDistanceThreshold: 1
    property real distanceThreshold: !!fromPosition && fromPosition.horizontalAccuracyValid && fromPosition.horizontalAccuracy > 0
                                     ? fromPosition.horizontalAccuracy
                                     : 5
    readonly property bool isWithinDistanceThreshold: distance <= distanceThreshold
    readonly property bool isWithinShortDistance: distance <= shortDistanceThreshold

    readonly property bool hasAzimuth: isFinite(azimuth)
    readonly property real pointerAngle: hasAzimuth && directionValid
                                         ? (azimuth - direction + 720) % 360
                                         : 0

    property real compassAzimuth: Number.NaN
    readonly property bool compassAzimuthValid: isFinite(compassAzimuth)
    property real compassThreshold: 500

    //--------------------------------------------------------------------------

    readonly property string kIconNameArrow: "compass"
    readonly property string kIconNameArrowCircle: "compass-north-circle"
    readonly property string kIconNamePin: "pin"

    //--------------------------------------------------------------------------

    implicitWidth: 50 * AppFramework.displayScaleFactor

    enabled: isValid

    font {
        pointSize: 10
    }

    palette {
        text: "#ccc"
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        color: "transparent"

        MouseArea {
            anchors.fill: parent

            enabled: control.enabled
            hoverEnabled: enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            acceptedButtons: Qt.NoButton
        }
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        spacing: 2 * AppFramework.displayScaleFactor
        visible: isValid


        Item {
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
            Layout.alignment: Qt.AlignHCenter

            /*
            Image {
                anchors.fill: parent

                visible: compassAzimuthValid && hasAzimuth

                source: "images/compass-view.png"
                rotation: compassAzimuthValid ? (azimuth - compassAzimuth + 720) % 360 : 0
                asynchronous: true

                scale: 2

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 8
                    }

                    radius: height / 2
                }

                Behavior on rotation {
                    enabled: true
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                    }
                }
            }
*/

            Item {
                id: compassIndicator

                anchors.fill: parent

                visible: compassAzimuthValid && hasAzimuth && distance <= compassThreshold

                rotation: compassAzimuthValid ? (azimuth - compassAzimuth + 720) % 360 : 0

                Glyph {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.top
                    }

                    name: "chevron-up"
                    color: palette.windowText
                    height: 15
                }

//                Rectangle {
//                    anchors {
//                        horizontalCenter: parent.horizontalCenter
//                        verticalCenter: parent.top
//                    }

//                    color: "red"

//                    height: 5
//                    width: height
//                    radius: height / 2
//                }

                Behavior on rotation {
                    enabled: true
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                    }
                }
            }


//            Rectangle {
//                id: compassIndicator

//                anchors.fill: parent

//                visible: compassAzimuthValid && hasAzimuth
//                rotation: compassAzimuthValid ? (azimuth - compassAzimuth + 720) % 360 : 0

//                color: "#eee"
//                radius: height / 2
//            }

//            Canvas {
//                id: compassIndicator

//                anchors.fill: parent

//                visible: compassAzimuthValid && hasAzimuth
//                rotation: -90 //compassAzimuthValid ? (azimuth - compassAzimuth + 720 - 90) % 360 : 0

//                onPaint: {
//                    var ctx = getContext("2d");
//                    //ctx.reset();
//                    ctx.fillStyle = "#ddd";
//                    ctx.moveTo(width / 2, height / 2);
//                    ctx.arc(width / 2, height / 2, width / 2, Math.PI * -0.2, Math.PI * 0.2);
//                    ctx.closePath();
//                    ctx.fill();
//                }
//            }

            Glyph {
                anchors.fill: parent

                visible: isWithinShortDistance
                palette: control.palette
                name: kIconNamePin
            }

            Glyph {
                anchors.fill: parent

                padding: compassIndicator.visible && !isWithinShortDistance ? 3 : 0
                visible: hasAzimuth && directionValid && !isWithinShortDistance

                rotation: pointerAngle
                palette: control.palette
                name: isWithinDistanceThreshold
                      ? kIconNameArrowCircle
                      : kIconNameArrow

                Behavior on rotation {
                    RotationAnimation {
                        duration: 250
                        direction: RotationAnimation.Shortest
                    }
                }
            }

//            Glyph {
//                id: compassIndicator

//                anchors.fill: parent

//                visible: compassAzimuthValid && hasAzimuth
//                rotation: compassAzimuthValid ? (azimuth - compassAzimuth + 720) % 360 : 0

//                palette: control.palette
//                name: "circle"
//            }

            /*
            Glyph {
                anchors.fill: parent

                visible: compassAzimuthValid && hasAzimuth
                rotation: compassAzimuthValid ? (azimuth - compassAzimuth + 720) % 360 : 0
                name: "compass-needle"
                color: "red"

                Behavior on rotation {
                    RotationAnimation {
                        duration: 250
                        direction: RotationAnimation.Shortest
                    }
                }
            }
            */

            Text {
                anchors.fill: parent

                visible: hasAzimuth && !directionValid && !isWithinShortDistance

                text: Units.cardinalDirectionName(azimuth)
                color: palette.windowText
                font {
                    pointSize: 13
                    //italic: isWithinDistanceThreshold
                    bold: control.font.bold
                    family: control.font.family
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            Layout.fillWidth: true

            text: Units.distanceText(distance, measurementSystem)
            color: palette.windowText

            font: control.font
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: font.pointSize * 0.8
            horizontalAlignment: Text.AlignHCenter
            elide: ControlsSingleton.localeProperties.textElide
        }
    }

    //--------------------------------------------------------------------------

    function positionValue(position, name, defaultValue) {
        if (!position) {
            return defaultValue;
        }

        return position[name + "Valid"] ? position[name] : defaultValue;
    }

    //--------------------------------------------------------------------------
}
