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
import ArcGIS.AppFramework.Notifications 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    id: alertsTab

    //--------------------------------------------------------------------------

    title: qsTr("Alerts")
    icon.name: "exclamation-mark-triangle"
    description: ""

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    property bool showAlertsVisual: true
    property bool showAlertsSpeech: true
    property bool showAlertsVibrate: true
    property bool showAlertsTimeout: false

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings
    readonly property bool isTheActiveSensor: deviceName === gnssSettings.kInternalPositionSourceName || controller.currentName === deviceName

    readonly property string kBanner: qsTr("Visual")
    readonly property string kVoice: qsTr("Audio")
    readonly property string kVibrate: qsTr("Vibrate")
    readonly property string kNone: qsTr("Off")

    property bool initialized

    //--------------------------------------------------------------------------

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

                title: qsTr("Styles")

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Alerts are triggered when the status of your connection changes. This includes receiver disconnection or data not being received. The alert style is how alerts are presented to you in the app.")
                }

                AppSwitch {
                    id: visualSwitch

                    Layout.fillWidth: true

                    visible: showAlertsVisual

                    checked: gnssSettings.knownDevices[deviceName].locationAlertsVisual

                    text: kBanner

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].locationAlertsVisual = checked;
                            if (isTheActiveSensor) {
                                gnssSettings.locationAlertsVisual = checked;
                            }
                        }

                        changed();
                    }
                }

                AppSwitch {
                    id: speechSwitch

                    Layout.fillWidth: true

                    visible: showAlertsSpeech

                    checked: gnssSettings.knownDevices[deviceName].locationAlertsSpeech

                    text: kVoice

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].locationAlertsSpeech = checked;
                            if (isTheActiveSensor) {
                                gnssSettings.locationAlertsSpeech = checked;
                            }
                        }

                        changed();
                    }
                }

                AppSwitch {
                    id: vibrateSwitch

                    Layout.fillWidth: true

                    visible: showAlertsVibrate

                    enabled: Vibration.supported
                    checked: gnssSettings.knownDevices[deviceName].locationAlertsVibrate

                    text: kVibrate

                    onCheckedChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].locationAlertsVibrate = checked;
                            if (isTheActiveSensor) {
                                gnssSettings.locationAlertsVibrate = checked;
                            }
                        }

                        changed();
                    }
                }

                AppSlider {
                    id: timeoutSlider

                    Layout.fillWidth: true

                    visible: showAlertsTimeout

                    to: 120000
                    from: 5000
                    stepSize: 5000

                    value: gnssSettings.knownDevices[deviceName].locationMaximumPositionAge

                    text: qsTr("Timeout %1 s".arg(value / 1000))

                    onValueChanged: {
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].locationMaximumPositionAge = value;
                            gnssSettings.knownDevices[deviceName].locationMaximumDataAge = value;
                            if (isTheActiveSensor) {
                                gnssSettings.locationMaximumPositionAge = value;
                                gnssSettings.locationMaximumDataAge = value;
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
