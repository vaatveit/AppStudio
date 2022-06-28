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
    id: accuracyTab

    //--------------------------------------------------------------------------

    title: qsTr("Accuracy")
    icon.name: "gps-on"
    description: ""

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings
    readonly property bool isTheActiveSensor: deviceName === gnssSettings.kInternalPositionSourceName || controller.currentName === deviceName

    readonly property string confidenceLevelType68Label: qsTr("68%")
    readonly property string confidenceLevelType95Label: qsTr("95%")

    property bool initialized

    signal changed()

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        Component.onCompleted: {
            var confidenceLevelType = gnssSettings.knownDevices[deviceName].confidenceLevelType;

            if (confidenceLevelType === gnssSettings.kConfidenceLevelType68) {
                sixtyeightButton.checked = true;
            }

            if (confidenceLevelType === gnssSettings.kConfidenceLevelType95) {
                ninetyfiveButton.checked = true;
            }

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

                title: qsTr("Confidence level")

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("By default location providers report horizontal and vertical accuracy with a 68% confidence level. Choose 95% to report accuracy at a higher confidence.")
                }

                AppRadioButton {
                    id: sixtyeightButton

                    Layout.fillWidth: true

                    text: confidenceLevelType68Label

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating && checked) {
                            ninetyfiveButton.checked = false;
                            gnssSettings.knownDevices[deviceName].confidenceLevelType = gnssSettings.kConfidenceLevelType68;
                            if (isTheActiveSensor) {
                                gnssSettings.locationConfidenceLevelType = gnssSettings.kConfidenceLevelType68;
                            }
                        }

                        changed();
                    }
                }

                AppRadioButton {
                    id: ninetyfiveButton

                    Layout.fillWidth: true

                    text: confidenceLevelType95Label

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating && checked) {
                            sixtyeightButton.checked = false;
                            gnssSettings.knownDevices[deviceName].confidenceLevelType = gnssSettings.kConfidenceLevelType95;
                            if (isTheActiveSensor) {
                                gnssSettings.locationConfidenceLevelType = gnssSettings.kConfidenceLevelType95;
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
