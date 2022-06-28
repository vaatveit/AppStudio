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
    id: glyphSet

    //--------------------------------------------------------------------------

    property alias font: fontMetrics.font
    property alias source: fontLoader.source
    readonly property var names: readNames(source)
    readonly property var info: readInfo(source)


    property string undefinedChar: "?"
    property point defaultOrigin: Qt.point(0.5, 0.5)
    property bool debug: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "family:", fontMetrics.font.family, "glyphs:", Object.keys(names).length, "source:", source);
        if (debug) {
            console.log(logCategory, "metrics:", JSON.stringify(fontMetrics), "font:", JSON.stringify(font));
        }
    }

    //--------------------------------------------------------------------------

    function readNames(source) {
        var names = {};

        var fileInfo = AppFramework.fileInfo(source);
        if (!fileInfo.exists) {
            return names;
        }

        var json = fileInfo.folder.readJsonFile(fileInfo.baseName + ".json");
        if (!json) {
            return names;
        }

        for (let [name, value] of Object.entries(json)) {
            var codePoint = typeof value === "number"
                    ? value
                    : parseInt(value.replace("\\", "0x"));
            names[name] = String.fromCodePoint(codePoint);
        }

        if (debug) {
            console.log(arguments.callee.name, "names:", JSON.stringify(names, undefined, 2));
        }

        return names;
    }

    //--------------------------------------------------------------------------

    function readInfo(source) {
        var info = {};

        var fileInfo = AppFramework.fileInfo(source);
        if (!fileInfo.exists) {
            return info;
        }

        var json = fileInfo.folder.readJsonFile(fileInfo.baseName + ".info");
        if (!json) {
            return info;
        }

        info = json;

        if (debug) {
            console.log(arguments.callee.name, "info:", JSON.stringify(info, undefined, 2));
        }

        return info;
    }

    //--------------------------------------------------------------------------

    function glyphChar(name) {
        return names[name] || undefinedChar;
    }

    //--------------------------------------------------------------------------

    function glyphOrigin(name) {
        var glyphInfo = info[name];

        if (!glyphInfo) {
            return defaultOrigin;
        }

        if (glyphInfo.origin) {
            return glyphInfo.origin;
        }

        var x = defaultOrigin.x;
        var y = defaultOrigin.y;

        if (isFinite(glyphInfo.xorigin)) {
            x = glyphInfo.xorigin;
        }

        if (isFinite(glyphInfo.yorigin)) {
            y = glyphInfo.yorigin;
        }

        glyphInfo.origin = Qt.point(x, y);

        return glyphInfo.origin;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(glyphSet, true)
    }

    //--------------------------------------------------------------------------

    FontLoader {
        id: fontLoader

        onStatusChanged: {
            if (debug) {
                console.log("GlyphSet status:", status, "name:", name, "source:", source);
            }
        }
    }

    //--------------------------------------------------------------------------

    FontMetrics {
        id: fontMetrics

        font {
            family: fontLoader.name
        }
    }

    //--------------------------------------------------------------------------
}
