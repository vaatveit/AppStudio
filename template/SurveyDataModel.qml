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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "SurveyHelper.js" as Helper

import "../XForms"
import "../XForms/Singletons"
import "../XForms/XForm.js" as XFormJS
import "../XForms/XFormGeometry.js" as Geometry

ListModel {
    id: model

    //--------------------------------------------------------------------------

    property XFormsDatabase surveysDatabase: app.surveysDatabase
    property XFormSqlDatabase database: surveysDatabase.database

    property int statusFilter: -1
    property int statusFilter2: statusFilter

    property int refreshCount
    property bool hasDateValues

    property bool debug: false

    property var extraProperties

    //--------------------------------------------------------------------------

    readonly property string kPropertyUpdated: "updated"
    readonly property string kPropertySnippet: "snippet"

    readonly property string kPropertyDistance: "distance"

    //--------------------------------------------------------------------------

    property XFormSchema schema

    readonly property string geometryFieldName: !!schema
                                                ? schema.schema.geometryFieldName || ""
                                                : ""

    readonly property string geometryType: schema ? schema.schema.geometryField.type : ""

    readonly property bool hasGeometry: geometryType > "" && geometryFieldName > ""

    readonly property bool isPointGeometry: geometryType === Bind.kTypeGeopoint
    readonly property bool isPolylineGeometry: geometryType === Bind.kTypeGeotrace
    readonly property bool isPolygonGeometry: geometryType === Bind.kTypeGeoshape
    readonly property bool isPolyGeometry: isPolylineGeometry || isPolygonGeometry

    readonly property var kNullGeometryInfo :({
                                                  coordinate: QtPositioning.coordinate(),
                                                  shape: QtPositioning.shape()
                                              })

    property real centroidThreshold: 10
    property real circleRadius: 0
    property real pathWidth: 0

    //--------------------------------------------------------------------------

    property var geometries: []

    //--------------------------------------------------------------------------

    signal error(string message)
    signal refreshed()

    signal cleared()
    signal added(int index, int rowid)
    signal updated(int index, int rowid)
    signal removed(int index, int rowid)

    //--------------------------------------------------------------------------

    objectName: AppFramework.typeOf(model, true)
    dynamicRoles: true

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: loggingCategory

        name: AppFramework.typeOf(model, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        surveysDatabase.rowAdded.connect(addItem);
        surveysDatabase.rowUpdated.connect(updateItem);
        surveysDatabase.rowDeleted.connect(deleteItem);

        surveysDatabase.error.connect(error);
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        surveysDatabase.rowAdded.disconnect(addItem);
        surveysDatabase.rowUpdated.disconnect(updateItem);
        surveysDatabase.rowDeleted.disconnect(deleteItem);

        surveysDatabase.error.disconnect(error);
    }

    //--------------------------------------------------------------------------

    onError: {
        console.error(logCategory, "error message:", message);
    }

    //--------------------------------------------------------------------------

    onRefreshed: {
        console.log(logCategory, "onRefreshed count:", count);
    }

    //--------------------------------------------------------------------------

    onRemoved: {
        if (index < geometries.length) {
            return;
        }

        geometries.splice(index, 1);
    }

    //--------------------------------------------------------------------------

    onUpdated: {
        if (index < geometries.length) {
            return;
        }

        geometries[index] = undefined;
    }

    //--------------------------------------------------------------------------

    function refresh(path) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", path);
            console.log(logCategory, arguments.callee.name, "extraProperties:", JSON.stringify(extraProperties, undefined, 2));
            console.log(logCategory, arguments.callee.name, "geometryType:", geometryType);
            console.log(logCategory, arguments.callee.name, "geometryFieldName:", geometryFieldName);
        }

        console.time("dataModel");

        clear();
        geometries = [];
        cleared();
        hasDateValues = false;

        var select = "SELECT rowid, * FROM Surveys ";
        var orderClause = "";//" ORDER BY updated desc";
        var query;

        if (statusFilter >= 0) {
            if (path > "") {
                query = database.executeSql(select + 'WHERE path = ? AND (status = ? OR status = ?)' + orderClause, path, statusFilter, statusFilter2);
            } else {
                query = database.executeSql(select + 'WHERE status = ?' + orderClause, statusFilter);
            }
        } else {
            if (path > "") {
                query = database.executeSql(select + 'WHERE path = ?' + orderClause, path);
            } else {
                query = database.executeSql(select + orderClause);
            }
        }

        if (!query) {
            console.error(logCategory, arguments.callee.name);
            return;
        }

        while (query.next()) {
            appendItem(query.values);
        }

        geometries.length = count;

        console.timeEnd("dataModel");

        refreshCount++;
        refreshed();
    }

    //--------------------------------------------------------------------------

    function appendItem(rowData) {
        //console.log(logCategory, arguments.callee.name, "rowid:", rowData.rowid);

        function parseObject(value) {
            if (!value) {
                return null;
            }

            if (typeof value === "object") {
                return value;
            }

            if (typeof value === "string") {
                return JSON.parse(rowData.data);
            }

            return null;
        }

        function parseDate(value) {
            if (!value) {
                return "";
            }

            var dateString = XFormJS.isValidDate(value)
                    ? value.toISOString()
                    : typeof value === "string"
                      ? value
                      : "";

            if (!dateString.endsWith("Z")) {
                dateString += "Z";
            }

            return dateString;
        }

        rowData.data = parseObject(rowData.data);
        rowData.feature = parseObject(rowData.feature);
        rowData.created = parseDate(rowData.created);
        rowData.updated = parseDate(rowData.updated);

        if (extraProperties) {
            for (let [key, value] of Object.entries(extraProperties)) {
                rowData[key] = value;
            }
        }

        if (rowData.updated > "") {
            hasDateValues = true;
        }

        var index = count;
        //console.log(logCategory, arguments.callee.name, "index:", index, "rowData:", JSON.stringify(rowData, undefined, 2));

        append(rowData);

        return index;
    }

    //--------------------------------------------------------------------------

    function addItem(rowData) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "rowid:", rowData.rowid, "status:", rowData.status);
        }

        if (statusCheck(rowData.status)) {
            var index = appendItem(rowData);
            added(index, rowData.rowid);

            if (debug) {
                console.log(logCategory, arguments.callee.name, "index:", index);
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateItem(rowData) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "rowid:", rowData.rowid);
        }

        var modelRow;
        var i;

        if (rowData.favorite) {
            for (i = 0; i < count; i++) {
                modelRow = get(i);
                if (modelRow.path === rowData.path) {

                    modelRow.favorite = modelRow.rowid === rowData.rowid ? 1 : 0;

                    set(i, modelRow);
                }
            }
        }

        for (i = 0; i < count; i++) {
            modelRow = get(i);
            if (modelRow.rowid === rowData.rowid) {
                modelRow.status = rowData.status;

                if (rowData.statusText) {
                    modelRow.statusText = rowData.statusText;
                }

                if (rowData.data) {
                    modelRow.data = rowData.data;
                }

                if (rowData.feature) {
                    modelRow.feature = rowData.feature;
                }

                if (statusCheck(rowData.status)) {
                    set(i, modelRow);
                    updated(i, modelRow.rowid);
                } else {
                    remove(i);
                    removed(i, rowData.rowid);
                }
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function deleteItem(rowid) {
        console.log(logCategory, arguments.callee.name, "rowid:", rowid);

        for (var i = 0; i < count; i++) {
            if (get(i).rowid === rowid) {
                remove(i);
                removed(rowid);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function statusCheck(status) {
        return statusFilter < 0
                || status === statusFilter
                || status === statusFilter2;
    }

    //--------------------------------------------------------------------------

    function getSurvey(index, includeGeometry) {
        var item = get(index);

        if (!includeGeometry) {
            return item;
        }

        var rowData = JSON.parse(JSON.stringify(item));

        rowData.geometry = getGeometry(index);

        return rowData;
    }

    //--------------------------------------------------------------------------

    function _stringify(value) {
        if (value === null) {
            return null;
        }

        return JSON.stringify(value, undefined, 2);
    }

    //--------------------------------------------------------------------------

    function getCoordinate(index) {
        return getGeometry(index).coordinate;
    }

    //--------------------------------------------------------------------------

    function getShape(index) {
        return getGeometry(index).shape;
    }

    //--------------------------------------------------------------------------

    function getExtent(index) {
        return getGeometry(index).shape.boundingGeoRectangle();
    }

    //--------------------------------------------------------------------------

    function getGeometry(index) {
        if (index < 0 || index >= count) {
            return kNullGeometryInfo;
        }

        var geometry = geometries[index];
        if (geometry) {
            //logGeometry("cached", index, geometry);

            return geometry;
        }

        geometry = dataGeometry(get(index).data);
        geometries[index] = geometry;

        //logGeometry("created", index, geometry);

        return geometry;
    }

    //--------------------------------------------------------------------------

    function logGeometry(text, index, geometry) {
        console.log(logCategory, text, "index:", index, "type:", typeof geometry);
        console.log(logCategory, " - coordinate:", geometry.coordinate);
        console.log(logCategory, " - extent:", geometry.shape.boundingGeoRectangle());
        console.log(logCategory, " - shape:", geometry.shape);
    }

    //--------------------------------------------------------------------------
    // coordinate:  geopoint => coordinate, geotrace => midpoint, geoshape => centroid
    // shape:       geopoint => geocircle, geotrace => geopath, geoshape => geopolygon

    function dataGeometry(data) {
        if (!data) {
            return kNullGeometryInfo;
        }

        var instance = data[schema.instanceName];
        if (!instance) {
            return kNullGeometryInfo;
        }

        var geometry = instance[geometryFieldName];

        if (!geometry) {
            return kNullGeometryInfo;
        }

        var coordinate;
        var path;

        if (geometry.x && geometry.y) {
            coordinate = QtPositioning.coordinate(geometry.y, geometry.x);

            return {
                coordinate: coordinate,
                shape: QtPositioning.circle(coordinate, circleRadius)
            };

        } else if (isPolygonGeometry && Array.isArray(geometry.rings)) {
            path = Geometry.pointsToPath(geometry.rings[0]);
            coordinate = Geometry.pathCentroid(path, centroidThreshold);

            return {
                coordinate: coordinate,
                shape: QtPositioning.polygon(path)
            };
        } else if (isPolylineGeometry && Array.isArray(geometry.paths)) {
            path = Geometry.pointsToPath(geometry.paths[0]);
            coordinate = Geometry.pathMidPoint(path);

            return {
                coordinate: coordinate,
                shape: QtPositioning.path(path, pathWidth)
            };
        } else {
            return kNullGeometryInfo;
        }
    }

    //--------------------------------------------------------------------------

    function geometryContains(geometry, coordinate, tolerance) {
        //console.log(logCategory, arguments.callee.name, "coordinate:", coordinate);

        if (!geometry || !geometry.shape || !geometry.shape.isValid || !geometry.shape) {
            return;
        }

        switch (geometry.shape.type) {
        case GeoShape.CircleType:
            geometry.shape.radius = tolerance;
            break;

        case GeoShape.PathType:
            geometry.shape.width = tolerance;
            break;
        }

        return geometry.shape.contains(coordinate);
    }

    //--------------------------------------------------------------------------
}
