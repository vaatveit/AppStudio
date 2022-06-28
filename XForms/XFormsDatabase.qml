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

import "../template/SurveyHelper.js" as Helper
import "XForm.js" as XFormJS
import "Singletons"

QtObject {
    id: surveysDatabase

    //--------------------------------------------------------------------------

    property bool keyEnabled
    property string key
    property string keyType: "hex"

    //--------------------------------------------------------------------------

    property string dbIdentifer: "SurveysData"
    property string dbVersion: "1.0"
    property string dbDescription: "Surveys Database"

    readonly property FileFolder folder: AppFramework.fileFolder(AppFramework.offlineStoragePath).folder("Databases")
    readonly property string fileName: Qt.md5(dbIdentifer) + ".sqlite"
    readonly property string databasePath: folder.filePath(fileName)

    property int changed: 0

    property bool validSchema
    property bool hasDateValues

    property alias isOpen: database.isOpen
    property bool isDatabase

    //--------------------------------------------------------------------------

    signal rowAdded(var rowData)
    signal rowUpdated(var rowData)
    signal rowDeleted(int rowid);

    signal error(string message)

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: loggingCategory

        name: AppFramework.typeOf(surveysDatabase, true)
    }

    //--------------------------------------------------------------------------

    property XFormSqlDatabase database: XFormSqlDatabase {
        id: database

        onExecuteError: {
            console.error(logCategory, "executeError sqlError:", sqlError.toString());

            surveysDatabase.error(sqlError.toString());
        }
    }

    //--------------------------------------------------------------------------

    onChangedChanged: {
        console.log("changedChanged")
    }

    //--------------------------------------------------------------------------

    onError: {
        console.error(logCategory, "error message:", message);
    }

    //--------------------------------------------------------------------------

    function open() {
        console.log(logCategory, arguments.callee.name, "databasePath:", databasePath);

        isDatabase = false;

        if (!isOpen) {
            database.databaseName = databasePath;
            if (!database.open()) {
                console.error(logCategory, arguments.callee.name, "Error opening:", databasePath);
                return;
            }
        }

        if (keyEnabled && key > "") {
            console.log(logCategory, arguments.callee.name, "PRAGMA %1key".arg(keyType));

            var query = database.executeSql("PRAGMA %1key='%2'".arg(keyType).arg(key));
            if (!query) {
                error(query.error.toString());
                close();
            }
        }

        // Test if a database

        query = database.executeSql("SELECT count(*) from sqlite_master");
        isDatabase = !!query && !query.error;

        console.log(logCategory, arguments.callee.name, "isDatabase:", isDatabase);
    }

    //--------------------------------------------------------------------------

    function close() {
        console.log(logCategory, arguments.callee.name, "databasePath:", databasePath);

        database.close();
        isDatabase = false;
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, arguments.callee.name, "path:", databasePath);

        var fileInfo = AppFramework.fileInfo(databasePath);
        if (!fileInfo.folder.exists) {
            if (!fileInfo.folder.makeFolder()) {
                console.log(logCategory, "Error creating folder:", fileInfo.folder.path);
            }
        }

        open();

        database.executeSql("CREATE TABLE IF NOT EXISTS Surveys(name TEXT, path TEXT, created DATE, updated DATE, status INTEGER, statusText TEXT, data TEXT, feature TEXT, snippet TEXT, favorite INTEGER DEFAULT 0)");

        if (Qt.platform.os === "ios") {
            console.log("Checking survey paths");
            fixSurveysPath();
        }
    }

    //--------------------------------------------------------------------------

    function reinitialize() {
        console.log(logCategory, arguments.callee.name, "databasePath:", databasePath);

        database.close();

        console.log(logCategory, arguments.callee.name, "delete fileName:", fileName);
        if (!folder.removeFile(fileName)) {
            console.error(logCategory, arguments.callee.name, "Unable to remove file:", folder.filePath(fileName));
            return false;
        }

        open();

        initialize();
        changed++;

        return true;
    }

    //--------------------------------------------------------------------------

    function validateSchema() {
        console.log(logCategory, arguments.callee.name);

        if (!isOpen) {
            console.error(logCategory, "Database not open");
            return;
        }

        var columns = [];

        var query = database.executeSql("PRAGMA table_info(Surveys)");

        if (query) {
            while (query.next()) {
                var row = query.values;
                //console.log("row", JSON.stringify(row, undefined, 2));
                columns.push(row.name);
            }
        }

        validSchema = true;

        var requiredColumns = [
                    "name",
                    "path",
                    "created",
                    "updated",
                    "status",
                    "statusText",
                    "data",
                    "feature",
                    "snippet"
                ];

        requiredColumns.forEach(function (name) {
            if (columns.indexOf(name) < 0) {
                console.error(logCategory, "Column not found:", name);
                validSchema = false;
            }
        });

        //console.log("validSchema", validSchema, JSON.stringify(columns), JSON.stringify(requiredColumns));

        return validSchema;
    }

    //--------------------------------------------------------------------------

    function addRow(jobs) {
        for (var i = 0; i < jobs.length; i++) {
            var rowData = jobs[i];

            if (!rowData.statusText) {
                rowData.statusText = "";
            }

            if (!rowData.created) {
                rowData.created = new Date();
            }

            if (!rowData.updated) {
                rowData.updated = rowData.created;
            }

            //console.log("addRow:", JSON.stringify(rowData, undefined, 2));

            var result = database.executeSql(
                        "INSERT INTO Surveys (name, path, created, updated, status, statusText, data, feature, snippet) VALUES (?,?,?,?,?,?,?,?,?)",
                        rowData.name,
                        rowData.path,
                        XFormJS.isValidDate(rowData.created) ? rowData.created.toISOString() : null,
                        XFormJS.isValidDate(rowData.updated) ? rowData.updated.toISOString() : null,
                        rowData.status,
                        rowData.statusText,
                        JSON.stringify(rowData.data, undefined, 2),
                        _stringify(rowData.feature),
                        rowData.snippet);

            //console.log("addRow result:", JSON.stringify(result, undefined, 2));

            rowData.rowid = result.insertId;

            if (rowData.favorite) {
                updateFavorite(rowData);
            }

            rowAdded(rowData);
        }
    }

    //--------------------------------------------------------------------------

    function finalizeAddRows() {
        changed++;
    }

    //--------------------------------------------------------------------------

    function queryRow(rowid) {
        var rowData;

        var result = database.executeSql("SELECT rowid, * FROM Surveys WHERE rowid = ?", rowid);

        if (result && result.first()) {
            var row = result.values;

            rowData = {
                rowid: row.rowid,
                data: JSON.parse(row.data),
                feature: JSON.parse(row.feature),
                snippet: row.snippet,
                updated: new Date(row.updated),
                status: row.status,
                statusText: row.statusText,
            };
        }

        //console.log("queryRow result:", JSON.stringify(rowData, undefined, 2));

        return rowData;
    }

    //--------------------------------------------------------------------------

    function updateRow(rowData, setUpdatedTimeStamp) {

        if (setUpdatedTimeStamp === undefined) {
            setUpdatedTimeStamp = true;
        }

        if (!rowData.statusText) {
            rowData.statusText = "";
        }

        if (setUpdatedTimeStamp) {
            rowData.updated = new Date();
        }

        var results = database.executeSql(
                    "UPDATE Surveys SET status = ?, statusText = ?, data = ?, feature = ?, snippet = ? WHERE rowid = ?",
                    rowData.status,
                    rowData.statusText,
                    JSON.stringify(rowData.data, undefined, 2),
                    _stringify(rowData.feature),
                    rowData.snippet,
                    rowData.rowid);

        if (setUpdatedTimeStamp) {
            var timeStampUpdateResults = database.executeSql(
                        "UPDATE Surveys SET updated = ? WHERE rowid = ?",
                        rowData.updated.toISOString(),
                        rowData.rowid);
        }

        if (rowData.favorite) {
            updateFavorite(rowData);
        }

        rowUpdated(rowData);

        changed++;
    }

    //--------------------------------------------------------------------------

    function updateStatus(rowid, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        if (database.executeSql(
                    "UPDATE Surveys SET status = ?, statusText = ? WHERE rowid = ?",
                    status,
                    statusText,
                    rowid)) {

            rowUpdated({
                               "rowid": rowid,
                               "status": status,
                               "statusText": statusText
                           });

            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function updateDataStatus(rowid, data, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        if (database.executeSql(
                    "UPDATE Surveys SET data = ?, status = ?, statusText = ? WHERE rowid = ?",
                    JSON.stringify(data, undefined, 2),
                    status,
                    statusText,
                    rowid)) {
            rowUpdated({
                               "rowid": rowid,
                               "data": data,
                               "status": status,
                               "statusText": statusText
                           });

            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function updateFavorite(rowData) {
        database.executeSql("UPDATE Surveys SET favorite = 0 WHERE path = ?", rowData.path);
        database.executeSql("UPDATE Surveys SET favorite = 1 WHERE rowid = ?", rowData.rowid);

        //console.log("updateFavorite", JSON.stringify(results, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function getFavorite(path) {

        var row = {};

        var query = database.executeSql(
                    'SELECT rowid, * FROM Surveys WHERE path = ? AND favorite > 0',
                    path);

        if (query && query.first()) {
            row = query.values;

            if (row.data > "") {
                row.data = JSON.parse(row.data);
            } else {
                row.data = null;
            }

            if (row.feature > "") {
                row.feature = JSON.parse(row.feature);
            } else {
                row.feature = null;
            }
        }

        //console.log("getFavorite", path, "row:", JSON.stringify(row, undefined, 2));

        return row;
    }

    //--------------------------------------------------------------------------

    function deleteSurvey(rowid) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE rowid = ?",
                    rowid)) {

            rowDeleted(rowid);

            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveys(status) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE status = ? AND favorite = 0",
                    status)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveyBox(formname, status) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE name = ? AND status = ? AND favorite = 0",
                    formname,
                    status)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveyData(path) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE path = ?",
                    path)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function surveyCount(path) {
        var count = 0;

        var query = database.executeSql(
                    "SELECT COUNT(*) AS count FROM Surveys WHERE path = ?",
                    path);

        if (query && query.first()) {
            count = query.values.count;
        }

        return count;
    }

    //--------------------------------------------------------------------------

    function statusCount(path, status) {
        var count = 0;
        var query;

        if (path > "") {
            query = database.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE path = ? AND status = ?",
                                        path,
                                        status);
        } else {
            query = database.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE status = ?", status);
        }

        if (query && query.first()) {
            count = query.values.count;
        }

        return count;
    }

    //--------------------------------------------------------------------------

    function fixSurveysPath() {
        var jobs = [];

        var query = database.executeSql("SELECT rowid, * FROM Surveys");

        while (query.next()) {
            var row = query.values;

            var resolvedPath = Helper.resolveSurveyPath(row.path, surveysFolder);

            if ((resolvedPath !== null) && (row.path !== resolvedPath)) {
                var rowData = {
                    "path": resolvedPath,
                    "rowid": row.rowid
                };

                jobs.push(rowData);
            }
        }

        for (var i = 0; i < jobs.length; i++) {
            database.executeSql(
                        "UPDATE Surveys SET path = ? WHERE rowid = ?",
                        jobs[i].path,
                        jobs[i].rowid);
        }
    }

    //--------------------------------------------------------------------------

    function _stringify(value) {
        if (value === null) {
            return null;
        }

        return JSON.stringify(value, undefined, 2);
    }

    //--------------------------------------------------------------------------
    // +ve statusFilter for EQUAL
    // -ve statusFilter for NOT EQUAL

    function queryData(path, statusFilter) {
        var select = "SELECT data FROM Surveys WHERE path = ? AND status %1 ?".arg(statusFilter < 0 ? "<>" : "=")

        var query = database.executeSql(select, path, Math.abs(statusFilter));

        return query;
    }

    //--------------------------------------------------------------------------
}
