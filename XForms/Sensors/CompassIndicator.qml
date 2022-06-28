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
import QtGraphicalEffects 1.0
import QtQuick.Shapes 1.13

import ArcGIS.AppFramework 1.0

Item {
    id: control

    //--------------------------------------------------------------------------

    property font font: Qt.application.font
    property color color: "black"
    property color borderColor: "#eee"
    property color minorTickColor: "#aaa"
    property color majorTickColor: color
    property alias faceColor: backgroundRect.color
    property real azimuth: 0

    property alias rotationAnimation: rotationAnimation
    property real northTickHeight: 15 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    readonly property var kCardinals: [
        qsTr("N"),
        qsTr("E"),
        qsTr("S"),
        qsTr("W")
    ]

    //--------------------------------------------------------------------------

    implicitWidth: 100
    implicitHeight: 100

    //--------------------------------------------------------------------------

    Rectangle {
        id: backgroundRect

        anchors {
            fill: parent
            margins: face.anchors.margins
        }

        color: "white"
        radius: height / 2

        border {
            width: 2 * AppFramework.displayScaleFactor
            color: borderColor
        }

        Item {
            anchors {
                fill: parent
                margins: parent.height * 0.3
            }

            Rectangle {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }

                color: "#333"
                implicitHeight: 1 * AppFramework.displayScaleFactor
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    bottom: parent.bottom
                }

                color: "#333"
                implicitWidth: 1 * AppFramework.displayScaleFactor
            }
        }
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        width: 3 * AppFramework.displayScaleFactor
        height: face.anchors.margins + 5 * AppFramework.displayScaleFactor
        color: "#555"
    }

    //--------------------------------------------------------------------------

    Item {
        id: face

        anchors {
            fill: parent
            margins: triShape.height + triShape.anchors.bottomMargin
        }

        rotation: isFinite(azimuth) ? -azimuth : 0

        Behavior on rotation {
            id: rotationAnimation

            RotationAnimation {

                duration: 250
                direction: RotationAnimation.Shortest
                easing.type: Easing.InOutQuad
            }
        }

        Shape {
            id: triShape

            height: northTickHeight
            width: height

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: 3 * AppFramework.displayScaleFactor
            }

            ShapePath {
                id: triPath

                strokeColor: "#ddd"
                strokeWidth: 1
                fillColor: "red"
                startX: triShape.width / 2
                startY: 0

                PathLine { x: triShape.width; y: triShape.height }
                PathLine { x: 0; y: triShape.height }
                PathLine { x: triPath.startX; y: triPath.startY }
            }
        }

        //--------------------------------------------------------------------------

        Canvas {
            anchors.fill: parent

            onPaint: {
                var ctx = getContext('2d');

                ctx.save();
                ctx.reset();

                paintTicks(ctx, 22.5/2, minorTickColor, 1, 0.1);
                paintTicks(ctx, 45, majorTickColor, 3, 0.1);
                //paintTicks(ctx, 90, control.color, 3, 0.1);

                paintLabels(ctx, control.color);

                ctx.restore();
            }

            function paintLabels(ctx, color) {

                var px = Math.round(width / 2 * 0.2);

                ctx.font = "normal %1px \"%2\"".arg(px).arg(font.family);
                ctx.textAlign = "center";
                ctx.textBaseline = "top";
                ctx.fillStyle = color;

                enumerateTicks(90, 0.9, 0, function (p1, p2, i, angle) {
                    ctx.save();
                    ctx.translate(p1.x, p1.y);
                    ctx.rotate(toRadians(angle));

                    ctx.fillText(kCardinals[i], 0, 0);

                    ctx.restore();
                });
            }

            function paintTicks(ctx, step, color, lineWidth, length, callback) {

                ctx.strokeStyle = color;
                ctx.lineWidth = lineWidth * AppFramework.displayScaleFactor;

                ctx.beginPath();

                enumerateTicks(step, 1, 1 - length, function (p1, p2) {
                    ctx.moveTo(p1.x, p1.y);
                    ctx.lineTo(p2.x, p2.y);
                });

                ctx.stroke();
            }

            function enumerateTicks(step, r1, r2, callback) {
                var r = width / 2;

                for (var a = 0, i = 0; a < 360; a += step, i++) {
                    var p1 = toAngleRadius(a, r * r1);
                    var p2 = toAngleRadius(a, r * r2);

                    callback(p1, p2, i, a);
                }
            }

            function toAngleRadius(angle, radius) {
                var px = x + width / 2 + Math.sin(toRadians(angle)) * radius;
                var py = y + height / 2 - Math.cos(toRadians(angle)) * radius;

                return Qt.point(px, py);
            }
        }
    }

    //--------------------------------------------------------------------------

    function toRadians(degrees) {
        return Math.PI * degrees / 180.0;
    }

    //--------------------------------------------------------------------------
}
