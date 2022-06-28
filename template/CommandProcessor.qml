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

import "../XForms/XForm.js" as XFormJS
import "SurveyHelper.js" as Helper


Item {
    id: commandProcessor

    //--------------------------------------------------------------------------

    property App app
    property string appScheme: app.info.value("urlScheme") || ""
    property string appLink: app.info.value("appLink") || ""
    readonly property string appLinkHost: AppFramework.urlInfo(appLink).host.toLowerCase()
    property FileFolder logsFolder
    property bool enableDiagnostics: true

    //--------------------------------------------------------------------------

    readonly property string kSchemeSysLog: "syslog"
    readonly property string kSchemeLogging: "logging"

    readonly property string kHostLogging: "logging"

    readonly property string kPropertyEnabled: "enabled"
    readonly property string kPropertyUserData: "userData"
    readonly property string kPropertyOutputLocation: "outputLocation"
    readonly property string kPropertyFile: "file"

    readonly property string kSuffixLog: "log"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "appScheme:", appScheme);
        console.log(logCategory, "appLinkHost:", appLinkHost);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(commandProcessor, true)
    }

    //--------------------------------------------------------------------------

    function parse(command) {
        var urlInfo = AppFramework.urlInfo(command);
        if (!urlInfo.isValid) {
            return;
        }

        var scheme = urlInfo.scheme.toLowerCase();

        if (urlInfo.scheme === appScheme) {
            if (urlInfo.host > "") {
                return invoke(urlInfo);
            }

            Qt.callLater(function () {
                console.log(logCategory, arguments.callee.name, "opening url:", urlInfo.url);

                app.openUrl(urlInfo.url);
            });

            return true;
        } else if (urlInfo.scheme === kSchemeSysLog) {
            return syslog(urlInfo);
        } else if (urlInfo.scheme === kSchemeLogging) {
            return loggingCommand(urlInfo);
        } else if (scheme === "https" && urlInfo.host === "arcg.is") {
            console.log(logCategory, arguments.callee.name, "ArcGIS url:", urlInfo.url);

            Qt.openUrlExternally(urlInfo.url);

            return true;
        } else if (scheme === "https" || scheme === "http") {
            var url;

            if (urlInfo.host.toLowerCase() === appLinkHost) {
                url = appScheme + "://?" + urlInfo.query;

                console.log(logCategory, arguments.callee.name, "appLink url:", url);
                app.openUrl(url);

                return true;
            }

            var tokens = urlInfo.path.match(/\/((?:share)|(?:surveys))\/([0-9a-f]{32})/i);

            if (Array.isArray(tokens) && tokens.length > 1) {
                var url = "%1://?itemID=%2".arg(appScheme).arg(tokens[2]);
                if (urlInfo.query > "") {
                    url += "&" + urlInfo.query;
                }

                console.log(logCategory, arguments.callee.name, "page:", tokens[1], "url:", url);
                app.openUrl(url);

                return true;
            }

            tokens = urlInfo.url.toString().match(/\/item.html\?id=([0-9a-f]{32})/i);

            if (Array.isArray(tokens) && tokens.length > 1) {
                url = "%1://?itemID=%2".arg(appScheme).arg(tokens[1]);

                console.log(logCategory, arguments.callee.name, "item url:", url);
                app.openUrl(url);

                return true;
            }
        }

        console.warn(logCategory, arguments.callee.name, "unhandled command:", command);
    }

    //--------------------------------------------------------------------------

    function syslog(urlInfo) {
        if (!enableDiagnostics) {
            console.warn(logCategory, arguments.callee.name, "Diagnostics disabled");
            return;
        }

        console.log(logCategory, arguments.callee.name, "url:", urlInfo.url);

        var userData = urlInfo.queryParameters.userData || "";

        AppFramework.logging.outputLocation = urlInfo.url;
        AppFramework.logging.userData = userData;
        AppFramework.logging.enabled = true;

        return true;
    }

    //--------------------------------------------------------------------------

    function invoke(urlInfo) {
        console.log(logCategory, arguments.callee.name, "url:", urlInfo.url);

        switch (urlInfo.host.toLowerCase()) {
        case kHostLogging:
            return loggingCommand(urlInfo);

        default:
            console.error(logCategory, arguments.callee.name, "Unhandled command host:", urlInfo.host);
            return false;
        }
    }

    //--------------------------------------------------------------------------

    function loggingCommand(urlInfo) {
        if (!enableDiagnostics) {
            console.warn(logCategory, arguments.callee.name, "Diagnostics disabled");
            return;
        }

        console.log(logCategory, arguments.callee.name, "url:", urlInfo.url);

        var parameters = urlInfo.queryParameters;

        if (parameters.hasOwnProperty(kPropertyUserData)) {
            AppFramework.logging.userData = parameters[kPropertyUserData];
        }

        if (parameters.hasOwnProperty(kPropertyOutputLocation)) {
            AppFramework.logging.outputLocation = parameters[kPropertyOutputLocation];
        }

        if (parameters.hasOwnProperty(kPropertyFile)) {
            var fileInfo = logsFolder.fileInfo(parameters[kPropertyFile]);
            if (!fileInfo.suffix) {
                fileInfo.suffix = kSuffixLog;
            }

            AppFramework.logging.outputLocation = fileInfo.url;
        }

        if (parameters.hasOwnProperty(kPropertyEnabled)) {
            var enabled = XFormJS.toBoolean(parameters[kPropertyEnabled], true);
            if (enabled && !AppFramework.logging.outputLocation.toString()) {
                var fileName = "%1.%2"
                .arg(Helper.dateStamp())
                .arg(kSuffixLog);

                fileInfo = logsFolder.fileInfo(fileName);
                AppFramework.logging.outputLocation = fileInfo.url;
            }

            AppFramework.logging.enabled = enabled;
        }

        console.log(logCategory, arguments.callee.name,
                    "enabled:", AppFramework.logging.enabled,
                    "outputLocation:", AppFramework.logging.outputLocation,
                    "userData:", AppFramework.logging.userData);

        return true;
    }

    //--------------------------------------------------------------------------
}
