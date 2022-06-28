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
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

GridView {
    id: gridView

    //--------------------------------------------------------------------------

    property Map map
    readonly property var supportedMapTypes: map.supportedMapTypes

    property int referenceWidth: 200 * AppFramework.displayScaleFactor
    property int cells: calcCells(width)
    property bool dynamicSpacing: false
    property int minimumSpacing: 8 * AppFramework.displayScaleFactor
    property int cellSize: 175 * AppFramework.displayScaleFactor

    property var mapTypes: []

    property int sortOrder: 0
    property var compareFunction: !sortOrder
                                  ? compareIndex
                                  : sortOrder > 0
                                    ? compareNameAscending
                                    : compareNameDescending


    property string filterText

    property bool showBasicMaps: true
    property bool showSharedMaps: false
    readonly property bool isFiltered: !showBasicMaps || !showSharedMaps
    property bool showContentStatus: false

    property bool initialized: false
    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kCategoryBasic: "basic"
    readonly property string kCategoryShared: "shared"

    //--------------------------------------------------------------------------

    signal clicked(int index, MapType mapType)
    signal pressAndHold(int index, MapType mapType)

    //--------------------------------------------------------------------------

    cellWidth: width / cells
    cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth

    clip: true

    delegate: mapTypeDelegate

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "onCompleted");

        initialized = true;
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    onSupportedMapTypesChanged: {
        if (initialized) {
            Qt.callLater(update);
        }
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log(logCategory, arguments.callee.name);

        updateMapTypes();
        filter();
    }

    //--------------------------------------------------------------------------

    function filter(text) {
        console.log(logCategory, arguments.callee.name, "text:", JSON.stringify(text));

        if (text >= "") {
            filterText = text.toLowerCase();
        }

        function mapTypeFilter(mapType) {
            if (mapType.selected) {
                return true;
            }

            if (!showBasicMaps && mapType.category === kCategoryBasic) {
                return false;
            }

            if (!showSharedMaps && mapType.category === kCategoryShared) {
                return false;
            }

            if (filterText > "") {
                return mapType.name.toLowerCase().indexOf(filterText) >= 0;
            }

            return true;
        }

        var filteredMapTypes = mapTypes.filter(mapTypeFilter);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "filteredMapTypes:", filteredMapTypes.length);
        }

        updateModel(filteredMapTypes);
    }

    //--------------------------------------------------------------------------

    function updateMapTypes() {
        console.log(logCategory, arguments.callee.name, "supportedMapTypes:", map.supportedMapTypes.length);

        var _mapTypes = [];

        for (var i = 0; i < map.supportedMapTypes.length; i++) {
            var supportedMapType = map.supportedMapTypes[i];

            if (!supportedMapType.mobile) {
                console.log(logCategory, arguments.callee.name, "excluding mobile:", supportedMapType.mobile, "name:", supportedMapType.name);
                continue;
            }

            // Skip basic map types duplicated in other categories

            if (supportedMapType.metadata.id > ""
                    && supportedMapType.metadata.category === kCategoryBasic) {
                var id = supportedMapType.metadata.id.toLowerCase();

                for (var j = 0; j < map.supportedMapTypes.length; j++) {
                    var _supportedMapType = map.supportedMapTypes[j];

                    if (_supportedMapType.metadata.id > "" &&
                            _supportedMapType.metadata.category !== supportedMapType.metadata.category &&
                            _supportedMapType.metadata.id.toLowerCase() === id) {
                        console.log(logCategory, arguments.callee.name, "excluding duplicate category:", supportedMapType.metadata.category, "id:", id, "name:", supportedMapType.name);
                        supportedMapType = null;
                        break;
                    }
                }
            }

            if (supportedMapType) {
                var mapType = {
                    id: supportedMapType.metadata.id || "",
                    name: supportedMapType.name,
                    thumbnailUrl: supportedMapType.metadata.thumbnailUrl,
                    category: supportedMapType.metadata.category || "",
                    index: i,
                    selected: false,
                    metadata: supportedMapType.metadata
                }

                _mapTypes.push(mapType);
            }
        }

        var selectedMapType;

        if (map.activeMapType.metadata.id > "") {
            for (mapType of _mapTypes) {
                if (mapType.metadata.id > "" &&
                        mapType.metadata.id.toLowerCase() === map.activeMapType.metadata.id) {
                    mapType.selected = true;
                    selectedMapType = mapType;
                    break;
                }
            }
        }

        if (!selectedMapType) {
            for (mapType of _mapTypes) {
                if (mapType.name === map.activeMapType.name) {
                    mapType.selected = true;
                    selectedMapType = mapType;
                    break;
                }
            }
        }

        if (sortOrder) {
            mapTypes = _mapTypes.sort(compareFunction);
        } else {
            mapTypes = _mapTypes;
        }

        console.log(logCategory, "mapTypes:", mapTypes.length, "selectedMapType:", JSON.stringify(selectedMapType, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function updateModel(mapTypes) {
        mapTypes.sort(compareFunction);
        model = mapTypes;
        positionViewAtSelected();
    }

    //--------------------------------------------------------------------------

    function sort() {
        console.log(logCategory, arguments.callee.name, "sortOrder:", sortOrder);

        var mapTypes = model;

        model = mapTypes.sort(compareFunction);
        positionViewAtSelected();
    }

    //--------------------------------------------------------------------------

    function positionViewAtSelected() {
        var activeIndex = -1;

        for (var i = 0; i < model.length; i++) {
            if (model[i].selected) {
                activeIndex = i;
                break;
            }
        }

        currentIndex = activeIndex;
        positionViewAtIndex(currentIndex, GridView.Center);
    }

    //--------------------------------------------------------------------------

    function compareIndex(a, b) {
        return a.index > b.index ? 1 : a.index < b.index ? -1 : 0;
    }

    function compareNameAscending(a, b) {
        return a.name > b.name ? 1 : a.name < b.name ? -1 : 0;
    }

    function compareNameDescending(a, b) {
        return -compareNameAscending(a, b);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(gridView, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypeDelegate

        Rectangle {
            width: cellWidth
            height: cellHeight

            color: "transparent"
            //            border {
            //                color: modelData.selected ? "#00b2ff" : "transparent"
            //                width: 2 * AppFramework.displayScaleFactor
            //            }
            //            radius: 5 * AppFramework.displayScaleFactor

            MapTypeDelegate {
                anchors {
                    fill: parent
                    margins: 8 * AppFramework.displayScaleFactor
                }

                mapType: map.supportedMapTypes[modelData.index]

                dropShadow.color: modelData.selected ? "#00b2ff" : "#12000000"
                showContentStatus: gridView.showContentStatus

                onClicked: {
                    gridView.clicked(modelData.index, mapType);
                }

                onPressAndHold: {
                    gridView.pressAndHold(modelData.index, mapType);
                }

                onInfoClicked: {
                    var popup = mapTypePopup.createObject(gridView,
                                                          {
                                                              mapType: mapType
                                                          });

                    popup.open();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function calcCells(w) {
        if (dynamicSpacing) {
            return Math.max(1, Math.floor(w / (cellSize + minimumSpacing)));
        }

        var rw =  referenceWidth;
        var c = Math.max(1, Math.round(w / referenceWidth));

        var cw = w / c;

        if (cw > rw) {
            c++;
        }

        cw = w / c;

        if (c > 1 && cw < (rw * 0.85)) {
            c--;
        }

        cw = w / c;

        if (cw > rw) {
            c++;
        }

        return c;
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypePopup

        MapTypePopup {
        }
    }

    //--------------------------------------------------------------------------
}
