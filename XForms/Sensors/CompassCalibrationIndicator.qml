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
import QtGraphicalEffects 1.0
import QtQuick.Shapes 1.13

import ArcGIS.AppFramework 1.0

Item {

    //--------------------------------------------------------------------------

    property real calibrationLevel: 0
    property color levelColor: "black"

    //--------------------------------------------------------------------------

    implicitWidth: 100
    implicitHeight: 30 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: parent
            bottomMargin: triShape.height
        }

        Rectangle {
            anchors {
                centerIn: parent
            }

            width: parent.height
            height: parent.width
            rotation: 90

            gradient: Gradient {
                GradientStop { position: 0.0; color: "green" }
                GradientStop { position: 0.5; color: "yellow" }
                GradientStop { position: 1.0; color: "red" }
            }

            border {
                color: "grey"
                width: 1 * AppFramework.displayScaleFactor
            }

            radius: 2 * AppFramework.displayScaleFactor
            opacity: 0.3
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: calibrationLevel * parent.width
        }

        visible: isFinite(calibrationLevel)
        color: levelColor
        width: 1 * AppFramework.displayScaleFactor

        Shape {
            id: triShape

            width: 15 * AppFramework.displayScaleFactor
            height: width * 0.866 // sin(60)

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }

            ShapePath {
                id: triPath

                strokeColor: "transparent"
                fillColor: levelColor
                startX: triShape.width / 2
                startY: 0

                PathLine { x: triShape.width; y: triShape.height }
                PathLine { x: 0; y: triShape.height }
                PathLine { x: triPath.startX; y: triPath.startY }
            }
        }
    }

    //--------------------------------------------------------------------------
}
