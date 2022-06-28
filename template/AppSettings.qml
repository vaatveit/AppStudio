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
import QtSensors 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Notifications 1.0

QtObject {
    id: object

    //--------------------------------------------------------------------------

    property App app
    property Settings settings: app.settings

    //--------------------------------------------------------------------------

    // Map

    property string mapPlugin: kDefaultMapPlugin

    // Accessibility

    property bool boldText: false
    property bool plainBackgrounds: true
    property bool hapticFeedback: HapticFeedback.supported

    // Text

    property string defaultFontFamily: app.info.propertyValue(kKeyFontFamily, fontFamily)
    property string fontFamily: Qt.application.font.family
    property real textScaleFactor: 1

    // Storage

    property string mapLibraryPaths: kDefaultMapLibraryPath

    // Spatial reference

    property int defaultWkid: 4326
    property int wkid: defaultWkid

    // Location

    // default settings - allow the user to set the GNSS defaults needed in the app
    property bool defaultShowActivationModeSettings: false
    property bool defaultShowAlertsTimeoutSettings: false
    property bool defaultShowAccuracySettings: false

    property bool defaultLocationAlertsVisualInternal: false
    property bool defaultLocationAlertsSpeechInternal: false
    property bool defaultLocationAlertsVibrateInternal: false

    property bool defaultLocationAlertsVisualExternal: true
    property bool defaultLocationAlertsSpeechExternal: true
    property bool defaultLocationAlertsVibrateExternal: true

    property bool defaultLocationAlertsMonitorNmeaData: false

    property int defaultLocationMaximumDataAge: 5000
    property int defaultLocationMaximumPositionAge: 5000
    property int defaultLocationSensorActivationMode: kActivationModeAlways
    property int defaultLocationSensorConnectionType: kConnectionTypeInternal
    property int defaultLocationAltitudeType: kAltitudeTypeMSL
    property int defaultLocationConfidenceLevelType: kConfidenceLevelType68

    property real defaultLocationGeoidSeparation: Number.NaN
    property real defaultLocationAntennaHeight: Number.NaN

    // current settings state
    property bool showActivationModeSettings: defaultShowActivationModeSettings
    property bool showAlertsTimeoutSettings: defaultShowAlertsTimeoutSettings
    property bool showAccuracySettings: defaultShowAccuracySettings

    property bool locationAlertsVisual: defaultLocationAlertsVisualInternal
    property bool locationAlertsSpeech: defaultLocationAlertsSpeechInternal
    property bool locationAlertsVibrate: defaultLocationAlertsVibrateInternal

    property bool locationAlertsMonitorNmeaData: defaultLocationAlertsMonitorNmeaData

    property int locationMaximumDataAge: defaultLocationMaximumDataAge
    property int locationMaximumPositionAge: defaultLocationMaximumPositionAge
    property int locationSensorActivationMode: defaultLocationSensorActivationMode
    property int locationSensorConnectionType: defaultLocationSensorConnectionType
    property int locationAltitudeType: defaultLocationAltitudeType
    property int locationConfidenceLevelType: defaultLocationConfidenceLevelType

    property real locationGeoidSeparation: defaultLocationGeoidSeparation
    property real locationAntennaHeight: defaultLocationAntennaHeight

    property string lastUsedDeviceLabel: ""
    property string lastUsedDeviceName: ""
    property string lastUsedDeviceJSON: ""
    property string hostname: ""
    property string port: ""

    property string nmeaLogFile: ""
    property int updateInterval: 0
    property bool repeat: false

    property var knownDevices: ({})

    // Compass

    readonly property bool compassAvailable: QmlSensors.sensorTypes().indexOf("QCompass") >= 0

    property bool compassEnabled
    property real magneticDeclination: 0

    //--------------------------------------------------------------------------

    readonly property string kKeyApp: "App"

    // Map

    readonly property string kKeyMapPlugin: "mapPlugin"
    readonly property string kDefaultMapPlugin: getDefaultMapPlugin()

    readonly property string kPluginAppStudio: "AppStudio"
    readonly property string kPluginArcGISRuntime: "ArcGISRuntime"


    // Accessibility

    readonly property string kKeyAccessibilityPrefix: "Accessibility/"
    readonly property string kKeyAccessibilityBoldText: kKeyAccessibilityPrefix + "boldText"
    readonly property string kKeyAccessibilityPlainBackgrounds: kKeyAccessibilityPrefix + "plainBackgrounds"
    readonly property string kKeyAccessibilityHapticFeedback: kKeyAccessibilityPrefix + "hapticFeedback"

    // Text

    readonly property string kKeyFontFamily: "fontFamily"
    readonly property string kKeyTextScaleFactor: "textScaleFactor"

    // Storage

    readonly property string kDefaultMapLibraryPath: "~/ArcGIS/My Surveys/Maps"
    readonly property string kKeyMapLibraryPaths: "mapLibraryPaths"

    // Spatial reference

    readonly property string kKeyWkid: "wkid"

    // Location

    // this is used to access the integrated provider settings, DO NOT CHANGE
    readonly property string kInternalPositionSourceName: "IntegratedProvider"

    // this is the (translated) name of the integrated provider as it appears on the settings page
    readonly property string kInternalPositionSourceNameTranslated: qsTr("Integrated Provider")

    readonly property string kKeyLocationPrefix: "Location/"
    readonly property string kKeyLocationKnownDevices: kKeyLocationPrefix + "knownDevices"
    readonly property string kKeyLocationLastUsedDevice: kKeyLocationPrefix + "lastUsedDevice"

    readonly property string kKeyShowActivationModeSettings: kKeyLocationPrefix + "ShowActivationModeSettings"
    readonly property string kKeyShowAlertsTimeoutSettings: kKeyLocationPrefix + "ShowAlertsTimeoutSettings"
    readonly property string kKeyShowAccuracySettings: kKeyLocationPrefix + "ShowAccuracySettings"

    readonly property int kActivationModeAsNeeded: 0
    readonly property int kActivationModeInSurvey: 1
    readonly property int kActivationModeAlways: 2

    readonly property int kConnectionTypeInternal: 0
    readonly property int kConnectionTypeExternal: 1
    readonly property int kConnectionTypeNetwork: 2
    readonly property int kConnectionTypeFile: 3

    readonly property int kAltitudeTypeMSL: 0
    readonly property int kAltitudeTypeHAE: 1

    readonly property int kConfidenceLevelType68: 0
    readonly property int kConfidenceLevelType95: 1

    // Compass

    readonly property string kKeyCompassEnabled: "compassEnabled"
    readonly property string kKeyMagneticDeclination: "magneticDeclination"
    readonly property bool kDefaultCompassEnabled: compassAvailable && app.features.enableCompass


    // rect, size

    readonly property string kKeyX: "x"
    readonly property string kKeyY: "y"
    readonly property string kKeyWidth: "width"
    readonly property string kKeyHeight: "height"

    //--------------------------------------------------------------------------

    property bool updating

    signal receiverAdded(string name)
    signal receiverRemoved(string name)

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(object, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "defaultMapPlugin:", kDefaultMapPlugin);
    }

    //--------------------------------------------------------------------------

    function getDefaultMapPlugin() {
        if (Qt.platform.os === "android") {
            var systemInformation = AppFramework.systemInformation;

            var architecture = systemInformation.unixMachine !== undefined
                    ? systemInformation.unixMachine
                    : AppFramework.currentCpuArchitecture;

            if (typeof architecture === "string" && architecture.startsWith("armv7")) {
                return kPluginAppStudio;
            }
        } else if (Qt.platform.os === "ios" && parseFloat(AppFramework.osVersion) < 13) {
            return kPluginAppStudio;
        }

        return app.info.propertyValue(kKeyMapPlugin, kPluginArcGISRuntime);
    }

    //--------------------------------------------------------------------------

    // update the current global settings on receiver change
    onLastUsedDeviceNameChanged: {
        updating = true;

        if (knownDevices && lastUsedDeviceName > "") {
            var receiver = knownDevices[lastUsedDeviceName];

            if (receiver) {
                switch (receiver.connectionType) {
                case kConnectionTypeInternal:
                    lastUsedDeviceLabel = receiver.label;
                    lastUsedDeviceJSON = "";
                    hostname = "";
                    port = "";
                    nmeaLogFile = "";
                    updateInterval = 0;
                    repeat = false;
                    break;

                case kConnectionTypeExternal:
                    lastUsedDeviceLabel = receiver.label;
                    lastUsedDeviceJSON = receiver.receiver > "" ? JSON.stringify(receiver.receiver) : "";
                    hostname = "";
                    port = "";
                    nmeaLogFile = "";
                    updateInterval = 0;
                    repeat = false;
                    break;

                case kConnectionTypeNetwork:
                    lastUsedDeviceLabel = receiver.label;
                    lastUsedDeviceJSON = ""
                    hostname = receiver.hostname;
                    port = receiver.port;
                    nmeaLogFile = "";
                    updateInterval = 0;
                    repeat = false;
                    break;

                case kConnectionTypeFile:
                    lastUsedDeviceLabel = receiver.label;
                    lastUsedDeviceJSON = ""
                    hostname = "";
                    port = "";
                    nmeaLogFile = receiver.filename;
                    updateInterval = receiver.updateinterval;
                    repeat = receiver.repeat;
                    break;

                default:
                    console.log("Error: unknown connectionType", receiver.connectionType);
                    updating = false;
                    return;
                }

                function receiverSetting(name, defaultValue) {
                    if (!receiver) {
                        return defaultValue;
                    }

                    var value = receiver[name];
                    if (value !== null && value !== undefined) {
                        return value;
                    } else {
                        return defaultValue;
                    }
                }

                locationAlertsVisual = receiverSetting("locationAlertsVisual", defaultLocationAlertsVisualInternal);
                locationAlertsSpeech = receiverSetting("locationAlertsSpeech", defaultLocationAlertsSpeechInternal);
                locationAlertsVibrate = receiverSetting("locationAlertsVibrate", defaultLocationAlertsVibrateInternal);
                locationAlertsMonitorNmeaData = receiverSetting("locationAlertsMonitorNmeaData", defaultLocationAlertsMonitorNmeaData);
                locationMaximumDataAge = receiverSetting("locationMaximumDataAge", defaultLocationMaximumDataAge);
                locationMaximumPositionAge = receiverSetting("locationMaximumPositionAge", defaultLocationMaximumPositionAge);
                locationSensorActivationMode = receiverSetting("activationMode", defaultLocationSensorActivationMode);
                locationSensorConnectionType = receiverSetting("connectionType", defaultLocationSensorConnectionType);
                locationAltitudeType = receiverSetting("altitudeType", defaultLocationAltitudeType);
                locationConfidenceLevelType = receiverSetting("confidenceLevelType", defaultLocationConfidenceLevelType);
                locationGeoidSeparation = receiverSetting("geoidSeparation", defaultLocationGeoidSeparation);
                locationAntennaHeight = receiverSetting("antennaHeight", defaultLocationAntennaHeight);
            }
        }

        updating = false;
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log(logCategory, "Reading app settings -", settings.path);

        // Map

        mapPlugin = settings.value(kKeyMapPlugin, kDefaultMapPlugin);

        // Accessibility

        boldText = settings.boolValue(kKeyAccessibilityBoldText, false);
        plainBackgrounds = settings.boolValue(kKeyAccessibilityPlainBackgrounds, true);
        hapticFeedback = settings.boolValue(kKeyAccessibilityHapticFeedback, HapticFeedback.supported);

        // Text

        fontFamily = settings.value(kKeyFontFamily, defaultFontFamily);
        textScaleFactor = settings.value(kKeyTextScaleFactor, 1);

        // Storage

        mapLibraryPaths = settings.value(kKeyMapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        wkid = settings.numberValue(kKeyWkid, defaultWkid);

        // Location

        showActivationModeSettings = settings.boolValue(kKeyShowActivationModeSettings, defaultShowActivationModeSettings);
        showAlertsTimeoutSettings = settings.boolValue(kKeyShowAlertsTimeoutSettings, defaultShowAlertsTimeoutSettings);
        showAccuracySettings = settings.boolValue(kKeyShowAccuracySettings, defaultShowAccuracySettings);

        try {
            knownDevices = JSON.parse(settings.value(kKeyLocationKnownDevices, "{}"));
        } catch (e) {
            console.log(logCategory, "Error while parsing settings file.", e);
        }

        var internalFound = false;
        for (var deviceName in knownDevices) {
            // add default internal position source if necessary
            if (deviceName === kInternalPositionSourceName) {
                internalFound = true;
            }

            // clean up device settings if necessary (activationMode was previously connectionMode)
            if (!knownDevices[deviceName].activationMode && knownDevices[deviceName].activationMode !== 0) {
                knownDevices[deviceName].activationMode = kActivationModeAlways;
                delete knownDevices[deviceName].connectionMode;
            }
        }

        if (!internalFound) {
            createInternalSettings();
        } else {
            // update the label of the internal position source provider in case the system
            // language has changed since last using the app
            var receiverSettings = knownDevices[kInternalPositionSourceName];
            if (receiverSettings && receiverSettings["label"] !== kInternalPositionSourceNameTranslated) {
                receiverSettings["label"] = kInternalPositionSourceNameTranslated;
            }

            // this triggers an update of the global settings using the last known receiver
            lastUsedDeviceName = settings.value(kKeyLocationLastUsedDevice, kInternalPositionSourceName)
        }

        // Compass

        compassEnabled = settings.boolValue(kKeyCompassEnabled, kDefaultCompassEnabled);
        magneticDeclination = settings.value(kKeyMagneticDeclination, 0);

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log(logCategory, "Writing app settings -", settings.path);

        // Map

        settings.setValue(kKeyMapPlugin, mapPlugin, kDefaultMapPlugin);

        // Accessibility

        settings.setValue(kKeyAccessibilityBoldText, boldText, false);
        settings.setValue(kKeyAccessibilityPlainBackgrounds, plainBackgrounds, true);
        settings.setValue(kKeyAccessibilityHapticFeedback, hapticFeedback, HapticFeedback.supported);

        // Text

        settings.setValue(kKeyFontFamily, fontFamily, defaultFontFamily);
        settings.setValue(kKeyTextScaleFactor, textScaleFactor, 1);

        // Storage

        settings.setValue(kKeyMapLibraryPaths, mapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        settings.setValue(kKeyWkid, wkid, defaultWkid);

        // Location

        settings.setValue(kKeyShowActivationModeSettings, showActivationModeSettings, defaultShowActivationModeSettings);
        settings.setValue(kKeyShowAlertsTimeoutSettings, showAlertsTimeoutSettings, defaultShowAlertsTimeoutSettings);
        settings.setValue(kKeyShowAccuracySettings, showAccuracySettings, defaultShowAccuracySettings);

        settings.setValue(kKeyLocationLastUsedDevice, lastUsedDeviceName, kInternalPositionSourceName);
        settings.setValue(kKeyLocationKnownDevices, JSON.stringify(knownDevices), ({}));


        // Compass

        settings.setValue(kKeyCompassEnabled, compassEnabled, kDefaultCompassEnabled);
        settings.setValue(kKeyMagneticDeclination, magneticDeclination, 0);

        //log();
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "App settings -");

        // Map

        console.log(logCategory, "* mapPlugin:", mapPlugin);

        // Accessibility

        console.log(logCategory, "* boldText:", boldText);
        console.log(logCategory, "* plainBackgrounds:", plainBackgrounds);
        console.log(logCategory, "* hapticFeedback:", hapticFeedback);

        // Text

        console.log(logCategory, "* fontFamily:", fontFamily);
        console.log(logCategory, "* textScaleFactor:", textScaleFactor);

        // Storage

        console.log(logCategory, "* mapLibraryPaths:", mapLibraryPaths);

        // Spatial reference

        console.log(logCategory, "* wkid:", wkid);

        // Location

        console.log(logCategory, "* showActivationModeSettings", showActivationModeSettings);
        console.log(logCategory, "* showAlertsTimeoutSettings", showAlertsTimeoutSettings);
        console.log(logCategory, "* showAccuracySettings", showAccuracySettings);

        console.log(logCategory, "* locationAlertsVisual:", locationAlertsVisual);
        console.log(logCategory, "* locationAlertsSpeech:", locationAlertsSpeech);
        console.log(logCategory, "* locationAlertsVibrate:", locationAlertsVibrate);

        console.log(logCategory, "* locationAlertsMonitorNmeaData:", locationAlertsMonitorNmeaData);

        console.log(logCategory, "* locationMaximumDataAge:", locationMaximumDataAge);
        console.log(logCategory, "* locationMaximumPositionAge:", locationMaximumPositionAge);
        console.log(logCategory, "* locationSensorActivationMode:", locationSensorActivationMode);
        console.log(logCategory, "* locationSensorConnectionType:", locationSensorConnectionType);
        console.log(logCategory, "* locationAltitudeType:", locationAltitudeType);
        console.log(logCategory, "* locationConfidenceLevelType:", locationConfidenceLevelType);

        console.log(logCategory, "* locationGeoidSeparation:", locationGeoidSeparation);
        console.log(logCategory, "* locationAntennaHeight:", locationAntennaHeight);

        console.log(logCategory, "* lastUsedDeviceName:", lastUsedDeviceName);
        console.log(logCategory, "* lastUsedDeviceLabel:", lastUsedDeviceLabel);

        console.log(logCategory, "* knownDevices:", JSON.stringify(knownDevices, undefined, 2));

        // Compass

        console.log(logCategory, "* compassEnabled:", compassEnabled);
    }

    //--------------------------------------------------------------------------

    function createDefaultSettingsObject(connectionType) {
        return {
            "locationAlertsVisual": connectionType === kConnectionTypeInternal ? defaultLocationAlertsVisualInternal : defaultLocationAlertsVisualExternal,
            "locationAlertsSpeech": connectionType === kConnectionTypeInternal ? defaultLocationAlertsSpeechInternal : defaultLocationAlertsSpeechExternal,
            "locationAlertsVibrate": connectionType === kConnectionTypeInternal ? defaultLocationAlertsVibrateInternal : defaultLocationAlertsVibrateExternal,
            "locationAlertsMonitorNmeaData": defaultLocationAlertsMonitorNmeaData,
            "locationMaximumDataAge": defaultLocationMaximumDataAge,
            "locationMaximumPositionAge": defaultLocationMaximumPositionAge,
            "activationMode": defaultLocationSensorActivationMode,
            "altitudeType": defaultLocationAltitudeType,
            "confidenceLevelType": defaultLocationConfidenceLevelType,
            "antennaHeight": defaultLocationAntennaHeight,
            "geoidSeparation": defaultLocationGeoidSeparation,
            "connectionType": connectionType
        }
    }

    //--------------------------------------------------------------------------

    function createInternalSettings() {
        if (knownDevices) {
            // use the fixed internal provider name as the identifier
            var name = kInternalPositionSourceName;

            if (!knownDevices[name]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeInternal);

                // use the localised internal provider name as the label
                receiverSettings["label"] = kInternalPositionSourceNameTranslated;

                knownDevices[name] = receiverSettings;
                receiverAdded(name);
            }

            lastUsedDeviceName = name;

            return name;
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function createExternalReceiverSettings(deviceName, device) {
        if (knownDevices && device && deviceName > "") {

            if (!knownDevices[deviceName]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeExternal);
                receiverSettings["receiver"] = device;
                receiverSettings["label"] = deviceName;

                knownDevices[deviceName] = receiverSettings;
                receiverAdded(deviceName);
            }

            lastUsedDeviceName = deviceName;

            return deviceName;
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function createNetworkSettings(hostname, port) {
        if (knownDevices && hostname > "" && port > "") {
            var networkAddress = hostname + ":" + port;

            if (!knownDevices[networkAddress]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeNetwork);
                receiverSettings["hostname"] = hostname;
                receiverSettings["port"] = port;
                receiverSettings["label"] = networkAddress;

                knownDevices[networkAddress] = receiverSettings;
                receiverAdded(networkAddress);
            }

            lastUsedDeviceName = networkAddress;

            return networkAddress;
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function createNmeaLogFileSettings(fileUrl) {
        if (knownDevices && fileUrl > "") {
            var label = fileUrlToLabel(fileUrl);

            if (!knownDevices[fileUrl]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeFile);
                receiverSettings["filename"] = fileUrl;
                receiverSettings["label"] = label;
                receiverSettings["updateinterval"] = 1000;
                receiverSettings["repeat"] = true;

                knownDevices[fileUrl] = receiverSettings;
                receiverAdded(fileUrl);
            }

            lastUsedDeviceName = fileUrl;

            return label;
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function deleteKnownDevice(deviceName) {
        try {
            delete knownDevices[deviceName];
            receiverRemoved(deviceName);
        }
        catch(e){
            console.log(logCategory, e);
        }
    }

    //--------------------------------------------------------------------------

    function fileUrlToLabel(fileUrl) {
        return AppFramework.fileInfo(fileUrl).displayName;
    }

    //--------------------------------------------------------------------------

    function fileUrlToDisplayPath(fileUrl) {
        var path = fileUrlToPath(fileUrl);

        if (Qt.platform.os === "android") {
            path = path.replace(/%3A/g, ":").replace(/%2F/g, "/").replace(/%20/g, ":");
            var prefix = path.substring(0, path.lastIndexOf(":") + 1);
            prefix = prefix.substring(prefix.lastIndexOf("/") + 1);
            path = path.substring(path.lastIndexOf(":") + 1)
            path = prefix + path.substring(path.lastIndexOf(":") + 1, path.lastIndexOf("/") + 1);
            path = path + fileUrlToLabel(fileUrl);
        }

        return path;
    }

    //--------------------------------------------------------------------------

    function fileUrlToPath(fileUrl) {
        var fileInfo = AppFramework.fileInfo(fileUrl);
        var path = Qt.platform.os === "ios" ? fileInfo.filePath.replace(AppFramework.userHomePath + "/", "") : fileInfo.filePath;

        return path;
    }

    //--------------------------------------------------------------------------

    function keyName(prefix, name) {
        if (prefix > "") {
            if (!prefix.endsWith("/")) {
                prefix += "/";
            }

            return prefix + name;
        } else {
            return name;
        }
    }

    //--------------------------------------------------------------------------

    function readSize(keyPrefix, defaultSize) {
        if (!defaultSize) {
            defaultSize = Qt.size(0, 0);
        }

        var width = settings.value(keyName(keyPrefix, kKeyWidth), defaultSize.width);
        var height = settings.value(keyName(keyPrefix, kKeyHeight), defaultSize.height);

        return Qt.size(width, height);
    }

    //--------------------------------------------------------------------------

    function writeSize(keyPrefix, size) {
        if (!size) {
            settings.remove(keyName(keyPrefix, kKeyWidth));
            settings.remove(keyName(keyPrefix, kKeyHeight));

            return;
        }

        settings.setValue(keyName(keyPrefix, kKeyWidth), size.width);
        settings.setValue(keyName(keyPrefix, kKeyHeight), size.height);
    }

    //--------------------------------------------------------------------------

    function readRect(keyPrefix, defaultRect) {
        if (!defaultRect) {
            defaultRect = Qt.rect(0, 0, 0, 0);
        }

        var x = settings.value(keyName(keyPrefix, kKeyX), defaultRect.x);
        var y = settings.value(keyName(keyPrefix, kKeyY), defaultRect.y);
        var width = settings.value(keyName(keyPrefix, kKeyWidth), defaultRect.width);
        var height = settings.value(keyName(keyPrefix, kKeyHeight), defaultRect.height);

        return Qt.rect(x, y, width, height);
    }

    //--------------------------------------------------------------------------

    function writeRect(keyPrefix, rect) {
        if (!rect) {
            settings.remove(keyName(keyPrefix, kKeyX));
            settings.remove(keyName(keyPrefix, kKeyY));
            settings.remove(keyName(keyPrefix, kKeyWidth));
            settings.remove(keyName(keyPrefix, kKeyHeight));

            return;
        }

        settings.setValue(keyName(keyPrefix, kKeyX), rect.x);
        settings.setValue(keyName(keyPrefix, kKeyY), rect.y);
        settings.setValue(keyName(keyPrefix, kKeyWidth), rect.width);
        settings.setValue(keyName(keyPrefix, kKeyHeight), rect.height);
    }

    //--------------------------------------------------------------------------
}
