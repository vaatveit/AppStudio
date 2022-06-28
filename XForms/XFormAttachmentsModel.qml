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
import "../Controls/Singletons"

ListModel {
    id: model

    //--------------------------------------------------------------------------

    property FileFolder folder
    property bool updateEnabled: true
    property int currentIndex: -1
    property int size: 0                    // Sum of all attachment sizes
    
    //--------------------------------------------------------------------------

    onCountChanged: {
        if (count) {
            if (currentIndex < 0) {
                currentIndex = 0;
            } else if (currentIndex >= count) {
                currentIndex = count - 1;
            }
        } else {
            currentIndex = -1;
            size = 0;
        }
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(model, true)
    }

    //--------------------------------------------------------------------------

    function addFile(url) {
        var fileInfo = AppFramework.fileInfo(url);

        if (fileInfoExists(fileInfo)) {
            return false;
        }

        addFileInfo(fileInfo);

        return true;
    }

    //--------------------------------------------------------------------------

    function addFiles(urls) {
        if (urls) {
            urls.forEach(addFile);
        }
    }

    //--------------------------------------------------------------------------

    function addFileInfo(fileInfo) {
        if (!fileInfo.exists) {
            return false;
        }
        
        append(toJson(fileInfo));
        size += fileInfo.size;

        return true;
    }
    
    //--------------------------------------------------------------------------

    function updateFile(currentIndex, url) {
        updateFileInfo(currentIndex, AppFramework.fileInfo(url));
    }

    //--------------------------------------------------------------------------

    function updateFileInfo(currentIndex, fileInfo) {
        set(currentIndex, toJson(fileInfo));
    }

    //--------------------------------------------------------------------------

    function removeFile(index) {
        var fileInfo = get(index);
        if (!fileInfo) {
            console.error(logCategory, arguments.callee.name, "Invalid index:", index);
            return;
        }

        var fileName = fileInfo.fileName;

        console.log(logCategory, arguments.callee.name, "index:", index, "fileName:", fileName);

        size -= fileInfo.fileSize;
        folder.removeFile(fileName);
        remove(index);
    }

    //--------------------------------------------------------------------------

    function fileName(index) {
        if (index >= 0 && index < count) {
            return get(index).fileName;
        }
    }

    //--------------------------------------------------------------------------

    function toJson(fileInfo) {
        return {
            fileUrl: fileInfo.url.toString(),
            fileName: fileInfo.fileName,
            filePath: fileInfo.filePath,
            fileSize: fileInfo.size,
            displayName: XFormJS.fileDisplayName(fileInfo.fileName),
            fileSuffix: fileInfo.suffix,
            fileIcon: Icons.fileIconName(fileInfo.suffix)
        };
    }

    //--------------------------------------------------------------------------

    function fileExists(url) {
        return fileInfoExists(AppFramework.fileInfo(url));
    }

    //--------------------------------------------------------------------------

    function fileInfoExists(fileInfo) {
        for (var i = 0; i < count; i++) {
            if (get(i).displayName === fileInfo.fileName) {
                return true;
            }
        }

        return false;
    }

    //--------------------------------------------------------------------------

    function join() {
        if (!count) {
            return;
        }
        
        var value = "";
        
        for (var i = 0; i < count; i++) {
            var fileInfo = get(i);
            if (value > "") {
                value += Body.kValueSeparator;
            }
            
            value += fileInfo.fileName;
        }
        
        return value;
    }
    
    //--------------------------------------------------------------------------

    function split(value) {
        updateEnabled = false;
        clear();
        
        if (value > "") {
            for (const fileName of value.split(Body.kValueSeparator)) {
                addFileInfo(folder.fileInfo(fileName));
            }
        }
        
        updateEnabled = true;
    }

    //--------------------------------------------------------------------------
}
