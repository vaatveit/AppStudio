/* Copyright 2019 Esri
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

import "../XForms"
import "../Portal"

MapSourcesManager {
    id: mapSourcesManager

    //--------------------------------------------------------------------------

    property string itemId

    property bool autoRefresh: true

    //--------------------------------------------------------------------------

    cacheFileName: ".cache.json"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (useCache) {
            readCache();
        }
    }

    //--------------------------------------------------------------------------

    function refresh() {
        if (!canRefresh()) {
            return;
        }

        console.log(logCategory, arguments.callee.name);

        var requestsPromises = [];

        function addRequest(promise) {
            if (promise) {
                requestsPromises.push(promise);
            }
        }

        if (itemId > "") {
            addRequest(refreshRelatedContent(itemId));
        }

        startRefresh(requestsPromises);
    }

    //--------------------------------------------------------------------------

    function refreshRelatedContent(itemId) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemId:", itemId);
        }

        return relatedContentRequest.start(itemId);
    }

    //--------------------------------------------------------------------------

    function addFolder(url) {
        var mapFolder = AppFramework.fileFolder(url);

        kPackageSuffixes.forEach(function (suffix) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "suffix:", suffix, "mapFolder:", mapFolder.path)
            }

            var fileNames = mapFolder.fileNames("*." + suffix);

            fileNames.forEach(function(fileName) {
                addMap(mapFolder, fileName);
            });
        });
    }

    //--------------------------------------------------------------------------

    function addMap(mapFolder, fileName) {

        var fileInfo = mapFolder.fileInfo(fileName);
        var url = fileInfo.url.toString();

        function checkUrl(mapSource) {
            return mapSource.url.toLowerCase() === url.toLowerCase();
        }

        if (onlineMapSources.find(checkUrl)) {
            console.log(logCategory, arguments.callee.name, "Found mapSource url:", url);
            return;
        }

        var itemInfo = mapFolder.readJsonFile(fileInfo.baseName + ".iteminfo");
        var name = itemInfo.title || fileInfo.fileName;
        var description = itemInfo.description || fileInfo.fileName;
        var copyrightText = itemInfo.accessInformation || "";

        var mapSource = {
            "style": "CustomMap",
            "name": name,
            "description": description,
            "mobile": true,
            "night": false,
            "url": url,
            "copyrightText": copyrightText
        };

        onlineMapSources.push(mapSource);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapSourcesManager, true)
    }

    //--------------------------------------------------------------------------

    RelatedContentRequest {
        id: relatedContentRequest

        property string itemId
        property var resolve
        property var reject

        portal: mapSourcesManager.portal
        debug: mapSourcesManager.debug

        onRelatedItem: {
            addMapItem(itemInfo);
        }

        onFinished: {
            console.log(logCategory, "Related maps search finished");
            resolve();
        }

        onFailed: {
            console.error(logCategory, "Related maps search failed");
            resolve();
            //reject();
        }

        function start(itemId) {
            console.log(logCategory, arguments.callee.name, "related search itemId:", itemId);

            var promise = new Promise(function (_resolve, _reject) {
                resolve = _resolve;
                reject = _reject;

                requestRelatedItems(itemId);
            });

            return promise;
        }
    }

    //--------------------------------------------------------------------------
}
