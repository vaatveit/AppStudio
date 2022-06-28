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
    id: itemsets

    //--------------------------------------------------------------------------

    property FileFolder dataFolder
    property string dataFileName: "itemsets.csv"
    readonly property string dataSeparator: ","
    readonly property string listNameColumn: "list_name"
    property var itemLists: ({})

    property bool debug

    property XFormItemsetsData itemsetsData

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (itemsetsData) {
            console.log(logCategory, "Shared itemsets data instance");
        } else {
            itemsetsData = itemsetsDataComponent.createObject(itemsets);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(itemsets, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: itemsetsDataComponent

        XFormItemsetsData {
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        itemsetsData.dataFolder = dataFolder;
        itemsetsData.initialize();
        loadExternal();
    }

    //--------------------------------------------------------------------------

    function parseItemset(itemset) {
        if (itemset && typeof itemset !== "object") {
            console.error(logCategory, arguments.callee.name, "invalid itemset:", JSON.stringify(itemset, undefined, 2));
            return;
        }

        var info = parseNodeset(itemset["@nodeset"]);
        if (!info) {
            return;
        }

        info.src = Attribute.value(findInstance(info.instanceId), Attribute.kSrc);
        info.valueProperty = itemset.value["@ref"] || "value";

        var labelRef = itemset.label["@ref"];
        var tokens = labelRef.match(/(?:jr:itext\()(\w+)(?:\))/);

        if (Array.isArray(tokens)) {
            info.labelProperty = "";
            info.textIdProperty = tokens[1];
        } else {
            info.labelProperty = labelRef;
            info.textIdProperty = "";
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemsetInfo:", JSON.stringify(info, undefined, 2));
        }

        return info;
    }

    //--------------------------------------------------------------------------

    function parseNodeset(nodeset) {
        var tokens = nodeset.match(/instance\(\s*\'(.+)\'\s*\)([\w\/.']+)(?:\[(.+)\])?/);

        if (!Array.isArray(tokens)) {
            console.error(logCategory, arguments.callee.name, "error parsing nodeset:", nodeset);
            return;
        }

        var info = {
            nodeset: nodeset,
            instanceId: tokens[1],
            path: tokens[2].split("/").filter(s => !!s),
            expression: tokens[3],
            randomize: nodeset.startsWith("randomize(")
        }

        return info;
    }

    //--------------------------------------------------------------------------

    function getItems(itemsetInfo, noCache) {
        if (Array.isArray(itemLists[itemsetInfo.instanceId])) {
            return itemLists[itemsetInfo.instanceId];
        }

        var instance = findInstance(itemsetInfo.instanceId);

        if (!instance) {
            console.error(logCategory, "List instance not found:", itemsetInfo.instanceId);
            return [];
        }

        //console.log(logCategory, "instance:", JSON.stringify(instance, undefined, 2));

        var items;

        var src = Attribute.value(instance, Attribute.kSrc);
        if (src) {
            items = getItemsFromSource(src);
        } else {
            items = XFormJS.childElements(instance[itemsetInfo.path[0]]);
        }

        //console.log(logCategory, "items:", JSON.stringify(items, undefined, 2));

        if (!noCache) {
            itemLists[itemsetInfo.instanceId] = items;
        }

        return items;
    }

    //--------------------------------------------------------------------------

    function getItemsFromSource(src, itemsetInfo) {
        console.log(logCategory, arguments.callee.name, "src:", src);

        var tokens = src.match(/jr:\/\/([\w-]+)\/(.+)/);
        if (!Array.isArray(tokens)) {
            console.error(logCategory, arguments.callee.name, "Invalid src:", src);
            return [];
        }

        //console.log(logCategory, "tokens:", JSON.stringify(tokens));

        var fileType = tokens[1];
        var fileName = tokens[2];

        var items;

        switch (fileType) {
        case "file-csv":
            items = getCsvItems(fileName);
            break;

        default:
            console.error(logCategory, "Unhandled fileType:", fileType, "fileName:", fileName, "src:", src);
            items = [];
            break;
        }

        return items;
    }

    //--------------------------------------------------------------------------

    function getCsvItems(fileName) {
        console.log(logCategory, arguments.callee.name, "fileName:", fileName);

        var list = itemsetsData.getCsvTable(fileName);
        if (!list) {
            console.error(logCategory, "Error getting fileName:", fileName);
            return [];
        }

        return list.rows;
    }

    //--------------------------------------------------------------------------

    function getValueLabelItems(itemsetInfo) {
        var listKey = "%1:%2:%3"
        .arg(itemsetInfo.instanceId)
        .arg(itemsetInfo.valueProperty)
        .arg(itemsetInfo.textIdProperty);

        if (Array.isArray(itemLists[listKey])) {
            return itemLists[listKey];
        }

        var instanceItems = getItems(itemsetInfo, true);

        var items = [];

        for (let instanceItem of instanceItems) {
            var label;

            if (itemsetInfo.textIdProperty) {
                label = {
                    "@ref": "jr:itext('%1')".arg(instanceItem[itemsetInfo.textIdProperty])
                };
            } else if (itemsetInfo.labelProperty) {
                label = instanceItem[itemsetInfo.labelProperty] || "";
            } else {
                label = "<Error>";
            }

            items.push({
                           value: instanceItem[itemsetInfo.valueProperty],
                           label: label
                       });
        }

        itemLists[listKey] = items;

        //console.log(logCategory, "itemsetInfo:", JSON.stringify(itemsetInfo, undefined, 2), "items:", JSON.stringify(items, undefined, 2))

        return items;
    }

    //--------------------------------------------------------------------------

    function loadExternal() {
        if (!dataFolder.fileExists(dataFileName)) {
            console.log(logCategory, "Itemsets data file not found:", dataFolder.filePath(dataFileName));

            return;
        }

        if (itemsetsData.useDatabase) {
            loadExternalTable();
        } else {
            loadExternalFile();
        }
    }

    //--------------------------------------------------------------------------

    function loadExternalFile() {
        console.log(logCategory, "Loading itemsets file:", dataFolder.filePath(dataFileName));

        var eventName = "itemsets:readFile";
        itemsetsData.event(eventName);

        var data = dataFolder.readTextFile(dataFileName);

        var rows = data.split("\n");

        if (rows < 1) {
            console.log("No data rows");
            return;
        }

        var columns = rows[0].split(dataSeparator);

        for (var i = 0; i < columns.length; i++) {
            columns[i] = columnValue(columns[i]);
        }

        console.log("# rows", rows.length, "columns:", JSON.stringify(columns, undefined, 2));

        for (i = 1; i < rows.length; i++) {
            var values = rows[i].split(dataSeparator);

            if (values.length < columns.length) {
                continue;
            }

            var valuesObject = {};

            for (var j = 0; j < values.length; j++) {
                valuesObject[columns[j]] = columnValue(values[j]);
            }

            addListRow(valuesObject);
        }

        itemsetsData.eventEnd(eventName);

        // console.log("itemLists:", JSON.stringify(itemLists, undefined, 2));
    }
    
    //--------------------------------------------------------------------------

    function addListRow(values) {
        var listName = values[listNameColumn];

        if (!(listName > "")) {
            if (debug) {
                console.log(logCategory, "skip list row:", JSON.stringify(values, undefined, 2));
            }
            return;
        }

        values[listNameColumn] = undefined;

        if (!Array.isArray(itemLists[listName])) {
            itemLists[listName] = [];
        }

        itemLists[listName].push(values);
    }

    //--------------------------------------------------------------------------

    function columnValue(value) {
        var tokens = value.match(/\"(.*)\"/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return value;
        }
    }

    //--------------------------------------------------------------------------

    function findInstance(id) {
        if (!id || !Array.isArray(xform.instances)) {
            return;
        }

        for (var i = 0; i < xform.instances.length; i++) {
            var instance = xform.instances[i];

            if (instance["@id"] === id) {
                return instance;
            }
        }

        console.error(logCategory, "instance not found id:", id);
    }

    //--------------------------------------------------------------------------

    function loadExternalTable() {
        console.log(logCategory, "Loading itemsets table");

        initializeItemsetsTable(dataFolder.filePath(dataFileName));

        var eventName = "itemsets:readTable";

        itemsetsData.event(eventName);

        var query = itemsetsData.database.query("SELECT * from itemsets");

        if (query.error) {
            console.error(query.error);
            return;
        }

        var ok = query.first();
        while (ok) {
            addListRow(query.values);
            ok = query.next();
        }
        query.finish();

        itemsetsData.eventEnd(eventName);
    }

    //--------------------------------------------------------------------------

    function initializeItemsetsTable(path) {
        var fileInfo = AppFramework.fileInfo(path);

        console.log(logCategory, "Initializing itemsets table from:", path);

        itemsetsData.loadTable(
                    fileInfo,
                    undefined,
                    "WHERE \"%1\" > '' AND name > ''".arg(listNameColumn),
                    initializeItemsetsTableIndices);

        console.log(logCategory, "itemsets table initialized");
    }

    //--------------------------------------------------------------------------

    function initializeItemsetsTableIndices(tableName, table) {
        console.log(logCategory, "Initializing itemsets indices table:", tableName);

        var eventName = tableName + ":createIndex";
        itemsetsData.event(eventName);

        var commands = [];

        commands.push("CREATE INDEX \"%1_index_%2\" ON \"%1\" (\"%2\");"
                      .arg(tableName)
                      .arg(listNameColumn));

        var skipFields = [listNameColumn];
        var descFields = ["label", "image", "audio", "video"];

        for (var i = 0; i < table.fields.count; i++) {
            var fieldName = table.fields.fieldName(i);

            //console.log("field:", fieldName);

            if (skipFields.indexOf(fieldName) >= 0) {
                console.log(logCategory, "skip indexing field:", fieldName);
                continue;
            }

            for (var j = 0; j < descFields.length; j++) {
                var descField = descFields[j];

                if (fieldName === descField || fieldName.substring(0, descField.length + 2) === (descField + "::")) {
                    console.log(logCategory, "skip indexing description field:", fieldName);
                    fieldName = undefined;
                    break;
                }
            }

            if (!fieldName) {
                continue;
            }

            commands.push("CREATE INDEX \"%1_index_%3\" ON \"%1\" (\"%2\", \"%3\");"
                          .arg(tableName)
                          .arg(listNameColumn)
                          .arg(fieldName));
        }

        itemsetsData.database.batchExecute(commands);

        itemsetsData.eventEnd(eventName);
    }

    //--------------------------------------------------------------------------
}
