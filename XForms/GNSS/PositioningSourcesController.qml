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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Positioning 1.0

Item {
    id: controller

    // -------------------------------------------------------------------------

    enum ConnectionType {
        Internal = 0,
        External = 1,
        Network = 2,
        File = 3
    }

    // -------------------------------------------------------------------------

    property PositioningSources sources

    readonly property PositionSource positionSource: sources.positionSource
    readonly property SatelliteInfoSource satelliteInfoSource: sources.satelliteInfoSource
    readonly property NmeaSource nmeaSource: sources.nmeaSource
    readonly property TcpSocket tcpSocket: sources.tcpSocket
    readonly property DeviceDiscoveryAgent discoveryAgent: sources.discoveryAgent
    readonly property Device currentDevice: sources.currentDevice

    readonly property string currentNetworkAddress: sources.currentNetworkAddress
    readonly property string integratedProviderName: sources.integratedProviderName

    readonly property bool isConnecting: positionSource.valid && !useInternalGPS && sources.isConnecting
    readonly property bool isConnected: positionSource.valid && (useInternalGPS || sources.isConnected)

    readonly property bool useInternalGPS: connectionType === PositioningSourcesController.ConnectionType.Internal
    readonly property bool useExternalGPS: connectionType === PositioningSourcesController.ConnectionType.External
    readonly property bool useTCPConnection: connectionType === PositioningSourcesController.ConnectionType.Network
    readonly property bool useFile: connectionType === PositioningSourcesController.ConnectionType.File

    readonly property string currentName:
        useInternalGPS
        ? integratedProviderName
        : useExternalGPS && currentDevice
          ? currentDevice.name
          : useTCPConnection && currentNetworkAddress > ""
            ? currentNetworkAddress
            : useFile && nmeaLogFile > ""
              ? nmeaLogFile
              : ""

    property string currentLabel: currentName

    readonly property string noExternalReceiverError: qsTr("No external GNSS receiver configured.")
    readonly property string noNetworkProviderError: qsTr("No network location provider configured.")
    readonly property string noNmeaLogFileError: qsTr("No NMEA log file configured.")
    readonly property string nmeaLogFileOpenError: qsTr("Unable to open NMEA log file.")
    readonly property string timeOutError: qsTr("Connection attempt timed out.")

    property int connectionType: PositioningSourcesController.ConnectionType.Internal
    property string storedDeviceName: ""
    property string storedDeviceJSON: ""
    property string hostname: ""
    property int port: Number.NaN

    property string nmeaLogFile: ""
    property int updateInterval: 1000
    property bool repeat: true

    property bool errorWhileConnecting: false
    property bool onDetailedSettingsPage: false
    property bool onSettingsPage: false
    property bool stayConnected: true
    property bool initialized: false

    // -------------------------------------------------------------------------

    signal startPositionSource()
    signal stopPositionSource()
    signal startDiscoveryAgent()
    signal stopDiscoveryAgent()

    signal tcpError(string errorString)
    signal deviceError(string errorString)
    signal nmeaLogFileError(string errorString)
    signal discoveryAgentError(string errorString)

    signal nmeaLogFileSelected(string fileName)
    signal networkHostSelected(string hostname, int port)
    signal deviceSelected(Device device)
    signal deviceDeselected()
    signal disconnect()
    signal reconnect()
    signal fullDisconnect()

    // -------------------------------------------------------------------------

    Component.onCompleted: {
        // prepare to connect to device that was used previously
        if (useExternalGPS && storedDeviceJSON > "") {
            sources.currentDevice = Device.fromJson(storedDeviceJSON, this);
        }

        if (useFile && storedDeviceName > "") {
            sources.currentNmeaLogFile = storedDeviceName;
        }

        initialized = true;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(controller, true)
    }

    // -------------------------------------------------------------------------

    onIsConnectedChanged: {
        if (initialized) {
            if (isConnected) {
                if (connectionType === PositioningSourcesController.ConnectionType.External && currentDevice) {
                    console.log(logCategory, "Connected to device:", currentDevice.name, "address:", currentDevice.address);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Network) {
                    console.log(logCategory, "Connected to remote host:", tcpSocket.remoteName, "port:", tcpSocket.remotePort);
                } else if (connectionType === PositioningSourcesController.ConnectionType.File) {
                    console.log(logCategory, "Connected to NMEA log file:", nmeaLogFile);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Internal) {
                    console.log(logCategory, "Connected to system location source:", integratedProviderName);
                }
            } else {
                if (connectionType === PositioningSourcesController.ConnectionType.External && currentDevice) {
                    console.log(logCategory, "Disconnecting device:", currentDevice.name, "address", currentDevice.address);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Network) {
                    console.log(logCategory, "Disconnecting from remote host:", tcpSocket.remoteName, "port:", tcpSocket.remotePort);
                } else if (connectionType === PositioningSourcesController.ConnectionType.File) {
                    console.log(logCategory, "Disconnecting from NMEA log file:", nmeaLogFile);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Internal) {
                    console.log(logCategory, "Disconnecting from system location source:", integratedProviderName);
                }
            }

            connectionErrorTimer.stop();
            errorWhileConnecting = false;
        }
    }

    // -------------------------------------------------------------------------

    onReconnect: {
        if (!reconnectTimer.running) {
            reconnectTimer.start();
        }
    }

    function reconnectNow() {
        if (!isConnecting && !isConnected) {
            if (useExternalGPS) {
                if (currentDevice) {
                    deviceSelected(currentDevice)
                } else if (!onSettingsPage) {
                    deviceError(noExternalReceiverError);
                }
            } else if (useTCPConnection) {
                if (hostname > "" && port > "") {
                    networkHostSelected(hostname, port);
                } else if (!onSettingsPage) {
                    tcpError(noNetworkProviderError);
                }
            } else if (useFile) {
                if (nmeaLogFile > "") {
                    nmeaLogFileSelected(nmeaLogFile)
                } else if (!onSettingsPage) {
                    nmeaLogFileError(noNmeaLogFileError);
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    onStartPositionSource:  {
        positionSource.start();
        reconnect();
    }

    // -------------------------------------------------------------------------

    onStopPositionSource:  {
        positionSource.stop();
    }

    // -------------------------------------------------------------------------

    onStartDiscoveryAgent: {
        discoveryTimer.start();
    }

    // -------------------------------------------------------------------------

    onStopDiscoveryAgent: {
        discoveryAgent.stop();
    }

    // -------------------------------------------------------------------------

    onNmeaLogFileSelected: {
        errorWhileConnecting = false;
        sources.nmeaLogFileSelected(fileName);
    }

    // -------------------------------------------------------------------------

    onNetworkHostSelected: {
        errorWhileConnecting = false;
        sources.networkHostSelected(hostname, port);
    }

    // -------------------------------------------------------------------------

    onDeviceSelected: {
        errorWhileConnecting = false;
        sources.deviceSelected(device);
    }

    // -------------------------------------------------------------------------

    onDeviceDeselected: {
        sources.disconnect();
    }

    // -------------------------------------------------------------------------

    onDisconnect: {
        sources.disconnect();
    }

    // -------------------------------------------------------------------------

    onFullDisconnect: {
        sources.disconnect();
        discoveryAgent.stop();
        discoveryTimer.stop();
        reconnectTimer.stop();
        connectionErrorTimer.stop();
        errorWhileConnecting = false;
    }

    // -------------------------------------------------------------------------

    Connections {
        target: nmeaSource

        function onErrorChanged() {
            if (useFile) {
                console.log("NMEA log file error:", nmeaSource.error)

                if (stayConnected && !onSettingsPage) {
                    errorWhileConnecting = true;
                    connectionErrorTimer.start();
                    reconnect();
                } else {
                    nmeaLogFileError(nmeaLogFileOpenError);
                    connectionErrorTimer.stop();
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: tcpSocket

        function onErrorChanged() {
            if (useTCPConnection) {
                console.log("TCP connection error:", tcpSocket.error, tcpSocket.errorString)

                if (stayConnected && !onSettingsPage) {
                    errorWhileConnecting = true;
                    connectionErrorTimer.start();
                    reconnect();
                } else {
                    tcpError(tcpSocket.errorString);
                    connectionErrorTimer.stop();
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: currentDevice

        onConnectedChanged: {
            if (currentDevice && useExternalGPS) {
                if (stayConnected && !onSettingsPage) {
                    reconnect();
                }
            }
        }

        onErrorChanged: {
            if (currentDevice && useExternalGPS) {
                console.log("Device connection error:", currentDevice.error)

                if (stayConnected && !onSettingsPage) {
                    errorWhileConnecting = true;
                    connectionErrorTimer.start();
                    reconnect();
                } else {
                    deviceError(currentDevice.error);
                    connectionErrorTimer.stop();
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: discoveryAgent

        function onDiscoverDevicesCompleted() {
            console.log("Device discovery completed");
        }

        function onRunningChanged() {
            console.log("DeviceDiscoveryAgent running", discoveryAgent.running);
        }

        function onErrorChanged() {
            console.log("Device discovery agent error:", discoveryAgent.error)

            if (onSettingsPage) {
                discoveryAgentError(discoveryAgent.error);
            }
        }

        function onDeviceDiscovered() {
            if (discoveryAgent.deviceFilter(device)) {
                console.log("Device discovered - Name:", device.name, "Type:", device.deviceType);
            }
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: reconnectTimer

        interval: 1000
        running: false
        repeat: false

        onTriggered: {
            reconnectNow();
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: discoveryTimer

        interval: 100
        running: false
        repeat: false

        onTriggered: {
            discoveryAgent.start();
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: connectionTimeOutTimer

        interval: 60000
        running: isConnecting
        repeat: false

        onTriggered: {
            console.log("Connection attempt timed out");
            fullDisconnect();

            if (useExternalGPS) {
                deviceError(timeOutError);
            } else if (useTCPConnection) {
                tcpError(timeOutError);
            } else if (useFile) {
                nmeaLogFileError(timeOutError);
            }
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: connectionErrorTimer

        interval: 60000
        running: false
        repeat: false

        onTriggered: {
            console.log("Too many errors, giving up");
            fullDisconnect();

            if (useExternalGPS) {
                deviceError(currentDevice.error);
            } else if (useTCPConnection) {
                tcpError(tcpSocket.errorString);
            } else if (useFile) {
                nmeaLogFileError(nmeaLogFileOpenError);
            }
        }
    }

    // -------------------------------------------------------------------------
}
