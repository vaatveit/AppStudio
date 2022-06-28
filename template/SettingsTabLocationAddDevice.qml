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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    id: addDeviceTab

    //--------------------------------------------------------------------------

    title: qsTr("Select Provider")

    //--------------------------------------------------------------------------

    property var receiverListModel

    property real listDelegateHeight: settingsTabLocation.listDelegateHeight
    property color hoverBackgroundColor: settingsTabLocation.hoverBackgroundColor
    property color listBackgroundColor: "#FAFAFA"

    readonly property AppSettings gnssSettings: appSettings

    //--------------------------------------------------------------------------

    signal showReceiverSettingsPage(var deviceName)

    //--------------------------------------------------------------------------

    SettingsTabContainer {
        id: settingsTabContainer
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        // Internal properties -------------------------------------------------

        readonly property DeviceDiscoveryAgent discoveryAgent: controller.discoveryAgent

        readonly property bool scanSerialPort: positionSourceManager.discoverSerialPort
        readonly property bool iOS: Qt.platform.os === "ios"

        property bool initialized

        // ---------------------------------------------------------------------

        Component.onCompleted: {
            _item.initialized = true;

            controller.onDetailedSettingsPage = true;

            // disable Bluetooth scanning if not needed
            discoveryAgent.setPropertyValue("isScanBluetoothDevices" , scanSerialPort ? false : true);
            discoveryAgent.setPropertyValue("isScanSerialPortDevices" , scanSerialPort ? true : false);

            // omit previously stored device from discovered devices list
            discoveryAgent.deviceFilter = function(device) {
                for (var i = 0; i < receiverListModel.count; i++) {
                    var cachedReceiver = receiverListModel.get(i);
                    if (device && cachedReceiver && device.name === cachedReceiver.name) {
                        return false;
                    }
                }
                return discoveryAgent.filter(device);
            }
        }

        // ---------------------------------------------------------------------

        Component.onDestruction: {
            controller.onDetailedSettingsPage = false;

            // Clear the model so old devices are not visible if view is re-loaded.
            discoveryAgent.devices.clear();

            // reset standard filter
            discoveryAgent.deviceFilter = function(device) { return discoveryAgent.filter(device); }

            // stop the discoveryAgent
            discoveryAgent.stop();
        }

        // ---------------------------------------------------------------------

        Connections {
            target: addDeviceTab

            onActivated: {
                // Activating this here ensures that any error message is displayed
                // on this page (not it's ancestor)
                discoverySwitch.checked = true;
            }
        }

        // ---------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Accessible.role: Accessible.Pane

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addDeviceTab.listDelegateHeight
                color: addDeviceTab.listBackgroundColor

                AppSwitch {
                    id: discoverySwitch

                    property bool updating

                    anchors.fill: parent
                    anchors.leftMargin: 10 * AppFramework.displayScaleFactor

                    text: qsTr("Discover")

                    palette {
                        text: settingsTabLocation.textColor
                        //dark: settingsTabLocation.selectedColor
                    }

                    font {
                        pointSize: 16
                    }

                    onCheckedChanged: {
                        if (_item.initialized && !updating) {
                            if (checked) {
                                if (!iOS || _item.scanSerialPort || Permission.serviceStatus(Permission.BluetoothService) === Permission.ServiceStatusPoweredOn) {
                                    devicesListView.model.clear()
                                    controller.startDiscoveryAgent();
                                } else {
                                    positionSourceManager.discoveryAgentError("")
                                    checked = false;
                                }
                            } else {
                                controller.stopDiscoveryAgent();
                            }
                        }
                    }

                    Connections {
                        target: _item.discoveryAgent

                        onRunningChanged: {
                            discoverySwitch.updating = true;
                            discoverySwitch.checked = _item.discoveryAgent.running;
                            discoverySwitch.updating = false;
                        }
                    }
                }
            }

            // -----------------------------------------------------------------

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * AppFramework.displayScaleFactor
                Layout.topMargin: 24 * AppFramework.displayScaleFactor
                Layout.leftMargin: 16 * AppFramework.displayScaleFactor
                Layout.rightMargin: 16 * AppFramework.displayScaleFactor

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Select a provider")
                    color: textColor

                    font {
                        pointSize: 16
                        bold: true
                    }
                }

                AppBusyIndicator {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 26 * AppFramework.displayScaleFactor
                    Layout.preferredWidth: 26 * AppFramework.displayScaleFactor

                    backgroundColor: selectedColor

                    running: discoverySwitch.checked
                }
            }

            // -----------------------------------------------------------------

            ListView {
                id: devicesListView

                Layout.fillWidth: true
                Layout.preferredHeight: count * (addDeviceTab.listDelegateHeight + spacing)
                Layout.maximumHeight: _item.height * 3 / 4

                visible: count > 0

                spacing: 2 * AppFramework.displayScaleFactor

                clip: true

                model: _item.discoveryAgent.devices
                delegate: deviceDelegate
            }

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: listDelegateHeight

                visible: !devicesListView.visible

                color: addDeviceTab.listBackgroundColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * AppFramework.displayScaleFactor
                    anchors.rightMargin: 16 * AppFramework.displayScaleFactor

                    AppText {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        verticalAlignment: Text.AlignVCenter

                        text: discoverySwitch.checked ? qsTr("Searching...") : qsTr("Press <b>Discover</b> to search.")
                        color: textColor
                        opacity: 0.5

                        font {
                            pointSize: 16
                        }
                    }
                }
            }

            // -----------------------------------------------------------------

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // ---------------------------------------------------------------------

        Component {
            id: deviceDelegate

            Rectangle {
                id: delegateRect

                width: ListView.view.width
                height: listDelegateHeight

                color: mouseArea.containsMouse ? hoverBackgroundColor : listBackgroundColor
                opacity: parent.enabled ? 1.0 : 0.5

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height

                        StyledImage {
                            anchors.centerIn: parent

                            width: 30 * AppFramework.displayScaleFactor
                            height: width

                            source: Icons.bigIcon("deviceType-%1".arg(deviceType))
                            color: unselectedColor
                        }
                    }

                    AppText {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: name
                        color: unselectedColor

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        verticalAlignment: Text.AlignVCenter

                        font {
                            pointSize: 16
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height

                        IconImage {
                            anchors.centerIn: parent

                            width: 30 * AppFramework.displayScaleFactor
                            height: width

                            icon: {
                                name: "chevron-right"
                                color: unselectedColor
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        var device = _item.discoveryAgent.devices.get(index);
                        var deviceName = gnssSettings.createExternalReceiverSettings(name, device.toJson());
                        controller.deviceSelected(device);
                        showReceiverSettingsPage(deviceName);
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
    }
}
