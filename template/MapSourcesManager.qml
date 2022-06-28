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

import "../XForms"
import "../Portal"

Item {
    id: mapSourcesManager

    //--------------------------------------------------------------------------

    property Portal portal

    property var mapSources: []
    property bool sort: true

    property bool useCache: false//cacheFileName > "" && !!cacheFolder
    property FileFolder cacheFolder
    property string cacheFileName
    property string cacheKey: "mapSources"
    property bool cached: false

    property bool busy: false
    property var refreshMapSources: []

    property bool debug: false

    //--------------------------------------------------------------------------

    property string kTypeMapService: "Map Service"

    property var kMapItemTypesBasic: [
        kTypeMapService
    ]

    property var kMapItemTypesStandard: [
        kTypeMapService,
        "Web Map",
        "Image Service",
        "Vector Tile Service",
        "WMTS",
    ]

    property var kMapSourceTypes: {
        "Map Service": "TiledLayer",
        "Web Map": "Webmap",
        "Image Service": "",
        "Vector Tile Service": "VectorTiledLayer",
        "WMTS": "WMTSLayer",
    }

    //--------------------------------------------------------------------------

    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    readonly property bool isBasicMap: mapPlugin !== app.appSettings.kPluginArcGISRuntime

    readonly property var kPackageSuffixesBasic: ["tpk"]
    readonly property var kPackageSuffixesStandard: ["tpk", "vtpk", "mmpk"]

    readonly property url kDefaultThumbnail: "../XForms/mapThumbnails/default.png"

    //--------------------------------------------------------------------------

    readonly property var kMapItemTypes: isBasicMap ? kMapItemTypesBasic : kMapItemTypesStandard
    readonly property var kPackageSuffixes: isBasicMap ? kPackageSuffixesBasic : kPackageSuffixesStandard

    //--------------------------------------------------------------------------

    signal finished()

    //--------------------------------------------------------------------------

    onFinished: {
        console.log(logCategory, "onFinished");

        if (debug) {
            log();
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        console.log(logCategory, arguments.callee.name);

        mapSources = [];
    }

    //--------------------------------------------------------------------------

    function canRefresh() {
        if (!(portal && portal.isOnline)) {
            return;
        }

        console.log(logCategory, arguments.callee.name);

        if (busy) {
            console.error(logCategory, arguments.callee.name, "Previous refresh in progress");
            console.trace();

            return;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function startRefresh(promises) {
        console.log(logCategory, arguments.callee.name);

        if (!Array.isArray(promises)) {
            console.error(logCategory, arguments.callee.name, "Invalid array:", promises);
            return;
        }

        promises = promises.filter(promise => !!promise);

        if (!promises.length) {
            console.warn(logCategory, arguments.callee.name, "Nothing to refresh");
            return;
        }

        busy = true;

        refreshMapSources = [];

        Promise.all(promises)
        .then(refreshFinished)
        .catch(refreshFailed);
    }

    //--------------------------------------------------------------------------

    function refreshFinished() {
        console.log(logCategory, arguments.callee.name);

        if (sort) {
            mapSources = refreshMapSources.sort(function (a, b) {
                return a.name > b.name ? 1 : a.name < b.name ? -1 : 0;
            });
        } else {
            mapSources = refreshMapSources;
        }

        cached = false;
        if (useCache) {
            writeCache();
        }
        busy = false;

        finished();
    }

    //--------------------------------------------------------------------------

    function refreshFailed() {
        console.error(logCategory, arguments.callee.name);

        busy = false;
    }

    //--------------------------------------------------------------------------

    function readCache() {
        var cache = cacheFolder.readJsonFile(cacheFileName);

        mapSources = Array.isArray(cache[cacheKey])
                ? cache[cacheKey]
                : [];

        cached = true;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }

        console.log(logCategory, arguments.callee.name, mapSources.length, "cache:", cacheFolder.filePath(cacheFileName));
    }

    //--------------------------------------------------------------------------

    function writeCache() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }

        console.log(logCategory, arguments.callee.name, mapSources.length, "cache:", cacheFolder.filePath(cacheFileName));

        var cache = cacheFolder.readJsonFile(cacheFileName);

        cache[cacheKey] = mapSources;

        cacheFolder.writeJsonFile(cacheFileName, cache);
    }

    //--------------------------------------------------------------------------

    function addMapItem(itemInfo) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemInfo:", JSON.stringify(itemInfo, undefined, 2));
        }

        if (kMapItemTypes.indexOf(itemInfo.type) < 0) {
            console.warn(logCategory, arguments.callee.name, "Unsupported type:", itemInfo.type, "title:", itemInfo.title, "plugin:", mapPlugin);
            return;
        }

        var sourceType = kMapSourceTypes[itemInfo.type];
        if (!sourceType) {
            console.warn(logCategory, arguments.callee.name, "Unsupported type:", itemInfo.type);
            return;
        }

        var itemUrl = portal.portalUrl + "/home/item.html?id=%1".arg(itemInfo.id);
        var url = itemUrl;

        if (itemInfo.type === kTypeMapService) {
            url = itemInfo.url;
        }

        var mapSource = {
            "style": "CustomMap",
            "name": itemInfo.title,
            "description": itemInfo.description || "",
            "mobile": true,
            "night": false,
            "type": sourceType,
            "url": url,
            "id": itemInfo.id,
            "itemUrl": itemUrl,
            "copyrightText": itemInfo.accessInformation || "",
            "owner": itemInfo.owner,
            "contentStatus": itemInfo.contentStatus
        };

        var thumbnailUrl = kDefaultThumbnail;

        if (itemInfo.thumbnail > "") {
            thumbnailUrl = portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemInfo.id + "/info/" + itemInfo.thumbnail);
        }

        mapSource.thumbnailUrl = thumbnailUrl;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }

        refreshMapSources.push(mapSource);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "name:", mapSource.name, "type:", sourceType);
        }
    }

    //--------------------------------------------------------------------------

    function log() {
        if (!Array.isArray(mapSources)) {
            console.log(logCategory, arguments.callee.name, "mapSources:", mapSources);
            return;
        }

        console.log(logCategory, "mapSources:", mapSources.length);

        mapSources.forEach(function (mapSource, index) {
            console.log(logCategory, index, "type:", mapSource.type, "name:", JSON.stringify(mapSource.name), "url:", mapSource.url);
        });
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapSourcesManager, true)
    }

    //--------------------------------------------------------------------------
}
