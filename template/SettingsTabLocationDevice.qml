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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "../XForms/XForm.js" as XFormJS
import "Singletons"

SettingsTab {
    id: deviceTab

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings

    property var deviceProperties: null

    property bool showAboutDevice: true
    property bool showAlerts: true
    property bool showAntennaHeight: true
    property bool showAltitude: true
    property bool showAccuracy: true
    property bool showActivationMode: false

    property bool showAlertsVisual: true
    property bool showAlertsSpeech: true
    property bool showAlertsVibrate: true
    property bool showAlertsTimeout: false

    property var locale: ControlsSingleton.localeProperties.numberLocale

    //--------------------------------------------------------------------------

    signal selectInternal()
    signal updateViewAndDelegate()

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        gnssSettings.showActivationModeSettings = !gnssSettings.showActivationModeSettings
        gnssSettings.showAlertsTimeoutSettings = !gnssSettings.showAlertsTimeoutSettings
        gnssSettings.showAccuracySettings = !gnssSettings.showAccuracySettings
    }

    onUpdateViewAndDelegate: {
        var deviceLabel = gnssSettings.knownDevices[deviceName].label > "" ? gnssSettings.knownDevices[deviceName].label : deviceName;
        if (app.mainStackView.currentItem.settingsItem.objectName === deviceTab.deviceName) {
            app.mainStackView.currentItem.title = deviceLabel;
        }
        deviceTab.deviceLabel = deviceLabel;
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        Component.onCompleted: {
            controller.onDetailedSettingsPage = controller.useInternalGPS ? gnssSettings.kInternalPositionSourceName !== deviceName : controller.currentName !== deviceName;
            objectName = deviceName;
            updateDescriptions();
        }

        Component.onDestruction: {
            controller.onDetailedSettingsPage = false;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 5 * AppFramework.displayScaleFactor

            Accessible.role: Accessible.Pane

            ListTabView {
                id: settingsTabView

                Layout.fillWidth: true
                Layout.preferredHeight: settingsTabView.listTabView.contentHeight
                Layout.maximumHeight: _item.height * 3 / 4

                delegate: settingsDelegate

                SettingsTabLocationAboutDevice {
                    id: sensorAbout

                    visible: showAboutDevice
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    onChanged: {
                        updateViewAndDelegate();
                        _item.updateDescriptions();
                    }
                }

                SettingsTabLocationActivationMode {
                    id: sensorActivationMode

                    visible: showActivationMode
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    onChanged: {
                        _item.updateDescriptions();
                    }
                }

                SettingsTabLocationAlerts {
                    id: sensorAlerts

                    visible: showAlerts
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    showAlertsVisual: deviceTab.showAlertsVisual
                    showAlertsSpeech: deviceTab.showAlertsSpeech
                    showAlertsVibrate: deviceTab.showAlertsVibrate
                    showAlertsTimeout: deviceTab.showAlertsTimeout

                    onChanged: {
                        _item.updateDescriptions();
                    }
                }

                SettingsTabLocationAntennaHeight {
                    id: sensorAntennaHeight

                    visible: showAntennaHeight
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    onChanged: {
                        _item.updateDescriptions();
                    }
                }

                SettingsTabLocationAltitude {
                    id: sensorAltitude

                    visible: showAltitude
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    onChanged: {
                        _item.updateDescriptions();
                    }
                }

                SettingsTabLocationAccuracy {
                    id: sensorAccuracy

                    visible: showAccuracy
                    enabled: visible

                    deviceType: deviceTab.deviceType
                    deviceName: deviceTab.deviceName
                    deviceLabel: deviceTab.deviceLabel

                    onChanged: {
                        _item.updateDescriptions();
                    }
                }

                onSelected: {
                    app.mainStackView.push(settingsTabContainer,
                                           {
                                               settingsTab: item,
                                               title: item.title,
                                               settingsComponent: item.contentComponent,
                                           });
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * AppFramework.displayScaleFactor
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 44 * AppFramework.displayScaleFactor
                Layout.bottomMargin: 5 * AppFramework.displayScaleFactor
                visible: deviceType !== kDeviceTypeInternal

                Accessible.role: Accessible.Pane

                StyledButton {
                    id: removeDeviceButton

                    text: qsTr("Remove %1").arg(deviceLabel > "" ? deviceLabel : deviceName)
                    fontFamily: app.fontFamily

                    anchors{
                        fill: parent
                        leftMargin: 15 * AppFramework.displayScaleFactor
                        rightMargin: 15 * AppFramework.displayScaleFactor
                    }

                    enabled: deviceType !== kDeviceTypeInternal

                    onClicked: {
                        confirmDeletePopup.open();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: settingsDelegate

            SettingsTabDelegate {
                listTabView: settingsTabView
            }
        }

        //--------------------------------------------------------------------------

        MessagePopup {
            id: confirmDeletePopup

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.Cancel

            title: qsTr("Remove Provider")
            text: qsTr("The selected location provider will be removed.")

            yesAction {
                icon {
                    name: "trash"
                    color: Survey.kColorWarning
                }
                text: qsTr("Remove")
            }

            onYes: {
                deleteProvider();
            }

            function deleteProvider() {
                // If this is the currently connected device, select the internal
                if (controller.currentName === deviceTab.deviceName) {
                    selectInternal();
                }

                gnssSettings.deleteKnownDevice(deviceTab.deviceName);
                app.goBack();
            }
        }

        //--------------------------------------------------------------------------

        function updateDescriptions(){

            var props = gnssSettings.knownDevices[deviceName] || null;

            if (props === null) {
                return;
            }

            // about
            sensorAbout.description = settingsTabLocation.resolveDeviceName(deviceType, deviceName, false);

            // activation mode
            if (props.activationMode !== undefined) {
                sensorActivationMode.description = props.activationMode === gnssSettings.kActivationModeAsNeeded
                        ? sensorActivationMode.activationModeZeroLabel
                        : props.activationMode === gnssSettings.kActivationModeInSurvey
                          ? sensorActivationMode.activationModeOneLabel
                          : props.activationMode === gnssSettings.kActivationModeAlways
                            ? sensorActivationMode.activationModeTwoLabel
                            : "";
            }

            // alert styles
            var alertStylesDescString = "";

            if (props.locationAlertsVisual !== undefined && props.locationAlertsVisual) {
                alertStylesDescString += "%1".arg(sensorAlerts.kBanner);
            }

            if (props.locationAlertsSpeech !== undefined && props.locationAlertsSpeech) {
                alertStylesDescString += alertStylesDescString > "" ? ", %1".arg(sensorAlerts.kVoice) : "%1".arg(sensorAlerts.kVoice);
            }

            if (props.locationAlertsVibrate !== undefined && props.locationAlertsVibrate) {
                alertStylesDescString += alertStylesDescString > "" ? ", %1".arg(sensorAlerts.kVibrate) : "%1".arg(sensorAlerts.kVibrate);
            }

            if (alertStylesDescString === "") {
                alertStylesDescString = "%1".arg(sensorAlerts.kNone);
            }

            sensorAlerts.description = alertStylesDescString;

            // altitude type
            if (props.altitudeType !== undefined) {
                sensorAltitude.description = props.altitudeType === gnssSettings.kAltitudeTypeMSL
                        ? sensorAltitude.altitudeTypeMSLLabel
                        : props.altitudeType === gnssSettings.kAltitudeTypeHAE
                          ? sensorAltitude.altitudeTypeHAELabel
                          : "";
            }

            // antenna height
            if (props.antennaHeight !== undefined) {
                sensorAntennaHeight.description = isFinite(props.antennaHeight)
                        ? XFormJS.toLocaleLengthString(props.antennaHeight, locale)
                        : XFormJS.toLocaleLengthString(0, locale);
            }

            // accuracy type
            if (props.confidenceLevelType !== undefined) {
                sensorAccuracy.description = props.confidenceLevelType === gnssSettings.kConfidenceLevelType68
                        ? sensorAccuracy.confidenceLevelType68Label
                        : props.confidenceLevelType === gnssSettings.kConfidenceLevelType95
                          ? sensorAccuracy.confidenceLevelType95Label
                          : "";
            }
        }
    }

    //--------------------------------------------------------------------------

}
