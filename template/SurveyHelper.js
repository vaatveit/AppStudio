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

.pragma library

.import ArcGIS.AppFramework 1.0 as AF

//------------------------------------------------------------------------------

function findFirstSuffix(folder, baseName, suffixes) {
    for (var i = 0; i < suffixes.length; i++) {
        var fileName = baseName + "." + suffixes[i];
        if (folder.fileExists(fileName)) {
            return fileName;
        }
    }

    return "";
}

//------------------------------------------------------------------------------

function findThumbnail(folder, baseName, defaultThumbnail, itemInfoThumbnail) {

    // If baseName + extensions doesn't exist then look for itemInfoThumbnail

    if (itemInfoThumbnail !== undefined) {

        if (itemInfoThumbnail === null) {
            return defaultThumbnail;
        }

        if (typeof itemInfoThumbnail !== 'string') {
            itemInfoThumbnail = AF.AppFramework.fileInfo(itemInfoThumbnail.toString()).fileName;
        }

        if (itemInfoThumbnail > "") {
            var itemInfoFilename = itemInfoThumbnail;

            if (itemInfoThumbnail.search(/^thumbnail\//) > -1) {
                itemInfoFilename = itemInfoThumbnail.substring(itemInfoThumbnail.indexOf("/") + 1, itemInfoThumbnail.length);
            }

            if (itemInfoFilename.search(/(.png)$|(.jpg)$|(.gif)$|(.jpeg)$/) > -1  && folder.fileExists(itemInfoFilename)) {
                return folder.fileUrl(itemInfoFilename).toString();
            }
        }
    }

    var fileName = findFirstSuffix(folder, baseName, ["png", "jpg", "gif"]);

    if (fileName > "" && folder.fileExists(fileName)) {
        return folder.fileUrl(fileName).toString();
    }

    // Finally just return the default if all else fails.
    return defaultThumbnail ? defaultThumbnail : "";
}

//------------------------------------------------------------------------------

function resolveSurveyPath(filePath, surveysFolder) {
    var surveyPath = AF.AppFramework.resolvedPath(filePath);

    var fileInfo = AF.AppFramework.fileInfo(surveyPath);
    if (fileInfo.exists) {
        return surveyPath;
    }

    var packageFolder = AF.AppFramework.fileFolder(fileInfo.path);

    var relativeName;
    if (packageFolder.folderName === "esriinfo") {
        packageFolder.path = packageFolder.path.replace(/esriinfo$/, "");
        relativeName = packageFolder.folderName + "/esriinfo/" + fileInfo.fileName;
    } else {
        relativeName = packageFolder.folderName + "/" + fileInfo.fileName;
    }

    var packageName = packageFolder.folderName;

    //console.log("resolveSurveyPath:", surveyPath, "packageName:", packageName, "relativeName:", relativeName);

    if (surveysFolder.fileExists(relativeName)) {
        //console.warn("resolved with relativeName:", relativeName);
        return surveysFolder.filePath(relativeName);
    }

    relativeName = packageName + "/" + fileInfo.fileName;

    if (surveysFolder.fileExists(relativeName)) {
        //console.warn("resolved with modified relativeName:", relativeName);
        return surveysFolder.filePath(relativeName);
    }

    var formPath;

    if (packageFolder.exists) {
        formPath = resolveformInfoPath(packageFolder.path);
        if (formPath > "") {
            //console.warn("resolved from forminfo:", packageName, "in:", packageFolder.path);
            return formPath;
        }
    }

    if (surveysFolder.fileExists(packageName)) {
        formPath = resolveformInfoPath(surveysFolder.filePath(packageName));
        if (formPath > "") {
            //console.warn("resolved from forminfo:", packageName, "in:", surveysFolder.path);
            return formPath;
        }
    }

    console.error("Unable to resolve survey path:", surveyPath);

    return null;
}

//--------------------------------------------------------------------------

function resolveformInfoPath(folderPath) {
    function formInfoName(folder) {
        var formInfo = folder.readJsonFile("forminfo.json");
        if (formInfo.name > "") {
            return formInfo.name;
        }

        formInfo = folder.readJsonFile("esriinfo/forminfo.json");
        if (formInfo.name) {
            return "esriinfo/" + formInfo.name;
        }

        return null;
    }

    var folder = AF.AppFramework.fileFolder(folderPath);
    var name = formInfoName(folder);
    if (name > "") {
        name += ".xml";
        if (folder.fileExists(name)) {
            console.log("Found form in:", folder.path, "name:", name);

            return folder.filePath(name);
        }

        console.log("Form not found in:", folder.path, "name:", name);
    } else {
        console.warn("forminfo.json not found in:", folder.path);
    }

    return null;
}

//--------------------------------------------------------------------------

function getPropertyValue(object, name, defaultValue) {
    if (!object) {
        return defaultValue;
    }

    if (typeof name !== "string") {
        return defaultValue;
    }

    var keys = Object.keys(object);

    for (var i = 0; i < keys.length; i++) {
        if (name === keys[i]) {
            return object[keys[i]];
        }
    }

    name = name.toLowerCase();

    for (i = 0; i < keys.length; i++) {
        if (name === keys[i].toLowerCase()) {
            return object[keys[i]];
        }
    }

    return defaultValue;
}

//--------------------------------------------------------------------------

function isEmpty(value) {
    if (value === undefined || value === null) {
        return true;
    }

    if (typeof value === "string") {
        return !(value > "");
    }

    return false;
}

//--------------------------------------------------------------------------

function toBoolean(value) {
    if (typeof value == "boolean") {
        return value;
    }

    if (!value) {
        return false;
    }

    var s = value.toString().toLowerCase();

    switch (s) {
    case "t":
    case "true":
    case "y":
    case "yes":
        return true;
    }

    return false;
}

//--------------------------------------------------------------------------

function removeArrayProperties(o) {
    if (!o || (typeof o !== "object")) {
        return o;
    }

    var keys = Object.keys(o);

    keys.forEach(function (key) {
        if (Array.isArray(o[key])) {
            o[key] = undefined;
        }
    });

    return o;
}

//--------------------------------------------------------------------------

function displaySize(size) {
    if (!size) {
        return "0";
    }

    if (size < 1024) {
        return qsTr("%1 bytes").arg(size);
    }

    size /= 1024;

    if (size < 1024) {
        return qsTr("%1 KB").arg(size.toFixed(1));
    }

    size /= 1024;

    return qsTr("%1 MB").arg(size.toFixed(1));
}

//--------------------------------------------------------------------------

function appInfoText(app, html) {
    var body = "";

    function add(text) {
        if (html) {
            body += "<p>";
        }

        body += text;

        if (html) {
            body += "</p>";
        }

        body += "\r\n";
    }

    add("%1 version: %2".arg(app.info.title).arg(app.info.version));
    add("Operating system: %1 - %2".arg(Qt.platform.os).arg(AF.AppFramework.osVersion));

    var locale = app.localeProperties.locale;
    var systemLocale = app.localeProperties.systemLocale;

    add("Current locale: %1 %2".arg(locale.name).arg(locale.nativeLanguageName));
    if (locale.name !== systemLocale.name) {
        add("System locale: %1 %2".arg(systemLocale.name).arg(systemLocale.nativeLanguageName));
    }

    return body;
}

//--------------------------------------------------------------------------

function dateStamp(date) {
    if (!date) {
        date = new Date();
    }

    return "%1%2%3-%4%5%6"
    .arg(date.getFullYear().toString())
    .arg((date.getMonth() + 1).toString().padStart(2, "0"))
    .arg(date.getDate().toString().padStart(2, "0"))
    .arg(date.getHours().toString().padStart(2, "0"))
    .arg(date.getMinutes().toString().padStart(2, "0"))
    .arg(date.getSeconds().toString().padStart(2, "0"));
}

//--------------------------------------------------------------------------

function parseGuid(text) {
    if (!text || typeof text !== "string") {
        return;
    }

    var tokens = text.match(/(([\da-f]{8})-([\da-f]{4})-([\da-f]{4})-([\da-f]{4})-([\da-f]{12}))|([\da-f]{32})/i);

    if (!Array.isArray(tokens)) {
        return;
    }

    return tokens.slice(2).filter(token => token > "").join("").toLowerCase();
}

//--------------------------------------------------------------------------

function formatGuid(guid) {
    var value = parseGuid(guid);
    if (!value) {
        return "<Invalid:%1>".arg(guid);
    }

    return value.replace(/(.{8})(.{4})(.{4})(.{4})(.{12})/, "$1-$2-$3-$4-$5");
}

//--------------------------------------------------------------------------

function createAppLink(scheme, portal, itemInfo) {
    if (!scheme) {
        scheme = "arcgis-survey123";
    }

    return "%1://?portalUrl=%2&itemID=%3"
    .arg(scheme)
    .arg(portal.portalUrl)
    .arg(itemInfo.id);
}

//--------------------------------------------------------------------------
