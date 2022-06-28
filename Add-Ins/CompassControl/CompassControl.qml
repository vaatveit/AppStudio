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

import ArcGIS.AppFramework 1.0

import ArcGIS.Survey123 1.0
import ArcGIS.Survey123.Controls 1.0

ColumnLayout {
    id: control

    //--------------------------------------------------------------------------

    property real value
    property real azimuth: Math.round(readingValue(compass, "azimuth"))

    property alias compass: compass
    readonly property bool compassAvailable: QmlSensors.sensorTypes().indexOf("QCompass") >= 0
    readonly property bool rotationSensorAvailable: QmlSensors.sensorTypes().indexOf("QRotationSensor") >= 0

    property real startAzimuth

    //--------------------------------------------------------------------------

    readonly property var kCardinals: [
        qsTr("N"),
        qsTr("NNE"),
        qsTr("NE"),
        qsTr("ENE"),

        qsTr("E"),
        qsTr("ESE"),
        qsTr("SE"),
        qsTr("SSE"),

        qsTr("S"),
        qsTr("SSW"),
        qsTr("SW"),
        qsTr("WSW"),

        qsTr("W"),
        qsTr("WNW"),
        qsTr("NW"),
        qsTr("NNW")
    ];

    //--------------------------------------------------------------------------

    spacing: 0

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(JSON.stringify(QmlSensors.sensorTypes(), undefined, 2))
    }

    //--------------------------------------------------------------------------

    Compass {
        id: compass

        Component.onCompleted: {
            console.log("sensor:", type, "description:", description, "id:", identifier);
            compass.start();
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.preferredHeight: 200 * AppFramework.displayScaleFactor

        Item {
            Layout.preferredWidth: calibrationIndicator.width

            visible: calibrationIndicator.visible
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: compassArea

                anchors {
                    centerIn: parent
                }

                width: Math.min(parent.width, parent.height)
                height: width

                CompassIndicator {
                    id: compassIndicator

                    anchors {
                        fill: parent
                    }

                    font: Survey123.font
                    azimuth: control.azimuth
                }

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

                RotatationMouseArea {
                    anchors.fill: parent

                    enabled: !compassAvailable

                    onStarted: {
                        startAzimuth = control.azimuth;
                        compassIndicator.rotationAnimation.enabled = false;
                    }

                    onUpdated: {
                        control.azimuth = Math.round(startAzimuth + angle + 360.0) % 360;
                        azimuthField.text = Math.round(compassIndicator.azimuth);
                    }

                    onFinished: {
                        compassIndicator.rotationAnimation.enabled = true;
                        azimuthField.text = Math.round(compassIndicator.azimuth);
                        azimuthField.editingFinished();
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: compassAvailable
                    hoverEnabled: enabled
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        azimuthField.text = Math.round(compassIndicator.azimuth);
                        azimuthField.editingFinished();
                    }
                }
            }
        }

        CalibrationIndicator {
            id: calibrationIndicator

            Layout.preferredHeight: compassArea.height * 0.75

            visible: compassAvailable

            calibrationLevel: (compass && compass.reading) ? compass.reading.calibrationLevel : 0

//            MouseArea {
//                anchors.fill: parent

//                hoverEnabled: true
//                cursorShape: Qt.PointingHandCursor

//                onClicked: {
//                    var popup = calibrationPopup.createObject(control);
//                    popup.open();
//                }
//            }
        }
    }

    //--------------------------------------------------------------------------

    TextBox {
        id: azimuthField

        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
        Layout.alignment: Qt.AlignHCenter

        font: addIn.font
        palette: addIn.palette

        validator: DoubleValidator {
            decimals: 0
            bottom: 0
            top: 359
            notation: DoubleValidator.StandardNotation
        }

        onEditingFinished: {
            value = Number(text);

            if (!compassAvailable && isFinite(value)) {
                azimuth = value;
            }
        }

        Label {
            anchors {
                left: parent.right
                leftMargin: 5 * AppFramework.displayScaleFactor
                verticalCenter: parent.verticalCenter
            }

            text: "° %1".arg(azimuthField.text.length ? toCardinal(Number(azimuthField.text)) : "")

            font: addIn.font
            palette: addIn.palette
        }
    }

    //--------------------------------------------------------------------------

    function readingValue(sensor, name, defaultValue) {
        if (defaultValue === undefined) {
            defaultValue = 0;
        }

        if (!sensor) {
            return defaultValue;
        }

        var reading = sensor.reading;

        if (!reading) {
            return defaultValue;
        }

        var value = reading[name];

        return isFinite(value) ? value : defaultValue;
    }

    //--------------------------------------------------------------------------

    function toCardinal(degrees) {
        if (!isFinite(degrees)) {
            return "";
        }

        var index = Math.floor((degrees / 22.5) + 0.5);
        return kCardinals[index % kCardinals.length];
    }

    //--------------------------------------------------------------------------

//    Component {
//        id: calibrationPopup

//        CompassCalibrationPopup {
//            compass: control.compass
//        }
//    }

    //--------------------------------------------------------------------------
}
