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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"

SettingsTab {
    id: addNetworkTab

    //--------------------------------------------------------------------------

    title: qsTr("Network Information")

    //--------------------------------------------------------------------------

    property real listDelegateHeight: settingsTabLocation.listDelegateHeight
    property color listBackgroundColor: "#FAFAFA"

    readonly property AppSettings gnssSettings: appSettings

    property bool discoveryEnabled: false

    //--------------------------------------------------------------------------

    signal showReceiverSettingsPage(var deviceName)

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        discoveryEnabled = true;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.type(addNetworkTab, true)
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        // Internal properties -------------------------------------------------

        property alias hostname: hostnameTextField.text
        property alias port: portTextField.text

        property bool initialized

        // ---------------------------------------------------------------------

        Component.onCompleted: {
            _item.initialized = true;

            controller.onDetailedSettingsPage = true;
        }

        // ---------------------------------------------------------------------

        Component.onDestruction: {
            controller.onDetailedSettingsPage = false;
        }

        // ---------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent

            spacing: 0

            Accessible.role: Accessible.Pane

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addNetworkTab.listDelegateHeight
                color: addNetworkTab.listBackgroundColor

                AppTextField {
                    id: hostnameTextField

                    anchors.fill: parent
                    anchors.topMargin: 10 * AppFramework.displayScaleFactor
                    anchors.bottomMargin: 10 * AppFramework.displayScaleFactor
                    anchors.leftMargin: 10 * AppFramework.displayScaleFactor
                    anchors.rightMargin: 10 * AppFramework.displayScaleFactor

                    placeholderText: qsTr("Hostname")
                }
            }

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addNetworkTab.listDelegateHeight
                color: addNetworkTab.listBackgroundColor

                AppTextField {
                    id: portTextField

                    anchors.fill: parent
                    anchors.topMargin: 10 * AppFramework.displayScaleFactor
                    anchors.bottomMargin: 10 * AppFramework.displayScaleFactor
                    anchors.leftMargin: 10 * AppFramework.displayScaleFactor
                    anchors.rightMargin: 10 * AppFramework.displayScaleFactor

                    placeholderText: qsTr("Port")
                }
            }

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addNetworkTab.listDelegateHeight
                color: addNetworkTab.listBackgroundColor

                AppButton {
                    enabled: _item.hostname > "" && Number.isInteger(Number(_item.port)) && _item.port > 0
                    opacity: enabled ? 1 : 0.5

                    height: 40 * AppFramework.displayScaleFactor

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10 * AppFramework.displayScaleFactor

                    text: qsTr("Add")

                    onClicked: {
                        var networkName = gnssSettings.createNetworkSettings(_item.hostname, _item.port);
                        controller.networkHostSelected(_item.hostname, _item.port);
                        showReceiverSettingsPage(networkName);
                    }
                }
            }

            // -----------------------------------------------------------------

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent

                    visible: Networking.isOnline && discoveryEnabled

                    HorizontalSeparator {
                        Layout.fillWidth: true
                    }

                    AppText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4 * AppFramework.displayScaleFactor
                        Layout.rightMargin: Layout.leftMargin

                        text: discoveryAgent.model.count > 0
                              ? qsTr("Select a location sensor")
                              : qsTr("Searching for location sensors")

                        font {
                            pointSize: 16
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: discoveryAgent.model
                        clip: true
                        spacing: 5 * AppFramework.displayScaleFactor
                        delegate: locationSensorDelegate

                        AppBusyIndicator {
                            anchors.centerIn: parent

                            running: discoveryAgent.model.count === 0
                            visible: running
                        }
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: locationSensorDelegate

            Rectangle {
                width: ListView.view.width
                height: locationSensoLayout.height + locationSensoLayout.anchors.margins * 2
                color: mouseArea.containsMouse
                       ? "#ecfbff"
                       : "white"

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }

                    height: 1 * AppFramework.displayScaleFactor
                    color: "#ddd"
                }

                RowLayout {
                    id: locationSensoLayout

                    anchors {
                        left: parent.left
                        right: parent.right
                        top : parent.top

                        margins: 5 * AppFramework.displayScaleFactor
                    }

                    spacing: 8 * AppFramework.displayScaleFactor

                    Image {
                        Layout.preferredHeight: 50 * AppFramework.displayScaleFactor
                        Layout.preferredWidth: Layout.preferredHeight

                        source: "images/SiteScan.jpg"
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 2 * AppFramework.displayScaleFactor

                        AppText {
                            Layout.fillWidth: true
                            text: productName
                            font {
                                pointSize: 16
                            }
                        }

                        AppText {
                            Layout.fillWidth: true
                            text: "%1:%2".arg(hostname).arg(port)
                            font {
                                pointSize: 13
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        var sensorInfo = discoveryAgent.model.get(index);
                        console.log(logCategory, "sensorInfo:", JSON.stringify(sensorInfo, undefined, 2));
                        hostnameTextField.text = sensorInfo.hostname;
                        portTextField.text = sensorInfo.port;
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        LocationSensorDiscoveryAgent {
            id: discoveryAgent

            Component.onCompleted: {
                start();
            }
        }

        // ---------------------------------------------------------------------
    }
}
