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
import ArcGIS.AppFramework.Management 1.0

import "SurveyHelper.js" as Helper

// https://www.appconfig.org/appconfigspeccreator/

Item {
    id: appConfig

    //--------------------------------------------------------------------------

    property App app

    //--------------------------------------------------------------------------

    readonly property string portalResourceKey: propertyValue(kPropertyPortalResourceKey, kDefaultPortalResourceKey)
    readonly property string portalUrl: propertyValue(kPropertyPortalUrl, kDefaultPortalUrl)
    readonly property string portalName: propertyValue(kPropertyPortalName, kDefaultPortalName)
    readonly property var portalAuthentication: propertyArrayValue(kPropertyPortalAuthentication, kDefaultPortalAuthentication)
    readonly property bool portalNetworkAuthentication: isNetworkAuthentication(portalAuthentication)
    readonly property bool portalSingleSignOn: isSingleSignOn(portalAuthentication)
    readonly property bool portalSupportsOAuth: isOAuth(portalAuthentication)

    readonly property bool requireSignIn: propertyBoolValue(kPropertyRequireSignIn, kDefaultRequireSignIn)

    //--------------------------------------------------------------------------

    readonly property bool enablePortalManagement: propertyBoolValue(kPropertyEnablePortalManagement, kDefaultEnablePortalManagement)
    readonly property bool enableDiagnostics: propertyBoolValue(kPropertyEnableDiagnostics, kDefaultEnableDiagnostics)
    readonly property bool enableDataRecovery: propertyBoolValue(kPropertyEnableDataRecovery, kDefaultEnableDataRecovery)

    //--------------------------------------------------------------------------

    readonly property string kPropertyPortalResourceKey: "portalResourceKey"
    readonly property string kPropertyPortalUrl: "portalURL"
    readonly property string kPropertyPortalName: "portalName"
    readonly property string kPropertyPortalAuthentication: "portalAuthentication"

    readonly property string kPropertyRequireSignIn: "requireSignIn"

    readonly property string kAuthenticationIWA: "iwa"
    readonly property string kAuthenticationSingleSignOn: "sso"

    readonly property string kPropertyEnablePortalManagement: "enablePortalManagement"
    readonly property string kPropertyEnableDiagnostics: "enableDiagnostics"
    readonly property string kPropertyEnableDataRecovery: "enableDataRecovery"

    //--------------------------------------------------------------------------

    readonly property string kDefaultPortalResourceKey: "Survey123Properties"
    readonly property string kDefaultPortalUrl: "https://www.arcgis.com"
    readonly property string kDefaultPortalName: "ArcGIS Online"
    readonly property string kDefaultPortalAuthentication: ""

    readonly property bool kDefaultRequireSignIn: false

    readonly property bool kDefaultEnablePortalManagement: true
    readonly property bool kDefaultEnableDiagnostics: true
    readonly property bool kDefaultEnableDataRecovery: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "ManagedAppConfiguration.supported:", ManagedAppConfiguration.supported);

        console.log(logCategory, "portalResourceKey:", portalResourceKey);
        console.log(logCategory, "portalUrl:", portalUrl);
        console.log(logCategory, "portalName:", portalName);
        console.log(logCategory, "portalAuthentication:", JSON.stringify(portalAuthentication));
        console.log(logCategory, "enablePortalManagement:", enablePortalManagement);

        console.log(logCategory, "requireSignIn:", requireSignIn);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(appConfig, true)
    }

    //--------------------------------------------------------------------------

    function isEmpty(value) {
        return value === undefined || value === null || value === "";
    }

    //--------------------------------------------------------------------------

    function propertyValue(name, defaultValue) {
        console.log(arguments.callee.name, "name:", name);

        var value = app.info.propertyValue(name, "");

        console.log(arguments.callee.name, "\tapp value:", JSON.stringify(value));

        if (ManagedAppConfiguration.supported) {
            value = ManagedAppConfiguration.value(name, false, value);

            console.log(arguments.callee.name, "\tmanaged value:", JSON.stringify(value));
        }

        if (isEmpty(value)) {
            value = defaultValue;
        }

        console.log(arguments.callee.name, "\tfinal value:", JSON.stringify(value));

        return value;
    }

    //--------------------------------------------------------------------------

    function propertyBoolValue(name, defaultValue) {
        return Helper.toBoolean(propertyValue(name, defaultValue));
    }

    //--------------------------------------------------------------------------

    function propertyArrayValue(name, defaultValue) {
        var value = propertyValue(name, defaultValue);
        if (!value) {
            value = "";
        }

        return value.toLowerCase().split(",").map(e => e.trim()).filter(e => e > "");
    }

    //--------------------------------------------------------------------------

    function isNetworkAuthentication(authentication) {
        return contains(authentication, kAuthenticationIWA);
    }

    //--------------------------------------------------------------------------

    function isSingleSignOn(authentication) {
        return contains(authentication, kAuthenticationSingleSignOn)
                && Qt.platform.os === "windows";
    }

    //--------------------------------------------------------------------------

    function isOAuth(authentication) {
        return !contains(authentication, kAuthenticationIWA);
    }

    //--------------------------------------------------------------------------

    function contains(a, value) {
        if (!Array.isArray(a)) {
            return false;
        }

        return a.indexOf(value) >= 0;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: ManagedAppConfiguration

        function onPolicySettingsChanged() {
            console.log("ManagedAppConfiguration settings:", JSON.stringify(ManagedAppConfiguration.policySettings, undefined, 2));
        }

        function onPolicyDefaultsChanged() {
            console.log("ManagedAppConfiguration defaults:", JSON.stringify(ManagedAppConfiguration.policyDefaults, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------
}
