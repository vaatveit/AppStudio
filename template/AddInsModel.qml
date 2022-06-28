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
import "../Models"
import "../Portal"
import "../XForms/XForm.js" as XFormJS

ListModel {
    id: addInsModel

    //--------------------------------------------------------------------------

    property AddInsFolder addInsFolder
    property string type: ""
    property string mode: ""
    property bool includeDisabled: false
    property bool includeInternal: true
    property var infos: []

    //--------------------------------------------------------------------------

    readonly property string kTypeTool: "tool"
    readonly property string kTypeCamera: "camera"
    readonly property string kTypeControl: "control"

    readonly property string kToolModeTile: "tile"
    readonly property string kToolModeTab: "tab"
    readonly property string kToolModeService: "service"
    readonly property string kToolModeHidden: "hidden"

    //--------------------------------------------------------------------------

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    property Component addInComponent: AddIn {}

    //--------------------------------------------------------------------------

    signal updated();

    //--------------------------------------------------------------------------

    dynamicRoles: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        name: AppFramework.typeOf(addInsModel, true)
    }

    //--------------------------------------------------------------------------

    readonly property Connections _connections: Connections {
        target: addInsFolder

        function onAddInsChanged() {
            Qt.callLater(addInsModel.update);
        }
    }

    //--------------------------------------------------------------------------

    readonly property AddInsFolder internalAddInsFolder: AddInsFolder {
        enabled: true
        path: app.folder.filePath("Add-Ins");

        onPathChanged: {
            update();
        }
    }

    //--------------------------------------------------------------------------

    function findByKeyValue(key, value) {
        for (var i = 0; i < count; i++) {
            if (get(i)[key] === value) {
                return i;
            }
        }

        return -1;
    }

    //--------------------------------------------------------------------------

    function update(updateFolder) {
        if (updateFolder) {
            addInsFolder.update();
        }

        updateLocal();
        updated();
    }

    //--------------------------------------------------------------------------

    function addInfo(info) {
        var index = infos.length;

        infos.push(info || {});

        return index;
    }

    //--------------------------------------------------------------------------

    function updateLocal() {
        console.log(logCategory, "Updating add-ins model");

        clear();
        infos = [];

        if (includeInternal) {
            appendFolder(internalAddInsFolder, true);
        }

        appendFolder(addInsFolder, false);

        console.log(logCategory, "Updated add-ins model count:", count, "type:", type, "mode:", mode);
    }

    //--------------------------------------------------------------------------

    function appendFolder(addInsFolder, internal) {
        if (!addInsFolder.enabled) {
            return;
        }

        console.log(logCategory, "Add-Ins path:", addInsFolder.path, "count:", addInsFolder.addIns.length);

        addInsFolder.addIns.forEach(function (addInInfo) {
            if (type > "" && addInInfo.type !== type) {
                return;
            }

            var addIn = addInComponent.createObject(null,
                                                    {
                                                        path: addInInfo.path
                                                    });

            var config = addIn.config;

            //console.log(logCategory, "enabled:", addIn.config.enabled, "includeDisabled:", includeDisabled);

            if (!config.enabled && !includeDisabled) {
                return;
            }

            if (mode > "" && addIn.config.mode !== mode) {
                return;
            }

            var addInFolder = addIn.folder;
            var itemInfo = addIn.itemInfo;
            var thumbnail = Helper.findThumbnail(addInFolder, "thumbnail", "images/addIn-thumbnail.png");
            var icon = addInFolder.fileUrl("icon.png");

            var infoIndex = addInfo(addInInfo);

            var addInItem = {
                itemId: itemInfo.id || "",
                itemUrl: addIn.itemUrl,
                path: addInInfo.path,
                folderName: addInInfo.folderName,
                title: addIn.title,
                description:  itemInfo.description || "",
                thumbnail: thumbnail,
                icon: icon,
                modified: itemInfo.modified,
                owner: itemInfo.owner || "",
                updateAvailable: false,
                enabled: config.enabled,
                internal: internal,
                infoIndex: infoIndex
            }

            append(addInItem);

            //console.log("addInItem:", JSON.stringify(addInItem, undefined, 2));
        });
    }

    //--------------------------------------------------------------------------

    function appendItem(itemInfo) {
        var itemId = itemInfo.id;

        for (var i = 0; i < count; i++) {
            var item = get(i);
            if (item.itemId === itemId) {
                var updated = itemInfo.modified > item.modified;
                setProperty(i, "updateAvailable", updated);
                return;
            }
        }

        var infoIndex = addInfo();

        var addInItem = {
            itemId: itemId,
            itemUrl: app.portal.portalUrl + "/home/item.html?id=%1".arg(itemId),
            path: "",
            title: itemInfo.title,
            description: itemInfo.description,
            thumbnail: itemInfo.thumbnail,
            modified: itemInfo.modified,
            owner: itemInfo.owner,
            updateAvailable: true,
            enabled: true,
            internal: false,
            infoIndex: infoIndex
        };

        append(addInItem);
    }

    //--------------------------------------------------------------------------

    function updateItem(index, addIn) {
        console.log(logCategory, arguments.callee.name, "index:", index);

        var config = addIn.config;

        setProperty(index, "enabled", config.enabled);
    }

    //--------------------------------------------------------------------------

    function run(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function edit(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function upload(addInInfo) {

    }

    //--------------------------------------------------------------------------
}
