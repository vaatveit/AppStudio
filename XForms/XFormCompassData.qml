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
import QtQuick.Controls 2.5
import QtSensors 5.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls"
import "../Controls/Singletons"

import "Sensors"

SwipeTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Compass")
    icon.name: "compass-needle"

    //--------------------------------------------------------------------------

    property string fontFamily
    property var locale: xform.locale

    property XFormPositionSourceConnection positionSourceConnection
    readonly property bool rotationSensorAvailable: QmlSensors.sensorTypes().indexOf("QRotationSensor") >= 0

    property bool showMagnetic: true

    readonly property string kSuffixMagnetic: qsTr("M")
    readonly property string kSuffixTrue: qsTr("T")

    readonly property real effectiveAzimuth: Math.round(((showMagnetic
                                               ? positionSourceConnection.compassAzimuth
                                               : positionSourceConnection.compassTrueAzimuth) + 360) % 360)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: container

        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 35 * AppFramework.displayScaleFactor

            CompassIndicator {
                id: indicator

                anchors.centerIn: parent

                width: Math.min(parent.width, parent.height, 300 * AppFramework.displayScaleFactor)
                height: width

                azimuth: effectiveAzimuth
                faceColor: "#f0f0f0"

                LevelIndicator {
                    anchors {
                        fill: parent
                        margins: parent.width * 0.15
                    }

                    visible: rotationSensorAvailable
                    rotationSensor: RotationSensor {
                        id: rotationSensor

                        Component.onCompleted: {
                            start();
                        }
                    }
                }

                XFormText {
                    anchors {
                        horizontalCenter: azimuthText.horizontalCenter
                        bottom: azimuthText.top
                    }

                    text: Units.cardinalDirectionName(positionSourceConnection.compassTrueAzimuth)
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 26
                    }
                }

                XFormText {
                    id: azimuthText

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.top
                    }

                    text: "%1".arg(effectiveAzimuth)
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 22
                    }

                    XFormText {
                        anchors {
                            left: parent.right
                            top: parent.top
                        }

                        text: "°%1".arg(showMagnetic ? kSuffixMagnetic : kSuffixTrue)
                        font {
                            pointSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            showMagnetic = !showMagnetic;
                        }
                    }
                }
            }
        }

        XFormText {
            Layout.fillWidth: true

            text: qsTr("Magnetic declination is %1°").arg(positionSourceConnection.magneticDeclination)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 14
            }
        }

        XFormText {
            Layout.fillWidth: true

            text: qsTr("Compass Calibration")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 14
            }
        }

        CompassCalibrationIndicator {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: indicator.width
            Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

            calibrationLevel: positionSourceConnection.compassCalibrationLevel
        }
    }

    //--------------------------------------------------------------------------
}
