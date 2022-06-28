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
    id: fileWatcher

    //--------------------------------------------------------------------------

    property alias interval: timer.interval
    property bool debug: true

    //--------------------------------------------------------------------------

    signal fileChanged(string path);

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(fileWatcher, true)
    }

    //--------------------------------------------------------------------------

    function addPath(path) {
        for (var i = 0; i < pathsModel.count; i++) {
            if (pathsModel.get(i).path === path) {
                return;
            }
        }

        var fileInfo = fileInfoComponent.createObject(fileWatcher,
                                                      {
                                                          filePath: path
                                                      });

        var item = {
            path: path,
            lastModified: fileInfo.lastModified,
            fileInfo: fileInfo
        };

        console.log(logCategory, arguments.callee.name, "path:", path, "lastModified:", fileInfo.lastModified);

        pathsModel.append(item);
    }

    //--------------------------------------------------------------------------

    function clear() {
        pathsModel.clear();
    }

    //--------------------------------------------------------------------------

    function check() {
        for (var i = 0; i < pathsModel.count; i++) {
            var item = pathsModel.get(i);
            var fileInfo = item.fileInfo;

            fileInfo.refresh();
            if (fileInfo.lastModified > item.lastModified) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "path:", item.path, fileInfo.lastModified, ">", item.lastModified);
                }

                pathsModel.setProperty(i, "lastModified", fileInfo.lastModified);
                fileChanged(item.path);
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: timer

        repeat: true
        triggeredOnStart: true
        running: fileWatcher.enabled && pathsModel.count > 0
        interval: 1000

        onTriggered: {
            check();
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: pathsModel
    }

    //--------------------------------------------------------------------------

    Component {
        id: fileInfoComponent

        FileInfo {
        }
    }

    //--------------------------------------------------------------------------
}
