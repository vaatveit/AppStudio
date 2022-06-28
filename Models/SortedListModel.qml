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

import "ModelSort.mjs" as ModelSort

ListModel {
    id: model

    //--------------------------------------------------------------------------

    property string sortProperty
    property var sortFunction

    property int sortType: kSortTypeProperty
    property string sortOrder: kSortOrderAsc
    readonly property int sortOrderType: sortOrder === kSortOrderAsc ? Qt.AscendingOrder : Qt.DescendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive

    readonly property int kSortTypeProperty: 0
    readonly property int kSortTypeFunction: 1

    readonly property string kSortOrderAsc: "asc"
    readonly property string kSortOrderDesc: "desc"

    property date lastSorted: new Date()
    property bool busy: false

    property bool debug: false

    //--------------------------------------------------------------------------

    signal sorted()

    //--------------------------------------------------------------------------

    dynamicRoles: true

    //--------------------------------------------------------------------------

    onSorted: {
        lastSorted = new Date();
        busy = false;

        if (debug) {
            console.log("lastSorted:", lastSorted);
        }
    }

    //--------------------------------------------------------------------------

    function setSortOrder(value) {
        switch (value) {
        case 0:
        case kSortOrderAsc:
            sortOrder = kSortOrderAsc;
            break;

        case 1:
        case kSortOrderDesc:
            sortOrder = kSortOrderDesc;
            break;
        }
    }

    //--------------------------------------------------------------------------

    function sort(begin) {
        console.time("sort");

        busy = true;

        if (sortType === kSortTypeProperty) {
            if (!(sortProperty > "")) {
                console.error("Empty sortProperty");
                return;
            }
        } else {
            if (typeof sortFunction !== 'function') {
                console.error("Invalid sort function:", sortFunction);
                return;
            }
        }

        if (debug) {
            console.log("Sorting property:", sortProperty, sortOrder);
        }

        var parameters = sortParameters();
        if (begin > 0) {
            parameters.offset = begin;
        }

        console.log("sort:", JSON.stringify(parameters, undefined, 2))
        ModelSort.sort(model, parameters);

        console.timeEnd("sort");

        sorted();
    }

    //--------------------------------------------------------------------------

    function toggleSortOrder() {
        sortOrder = sortOrder === kSortOrderAsc ? kSortOrderDesc : kSortOrderAsc;

        if (debug) {
            console.log("Toggled sort order:", sortProperty, sortOrder);
        }
    }

    //--------------------------------------------------------------------------

    function findByKeyValue(key, value) {
        for (var i = 0; i < count; i++) {
            if (get(i)[key] === value) {
                return i;
            }
        }

        return -1;
    }

    //--------------------------------------------------------------------------

    function sortParameters() {
        return {
            debug: debug,
            sortType: sortType,
            sortRole: sortProperty,
            sortOrder: sortOrderType,
            sortCaseSensitivity: sortCaseSensitivity,
            sortCompare: sortFunction
        }
    }

    //--------------------------------------------------------------------------

    function sortAsync() {
        sortWorker.sort(model, sortParameters());
    }

    readonly property ListModelSortWorker sortWorker: ListModelSortWorker {
        id: sortWorker

        debug: model.debug

        Component.onCompleted: {
            sorted.connect(model.sorted);
        }
    }

    //--------------------------------------------------------------------------
}
