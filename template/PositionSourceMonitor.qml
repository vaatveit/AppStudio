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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../XForms"
import "../XForms/GNSS"
import "../Controls"
import "../Controls/Singletons"

Item {
    id: monitor

    //--------------------------------------------------------------------------

    property XFormPositionSourceManager positionSourceManager
    property bool monitorNmeaData: false

    readonly property NmeaSource nmeaSource: positionSourceManager.nmeaSource
    readonly property DeviceDiscoveryAgent discoveryAgent: positionSourceManager.discoveryAgent
    readonly property PositioningSourcesController controller: positionSourceManager.controller

    readonly property bool active: positionSourceManager.active

    property bool positionIsCurrent: false
    property var currentPosition: ({})

    //--------------------------------------------------------------------------

    property int maximumDataAge: 5000
    property int maximumPositionAge: 5000

    //--------------------------------------------------------------------------

    property double dataReceivedTime
    property double positionReceivedTime

    //-------------------------------------------------------------------------
    // GNSS error messages

    readonly property string kUnableToConnect: qsTr("Unable to Connect")
    readonly property string kDiscoveryFailed: qsTr("Device Discovery Failed")
    readonly property string kProviderUnavailable: qsTr("Location Inaccessible")
    readonly property string kDiscoveryAgentError: qsTr("Please ensure:<br>1. Bluetooth is turned on.<br>2. The app has permission to access Bluetooth.")
    readonly property string kTcpConnectionError: qsTr("Please ensure:<br>1. Your device is online.<br>2. <b>%1</b> is a valid network address.")
    readonly property string kSerialportConnectionError: qsTr("Please ensure:<br>1. <b>%1</b> is turned on.<br>2. <b>%1</b> is connected to your device.")
    readonly property string kBluetoothConnectionError: qsTr("Please ensure:<br>1. Bluetooth is turned on.<br>2. <b>%1</b> is turned on.<br>3. <b>%1</b> is paired with your device.")
    readonly property string kNmeaLogFileError: qsTr("Please ensure <b>%1</b> exists and contains valid NMEA log data.")
    readonly property string kInternalLocationProviderError: qsTr("Please ensure:<br>1. Location services are turned on.<br>2. The app has permission to access your location.")

    //--------------------------------------------------------------------------

    signal newPosition(var position)
    signal alert(int alertType)

    //--------------------------------------------------------------------------

    onActiveChanged: {
        console.log(logCategory, "Position source monitoring active:", active);

        if (active) {
            initialize();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(monitor, true)
    }

    //--------------------------------------------------------------------------

    Timer {
        id: timer

        interval: 10000
        triggeredOnStart: false
        repeat: true
        running: active

        onTriggered: {
            monitorCheck();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        id: nmeaSourceConnections

        target: nmeaSource
        enabled: active && positionSourceManager.isGNSS

        onReceivedNmeaData: {
            dataReceivedTime = (new Date()).valueOf();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        id: positionSourceManagerConnections

        target: positionSourceManager

        onNewPosition: {
            positionReceivedTime = positionSourceManager.positionTimestamp

            if (!positionSourceManager.isGNSS || position.fixTypeValid && position.fixType > 0) {
                currentPosition = position;
                positionIsCurrent = true;
            } else {
                positionIsCurrent = false;
            }

            newPosition(position);
        }

        onIsConnectedChanged: {
            if (positionSourceManager.isGNSS) {
                if (positionSourceManager.isConnected) {
                    alert(AppAlert.AlertType.Connected);
                } else {
                    positionIsCurrent = false;
                    alert(AppAlert.AlertType.Disconnected);
                }
            }
        }

        onTcpError: {
            positionIsCurrent = false;
            showConnectionError(kUnableToConnect, kTcpConnectionError.arg(positionSourceManager.name), positionSourceManager.startPositionSource);
        }

        onDeviceError: {
            positionIsCurrent = false;
            if (positionSourceManager.isSerialPort) {
                showConnectionError(kUnableToConnect, kSerialportConnectionError.arg(positionSourceManager.name), positionSourceManager.startPositionSource);
            } else {
                showConnectionError(kUnableToConnect, kBluetoothConnectionError.arg(positionSourceManager.name), positionSourceManager.startPositionSource);
            }
        }

        onNmeaLogFileError: {
            positionIsCurrent = false;
            showConnectionError(kUnableToConnect, kNmeaLogFileError.arg(positionSourceManager.name), positionSourceManager.startPositionSource);
        }

        onPositionSourceError: {
            positionIsCurrent = false;
            showConnectionError(kProviderUnavailable, kInternalLocationProviderError, positionSourceManager.startPositionSource);
        }

        onDiscoveryAgentError: {
            showConnectionError(kDiscoveryFailed, kDiscoveryAgentError, controller.startDiscoveryAgent);
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        dataReceivedTime = (new Date()).valueOf();
        positionReceivedTime = (new Date()).valueOf();
    }

    //--------------------------------------------------------------------------

    function monitorCheck() {
        var now = new Date().valueOf();

        if (nmeaSourceConnections.enabled && monitorNmeaData && !positionSourceManager.onSettingsPage && !positionSourceManager.isConnecting && !discoveryAgent.running) {
            var dataAge = now - dataReceivedTime;

            if (dataAge > maximumDataAge) {
                positionIsCurrent = false;
                alert(AppAlert.AlertType.NoData);
                return;
            }
        }

        if (positionSourceManagerConnections.enabled && !positionSourceManager.onSettingsPage && !positionSourceManager.isConnecting && !discoveryAgent.running) {
            var positionAge = now - positionReceivedTime;

            if (positionAge > maximumPositionAge || positionSourceManager.isGNSS && (!currentPosition.fixTypeValid || currentPosition.fixType === 0)) {
                positionIsCurrent = false;
                alert(AppAlert.AlertType.NoPosition);
                return;
            }
        }
    }

    //--------------------------------------------------------------------------

    function showConnectionError(title, text, retryHandler) {
        var popup = connectionErrorPopup.createObject(monitor,
                                                {
                                                    title: title,
                                                    text: text
                                                });

        popup.accepted.connect(retryHandler);
        popup.open();
    }

    //--------------------------------------------------------------------------

    Component {
        id: connectionErrorPopup

        MessagePopup {
            parent: app

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Retry | StandardButton.Close

            textLabel.maximumLineCount: 8
        }
    }

    //--------------------------------------------------------------------------
}
