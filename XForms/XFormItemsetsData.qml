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

import "XForm.js" as XFormJS

Item {
    id: itemsetsData

    //--------------------------------------------------------------------------

    property FileFolder dataFolder
    property var tables: ({})
    property string dataSeparator: ","
    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property int kSchemaVersion: 1

    property alias database: database
    property bool useDatabase: app.features.itemsetsDatabase
    property var loadedTables: ({})

    //--------------------------------------------------------------------------

    signal event(string name)
    signal eventEnd(string name)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "Instance created");
        console.log(logCategory, "useDatabase:", useDatabase);
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        console.log(logCategory, "Instance destruction");
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(itemsetsData, true)
    }

    //--------------------------------------------------------------------------

    XFormSqlDatabase {
        id: database
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (useDatabase) {
            initializeDatabase();
        }
    }

    //--------------------------------------------------------------------------

    function getCsvTable(fileName) {
        if (tables[fileName]) {
            return tables[fileName];
        }

        var table = useDatabase
                ? readCsvTable(fileName)
                : readCsvFile(fileName);

        if (table) {
            tables[fileName] = table;
        }

        return table;
    }

    //--------------------------------------------------------------------------

    function readCsvFile(fileName) {
        if (!dataFolder.fileExists(fileName)) {
            console.error("CSV file not found:", dataFolder.filePath(fileName));
            return;
        }

        var table = {
            columns: [],
            rows: []
        };


        var eventName = fileName + ":readFile";

        event(eventName);

        var csvData = dataFolder.readTextFile(fileName);
        var csvRows = csvData.split("\n");
        var columns = csvRows[0].split(dataSeparator);

        for (var i = 0; i < columns.length; i++) {
            columns[i] = columnValue(columns[i].trim());
        }

        table.columns = columns;

        if (csvRows < 1) {
            console.warn("No data rows in:", fileName);
            return table;
        }

        for (i = 1; i < csvRows.length; i++) {
            var values = csvRows[i].split(dataSeparator);

            if (values.length < columns.length) {
                continue;
            }

            var row = {};

            for (var j = 0; j < values.length; j++) {
                row[columns[j]] = columnValue(values[j]);
            }

            table.rows.push(row);
        }

        eventEnd(eventName);

        if (debug) {
            console.log(fileName, "columns:", JSON.stringify(columns));
            console.log(fileName, "rows:", table.rows.length, JSON.stringify(table.rows));
        }

        return table;
    }

    //--------------------------------------------------------------------------

    function columnValue(value) {
        var tokens = value.match(/\"(.*)\"/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return value.trim()
        }
    }

    //--------------------------------------------------------------------------

    function lookupValue(tableName, valueField, keyField, keyValue) {
        return useDatabase
                ? lookupTableValue(tableName, valueField, keyField, keyValue)
                : lookupCsvValue(tableName, valueField, keyField, keyValue);
    }

    //--------------------------------------------------------------------------

    function lookupCsvValue(tableName, valueField, keyField, keyValue) {
        var table = getCsvTable(tableName + ".csv");
        if (!table) {
            return;
        }

        var row = table.rows.find(row => row[keyField] === keyValue);
        if (row) {
            return valueField
                    ? row[valueField]
                    : row;
        }
    }

    //--------------------------------------------------------------------------

    function initializeDatabase() {
        if (database.isOpen) {
            return;
        }

        var filePath = dataFolder.filePath("itemsets.sqlite");

        console.log(logCategory, "Initializing itemsets database:", filePath);

        database.databaseName = filePath;
        database.open();

        database.initializeProperties();
    }

    //--------------------------------------------------------------------------

    function loadTable(csvFileInfo, tableName, where, callback) {
        if (!tableName) {
            tableName = csvFileInfo.baseName;
        }

        if (loadedTables[tableName]) {
            if (debug) {
                console.log(logCategory, "Table already loaded:", tableName);
            }
            return true;
        }

        console.log(logCategory, "Loading table:", tableName, "source:", csvFileInfo.filePath);

        var lastModifiedProperty = "%1_lastModified".arg(tableName);
        var versionProperty = "%1_version".arg(tableName);

        var lastModified = Number(database.queryProperty(lastModifiedProperty));
        var version = Number(database.queryProperty(versionProperty, 0));

        console.log("source lastModified:", csvFileInfo.lastModified.valueOf(), "kSchemaVersion:", kSchemaVersion);
        console.log("target lastModified:", lastModified, "version:", version);

        if (csvFileInfo.lastModified.valueOf() === lastModified.valueOf() && kSchemaVersion === version) {
            console.log(logCategory, "Table is current:", tableName);
            loadedTables[tableName] = true;
            return true;
        }

        var eventName = tableName + ":createTable";

        event(eventName);

        var csvTableName = tableName + "_CSV";

        var commands = [];

        commands.push("DROP TABLE IF EXISTS \"%1\";".arg(csvTableName));
        commands.push("CREATE VIRTUAL TABLE IF NOT EXISTS \"%1\" USING CSV('%2');"
                      .arg(csvTableName)
                      .arg(csvFileInfo.filePath));
        commands.push("DROP TABLE IF EXISTS \"%1\";".arg(tableName));
        commands.push("CREATE TABLE IF NOT EXISTS \"%1\" AS SELECT * FROM \"%2\" %3;"
                      .arg(tableName)
                      .arg(csvTableName)
                      .arg(where || ""));
        commands.push("DROP TABLE \"%1\";".arg(csvTableName));

        database.batchExecute(commands, true);

        database.updateProperty(lastModifiedProperty, csvFileInfo.lastModified.valueOf(), Qt.formatDateTime(csvFileInfo.lastModified, Qt.ISODate));
        database.updateProperty(versionProperty, kSchemaVersion, "Schema version %1".arg(kSchemaVersion));

        eventEnd(eventName);

        if (callback) {
            var table = database.table(tableName);

            callback(tableName, table);
        }

        loadedTables[tableName] = true;

        return true;
    }

    //--------------------------------------------------------------------------

    function loadCsvTable(fileName, keyFields) {
        var fileInfo = dataFolder.fileInfo(fileName);
        if (!fileInfo.exists) {
            console.error(logCategory, "File not found:", fileInfo.filePath);
            return;
        }

        if (loadedTables[fileInfo.baseName]) {
            if (debug) {
                console.log(logCategory, "CSV Table already loaded:", fileInfo.baseName);
            }
            return true;
        }

        console.log("Loading database table:", fileName, "keyFields:", JSON.stringify(keyFields));

        return loadTable(fileInfo, undefined, undefined,
                         function (tableName, table) {
                             indexCsvTable(tableName, table, keyFields);
                         });
    }

    //--------------------------------------------------------------------------

    function indexCsvTable(tableName, table, keyFields) {
        console.log(logCategory, "Indexing table:", tableName, "keyFields:", JSON.stringify(keyFields));

        if (!Array.isArray(keyFields)) {
            keyFields = [];
        }

        var eventName = tableName + ":createIndex";
        event(eventName);

        var commands = [];

        for (var i = 0; i < table.fields.count; i++) {
            var fieldName = table.fields.fieldName(i);

            if (fieldName.endsWith("_key") || keyFields.indexOf(fieldName) >= 0) {
                commands.push("CREATE INDEX \"%1_index_%2\" ON \"%1\" (\"%2\");"
                              .arg(tableName)
                              .arg(fieldName));
            }
        }

        database.batchExecute(commands);

        eventEnd(eventName);
    }

    //--------------------------------------------------------------------------

    function readCsvTable(fileName) {
        if (!loadCsvTable(fileName)) {
            return;
        }

        var fileInfo = dataFolder.fileInfo(fileName);
        var query = itemsetsData.database.query("SELECT * from \"%1\"".arg(fileInfo.baseName));

        if (query.error) {
            console.error(query.error);
            return;
        }


        var eventName = fileName + ":readTable";
        event(eventName);

        var rows = [];

        var ok = query.first();
        while (ok) {
            rows.push(query.values);
            ok = query.next();
        }
        query.finish();

        eventEnd(eventName);

        var columns = [];
        for (var i = 0; i < query.fields.count; i++) {
            columns.push(query.fields.fieldName(i));
        }

        var table = {
            columns: columns,
            rows: rows
        }

        // console.log(logCategory, "table:", JSON.stringify(table, undefined, 2));

        return table;
    }

    //--------------------------------------------------------------------------

    function lookupTableValue(tableName, valueField, keyField, keyValue) {
        if (!loadCsvTable(tableName + ".csv")) {
            return;
        }

        var query = itemsetsData.database.query("SELECT \"%1\" from \"%2\" WHERE \"%3\" = \"%4\""
                                                .arg(valueField)
                                                .arg(tableName)
                                                .arg(keyField)
                                                .arg(keyValue));

        if (query.error) {
            console.error(query.error);
            return;
        }

        if (!query.first()) {
            return;
        }

        var value = query.value(valueField);

        query.finish();

        return value;
    }

    //--------------------------------------------------------------------------
    // searchType
    //   contains
    //   startswith
    //   endswith
    //   matches

    function search(tableName, searchType, searchColumn, searchText, filterColumn, filterText) {
        if (debug) {
            console.log(logCategory, "search:", JSON.stringify(arguments));
        }

        var rows = useDatabase
            ? searchTable(tableName, searchType, searchColumn, searchText, filterColumn, filterText)
            : searchFile(tableName, searchType, searchColumn, searchText, filterColumn, filterText);

        if (debug) {
            console.log(logCategory, "rows:", JSON.stringify(rows, undefined, 2));
        }

        return rows || [];
    }

    //--------------------------------------------------------------------------

    function searchFile(tableName, searchType, searchColumn, searchText, filterColumn, filterText) {
        var table = getCsvTable(tableName + ".csv");
        if (!table) {
            return;
        }

        if (!searchType) {
            return table.rows;
        }

        var searchTypes = {
            "contains": function (value) {
                return value.indexOf(searchText) >= 0;
            },

            "startswith": function (value) {
                return value.startsWith(searchText);
            },

            "endswith": function (value) {
                return value.endsWith(searchText);
            },

            "matches": function (value) {
                return value == searchText;
            }
        }

        var searchFunction = searchTypes[searchType];
        if (searchFunction) {
            if (XFormJS.isEmpty(searchText)) {
                return;
            }

            if (filterColumn && XFormJS.isEmpty(filterText)) {
                return;
            }
        } else {
            console.error(logCategory, "Invalid search type:", searchType);
            return;
        }

        return table.rows.filter(function (row) {
            if (filterColumn && row[filterColumn] !== filterText) {
                return;
            }

            var searchValue = row[searchColumn];
            if (searchValue === undefined) {
                return
            }

            return searchFunction(searchValue);
        });
    }

    //--------------------------------------------------------------------------

    function searchTable(tableName, searchType, searchColumn, searchText, filterColumn, filterText) {
        if (!loadCsvTable(tableName + ".csv")) {
            return;
        }

        var sql = "SELECT * from \"%1\"".arg(tableName);

        var searchPattern;
        switch (searchType) {
        case "contains":
            searchPattern = "LIKE '%%1%'";
            break;

        case "startswith":
            searchPattern = "LIKE '%1%'";
            break;

        case "endswith":
            searchPattern = "LIKE '%%1'";
            break;

        case "matches":
            searchPattern = "= '%1'";
            break;

        default:
            console.error(logCategory, "Invalid searchType:", searchType);
            return;
        }

        if (searchPattern) {
            if (XFormJS.isEmpty(searchText)) {
                return;
            }

            sql += " WHERE \"%1\" ".arg(searchColumn) + searchPattern.arg(searchText);

            if (filterColumn) {
                if (XFormJS.isEmpty(filterText)) {
                    return;
                }

                sql += " AND \"%1\" = '%2'".arg(filterColumn).arg(filterText)
            }
        }

        if (debug) {
            console.log(logCategory, "sql:", sql);
        }

        var query = itemsetsData.database.query(sql);

        if (query.error) {
            console.error(query.error);
            return;
        }

        var rows = [];

        var ok = query.first();
        while (ok) {
            rows.push(query.values);
            ok = query.next();
        }
        query.finish();

        return rows;
    }

    //--------------------------------------------------------------------------
}
