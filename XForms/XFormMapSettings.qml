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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "Singletons"
import "XForm.js" as XFormJS


Item {
    id: mapSettings

    //--------------------------------------------------------------------------

    property string provider: app.mapPlugin > "" ? app.mapPlugin : kPluginAppStudio
    property string defaultMapName


    property real homeLatitude: kDefaultLatitude
    property real homeLongitude: kDefaultLongitude
    property real homeZoomLevel: defaultZoomLevel
    readonly property var homeCoordinate: QtPositioning.coordinate(homeLatitude, homeLongitude)

    // TODO Deprecate
    property alias latitude: mapSettings.homeLatitude
    property alias longitude: mapSettings.homeLongitude
    property alias zoomLevel: mapSettings.homeZoomLevel

    property real previewZoomLevel: defaultPreviewZoomLevel
    property string previewCoordinateFormat: "dm"
    property real positionZoomLevel: homeZoomLevel
    property string coordinateFormat: "dmss"
    property var mapSources: []
    property bool appendMapTypes: false//true
    property bool sortMapTypes: false
    property bool includeLibrary: true
    property string libraryPath: "~/ArcGIS/My Surveys/Maps"
    property bool mobileOnly: true
    property bool debug: false

    property int horizontalAccuracyPrecisionLow: 1
    property int horizontalAccuracyPrecisionHigh: 2
    property int verticalAccuracyPrecisionLow: 1
    property int verticalAccuracyPrecisionHigh: 2

    property bool includeDefaultMaps: true
    readonly property url defaultMapConfig: "XFormMapSettings-%1.json".arg(provider)
    readonly property var defaultMapSources: readMapSources(defaultMapConfig, kCategoryBasic)

    property var searchPaths: []

    property var sharedMapSources
    property var linkedMapSources

    property bool initialized: false

    property alias logCategory: logCategory

    //--------------------------------------------------------------------------

    property GlyphSet pointSymbolSet: MapSymbols.point
    property string pointSymbolName: MapSymbols.defaultPointSymbolName
    property color pointSymbolColor: MapSymbols.defaultPointSymbolColor
    property int pointSymbolStyle: MapSymbols.defaultPointSymbolStyle
    property color pointSymbolStyleColor: MapSymbols.defaultPointSymbolStyleColor

    //--------------------------------------------------------------------------

    readonly property real defaultZoomLevel: 15
    readonly property real defaultPreviewZoomLevel: 14

    readonly property real kDefaultLatitude: 34.056223110283184
    readonly property real kDefaultLongitude: -117.19532583406398

    //--------------------------------------------------------------------------

    readonly property string kPluginAppStudio: "AppStudio"
    readonly property string kPluginArcGISRuntime: "ArcGISRuntime"

    readonly property bool isEnhancedMap: provider === kPluginArcGISRuntime

    readonly property var kPackageSuffixesBasic: ["tpk"]
    readonly property var kPackageSuffixesEnhanced: ["tpk", "vtpk", "mmpk"]
    readonly property var kPackageSuffixes: isEnhancedMap ? kPackageSuffixesEnhanced : kPackageSuffixesBasic

    readonly property var kThumbnailSuffixes: ["thumbnail", "png", "jpg"]

    readonly property string kCategoryBasic: "basic"
    readonly property string kCategoryShared: "shared"
    readonly property string kCategoryLinked: "linked"
    readonly property string kCategorySurvey: "survey"
    readonly property string kCategoryLibrary: "library"

    //--------------------------------------------------------------------------

    signal refreshed()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "mapPlugin:", provider);

        initialized = true;
        refresh();
    }

    //--------------------------------------------------------------------------

    onMapSourcesChanged: {
        console.log("XFormMapSettings onMapSourcesChanged:", mapSources.length);
    }

    //--------------------------------------------------------------------------

    onSharedMapSourcesChanged: {
        console.log("onSharedMapSourcesChanged initialized:", initialized);

        if (initialized) {
            Qt.callLater(updateMapSources);
        }
    }

    //--------------------------------------------------------------------------

    onLinkedMapSourcesChanged: {
        console.log("onLinkedMapSourcesChanged:", initialized);

        if (initialized) {
            Qt.callLater(updateMapSources);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapSettings, true)
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: thumbnailsFolder

        url: "mapThumbnails"
    }

    //--------------------------------------------------------------------------

    function readMapSources(pathName, category) {
        var fileInfo = AppFramework.fileInfo(pathName);

        console.log(arguments.callee.name, "pathName:", pathName, "->", fileInfo.pathName);

        var config = fileInfo.folder.readJsonFile(fileInfo.fileName);

        if (debug) {
            console.log(arguments.callee.name, "config:", JSON.stringify(config, undefined, 2));
        }

        var mapSources = config.mapSources;
        if (!Array.isArray(mapSources)) {
            mapSources = [];
        }

        mapSources.forEach(function (mapSource, index) {
            mapSource.thumbnailUrl = thumbnailsFolder.fileUrl("mapType-%1.png".arg(index));
            if (category > "") {
                mapSource.category = category;
            }
        });

        if (debug) {
            console.log(arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }

        return mapSources;
    }

    //--------------------------------------------------------------------------

    function selectMapType(map, mapName) {
        if (debug) {
            console.log(arguments.callee.name, "mapName:", mapName, "supportedMapTypes:", map.supportedMapTypes.length);
        }

        if (!map.supportedMapTypes.length) {
            return;
        }

        var mapType;

        if (mapName > "") {
            mapType = findMapType(map.supportedMapTypes, mapName);
        }

        if (!mapType && defaultMapName > "") {
            mapType = findMapType(map.supportedMapTypes, defaultMapName);
        }

        if (mapType) {
            map.activeMapType = mapType;

            if (debug) {
                console.log(logCategory, arguments.callee.name, "Activating mapType id:", mapType.metadata.id, "name:", mapType.name);
            }
        }

        return !!mapType;
    }

    //--------------------------------------------------------------------------

    function findMapType(mapTypes, name) {
        if (!name) {
            return;
        }

        var names = parseMapTypeName(name);
        if (!Array.isArray(names)) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapTypes:", mapTypes.length);
        }

        for (let value of names) {
            let id = XFormJS.parseId(value);

            if (debug) {
                console.log(logCategory, arguments.callee.name, "searching for value:", value, "id:", id);
            }

            if (id > "") {
                // Item id search

                for (var i = 0; i < mapTypes.length; i++) {
                    var mapType = mapTypes[i];

                    if (mapType.metadata.id > "" && mapType.metadata.id.toLowerCase() === id) {
                        if (debug) {
                            console.log(logCategory, arguments.callee.name, "matched id:", id);
                        }

                        return mapType;
                    }
                }
            } else {
                // Case sensitive name search

                for (i = 0; i < mapTypes.length; i++) {
                    mapType = mapTypes[i];

                    if (mapType.name === value) {
                        if (debug) {
                            console.log(logCategory, arguments.callee.name, "matched case sensitive name:", value);
                        }

                        return mapType;
                    }
                }

                // Case insensitive name search

                value = value.toLowerCase();

                for (i = 0; i < mapTypes.length; i++) {
                    mapType = mapTypes[i];

                    if (mapType.name.toLowerCase() === value) {
                        if (debug) {
                            console.log(logCategory, arguments.callee.name, "matched case insensitive name:", value);
                        }

                        return mapType;
                    }
                }
            }
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "No match for mapTypes:", mapTypes.length, "names:", JSON.stringify(names, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function mapTypeName(mapType) {
        var name = mapType.metadata.id > ""
                ? "id:%1||%2".arg(mapType.metadata.id.toLowerCase()).arg(mapType.name)
                : mapType.name;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "name:", name, "mapType:", JSON.stringify(mapType, undefined, 2));
        }

        return name;
    }

    //--------------------------------------------------------------------------

    function parseMapTypeName(mapTypeName) {
        if (!mapTypeName) {
            return;
        }

        var names = mapTypeName.split("||").map(name => name.trim()).filter(name => name.length > 0);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "name:", names, "names:", JSON.stringify(names, undefined, 2));
        }

        return names;
    }

    //--------------------------------------------------------------------------

    function refresh(surveyPath, mapInfo) {
        if (!mapInfo) {
            mapInfo = {};
        }

        console.log(logCategory, arguments.callee.name, "Refreshing map settings surveyPath:", surveyPath, "info:", JSON.stringify(mapInfo, undefined, 2));

        function isNumber(value) {
            return isFinite(Number(value));
        }

        function isBool(value) {
            return typeof value === "boolean";
        }

        if (mapInfo.coordinateFormat > "") {
            coordinateFormat = mapInfo.coordinateFormat;
        }

        // includeDefaultMaps = XFormJS.toBoolean(mapInfo.includeDefaultMaps, true);

        var defaultType = mapInfo.defaultType;
        if (defaultType) {
            if (defaultType.name > "") {
                defaultMapName = defaultType.name;
            }
        }

        var homeInfo = mapInfo.home;
        if (homeInfo) {
            if (isNumber(homeInfo.latitude) && isNumber(homeInfo.longitude)) {
                var homeCoordinate = QtPositioning.coordinate(homeInfo.latitude, homeInfo.longitude);
                if (homeCoordinate.isValid) {
                    homeLatitude = homeCoordinate.latitude;
                    homeLongitude = homeCoordinate.longitude;
                }
            }

            if (isNumber(homeInfo.zoomLevel)) {
                var zoom = Number(homeInfo.zoomLevel);
                if (zoom > 0) {
                    homeZoomLevel = zoom;
                } else {
                    homeZoomLevel = defaultZoomLevel;
                }
            }
        }

        var previewInfo = mapInfo.preview;
        if (previewInfo) {
            if (isNumber(previewInfo.zoomLevel)) {
                zoom = Number(previewInfo.zoomLevel);
                if (zoom > 0) {
                    previewZoomLevel = zoom;
                } else {
                    previewZoomLevel = defaultPreviewZoomLevel;
                }
            }

            if (previewInfo.coordinateFormat > "") {
                previewCoordinateFormat = previewInfo.coordinateFormat;
            }
        }

        var symbolInfo = mapInfo.symbol;
        if (symbolInfo) {
            if (symbolInfo.name > "") {
                pointSymbolName = symbolInfo.name;
            }
        }

        //        mapSources = [];

        //        if (includeDefaultMaps) {
        //            addDefaultMapSources(mapSources);
        //        }

        var mapTypes = mapInfo.mapTypes;
        if (mapTypes) {
            if (isBool(mapTypes.append)) {
                //appendMapTypes = mapTypes.append;
                //                if (!mapTypes.append) {
                //                    mapSources = [];
                //                }
            }

            if (isBool(mapTypes.sort)) {
                sortMapTypes = mapTypes.sort;
            }

            if (isBool(mapTypes.includeLibrary)) {
                includeLibrary = mapTypes.includeLibrary;
            }

            if (Array.isArray(mapTypes.mapSources)) {
                mapTypes.mapSources.forEach(function (mapSource) {
                    var urlInfo = AppFramework.urlInfo(mapSource.url);

                    if (urlInfo.fileName === "item.html") {
                        console.log("Map package item source:", JSON.stringify(mapSource, undefined, 2));
                    } else {
                        mapSources.push(mapSource);
                    }
                });
            }
        }

        var _searchPaths = [];

        if (surveyPath > "") {
            var surveyPathInfo = AppFramework.fileInfo(surveyPath);
            var surveyFolder = AppFramework.fileFolder(surveyPath);

            var mapFolderNames = [
                        surveyPathInfo.baseName + "-media",
                        "media",
                        "Maps",
                        "maps"
                    ];

            if (debug) {
                console.log(logCategory, arguments.callee.name, "Map folders:", JSON.stringify(mapFolderNames, undefined, 2));
            }

            mapFolderNames.forEach(function (folderName) {
                var mapsFolder = surveyFolder.folder(folderName);

                if (mapsFolder.exists) {
                    _searchPaths.push({
                                          url: mapsFolder.url,
                                          category: kCategorySurvey
                                      });
                }
            });
        }

        if (includeLibrary && libraryPath > "") {
            var paths = libraryPath.split(";");

            if (debug) {
                console.log(logCategory, arguments.callee.name, "library paths:", JSON.stringify(paths));
            }

            paths.forEach(function (path) {
                path = path.trim();
                if (path > "") {
                    var libraryFolder = AppFramework.fileFolder(path);

                    if (libraryFolder.exists) {
                        _searchPaths.push({
                                              url: libraryFolder.url,
                                              category: kCategoryLibrary
                                          });
                    }
                }
            });
        }

        searchPaths = _searchPaths;

        Qt.callLater(updateMapSources);
    }

    //--------------------------------------------------------------------------

    function updateMapSources() {
        console.log(logCategory, arguments.callee.name);

        var _mapSources = [];

        if (includeDefaultMaps) {
            addMapSourcesCategory(_mapSources, kCategoryBasic, defaultMapSources);
        }

        addSearchMapSources(_mapSources);
        addMapSourcesCategory(_mapSources, kCategoryLinked, linkedMapSources);
        addMapSourcesCategory(_mapSources, kCategoryShared, sharedMapSources);

        _mapSources.forEach(function (mapSource) {
            if (!mapSource.thumbnailUrl) {
                mapSource.thumbnailUrl = thumbnailsFolder.fileUrl("default.png");
            }
        });

        mapSources = _mapSources;

        console.log(logCategory, arguments.callee.name, "mapSources:", mapSources.length);
    }

    //--------------------------------------------------------------------------

    function addSearchMapSources(mapSources) {
        console.log(logCategory, arguments.callee.name, "searchPaths:", JSON.stringify(searchPaths, undefined, 2));

        searchPaths.forEach(function (searchPath) {
            addFolder(mapSources, searchPath.url);
        });
    }

    //--------------------------------------------------------------------------

    function addDefaultMapSources(mapSources) {
        console.log(arguments.callee.name, "defaultMapSources:", defaultMapSources.length);

        mapSources = mapSources.concat(defaultMapSources);
    }

    //--------------------------------------------------------------------------

    function addFolder(mapSources, url) {
        var mapFolder = AppFramework.fileFolder(url);

        kPackageSuffixes.forEach(function (suffix) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "suffix:", suffix, "mapFolder:", mapFolder.path)
            }

            var fileNames = mapFolder.fileNames("*." + suffix);

            fileNames.forEach(function(fileName) {
                addMap(mapSources, mapFolder, fileName);
            });
        });
    }

    //--------------------------------------------------------------------------

    function addMap(mapSources, mapFolder, fileName) {

        var fileInfo = mapFolder.fileInfo(fileName);
        var url = fileInfo.url.toString();



        function checkUrl(mapSource) {
            return mapSource.url.toLowerCase() === url.toLowerCase();
        }

        if (mapSources.find(checkUrl)) {
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

        kThumbnailSuffixes.forEach(function (suffix) {
            var thumbnailInfo = mapFolder.fileInfo(fileInfo.baseName + "." + suffix);

            if (thumbnailInfo.exists) {
                mapSource.thumbnailUrl = thumbnailInfo.url;
            }
        });

        mapSources.push(mapSource);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function addMapSourcesCategory(mapSources, category, categoryMapSources) {
        console.log(arguments.callee.name, "category:", category, "mapSources:", mapSources.length);

        if (Array.isArray(categoryMapSources)) {
            console.log(arguments.callee.name, "category:", category, "categoryMapSources:", categoryMapSources.length);

            categoryMapSources.forEach(function (mapSource) {
                mapSource.category = category;
                mapSources.push(mapSource);
            });
        }
    }

    //--------------------------------------------------------------------------
}
