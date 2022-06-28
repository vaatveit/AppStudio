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

import "../Portal"

MapSourcesManager {
    id: mapSourcesManager
    
    //--------------------------------------------------------------------------

    property string groupQuery

    //--------------------------------------------------------------------------

    debug: false

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        function onSignedInChanged() {
            if (portal.signedIn) {
                var portalId = Qt.md5(portal.portalUrl);
                cacheFileName = "%1-%2.json".arg(portalId).arg(portal.user.username);

                Qt.callLater(refresh);
            } else {
                clear();
            }
        }
    }

    //--------------------------------------------------------------------------

    function refresh() {
        if (!canRefresh()) {
            return;
        }

        if (useCache) {
            readCache();
        }

        var info = portal.info;

        console.log(logCategory, arguments.callee.name, "basemapGalleryGroupQuery:", info.basemapGalleryGroupQuery);
        console.log(logCategory, arguments.callee.name, "useVectorBasemaps:", info.useVectorBasemaps, "vectorBasemapGalleryGroupQuery:", info.vectorBasemapGalleryGroupQuery);

        var promises = [];

        if (groupQuery > "") {
            promises.push(portalContentRequest.start(groupQuery));
        } else if (info.useVectorBasemaps && info.vectorBasemapGalleryGroupQuery > "") {
            promises.push(portalContentRequest.start(info.vectorBasemapGalleryGroupQuery));
        } else if (info.basemapGalleryGroupQuery > "") {
            promises.push(portalContentRequest.start(info.basemapGalleryGroupQuery));
        }

        startRefresh(promises);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapSourcesManager, true)
    }

    //--------------------------------------------------------------------------

    PortalGroupContentRequest {
        id: portalContentRequest

        property var resolve
        property var reject

        portal: mapSourcesManager.portal

        onContentItem: {
            addMapItem(itemInfo);
        }

        onFinished: {
            console.log(logCategory, "Basemaps search finished");
            resolve();
        }

        onFailed: {
            console.error(logCategory, "Basemaps search failed");
            resolve();
            // reject();
        }

        function start(query) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "basemaps query:", query);
            }

            var promise = new Promise(function (_resolve, _reject) {
                resolve = _resolve;
                reject = _reject;

                search(query);
            });

            return promise;
        }
    }

    //--------------------------------------------------------------------------
}
