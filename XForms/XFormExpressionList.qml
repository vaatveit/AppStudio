/* Copyright 2019 Esri
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

import "../template"

QtObject {
    id: expressionsList

    //--------------------------------------------------------------------------

    property var expressions: []
    property var getValue
    property var getValues
    property var getContext
    property bool debug
    property bool enabled: false
    property var jsObjects: ({})
    property var jsObjectReferences: ({})
    property alias jsFileWatcher: jsFileWatcher
    property alias imagesFolder: exif.imagesFolder

    readonly property XFormExif exif: XFormExif {
        id: exif
    }
    
    readonly property string kFunctionTrue: "true()"
    readonly property string kFunctionFalse: "false()"

    readonly property string kYes: "yes"
    readonly property string kNo: "no"

    //--------------------------------------------------------------------------

    signal added(XFormExpression expression)
    signal valueChanged(var nodeset, var value)

    //--------------------------------------------------------------------------

    property Component expressionComponent: XFormExpression {
        enabled: expressionsList.enabled

        getValue: expressionsList.getValue
        getValues: expressionsList.getValues
        getContext: expressionsList.getContext
        exif: expressionsList.exif
        debug: expressionsList.debug
    }

    //--------------------------------------------------------------------------

    onEnabledChanged: {
        if (debug) {
            console.log("expressionList enabled:", enabled);
        }
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        if (debug) {
            console.log("expressionList valueChanged:", nodeset, "value:", value, "enabled:", enabled);
        }

        if (enabled) {
            updateExpressions(nodeset, value);
        }
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory _logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(expressionsList, true)
    }

    //--------------------------------------------------------------------------

    function updateExpressions(nodeset, value) {
        for (var i = 0; i < expressions.length; i++) {
            var instance = expressions[i];
            instance.valueChanged(nodeset, value);
        }
    }

    //--------------------------------------------------------------------------

    function triggerExpression(binding, purpose) {
        var nodeset = binding["@nodeset"];

        for (var i = 0; i < expressions.length; i++) {
            var instance = expressions[i];
            if (instance.thisNodeset === nodeset && instance.purpose === purpose) {
                if (debug) {
                    console.log("Triggering expresssion instance:", nodeset, "purpose:", purpose, "expression:", instance.expression);
                }
                instance.trigger();
            }
        }
    }

    //--------------------------------------------------------------------------

    function addExpression(expression, thisNodeset, purpose, forceAdd) {
        if (debug) {
            console.log("Add expression for:", purpose, "expression:", JSON.stringify(expression), "nodeset:", thisNodeset);
        }

        if (!thisNodeset) {
            thisNodeset = "";
        }

        var expressionInstance = expressionComponent.createObject(this, {
                                                                      expression: expression,
                                                                      thisNodeset: thisNodeset,
                                                                      purpose: purpose
                                                                  });

        if (!forceAdd) {
            for (var i = 0; i < expressions.length; i++) {
                var instance = expressions[i];
                if (instance.jsExpression === expressionInstance.jsExpression && !expressionInstance.isOnce && expressionInstance.isDeterministic) {

                    if (debug) {
                        console.log("Duplicate expression:", expression);
                    }

                    expressionInstance = undefined;
                    return instance;
                }
            }
        }

        expressions.push(expressionInstance);

        if (debug) {
            console.log("Added expression:", expression, "js:", expressionInstance.jsExpression);
        }

        added(expressionInstance);

        return expressionInstance;
    }

    //--------------------------------------------------------------------------

    function toBoolean(text, defaultValue, allowYesNo) {
        if (!text) {
            return null;
        }

        switch (text) {
        case kFunctionTrue:
            return true;

        case kFunctionFalse:
            return false;
        }

        if (allowYesNo) {
            text = text.toLowerCase();
            switch (text) {
            case kYes:
                return true;

            case kNo:
                return false;
            }
        }

        return defaultValue;
    }

    //--------------------------------------------------------------------------

    function addBoolExpression(expression, thisNodeset, purpose, defaultValue, allowYesNo, forceAdd) {
        if (debug) {
            console.log(arguments.callee.name, "expression:", JSON.stringify(expression), "thisNodeset:", thisNodeset);
        }

        if (!expression) {
            return defaultValue;
        }

        expression = expression.trim();

        if (!expression) {
            return defaultValue;
        }

        var value = toBoolean(expression, undefined, allowYesNo);
        if (typeof value === "boolean") {
            return value;
        }

        return addExpression(
                    expression,
                    thisNodeset,
                    purpose,
                    forceAdd).boolBinding(defaultValue);
    }

    //--------------------------------------------------------------------------

    function addJsObject(jsObject, url, expression) {

        var fileInfo = AppFramework.fileInfo(url);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "url:", url, "path:", fileInfo.path);
        }

        var cacheKey = fileInfo.fileName;

        if (jsObject) {
            jsObjects[cacheKey] = jsObject;
        }

        if (jsFileWatcher.enabled) {
            jsFileWatcher.addPath(fileInfo.filePath);

            var jsExpressions = jsObjectReferences[cacheKey];
            if (Array.isArray(jsExpressions)) {
                if (jsExpressions.indexOf(expression) < 0) {
                    jsExpressions.push(expression);
                }
            } else {
                jsObjectReferences[cacheKey] = [ expression ];
            }
        }
    }

    readonly property FileWatcher jsFileWatcher: FileWatcher {
        id: jsFileWatcher

        enabled: false

        onFileChanged: {
            console.log(logCategory, "jsObjects updated file:", path);

            var fileInfo = AppFramework.fileInfo(path);
            var cacheKey = fileInfo.fileName;

            var jsObject = jsObjects[cacheKey];
            if (jsObject) {
                jsObject.destroy();
                jsObjects[cacheKey] = undefined;
            }

            AppFramework.clearComponentCache();
            gc();

            jsObjectReferences[cacheKey].forEach(expression => Qt.callLater(expression.trigger));
        }
    }

    //--------------------------------------------------------------------------
}
