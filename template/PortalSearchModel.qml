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
import "../Models"

import "../template/SurveyHelper.js" as Helper


ListModel {
    id: listModel
    
    //--------------------------------------------------------------------------

    property bool busy: false
    property alias num: searchRequest.num
    property alias portal: searchRequest.portal
    property alias q: searchRequest.q
    property alias progress: searchRequest.searchProgress
    property bool debug

    property var itemInfoFilter: null

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyDescription: "description"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    signal searchCompleted();

    //--------------------------------------------------------------------------

    dynamicRoles: true

    //--------------------------------------------------------------------------

    function startSearch() {
        if (debug) {
            console.log(logCategory, "Searching for items:", q);
        }

        if (busy) {
            console.warn(logCategory, "Search in progress:", q);
            return;
        }

        listModel.clear();
        busy = true;
        searchRequest.search();
    }

    //--------------------------------------------------------------------------

    function startGroupSearch(groupQuery) {
        console.log(logCategory, arguments.callee.name, "groupQuery:", groupQuery, "portalUrl:", portal.portalUrl);

        listModel.clear();
        busy = true;
        groupSearchRequest.search(groupQuery);
    }

    //--------------------------------------------------------------------------

    function imageUrl(itemId, imageName) {
        return portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemId + "/info/" + imageName);
    }

    //--------------------------------------------------------------------------

    onItemInfoFilterChanged: {
        if (itemInfoFilter && typeof itemInfoFilter !== "function") {
            console.error("itemInfoFilter not a function:", typeof itemInfoFilter);
        }
    }

    //--------------------------------------------------------------------------

    onSearchCompleted: {
        console.log(logCategory, "Search completed:", count, "item(s)");
        busy = false;
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        name: AppFramework.typeOf(listModel, true)
    }

    //--------------------------------------------------------------------------

    readonly property PortalSearch searchRequest: PortalSearch {
        id: searchRequest

        sortField: "title"
        sortOrder: "asc"

        onSuccess: {
            addItems(response.results);

            if (response.nextStart > 0) {
                search(response.nextStart);
            } else {
                searchCompleted();
            }
        }
    }

    //--------------------------------------------------------------------------

    readonly property PortalGroupContentRequest groupSearchRequest: PortalGroupContentRequest {
        id: groupSearchRequest

        portal: listModel.portal

        sortField: searchRequest.sortField
        sortOrder: searchRequest.sortOrder

        num: listModel.num

        onContentItems: {
            addItems(itemInfos);
        }

        onFinished: {
            searchCompleted();
        }

        onFailed: {
            searchCompleted();
        }
    }

    //--------------------------------------------------------------------------

    function addItems(itemInfos) {
        for (var itemInfo of itemInfos) {
            if (!itemInfo.description) {
                itemInfo.description = "";
            }

            if (itemInfoFilter) {
                itemInfo = itemInfoFilter(itemInfo);
            }

            if (itemInfo) {
                var tags = Array.isArray(itemInfo.tags)
                        ? itemInfo.tags.join("^")
                        : ""

                itemInfo.tags = tags;

                listModel.append(Helper.removeArrayProperties(itemInfo));

                if (debug) {
                    console.log(logCategory, "searchResult:", JSON.stringify(itemInfo, undefined, 2));
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
