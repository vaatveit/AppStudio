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

Item {
    id: propertiesManager

    //--------------------------------------------------------------------------

    property url basePropertiesUrl: "AppProperties.json"
    readonly property var baseProperties: readProperties(basePropertiesUrl)

    property var appProperties: ({})
    property var orgProperties: ({})
    property var activeProperties: ({})
    property bool initialized: false

    property alias logCategory: logCategory
    property bool debug: false

    //--------------------------------------------------------------------------

    signal initialize(var properties)
    signal updated()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        initialize(appProperties);
        update();
        initialized = true;
    }

    //--------------------------------------------------------------------------

    onOrgPropertiesChanged: {
        if (initialized) {
            Qt.callLater(update);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(propertiesManager, true);
    }

    //--------------------------------------------------------------------------

    function readProperties(url) {
        var fileInfo = AppFramework.fileInfo(url);
        return fileInfo.folder.readJsonFile(fileInfo.fileName);
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log(logCategory, arguments.callee.name);

        console.log(logCategory, "baseProperties:", JSON.stringify(baseProperties, undefined, 2));
        console.log(logCategory, "appProperties:", JSON.stringify(appProperties, undefined, 2));
        console.log(logCategory, "orgProperties:", JSON.stringify(orgProperties, undefined, 2));

        var properties = clone(baseProperties);

        merge(properties, appProperties);
        merge(properties, orgProperties);

        activeProperties = properties;

        console.log(logCategory, "activeProperties:", JSON.stringify(activeProperties, undefined, 2));

        updated();
    }

    //--------------------------------------------------------------------------

    function merge(target, source) {
        if (!source) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "source:", JSON.stringify(source, undefined, 2));
        }

        for (let [key, value] of Object.entries(source)) {

            if (debug) {
                console.log(logCategory, arguments.callee.name, "key:", key, "value:", value);
            }

            if (value !== null && value !== undefined) {
                if (typeof value === "object") {
                    var targetValue = target[key];
                    if (targetValue === undefined || targetValue === null || typeof targetValue !== "object") {
                        target[key] = {};
                    }

                    merge(target[key], value);
                } else {
                    target[key] = value;
                }
            }
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "target:", JSON.stringify(target, undefined, 2));
        }

        return target;
    }

    //--------------------------------------------------------------------------

    function clone(properties) {
        return JSON.parse(JSON.stringify(properties));
    }

    //--------------------------------------------------------------------------

    function value(propertyPath, defaultValue) {
        return propertyValue(activeProperties, propertyPath, defaultValue);
    }

    //--------------------------------------------------------------------------

    function propertyValue(propertySet, propertyPath, defaultValue) {
        if (!propertySet) {
            return defaultValue;
        }

        var keys = propertyPath.split(/\[\]\.|\[\]|\]\.|\.|\[|\]/);

        if (keys.length < 1) {
            console.error(logCategory, arguments.callee.name, "Invalid propertyPath:", propertyPath);
            return defaultValue;
        }

        for (var i = 0; i < keys.length - 1; i++) {
            propertySet = propertySet[keys[i]];
            if (!propertySet || typeof propertySet !== "object") {
                return defaultValue;
            }
        }

        var key = keys.pop();
        var value = propertySet[key];
        if (value === undefined) {
            return defaultValue;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "property:", key, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function setPropertyValue(propertySet, propertyPath, value) {
        if (!propertySet) {
            return;
        }

        var keys = propertyPath.split(/\[\]\.|\[\]|\]\.|\.|\[|\]/);

        if (keys.length < 1) {
            console.error(logCategory, arguments.callee.name, "Invalid propertyPath:", propertyPath);
            return;
        }


        for (var i = 0; i < keys.length - 1; i++) {
            var parentSet = propertySet;
            var setKey = keys[i];
            propertySet = propertySet[setKey];
            if (!propertySet || typeof propertySet !== "object") {
                propertySet = {};
                parentSet[setKey] = propertySet;
            }
        }

        var key = keys.pop();

        propertySet[key] = value;
    }

    //--------------------------------------------------------------------------
}
