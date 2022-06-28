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

    implicitWidth: 20 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width: parent.width - triShape.width

        gradient: Gradient {
            GradientStop { position: 0.0; color: "green" }
            GradientStop { position: 0.5; color: "yellow" }
            GradientStop { position: 1.0; color: "red" }
        }

        border {
            color: "grey"
            width: 1 * AppFramework.displayScaleFactor
        }

        radius: width / 2

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: calibrationLevel * (parent.height - parent.width) + parent.width / 2
            }

            color: levelColor
            height: 1 * AppFramework.displayScaleFactor


            Shape {
                id: triShape

                height: 10 * AppFramework.displayScaleFactor
                width: height * 0.866 // sin(60)

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.right
                }

                ShapePath {
                    id: triPath

                    strokeColor: "transparent"
                    fillColor: levelColor
                    startX: 0
                    startY: triShape.height / 2

                    PathLine { x: triShape.width; y: 0 }
                    PathLine { x: triShape.width; y: triShape.height }
                    PathLine { x: triPath.startX; y: triPath.startY }
                }
            }
        }
    }
}
