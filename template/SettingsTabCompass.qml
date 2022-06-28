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
import QtQuick.Layouts 1.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"
import "../XForms"
import "../XForms/Sensors"

import "NOAA.js" as NOAA


SettingsTab {
    //--------------------------------------------------------------------------

    title: qsTr("Compass")
    description: qsTr("Configure compass properties")
    icon.name: "compass-needle"

    //--------------------------------------------------------------------------

    Item {
        id: tab

        //----------------------------------------------------------------------

        Component.onCompleted: {
            positionSourceConnection.start();
        }

        //--------------------------------------------------------------------------

        property var currentCoordinate: QtPositioning.coordinate()

        readonly property bool compassEnabled: appSettings.compassEnabled

        //----------------------------------------------------------------------

        onCompassEnabledChanged: {
            Qt.callLater(toggleCompass);
        }

        function toggleCompass() {
            if (compassEnabled) {
                positionSourceConnection.startCompass();
            } else {
                positionSourceConnection.stopCompass();
            }
        }

        //----------------------------------------------------------------------

        XFormPositionSourceConnection {
            id: positionSourceConnection

            positionSourceManager: app.positionSourceManager
            listener: "CompassSettings"
            compassEnabled: false

            onNewPosition: {
                tab.currentCoordinate = position.coordinate;
            }
        }

        //----------------------------------------------------------------------

        VerticalScrollView {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            ColumnLayout {
                spacing: 10 * AppFramework.displayScaleFactor

                AppSwitch {
                    Layout.fillWidth: true

                    checked: appSettings.compassEnabled
                    text: qsTr("Enable compass")

                    onCheckedChanged: {
                        appSettings.compassEnabled = checked;
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    visible: !positionSourceConnection.compassAvailable

                    text: "Compass sensor hardware is not present. Compass readings will be simulated."
                    horizontalAlignment: Text.AlignHCenter
                    color: "#a80000"
                    font {
                        pointSize: 16
                    }
                }

                GroupColumnLayout {
                    Layout.fillWidth: true

                    title: qsTr("Magnetic Declination")

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("The magnetic declination is the angle between the horizontal component of the Earth's magnetic field and true north. It is positive if a magnetic compass points east of true north, and negative if the compass points west of true north. This angle varies depending on your position on the Earth's surface and can change over time.")
                    }

                    NumberField {
                        id: magneticDeclinationField

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor

                        placeholderText: qsTr("Degrees")
                        suffixText: "°"
                        minimumValue: -45
                        maximumValue: 45

                        value: appSettings.magneticDeclination

                        onValueChanged: {
                            appSettings.magneticDeclination = value;
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        visible: confirmService.visible
                        text: qsTr('The magnetic declination for your current location can be estimated using the <a href="https://www.ngdc.noaa.gov/geomag-web/#declination">magnetic field calculator</a> service from NOAA. <a href="https://www.ngdc.noaa.gov/ngdcinfo/privacy.html#copyright">Copyright Notice</a>')

                        onLinkActivated: {
                            Qt.openUrlExternally(link);
                        }
                    }

                    AppSwitch {
                        id: confirmService

                        Layout.fillWidth: true

                        visible: Networking.isOnline
                        text: qsTr('I acknowledge my location will be sent to NOAA to estimate the magetic declination. <a href="https://www.ngdc.noaa.gov/ngdcinfo/privacy.html">Privacy policy.</a>')
                        checked: false
                    }

                    AppButton {
                        id: requestButtton

                        Layout.alignment: Qt.AlignHCenter

                        enabled: confirmService.checked && tab.currentCoordinate.isValid
                        visible: confirmService.visible
                        text: qsTr("Estimate magnetic declination")
                        iconSource: Icons.icon("web")

                        onClicked: {
                            enabled = false;
                            pulseAnimation.running = true;

                            NOAA.requestMagneticDeclination(
                                        tab.currentCoordinate,
                                        function (result) {
                                            if (result) {
                                                magneticDeclinationField.setValue(result.declination.value);
                                            }

                                            enabled = true;
                                            pulseAnimation.running = false;
                                        });
                        }

                        PulseAnimation {
                            id: pulseAnimation

                            target: requestButtton
                        }
                    }
                }

                GroupColumnLayout {
                    Layout.fillWidth: true

                    title: qsTr("Compass Calibration")
                    visible: appSettings.compassEnabled

                    CompassCalibrationIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 300 * AppFramework.displayScaleFactor

                        calibrationLevel: positionSourceConnection.compassCalibrationLevel
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                        IconImage {
                            icon {
                                name: "rotate-device"
                                color: app.textColor
                            }
                        }

                        AppText {
                            Layout.fillWidth: true

                            text: qsTr("To calibrate, keep clear of magnetic interferences such as electronic devices, metal objects, and magnets, then move your device in figure eight motions several times in horizontal, vertical and diagonal directions.")
                            horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
