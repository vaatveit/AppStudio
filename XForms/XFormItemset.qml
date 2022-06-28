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

import "Singletons"
import "XForm.js" as XFormJS

Item {
    id: itemsetItem

    //--------------------------------------------------------------------------

    property var itemset
    property var itemsetInfo
    property XFormData formData
    property string nodeset: itemset["@nodeset"] || ""
    property string valueProperty
    property string labelProperty
    readonly property string translatedLabelProperty: labelProperty + "::" + xform.language
    property string listName
    property bool randomize
    property string expression
    property XFormExpression expressionInstance
    property var expressionNodesets
    property var items
    readonly property bool hasFilter: expression > ""
    property var filteredItems: []
    property var nodesetValues
    property var previousNodesetValues
    property bool createLabelItems: true // TODO Improve and remove need for this

    property bool searchExpression

    property bool debug

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "itemset:", JSON.stringify(itemset, undefined, 2));
            console.log(logCategory, "nodeset:", nodeset);
        }

        if (searchExpression) {
            initializeSearch();
        } else {
            initialize();
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        itemsetInfo = xform.itemsets.parseItemset(itemset);
        if (debug) {
            console.log(logCategory, "itemsetInfo:", JSON.stringify(itemsetInfo, undefined, 2));
        }

        listName = itemsetInfo.instanceId;
        expression = itemsetInfo.expression || "";
        valueProperty = itemsetInfo.valueProperty;
        labelProperty = itemsetInfo.textIdProperty;
        randomize = !!itemsetInfo.randomize;

        if (itemsetInfo.src > ""
                && !searchExpression
                && expression) {
            // TODO Fix workaround for instance src to work with choice filter

            itemset.external = true;
            labelProperty = itemsetInfo.labelProperty;
        }

        if (!expression && createLabelItems) {
            items = xform.itemsets.getValueLabelItems(itemsetInfo);
            if (randomize) {
                XFormJS.randomizeArray(items);
            }
        } else {
            items = xform.itemsets.getItems(itemsetInfo);
        }

        if (debug) {
            console.log(logCategory, "items count:", items.length);
            //console.log(logCategory, "items:", JSON.stringify(items, undefined, 2));
        }

        if (expression) {
            expressionInstance = formData.expressionsList.addExpression(expression, undefined, "itemsetFilter");
            expressionNodesets = expressionInstance.nodesets;
            nodesetValues = expressionInstance.nodesetValuesBinding();
        }
    }

    //--------------------------------------------------------------------------

    function initializeSearch() {
        var propertiesRow = items[0];

        valueProperty = propertiesRow["value"];
        labelProperty = propertiesRow["label"];
        itemset.external = true;

        if (debug) {
            console.log("valueProperty:", valueProperty, "labelProperty:", labelProperty, "searchExpression:", searchExpression);
        }

        expressionInstance = formData.expressionsList.addExpression(expression, undefined, "itemsetSearch");
        expressionNodesets = expressionInstance.nodesets;
        nodesetValues = expressionInstance.nodesetValuesBinding();
        //        filteredItems = expressionInstance.binding();

        if (debug) {
            console.log("nodesets:", JSON.stringify(expressionInstance.nodesets, undefined, 2));
        }

        if (!expressionInstance.nodesets.length) {
            nodesetValuesChanged();
            //        Qt.callLater(nodesetValuesChanged);
        }
    }

    //--------------------------------------------------------------------------

    onNodesetValuesChanged: {
        if (debug) {
            console.log(logCategory, "onNodesetValuesChanged:", JSON.stringify(nodesetValues, undefined, 2));
        }

        if (searchExpression && !nodesetValues.length) {
            updateFilteredItems();
            return;
        }

        var changed = false;

        if (!previousNodesetValues) {
            previousNodesetValues = {};
        }

        expressionNodesets.forEach(function (nodeset) {
            if (nodesetValues[nodeset] != previousNodesetValues[nodeset]) {
                previousNodesetValues[nodeset] = nodesetValues[nodeset];
                changed = true;
            }
        });

        if (debug) {
            console.log(logCategory, "Itemset changed:", changed);
        }

        if (changed) {
            updateFilteredItems();
            //            console.log(logCategory, "filteredItems", JSON.stringify(filteredItems, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(itemsetItem, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onLanguageChanged: {
            console.log(logCategory, "nodeset:", nodeset, "language:", xform.language, "src:", itemsetInfo.src, "external:", itemset.external);

            if (itemset.external) {
                Qt.callLater(updateFilteredItems);
                //updateFilteredItems();
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateFilteredItems() {
        if (debug) {
            console.time("filter");
        }

        var filteredItems = searchExpression
                ? searchItems()
                : filterItems();


        if (debug) {
            console.timeEnd("filter");
            console.log(logCategory, "# Filtered:", filteredItems.length);
        }

        if (randomize) {
            XFormJS.randomizeArray(filteredItems);
        }

        //console.log(logCategory, "filteredItems:", JSON.stringify(filteredItems, undefined, 2))

        itemsetItem.filteredItems = filteredItems;
    }

    //--------------------------------------------------------------------------

    function filterItems() {
        if (!Array.isArray(items)) {
            return [];
        }

        if (debug) {
            console.log(logCategory, "Filtering #", items.length, "items external:", itemset.external, " expression:", expressionInstance.expression, "language:", xform.language);
        }

        var selectedItems = [];

        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (!expressionInstance || Boolean(expressionInstance.scopedEvaluate(item, false))) {
                if (createLabelItems) {
                    selectedItems.push(valueLabelItem(item));
                } else {
                    selectedItems.push(item);
                }
            }
        }

        return selectedItems;
    }

    //--------------------------------------------------------------------------

    function searchItems() {
        var items = expressionInstance.evaluate();
        if (!Array.isArray(items)) {
            return [];
        }

        var selectedItems = [];

        for (var item of items) {
            if (createLabelItems) {
                selectedItems.push(valueLabelItem(item));
            } else {
                selectedItems.push(item);
            }
        }

        return selectedItems;
    }

    //--------------------------------------------------------------------------

    function valueLabelItem(item) {
        // console.log(logCategory, "valueProperty:", valueProperty, "item:", JSON.stringify(item));

        return {
            value: item[valueProperty],
            label: itemset.external
                   ? translatedLabel(item)
                   : {
                         "@ref": "jr:itext('%1')".arg(item[labelProperty])
                     }
        }
    }

    //--------------------------------------------------------------------------

    function translatedLabel(item) {
        // console.log(logCategory, "labelProperty:", labelProperty, "tranlsatedLabelProperty:", translatedLabelProperty, "item:", JSON.stringify(item));

        if (item[translatedLabelProperty]) {
            return item[translatedLabelProperty];
        }

        return item[labelProperty];
    }

    //--------------------------------------------------------------------------
}
