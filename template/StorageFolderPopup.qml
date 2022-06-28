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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

PageLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property url folder

    property var volumes: []
    property var folders: []

    property real iconSize: 30 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    signal accepted()

    //--------------------------------------------------------------------------

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    font: ControlsSingleton.inputFont
    locale: ControlsSingleton.localeProperties.locale

    spacing: 10 * AppFramework.displayScaleFactor

    palette {
        text: app.textColor
        //window: app.backgroundColor
        //        buttonText: app.titleBarTextColor
        //        button: app.titleBarBackgroundColor

        highlight: "#ecfbff"
        //        highlightedText: "black"

        //        mid: "#e1f0fb"
        //        dark: "lightgrey"
        //        light: "#f0fff0"
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        updateVolumes();
    }

    //--------------------------------------------------------------------------

    function updateVolumes() {
        var volumes = [];

        for (var i = 0; i < storageInfo.mountedVolumes.length; i++) {
            var volume = storageInfo.mountedVolumes[i];

            var displayName = volume.displayName || volume.folder.path;

            if (!displayName) {
                console.log(logCategory, arguments.callee.name, "ignore path:", volume.folder.path);

                continue;
            }

            if (volume.storageType !== StorageInfo.StorageTypeInternal
                    && volume.storageType !== StorageInfo.StorageTypeRemovable) {

                console.log(logCategory, arguments.callee.name, "ignore storageType:", volume.storageType, "path:", volume.folder.path);

                continue;
            }

            volumes.push({
                             displayName: displayName,
                             path: volume.folder.path,
                             url: volume.folder.url,
                             storageType: volume.storageType
                         });
        }

        console.log(logCategory, arguments.callee.name, "volumes:", JSON.stringify(volumes, undefined, 2));

        popup.volumes = volumes;
        volumesComboBox.currentIndex = volumes.length > 0 ? 0 : -1;
    }

    //--------------------------------------------------------------------------

    function updateFolders(path) {
        console.log(logCategory, arguments.callee.name, "path:", path);

        var folders = [];

        if (!path) {
            return folders;
        }

        folders.push("/");

        fileFolder.path = path;

        for (var name of fileFolder.folderNames()) {
            folders.push(name);
        }

        popup.folders = folders;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: fileFolder
    }

    //--------------------------------------------------------------------------

    StorageInfo {
        id: storageInfo
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: folderLayout

        Layout.fillWidth: true
        Layout.leftMargin: 5 * AppFramework.displayScaleFactor
        Layout.rightMargin: 5 * AppFramework.displayScaleFactor

        spacing: 5 * AppFramework.displayScaleFactor
        layoutDirection: ControlsSingleton.localeProperties.layoutDirection

        Glyph {
            name: "data"
            color: popup.palette.text

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    updateVolumes();
                }

                onPressAndHold: {
                    console.log(logCategory, "volume url:", fileFolder.url);
                    Qt.openUrlExternally(fileFolder.url);
                }
            }
        }

        ComboBox {
            id: volumesComboBox

            Layout.fillWidth: true

            model: volumes
            textRole: "displayName"
            enabled: volumes.length > 0

            onCurrentIndexChanged: {
                updateFolders(currentIndex >= 0 ? volumes[currentIndex].path : undefined);
            }
        }
    }

    HorizontalSeparator {
        Layout.fillWidth: true
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 250 * AppFramework.displayScaleFactor

        clip: true
        model: folders
        spacing: 5 * AppFramework.displayScaleFactor
        delegate: folderDelegate
    }

    Component {
        id: folderDelegate

        Rectangle {
            width: ListView.view.width
            height: folderLayout.height + folderLayout.anchors.margins * 2

            color: mouseArea.pressed
                   ? palette.mid
                   : mouseArea.containsMouse
                     ? palette.highlight
                     : "transparent"

            border {
                color: mouseArea.pressed
                       ? palette.dark
                       : mouseArea.containsMouse
                         ? palette.mid
                         : "transparent"
            }

            function select() {
                var url = index > 0
                        ? fileFolder.fileUrl(folders[index])
                        : fileFolder.url;

                console.log(logCategory, "selected:", index, "folder:", fileFolder.url, "url:", url);

                folder = url;
                accepted();
                close();
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    select();
                }
            }

            RowLayout {
                id: folderLayout

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    margins: 5 * AppFramework.displayScaleFactor
                }

                spacing: 5 * AppFramework.displayScaleFactor
                layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                Glyph {
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize

                    name: "folder"
                    color: popup.palette.text

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            select();
                        }

                        onPressAndHold: {
                            var url = index > 0
                                    ? fileFolder.fileUrl(modelData)
                                    : fileFolder.url;

                            console.log(logCategory, index, "url:", url);

                            Qt.openUrlExternally(url);
                        }
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: modelData
                    color: palette.text
                    horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font {
                        pointSize: 15
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
