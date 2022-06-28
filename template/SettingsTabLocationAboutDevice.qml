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
    id: aboutDeviceTab

    //--------------------------------------------------------------------------

    title: qsTr("Information")
    icon.name: "information"
    description: ""

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings
    readonly property bool isTheActiveSensor: deviceName === gnssSettings.kInternalPositionSourceName || controller.currentName === deviceName

    property bool dirty: false
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
            if (dirty) {
                changed();
                dirty = false;
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            GroupColumnLayout {
                Layout.fillWidth: true
                visible: deviceType !== kDeviceTypeInternal

                title: qsTr("Display name")

                AppTextField {
                    id: deviceLabel

                    Layout.fillWidth: true

                    text: gnssSettings.knownDevices[deviceName].label > "" ? gnssSettings.knownDevices[deviceName].label : deviceName
                    placeholderText: qsTr("Custom display name")

                    onTextChanged: {
                        if (initialized && !gnssSettings.updating) {
                            var label = text;

                            if (deviceType === kDeviceTypeFile && !text) {
                                label = gnssSettings.fileUrlToLabel(gnssSettings.knownDevices[deviceName].filename);
                            }

                            gnssSettings.knownDevices[deviceName].label = label;
                            if (isTheActiveSensor) {
                                gnssSettings.lastUsedDeviceLabel = label;
                            }

                            dirty = true;
                        }
                    }
                }
            }

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Details")

                RowLayout {
                    Layout.fillWidth: true

                    AppText {
                        text: qsTr("Provider:")
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    AppText {
                        Layout.fillWidth: parent
                        text: settingsTabLocation.resolveDeviceName(deviceType, deviceName, true)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    AppText {
                        text: qsTr("Type:")
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    AppText {
                        Layout.fillWidth: parent
                        text: deviceType
                    }
                }
            }

            GroupColumnLayout {
                Layout.fillWidth: true

                visible: deviceType === kDeviceTypeFile

                title: qsTr("Log file parsing")

                AppSwitch {
                    id: visualSwitch

                    Layout.fillWidth: true

                    text: qsTr("Loop at end of file")

                    checked: gnssSettings.knownDevices[deviceName].repeat
                             ? gnssSettings.knownDevices[deviceName].repeat
                             : false

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].repeat = checked;
                            if (isTheActiveSensor) {
                                gnssSettings.repeat = checked;
                            }
                        }

                        changed();
                    }
                }

                AppSlider {
                    id: slider

                    Layout.fillWidth: true

                    text: qsTr("Position update rate: %1 Hz").arg(slider.value)

                    from: 1
                    to: 20
                    stepSize: 1

                    value: gnssSettings.knownDevices[deviceName].updateinterval
                           ? 1000 / gnssSettings.knownDevices[deviceName].updateinterval
                           : 1

                    onValueChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].updateinterval = 1000 / value;
                            if (isTheActiveSensor) {
                                gnssSettings.updateInterval = 1000 / value;
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
