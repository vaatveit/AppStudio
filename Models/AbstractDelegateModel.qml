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

DelegateModel {
    id: delegateModel

    //--------------------------------------------------------------------------

    property string indexRole: "_modelIndex"

    property bool debug
    property bool busy

    readonly property DelegateModelGroup filterGroup: findGroup(filterOnGroup)

    //--------------------------------------------------------------------------

    objectName: AppFramework.typeOf(delegateModel, true)

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(delegateModel, true)
    }

    //--------------------------------------------------------------------------

    function get(index) {
        var item = model.get(index);

        if (debug) {
            console.trace()
            console.log(logCategory, arguments.callee.name, "index:", index, JSON.stringify(item, undefined, 2));
        }

        return item;
    }

    //--------------------------------------------------------------------------

    function setProperty(index, name, value) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "index:", index, "name:", name, "value:", value);
        }

        model.setProperty(index, name, value);
    }

    //--------------------------------------------------------------------------

    function findGroup(name) {
        if (!name) {
            return items;
        }

        for (var i = 0; i < groups.length; i++) {
            if (groups[i].name === name) {
                return groups[i];
            }
        }
    }

    //--------------------------------------------------------------------------

    function getGroupItem(group, groupIndex) {
        if (groupIndex < 0) {
            return;
        }

        if (!group) {
            group = items;
        }

        if (groupIndex >= group.count) {
            if (debug) {
                console.warn(logCategory, arguments.callee.name, groupIndex, "=>", group.count);
            }
            return;
        }

        return group.get(groupIndex).model;
    }

    //--------------------------------------------------------------------------

    function setGroupItemProperty(group, groupIndex, name, value) {
        if (!group) {
            group = items;
        }

        var item = group.get(groupIndex);
        var modelIndex = item.model[indexRole];

        if (debug) {
            console.log(logCategory, arguments.callee.name, "group:", group.name, "groupIndex:", groupIndex, "modelIndex:", modelIndex, "name:", name, "value:", value);
        }

        model.setProperty(modelIndex, name, value);
    }

    //--------------------------------------------------------------------------

    function getFilterItem(groupIndex, name, value) {
        if (groupIndex < 0 || groupIndex > filterGroup.count) {
            return;
        }

        return filterGroup.get(groupIndex).model;
    }

    //--------------------------------------------------------------------------

    function setFilterItemProperty(index, name, value) {
        setGroupItemProperty(filterGroup, index, name, value);
    }

    //--------------------------------------------------------------------------
}
