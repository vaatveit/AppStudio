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

import QtQml 2.13
import QtQml.Models 2.13

import ArcGIS.AppFramework 1.0

AbstractDelegateModel {
    id: delegateModel

    //--------------------------------------------------------------------------

    property bool sortEnabled: sortRole > ""
    property string sortRole
    property int sortOrder: Qt.AscendingOrder
    property int sortCaseSensitivity: Qt.CaseInsensitive
    property bool sortLocaleAware: false

    property var lessThan: _lessThan

    property var filterFunction: _filterFunction
    property var filterRole
    property int filterCaseSensitivity: Qt.CaseInsensitive
    property var filterValue
    property var filterPattern: typeof filterValue === "string"
                                ? filterCaseSensitivity === Qt.CaseInsensitive
                                  ? filterValue.toLowerCase()
                                  : filterValue
    : filterValue


    //property var filterPattern: new RegExp(filterText, filterCaseSensitivity == Qt.CaseInsensitive ? "i" : undefined);


    property bool dynamic: true
    property bool dynamicSort: dynamic
    property bool dynamicFilter: dynamic

    property date lastSorted: new Date()

    //--------------------------------------------------------------------------

    property ListModel emptyModel: ListModel {}

    //--------------------------------------------------------------------------

    items.includeByDefault: false

    groups: [
        DelegateModelGroup {
            id: unfilteredItems

            name: "unfiltered"
            includeByDefault: true

            onChanged: {
                //                if (debug) {
                //                    console.log(delegateModel.objectName, ".", name, "#", count, "removed:", removed.length, "inserted:", inserted.length);
                //                }

                if (dynamicFilter) {
                    delegateModel._filter();
                }
            }
        },

        DelegateModelGroup {
            id: unmatchedItems

            name: "unmatched"
            includeByDefault: false

            //                if (debug) {
            //                    console.log(delegateModel.objectName, ".", name, "#", count, "removed:", removed.length, "inserted:", inserted.length);
            //                }
        },

        DelegateModelGroup {
            id: unsortedItems
            name: "unsorted"

            includeByDefault: false

            onChanged: {
                //                if (debug) {
                //                    console.log(delegateModel.objectName, ".", name, "#", count, "removed:", removed.length, "inserted:", inserted.length);
                //                }

                if (dynamicSort) {
                    delegateModel._sort();
                }
            }
        }
    ]

    //--------------------------------------------------------------------------

    onSortRoleChanged: {
        invalidate();
    }

    onSortOrderChanged: {
        invalidate();
    }

    onSortCaseSensitivityChanged: {
        invalidate();
    }

    onSortEnabledChanged: {
        invalidate();
    }

    //--------------------------------------------------------------------------

    onFilterFunctionChanged: {
        invalidateFilter();
    }

    onFilterPatternChanged: {
        invalidateFilter();
    }

    //--------------------------------------------------------------------------

    onDynamicChanged: {
        if (dynamicFilter) {
            invalidateFilter();
        } else if (dynamicSort) {
            invalidate();
        }
    }

    onDynamicSortChanged: {
        if (dynamicSort) {
            invalidate();
        }
    }

    onDynamicFilterChanged: {
        if (dynamicFilter) {
            invalidateFilter();
        }
    }

    //--------------------------------------------------------------------------

    function invalidate() {
        if (!sortEnabled || !model || !model.count) {
            return;
        }

        if (debug) {
            console.log(objectName, arguments.callee.name);
        }

        Qt.callLater(sort);
    }

    //--------------------------------------------------------------------------

    function invalidateFilter() {
        if (!model || !model.count) {
            return;
        }

        if (debug) {
            console.log(objectName, arguments.callee.name);
        }

        Qt.callLater(filter);
    }

    //--------------------------------------------------------------------------

    function _lessThan(leftItem, rightItem) {
        var leftValue = leftItem[sortRole];
        var rightValue = rightItem[sortRole];

        if (!sortCaseSensitivity) {
            if (typeof leftValue === "string") {
                leftValue = sortLocaleAware
                        ? leftValue.toLocaleLowerCase()
                        : leftValue.toLowerCase();
            }

            if (typeof rightValue === "string") {
                rightValue = sortLocaleAware
                        ? rightValue.toLocaleLowerCase()
                        : rightValue.toLowerCase();
            }
        }

        //        console.log(leftValue, sortOrder ? ">" : "<", rightValue, ":", sortOrder
        //                    ? leftValue > rightValue
        //                    : leftValue < rightValue);

        return sortOrder
                ? leftValue > rightValue
                : leftValue < rightValue;
    }

    //--------------------------------------------------------------------------

    function insertPosition(lessThan, item) {
        var lower = 0
        var upper = items.count

        while (lower < upper) {
            var middle = Math.floor(lower + (upper - lower) / 2)
            var result = lessThan(item.model, items.get(middle).model);
            if (result) {
                upper = middle
            } else {
                lower = middle + 1
            }
        }

        return lower
    }

    //--------------------------------------------------------------------------

    function sort() {
        if (!sortEnabled || !items.count && !unsortedItems.count) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name,
                        "sortRole:", sortRole,
                        "sortOrder:", sortOrder,
                        "sortCaseSensitivity:", sortCaseSensitivity);
        }

        console.time("sort");

        items.setGroups(0, items.count, unsortedItems.name);

        _sort();

        console.timeEnd("sort");

        lastSorted = new Date();
    }

    //--------------------------------------------------------------------------

    function _sort() {
        while (unsortedItems.count > 0) {
            var item = unsortedItems.get(0);

            var index = insertPosition(lessThan, item);

            item.groups = items.name;
            items.move(item.itemsIndex, index);
        }
    }

    //--------------------------------------------------------------------------

    function filter() {
        if (!items.count && !unmatchedItems.count && !unfilteredItems.count) {
            return;
        }

        console.time("filter");

        if (debug) {
            console.log(objectName, "items:", items.count);
        }

        if (items.count) {
            items.setGroups(0, items.count, unmatchedItems.name);
        }

        if (debug) {
            console.log(objectName, "unmatchedItems:", unmatchedItems.count);
        }

        if (unmatchedItems.count) {
            unmatchedItems.setGroups(0, unmatchedItems.count, unfilteredItems.name);
        }

        _filter();

        console.time("filter");
    }

    //--------------------------------------------------------------------------

    function _filter() {
        while (unfilteredItems.count > 0) {
            var item = unfilteredItems.get(0);

            var match = filterFunction
                    ? filterFunction(item.model)
                    : true

            if (sortEnabled) {
                item.inUnsorted = !!match;
            } else {
                item.inItems = !!match;
            }

            item.inUnmatched = !match;
            item.inUnfiltered = false;
        }
    }

    //--------------------------------------------------------------------------

    function _filterFunction(item) {
        if (!filterValue) {
            return true;
        }

        if (Array.isArray(filterRole)) {
            for (const role of filterRole) {
                if (inFilter(item[role])) {
                    return true;
                }
            }
        } else {
            return inFilter(item[filterRole]);
        }
    }

    //--------------------------------------------------------------------------

    function inFilter(value) {
        if (value > "") {
            return filterCaseSensitivity === Qt.CaseInsensitive
                    ? value.toLowerCase().search(filterPattern) >=0
                    : value.search(filterPattern) >=0;
        }
    }

    //----------------------------------------------------------------------

    function setSortOrder(value) {
        var _sortOrder = Qt.AscendingOrder;

        switch (value) {
        case Qt.AscendingOrder:
        case Qt.DescendingOrder:
            _sortOrder = value;
            break;

        default:
            if (value > "" && value.toString().toLocaleString().startsWith("d")) {
                _sortOrder = Qt.DescendingOrder;
            }
            break;
        }

        sortOrder = _sortOrder;
    }

    //--------------------------------------------------------------------------
}
