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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    id: activationModeTab

    //--------------------------------------------------------------------------

    title: qsTr("Connection Mode")
    icon.name: "link"
    description: ""

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings
    readonly property bool isTheActiveSensor: deviceName === gnssSettings.kInternalPositionSourceName || controller.currentName === deviceName

    readonly property string activationModeZeroLabel: qsTr("As needed")
    readonly property string activationModeOneLabel: qsTr("While a survey is open")
    readonly property string activationModeTwoLabel: qsTr("When the app is open")

    property bool initialized

    signal changed()

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        Component.onCompleted: {
            initialized = true;
        }

        Component.onDestruction: {
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Mode")

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("The connection mode determines when your location sensor is activated. This may affect accuracy, performance, and battery life. Refer to the documentation for more information.")
                }

                AppRadioButton {
                    id: asNeededButton

                    Layout.fillWidth: true

                    text: activationModeZeroLabel

                    checked: gnssSettings.knownDevices[deviceName].activationMode === gnssSettings.kActivationModeAsNeeded

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating && checked) {
                            gnssSettings.knownDevices[deviceName].activationMode = gnssSettings.kActivationModeAsNeeded;
                            if (isTheActiveSensor) {
                                gnssSettings.locationSensorActivationMode = gnssSettings.kActivationModeAsNeeded;
                            }
                        }

                        changed();
                    }
                }

                AppRadioButton {
                    id: inSurveyButton

                    Layout.fillWidth: true

                    text: activationModeOneLabel
                    checked: gnssSettings.knownDevices[deviceName].activationMode === gnssSettings.kActivationModeInSurvey

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating && checked) {
                            gnssSettings.knownDevices[deviceName].activationMode = gnssSettings.kActivationModeInSurvey;
                            if (isTheActiveSensor) {
                                gnssSettings.locationSensorActivationMode = gnssSettings.kActivationModeInSurvey;
                            }
                        }

                        changed();
                    }
                }

                AppRadioButton {
                    id: alwaysRunningButton

                    Layout.fillWidth: true

                    text: activationModeTwoLabel
                    checked: gnssSettings.knownDevices[deviceName].activationMode === gnssSettings.kActivationModeAlways

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating && checked) {
                            gnssSettings.knownDevices[deviceName].activationMode = gnssSettings.kActivationModeAlways;
                            if (isTheActiveSensor) {
                                gnssSettings.locationSensorActivationMode = gnssSettings.kActivationModeAlways;
                            }

                        }

                        changed();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
