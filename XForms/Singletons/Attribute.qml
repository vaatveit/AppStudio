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

pragma Singleton

import QtQml 2.12

import "../XForm.js" as XFormJS

QtObject {
    //--------------------------------------------------------------------------

    readonly property string kAppearance: "appearance"
    readonly property string kClass: "class"
    readonly property string kDefault: "default"
    readonly property string kEsriFieldType: "esri:fieldType"
    readonly property string kEsriStyle: "esri:style"
    readonly property string kEsriVisible: "esri:visible"
    readonly property string kForm: "form"
    readonly property string kId: "id"
    readonly property string kLang: "lang"
    readonly property string kMediaType: "mediatype"
    readonly property string kNodeset: "nodeset"
    readonly property string kQuery: "query"
    readonly property string kReadOnly: "readonly"
    readonly property string kRef: "ref"
    readonly property string kSrc: "src"
    readonly property string kSaveIncomplete: "saveIncomplete"

    //--------------------------------------------------------------------------

    function hasValue(element, name) {
        if (!element || typeof element !== "object") {
            return false;
        }

        return element.hasOwnProperty("@" + name);
    }

    //--------------------------------------------------------------------------

    function value(element, name, defaultValue) {
        if (!element || typeof element !== "object") {
            return defaultValue;
        }

        var _value = element["@" + name];
        if (_value === undefined) {
            return defaultValue;
        }

        return _value;
    }

    //--------------------------------------------------------------------------

    function boolValue(element, name, defaultValue) {
        return XFormJS.toBoolean(value(element, name), defaultValue);
    }

    //--------------------------------------------------------------------------

    function contains(element, name, searchValue) {
        return XFormJS.contains(value(element, name), searchValue);
    }

    //--------------------------------------------------------------------------
}

