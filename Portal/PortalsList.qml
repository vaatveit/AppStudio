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

//------------------------------------------------------------------------------

Item {
    id: portalsList

    //--------------------------------------------------------------------------

    property Settings settings
    property string settingsGroup: "Portal"
    property alias model: portalsModel
    property bool singleInstanceSupport: !(Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.application.os === "linux")

    property var defaultPortalInfo

    //--------------------------------------------------------------------------

    property string kSettingsKey: settingsGroup + "/portals"

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(portalsList, true)
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: portalsModel

        dynamicRoles: true
    }

    //--------------------------------------------------------------------------

    function clear(remove) {
        portalsModel.clear();
        portalsModel.append(defaultPortalInfo);

        if (remove) {
            if (settings) {
                settings.remove(kSettingsKey);
            }
        } else {
            write();
        }
    }

    //--------------------------------------------------------------------------

    function read() {
        if (!settings) {
            return;
        }

        var portalsList;

        var portals = settings.value(kSettingsKey, "");
        if (portals > "") {
            try {
                portalsList = JSON.parse(portals);
            } catch (err) {
                console.warn(logCategory, "Portal list parse error:", err);
            }
        } else {
            console.log(logCategory, arguments.callee.name, "Empty portal list");
        }

        if (!Array.isArray(portalsList)) {
            portalsList = [];

            portalsList.push(defaultPortalInfo);
        }

        portalsModel.clear();

        portalsList.forEach(function(element) {
            if (!element.hasOwnProperty("ignoreSslErrors")) {
                element.ignoreSslErrors = false;
            }

            if (!element.hasOwnProperty("isPortal")) {
                element.isPortal = false;
            }

            if (!element.hasOwnProperty("supportsOAuth")) {
                element.supportsOAuth = true;
            }

            if (!element.hasOwnProperty("externalUserAgent")) {
                element.externalUserAgent = false; //singleInstanceSupport;
            }

            if (!element.hasOwnProperty("networkAuthentication")) {
                element.networkAuthentication = false;
            }

            if (!element.hasOwnProperty("singleSignOn")) {
                element.singleSignOn = false;
            }

            if (!element.hasOwnProperty("pkiAuthentication")) {
                element.pkiAuthentication = false;
            }

            if (!element.hasOwnProperty("pkiFile")) {
                element.pkiFile = "";
            }

            if (!element.hasOwnProperty("pkiFileName")) {
                element.pkiFileName = "";
            }

            portalsModel.append(element);
        });

        console.log(logCategory, arguments.callee.name, "#portals:", portalsModel.count);
    }

    //--------------------------------------------------------------------------

    function write() {
        if (!settings) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "#portals:", portalsModel.count);

        var portalsList = [];

        for (var i = 0; i < portalsModel.count; i++) {
            var element = portalsModel.get(i);

            var entry = {
                url: element.url,
                name: element.name,
                ignoreSslErrors: element.ignoreSslErrors,
                isPortal: element.isPortal,
                supportsOAuth: element.supportsOAuth,
                externalUserAgent: element.externalUserAgent,
                networkAuthentication: element.networkAuthentication,
                singleSignOn: element.singleSignOn,
                pkiAuthentication: element.pkiAuthentication,
                pkiFile: element.pkiFile,
                pkiFileName: element.pkiFileName
            };

            portalsList.push(entry);
        }

        settings.setValue(kSettingsKey, JSON.stringify(portalsList));
    }

    //--------------------------------------------------------------------------

    function append(portalInfo) {
        console.log(logCategory, arguments.callee.name, "portalInfo:", JSON.stringify(portalInfo, undefined, 2));

        portalsModel.append(portalInfo);
        write();

        return portalsModel.count - 1;
    }

    //--------------------------------------------------------------------------

    function remove(index) {
        portalsModel.remove(index, 1);
        write();
    }

    //--------------------------------------------------------------------------

    function find(portal) {
        console.log(logCategory, arguments.callee.name, "portals:", portalsModel.count,  "url:", portal.portalUrl);

        for (var i = 0; i < portalsModel.count; i++) {
            var portalInfo = portalsModel.get(i);

            if (portalInfo.url.toString().toLowerCase() === portal.portalUrl.toString().toLowerCase() &&
                    portalInfo.supportsOAuth === portal.supportsOAuth &&
                    portalInfo.externalUserAgent === portal.externalUserAgent) {
                return i;
            }
        }

        for (i = 0; i < portalsModel.count; i++) {
            portalInfo = portalsModel.get(i);

            if (portalInfo.url.toString().toLowerCase() === portal.portalUrl.toString().toLowerCase()) {
                return i;
            }
        }

        return -1;
    }

    //--------------------------------------------------------------------------

    function findByUrl(url) {
        console.log(logCategory, arguments.callee.name, "url:", url);

        for (var i = 0; i < portalsModel.count; i++) {
            var portalInfo = portalsModel.get(i);

            if (portalInfo.url.toString().toLowerCase() === url.toString().toLowerCase()) {
                return portalInfo;
            }
        }
    }

    //--------------------------------------------------------------------------

    function add(url) {
        console.log(logCategory, arguments.callee.name, "url:", url);

        var portalInfo = findByUrl(url);
        if (!portalInfo) {
            return portalInfo;
        }

        portalInfo = JSON.parse(JSON.stringify(defaultPortalInfo));
        portalInfo.url = url;
        portalInfo.name = url;

        append(portalInfo);

        return portalInfo;
    }

    //--------------------------------------------------------------------------
}
