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

    property bool filterEnabled: filterRole || !!filterFunction
    property string filterRole
    property var filterFunction
    property alias filteredItems: filteredItems

    property int lastCount

    //--------------------------------------------------------------------------

    signal filtered()

    //--------------------------------------------------------------------------

    filterOnGroup: filterEnabled
                   ? filteredItems.name
                   : items.name

    groups: [
        DelegateModelGroup {
            id: filteredItems
            
            name: "filtered"
            includeByDefault: false
        }
    ]

    //--------------------------------------------------------------------------

    onFilterEnabledChanged: {
        invalidateFilter();
    }

    //--------------------------------------------------------------------------

    function invalidateFilter() {
        Qt.callLater(filter);
    }

    //--------------------------------------------------------------------------

    function filter() {
        if (!filterRole && !filterFunction) {
            return;
        }

        busy = true;
        console.log(logCategory, arguments.callee.name, "model.count:", model.count, "items.count:", items.count);
        console.time("filter");

        var itemsChanged = items.count !== lastCount;
        var filteredCount = filteredItems.count;

        for (var i = 0; i < items.count; i++) {
            var item = items.get(i);

            item.inFiltered = !!filterFunction
                    ? filterFunction(item.model)
                    : !!filterRole
                      ? !!item.model[filterRole]
                      : true;
        }

        var filteredDelta = filteredItems.count - filteredCount;
        lastCount = items.count;

        console.timeEnd("filter");
        console.log(logCategory, arguments.callee.name,
                    "filteredItems.count:", filteredItems.count,
                    "filteredDelta:", filteredDelta,
                    "itemsChanged:", itemsChanged);

        busy = false;

        if (!delegate && (itemsChanged || filteredDelta)) {
            filteredItems.countChanged();
        }

        if (itemsChanged || filteredDelta) {
            filtered();
        }
    }

    //--------------------------------------------------------------------------
}
