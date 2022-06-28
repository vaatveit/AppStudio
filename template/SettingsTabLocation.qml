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
import QtQml.Models 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../XForms"
import "../XForms/GNSS"
import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    id: settingsTabLocation

    //--------------------------------------------------------------------------

    title: qsTr("Location")
    description: qsTr("Manage location providers")
    icon.name: "satellite-3"

    //--------------------------------------------------------------------------

    property color iconColor: app.textColor
    property color textColor: app.textColor
    property color hoverBackgroundColor: "#e1f0fb"
    property color unselectedColor: app.textColor
    property color selectedColor: app.titleBarBackgroundColor
    property color selectedBackgroundColor: "#FAFAFA"
    property string fontFamily: app.fontFamily

    property real listDelegateHeight: 65 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------
    // Settings configuration

    // Show various "Add Provider" buttons (if supported by the platform)
    property bool showAddUSBProvider: true
    property bool showAddNetworkProvider: true
    property bool showAddFileProvider: true

    // Settings tabs to show in the detailed device configuration settings
    property bool showAboutDevice: true
    property bool showAlerts: true
    property bool showAntennaHeight: true
    property bool showAltitude: true
    property bool showAccuracy: gnssSettings.showAccuracySettings
    property bool showActivationMode: gnssSettings.showActivationModeSettings

    // Alert types to show in the alerts settings
    property bool showAlertsVisual: true
    property bool showAlertsSpeech: true
    property bool showAlertsVibrate: true
    property bool showAlertsTimeout: gnssSettings.showAlertsTimeoutSettings

    // Show provider alias if available
    property bool showProviderAlias: true

    //--------------------------------------------------------------------------
    // Internal properties

    readonly property AppSettings gnssSettings: appSettings
    readonly property PositioningSourcesController controller: app.positionSourceManager.controller
    readonly property Device currentDevice: controller.currentDevice
    readonly property string currentNmeaLogFile: controller.nmeaLogFile
    readonly property string currentNetworkAddress: controller.currentNetworkAddress

    readonly property bool isConnecting: controller.isConnecting
    readonly property bool isConnected: controller.isConnected

    readonly property bool showDetailedSettingsCog: showAboutDevice || showAlerts || showAntennaHeight || showAltitude || showAccuracy || showActivationMode
    readonly property bool showBluetoothOnly: !settingsTabLocation.showAddUSB && !settingsTabLocation.showAddNetworkProvider && !settingsTabLocation.showAddFileProvider
    readonly property bool showAddUSB: !(Qt.platform.os === "ios" || Qt.platform.os === "android") && showAddUSBProvider

    property string logFileLocation: app.logsFolder.path

    property var _addDeviceTab
    property var _addNetworkTab
    property var _addNMEALogTab

    property bool _dirty

    //--------------------------------------------------------------------------

    readonly property string kConnected: qsTr("Connected")
    readonly property string kConnecting: qsTr("Connecting")
    readonly property string kDisconnected: qsTr("Disconnected")

    readonly property string kDeviceTypeInternal: "Internal"
    readonly property string kDeviceTypeNetwork: "Network"
    readonly property string kDeviceTypeFile: "File"
    readonly property string kDeviceTypeBluetooth: "Bluetooth"
    readonly property string kDeviceTypeBluetoothLE: "BluetoothLE"
    readonly property string kDeviceTypeSerialPort: "SerialPort"
    readonly property string kDeviceTypeUnknown: "Unknown"

    readonly property var kDeviceIcons: ({
                                             "Bluetooth": "bluetooth",
                                             "BluetoothLE": "bluetooth",
                                             "File": "file",
                                             "Internal": "gps-on",
                                             "Network": "widgets-source",
                                             "SerialPort": "serial-port"
                                         })

    //--------------------------------------------------------------------------

    signal selectInternal()

    //--------------------------------------------------------------------------

    function resolveDeviceName(deviceType, deviceName, showFullPath) {
        switch (deviceType) {
        case kDeviceTypeInternal:
            return controller.integratedProviderName;
        case kDeviceTypeFile:
            if (showFullPath) {
                return gnssSettings.fileUrlToDisplayPath(deviceName);
            }
            return gnssSettings.fileUrlToLabel(deviceName);
        default:
            return deviceName;
        }
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        anchors.fill: parent
        Accessible.role: Accessible.Pane

        //----------------------------------------------------------------------

        Component.onCompleted: {
            controller.onSettingsPage = true;

            if (Qt.platform.os === "ios") {
                // On iOS this brings up a dialog notifying the user that Bluetooth
                // needs to be enabled to connect to external accessories
                Permission.serviceStatus(Permission.BluetoothService)
            }

            positionSourceConnection.start();
            _item.createListTabView(gnssSettings.knownDevices);
        }

        //----------------------------------------------------------------------

        Component.onDestruction: {
            controller.onSettingsPage = false;
        }

        //----------------------------------------------------------------------

        onWidthChanged: settingsTabLocation.width = _item.width

        //----------------------------------------------------------------------

        onHeightChanged: settingsTabLocation.height = _item.height

        //----------------------------------------------------------------------

        Connections {
            target: settingsTabLocation

            onActivated: {
                if (_dirty) {
                    _item.createListTabView(gnssSettings.knownDevices);
                    _dirty = false;
                }
            }
        }

        //----------------------------------------------------------------------

        Connections {
            target: gnssSettings

            onReceiverAdded: {
                _item.addDeviceListTab(name, gnssSettings.knownDevices)
                sortedListTabView.sort();
                _dirty = true;
            }

            onReceiverRemoved: {
                _dirty = true;
            }
        }

        //----------------------------------------------------------------------

        ListModel {
            id: cachedReceiversListModel
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent

            Accessible.role: Accessible.Pane

            spacing: 0

            ScrollView {
                id: scrollView

                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true

                SortedListTabView {
                    id: sortedListTabView

                    width: scrollView.availableWidth
                    height: scrollView.availableHeight

                    listSpacing: 2 * AppFramework.displayScaleFactor

                    delegate: deviceListDelegate

                    onSelected: pushItem(item)

                    lessThan: function(left, right) {
                        switch (left.deviceType) {
                        case kDeviceTypeInternal:
                            return true;
                        case kDeviceTypeBluetooth:
                        case kDeviceTypeBluetoothLE:
                        case kDeviceTypeNetwork:
                        case kDeviceTypeSerialPort:
                        case kDeviceTypeFile:
                        case kDeviceTypeUnknown:
                        default:
                            if (right.deviceType === kDeviceTypeInternal) {
                                return false;
                            }

                            return left.deviceLabel.localeCompare(right.deviceLabel) < 0 ? true : false;
                        }
                    }
                }
            }

            HorizontalSeparator {
                Layout.fillWidth: true
            }

            ActionGroupLayout {
                Layout.fillWidth: true

                font: ControlsSingleton.font
                locale: ControlsSingleton.localeProperties.locale
                palette {
                    window: app.backgroundColor
                    windowText: app.textColor
                }

                actionGroup: ActionGroup {
                    Action {
                        text: qsTr("Add location provider")
                        icon.name: "plus"

                        onTriggered: {
                            var popup = addProviderPopup.createObject(settingsTabLocation);
                            popup.open();
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: deviceTab

            SettingsTabLocationDevice {
                showAboutDevice: settingsTabLocation.showAboutDevice
                showAlerts: settingsTabLocation.showAlerts
                showAntennaHeight: settingsTabLocation.showAntennaHeight
                showAltitude: settingsTabLocation.showAltitude
                showAccuracy: settingsTabLocation.showAccuracy
                showActivationMode: settingsTabLocation.showActivationMode

                showAlertsVisual: settingsTabLocation.showAlertsVisual
                showAlertsSpeech: settingsTabLocation.showAlertsSpeech
                showAlertsVibrate: settingsTabLocation.showAlertsVibrate
                showAlertsTimeout: settingsTabLocation.showAlertsTimeout
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: addDeviceTab

            SettingsTabLocationAddDevice {
                receiverListModel: cachedReceiversListModel

                onShowReceiverSettingsPage: {
                    _item.showReceiverSettingsPage(deviceName)
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: addNetworkTab

            SettingsTabLocationAddNetwork {
                onShowReceiverSettingsPage: {
                    _item.showReceiverSettingsPage(deviceName)
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: addNMEALogTab

            SettingsTabLocationAddNmeaLog {
                logFileLocation: settingsTabLocation.logFileLocation

                onShowReceiverSettingsPage: {
                    _item.showReceiverSettingsPage(deviceName)
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: deviceListDelegate

            Rectangle {
                id: delegate

                property string delegateDeviceType: deviceType !== undefined ? deviceType : kDeviceTypeUnknown
                property string delegateDeviceName: deviceName !== undefined ? deviceName : ""
                property string delegateHostname: deviceProperties && deviceProperties.hostname !== undefined
                                                  ? deviceProperties.hostname
                                                  : ""
                property string delegatePort: deviceProperties && deviceProperties.port !== undefined
                                              ? deviceProperties.port
                                              : ""
                property string delegateFileName: deviceProperties && deviceProperties.filename !== undefined
                                                  ? deviceProperties.filename
                                                  : ""

                readonly property string label: deviceProperties.label

                property bool isInternal: delegateDeviceType === kDeviceTypeInternal
                property bool isNetwork: delegateDeviceType === kDeviceTypeNetwork
                property bool isFile: delegateDeviceType === kDeviceTypeFile
                property bool isDevice: !isInternal && !isNetwork&& !isFile

                property bool isSelected: isDevice && controller.useExternalGPS
                                          ? currentDevice && currentDevice.name === delegateDeviceName
                                          : isNetwork && controller.useTCPConnection
                                            ? controller.currentNetworkAddress === delegateHostname + ":" + delegatePort
                                            : isFile && controller.useFile
                                              ? controller.nmeaLogFile === delegateFileName
                                              : isInternal && controller.useInternalGPS

                readonly property bool hovered: tabAction.containsMouse || deviceSettingsMouseArea.containsMouse
                readonly property bool pressed: tabAction.containsPress || deviceSettingsMouseArea.containsPress

                Accessible.role: Accessible.Pane

                //--------------------------------------------------------------

                width: parent.parent.width
                height: settingsTabLocation.listDelegateHeight

                color: delegate.pressed
                       ? settingsTabLocation.hoverBackgroundColor
                       : delegate.hovered
                         ? settingsTabLocation.hoverBackgroundColor
                         : delegate.isSelected
                           ? settingsTabLocation.selectedBackgroundColor
                           : settingsTabLocation.selectedBackgroundColor

                readonly property color iconColor: delegate.pressed
                                                   ? settingsTabLocation.textColor
                                                   : delegate.hovered
                                                     ? settingsTabLocation.textColor
                                                     : delegate.isSelected
                                                       ? settingsTabLocation.selectedColor
                                                       : settingsTabLocation.iconColor

                readonly property color textColor: delegate.pressed
                                                   ? settingsTabLocation.textColor
                                                   : delegate.hovered
                                                     ? settingsTabLocation.textColor
                                                     : delegate.isSelected
                                                       ? settingsTabLocation.selectedColor
                                                       : settingsTabLocation.textColor

                //--------------------------------------------------------------

                onIsSelectedChanged: {
                    if (isSelected) {
                        Qt.callLater(ListView.view.positionViewAtIndex, DelegateModel.itemsIndex, ListView.Contain)
                    }
                }

                //----------------------------------------------------------------------

                ColumnLayout {
                    anchors.fill: parent

                    spacing: 0

                    RowLayout {
                        Layout.leftMargin: 8 * AppFramework.displayScaleFactor
                        Layout.rightMargin: Layout.leftMargin
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        spacing: 10 * AppFramework.displayScaleFactor
                        layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Accessible.role: Accessible.Pane

                            RowLayout {
                                anchors.fill: parent

                                spacing: 10 * AppFramework.displayScaleFactor
                                layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                                Accessible.role: Accessible.Pane

                                Item {
                                    Layout.preferredWidth: 32 * AppFramework.displayScaleFactor //height
                                    Layout.fillHeight: true

                                    Accessible.role: Accessible.Pane

                                    IconImage {
                                        id: selectedImage

                                        anchors.centerIn: parent

                                        width: parent.width
                                        height: width

                                        visible: delegate.isSelected && !isConnecting

                                        icon {
                                            name: isConnected
                                                  ? "check"
                                                  : "exclamation-mark-triangle"

                                            color: delegate.iconColor
                                        }
                                    }

                                    AppBusyIndicator {
                                        anchors.fill: selectedImage

                                        visible: delegate.isSelected && isConnecting
                                        backgroundColor: settingsTabLocation.selectedColor
                                        running: visible
                                    }
                                }

                                Item {
                                    Layout.preferredWidth: 32 * AppFramework.displayScaleFactor
                                    Layout.fillHeight: true

                                    Accessible.role: Accessible.Pane

                                    IconImage {
                                        width: parent.width
                                        height: width

                                        anchors.centerIn: parent

                                        icon {
                                            name: delegate.delegateDeviceType > ""
                                                  ? kDeviceIcons[delegate.delegateDeviceType]
                                                  : ""
                                            color: delegate.iconColor
                                        }

                                        Accessible.role: Accessible.Graphic
                                    }
                                }

                                Item {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true

                                    Accessible.role: Accessible.Pane

                                    ColumnLayout {
                                        id: textColumn

                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width

                                        spacing: 4 * AppFramework.displayScaleFactor

                                        readonly property bool hasAlias: modelData.title !== settingsTabLocation.resolveDeviceName(delegate.delegateDeviceType, delegate.delegateDeviceName, false) && !delegate.isInternal

                                        AppText {
                                            Layout.fillWidth: true

                                            text: modelData.title
                                            color: delegate.textColor

                                            font {
                                                pointSize: 16
                                                family: fontFamily
                                                bold: isSelected
                                            }

                                            horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                                            wrapMode: Text.NoWrap
                                            elide: ControlsSingleton.localeProperties.textElide
                                            clip: true

                                            Accessible.role: Accessible.StaticText
                                            Accessible.name: text
                                            Accessible.description: text
                                        }

                                        AppText {
                                            Layout.fillWidth: true

                                            visible: settingsTabLocation.showProviderAlias && textColumn.hasAlias

                                            text: settingsTabLocation.resolveDeviceName(delegate.delegateDeviceType, delegate.delegateDeviceName, false)
                                            color: delegate.textColor

                                            font {
                                                pointSize: 12
                                                family: fontFamily
                                                bold: false
                                            }

                                            horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                                            wrapMode: Text.NoWrap
                                            elide: ControlsSingleton.localeProperties.textElide
                                            clip: true

                                            Accessible.role: Accessible.StaticText
                                            Accessible.name: text
                                            Accessible.description: text
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: tabAction

                                anchors.fill: parent
                                hoverEnabled: true

                                Accessible.role: Accessible.Button

                                onClicked: {
                                    _item.connectProvider(delegate);
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: 32 * AppFramework.displayScaleFactor
                            Layout.fillHeight: true

                            visible: showDetailedSettingsCog
                            enabled: visible

                            Accessible.role: Accessible.Pane

                            IconImage {
                                anchors.centerIn: parent

                                width: 32 * AppFramework.displayScaleFactor
                                height: width

                                icon {
                                    name: "gear"
                                    color: delegate.iconColor
                                }

                                Accessible.role: Accessible.Graphic
                            }

                            MouseArea {
                                id: deviceSettingsMouseArea

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    sortedListTabView.selected(modelData);
                                }

                                Accessible.role: Accessible.Button
                            }
                        }
                    }
                }

                Connections {
                    target: settingsTabLocation

                    onSelectInternal: {
                        if (delegate.delegateDeviceType === kDeviceTypeInternal) {
                            _item.connectProvider(delegate);
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: addProviderPopup

            ActionsPopup {
                parent: app

                icon.name: "satellite-3"
                title: qsTr("Select Connection Type")

                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                actionsLayout {
                    onTriggered: {
                        close();
                    }
                }

                Action {
                    text: qsTr("Bluetooth")
                    icon.name: "bluetooth"

                    onTriggered: {
                        positionSourceManager.discoverBluetooth = true;
                        positionSourceManager.discoverBluetoothLE = false;
                        positionSourceManager.discoverSerialPort = false;

                        if (!_addDeviceTab) {
                            _addDeviceTab = addDeviceTab.createObject(_item);
                        }

                        pushItem(_addDeviceTab);
                    }
                }

                Action {
                    enabled: settingsTabLocation.showAddUSB
                    text: qsTr("USB")
                    icon.name: "serial-port"

                    onTriggered: {
                        positionSourceManager.discoverBluetooth = false;
                        positionSourceManager.discoverBluetoothLE = false;
                        positionSourceManager.discoverSerialPort = true;

                        if (!_addDeviceTab) {
                            _addDeviceTab = addDeviceTab.createObject(_item);
                        }

                        pushItem(_addDeviceTab);
                    }
                }

                Action {
                    enabled: settingsTabLocation.showAddNetworkProvider
                    text: qsTr("Network")
                    icon.name: "widgets-source"

                    onTriggered: {
                        if (!_addNetworkTab) {
                            _addNetworkTab = addNetworkTab.createObject(_item);
                        }

                        pushItem(_addNetworkTab);
                    }
                }

                Action {
                    enabled: settingsTabLocation.showAddFileProvider
                    text: qsTr("File")
                    icon.name: "file-text"

                    onTriggered: {
                        if (!_addNMEALogTab) {
                            _addNMEALogTab = addNMEALogTab.createObject(_item);
                        }

                        pushItem(_addNMEALogTab);
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        XFormPositionSourceConnection {
            id: positionSourceConnection

            positionSourceManager: app.positionSourceManager
            stayActiveOnError: true
            listener: "LocationSettings"

            Accessible.ignored: true
        }

        //----------------------------------------------------------------------

        SettingsTabContainer {
            id: settingsTabContainer
        }

        //----------------------------------------------------------------------

        function createListTabView(devicesList) {
            for (var i = 0; i < sortedListTabView.contentData.length; i++) {
                var tab = sortedListTabView.contentData[i]
                tab.destroy();
            }

            sortedListTabView.contentData = null;
            cachedReceiversListModel.clear();

            for (var deviceName in devicesList) {
                _item.addDeviceListTab(deviceName, devicesList)
            }

            // make sure the list is sorted
            sortedListTabView.sort();

            // highlight the currently selected item
            for (i = 0; i < sortedListTabView.model.count; i++) {
                var item = sortedListTabView.model.get(i).model;

                if (item.deviceName === controller.currentName) {
                    sortedListTabView.listTabView.positionViewAtIndex(i, ListView.Contain);
                    break;
                }
            }
        }

        //----------------------------------------------------------------------

        function addDeviceListTab(deviceName, devicesList) {
            if (deviceName === "") {
                return;
            }

            var receiverSettings = devicesList[deviceName];
            var deviceType = "";

            if (receiverSettings.receiver) {
                deviceType = receiverSettings.receiver.deviceType;
                cachedReceiversListModel.append({name: deviceName, deviceType: receiverSettings.receiver.deviceType});
            } else if (receiverSettings.hostname > "" && receiverSettings.port) {
                deviceType = kDeviceTypeNetwork;
                cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeNetwork});
            } else if (receiverSettings.filename > "") {
                deviceType = kDeviceTypeFile;
                cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeFile});
            } else if (deviceName === gnssSettings.kInternalPositionSourceName) {
                deviceType = kDeviceTypeInternal;
                cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeInternal});
            } else {
                return;
            }

            var _deviceTab = deviceTab.createObject(sortedListTabView.tabViewContainer, {
                                                        "title": receiverSettings.label && receiverSettings.label > "" ? receiverSettings.label : deviceName,
                                                        "deviceType": deviceType,
                                                        "deviceName": deviceName,
                                                        "deviceLabel": receiverSettings.label && receiverSettings.label > "" ? receiverSettings.label : deviceName,
                                                        "deviceProperties": receiverSettings
                                                    });

            _deviceTab.selectInternal.connect(function() {
                selectInternal();
            });

            _deviceTab.updateViewAndDelegate.connect(function() {
                _dirty = true;
            });
        }

        //----------------------------------------------------------------------

        function connectProvider(delegate) {
            if (delegate.isDevice) {
                if ( (!isConnecting && !isConnected) || !controller.useExternalGPS || (currentDevice && currentDevice.name !== delegate.delegateDeviceName) ) {
                    var device = gnssSettings.knownDevices[delegate.delegateDeviceName].receiver;
                    gnssSettings.createExternalReceiverSettings(delegate.delegateDeviceName, device);

                    controller.deviceSelected(Device.fromJson(JSON.stringify(device), controller));
                } else {
                    controller.deviceDeselected();
                }
            } else if (delegate.isNetwork) {
                if ( (!isConnecting && !isConnected) || !controller.useTCPConnection || (currentNetworkAddress > "" && currentNetworkAddress !== delegate.delegateDeviceName) ) {
                    var address = delegate.delegateDeviceName.split(":");
                    gnssSettings.createNetworkSettings(address[0], address[1]);

                    controller.networkHostSelected(address[0], address[1]);
                } else {
                    controller.deviceDeselected();
                }
            } else if (delegate.isFile) {
                if ( (!isConnecting && !isConnected) || !controller.useFile || (currentNmeaLogFile > "" && currentNmeaLogFile !== delegate.delegateDeviceName) ) {
                    gnssSettings.createNmeaLogFileSettings(delegate.delegateFileName);

                    controller.nmeaLogFileSelected(delegate.delegateFileName);
                } else {
                    controller.deviceDeselected();
                }
            } else if (delegate.isInternal) {
                controller.deviceDeselected();
                gnssSettings.createInternalSettings();
            } else {
                controller.deviceDeselected();
            }

            return;
        }

        //----------------------------------------------------------------------

        function showReceiverSettingsPage(name) {
            var listModel = sortedListTabView.contentData;

            var item = null;
            for (var i=0; i<listModel.length; i++) {
                if (listModel[i].deviceType === kDeviceTypeFile && listModel[i].deviceProperties.filename === name) {
                    item = listModel[i];
                    break;
                } else if (listModel[i].title === name) {
                    item = listModel[i];
                    break;
                }
            }

            if (item) {
                replaceItem(item);
            } else {
                app.mainStackView.pop();
            }
        }

        //----------------------------------------------------------------------

        function pushItem(item) {
            app.mainStackView.push(settingsTabContainer,
                                   {
                                       settingsTab: item,
                                       title: item.title,
                                       settingsComponent: item.contentComponent
                                   });
        }

        //----------------------------------------------------------------------

        function replaceItem(item) {
            app.mainStackView.push({
                                       item: settingsTabContainer,
                                       replace: true,
                                       properties: {
                                           settingsTab: item,
                                           title: item.title,
                                           settingsComponent: item.contentComponent
                                       }
                                   });
        }

        //--------------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------
}
