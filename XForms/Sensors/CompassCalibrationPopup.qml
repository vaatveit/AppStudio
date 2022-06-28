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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtSensors 5.12
import QtGraphicalEffects 1.0
import QtQuick.Shapes 1.13

import ArcGIS.AppFramework 1.0

import ".."

XFormPopup {
    //--------------------------------------------------------------------------

    property Compass compass

    property color textColor: "white"

    //--------------------------------------------------------------------------

    width: 300 * AppFramework.displayScaleFactor
    height: 300 * AppFramework.displayScaleFactor

    background: Rectangle {

        color: "#001e31"
        radius: 3 * AppFramework.displayScaleFactor

        border {
            color: "darkgrey"
            width: 1 * AppFramework.displayScaleFactor
        }
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {

        Text {
            Layout.fillWidth: true

            text: qsTr("Compass Calibration")
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            font {
                family: Survey123.font.family
                pointSize: 20
            }
        }

        spacing: 10 * AppFramework.displayScaleFactor

        RowLayout {
            spacing: 10 * AppFramework.displayScaleFactor

            CalibrationIndicator {
                Layout.fillHeight: true

                calibrationLevel: compass.reading.calibrationLevel
                levelColor: textColor
            }

            ColumnLayout {
                spacing: 10 * AppFramework.displayScaleFactor

                AnimatedImage {
                    Layout.fillWidth: true

                    Layout.preferredHeight: 80 * AppFramework.displayScaleFactor

                    fillMode: Image.PreserveAspectFit
                    source: "images/calibrate-compass.gif"
                    playing: true
                    rotation: 180
                }

                Text {
                    Layout.fillWidth: true

                    text: qsTr("To calibrate, keep clear of magnetic interferences such as electronic devices, metal objects, and magnets, then move your device in figure eight motions several times in horizontal, vertical and diagonal directions.")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor

                    font {
                        family: Survey123.font.family
                        pointSize: 12
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
