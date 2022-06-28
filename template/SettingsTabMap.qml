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
import QtQuick.Dialogs 1.2
import QtLocation 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Map")
    description: qsTr("Manage map settings")
    icon.name: "map"

    //--------------------------------------------------------------------------

    readonly property string kFolderSeparator: ";"
    readonly property bool canModifyMapLibrary: Qt.platform.os !== "ios"

    property real iconSize: 25 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    property bool showMapPlugin: true
    property bool showAllMapPlugins: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        //showMapPlugin = appSettings.mapPlugin !== appSettings.kDefaultMapPlugin;
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        if (showMapPlugin) {
            showAllMapPlugins = true;
        } else {
            showMapPlugin = true;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(tab, true)
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        //----------------------------------------------------------------------

        property string mapFoldersText: mapLibraryTextField.text.trim()
        property var mapFolderNames: splitFolders(mapFoldersText)

        //----------------------------------------------------------------------

        onMapFoldersTextChanged: {
            _item.updateSettings();
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 20 * AppFramework.displayScaleFactor

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                visible: showMapPlugin && !showAllMapPlugins

                title: qsTr("Map types")

                AppRadioButton {
                    Layout.fillWidth: true

                    text: qsTr("Basic")
                    checked: appSettings.mapPlugin === appSettings.kPluginAppStudio

                    font {
                        pointSize: 13
                    }

                    onClicked: {
                        appSettings.mapPlugin = appSettings.kPluginAppStudio;
                    }
                }

                AppRadioButton {
                    Layout.fillWidth: true

                    text: qsTr("Standard")
                    checked: appSettings.mapPlugin === appSettings.kPluginArcGISRuntime

                    font {
                        pointSize: 13
                    }

                    onClicked: {
                        appSettings.mapPlugin = appSettings.kPluginArcGISRuntime;
                    }
                }
            }

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                visible: showAllMapPlugins

                title: "Map plugin"

                ComboBox {
                    id: mapPluginComboBox

                    Layout.fillWidth: true

                    property Plugin plugin: Plugin {}

                    model: plugin.availableServiceProviders

                    Component.onCompleted: {
                        currentIndex = model.indexOf(appSettings.mapPlugin);

                        popup.font = font;
                    }

                    onActivated: {
                        appSettings.mapPlugin = currentText;
                    }

                    font {
                        family: app.fontFamily
                        pointSize: 15
                    }
                }
            }

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Map library")

                ColumnLayout {
                    Layout.fillWidth: true

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("Folders: %1").arg(_item.mapFolderNames.length)

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        AppTextField {
                            id: mapLibraryTextField

                            Layout.fillWidth: true

                            text: appSettings.mapLibraryPaths

                            readOnly: !canModifyMapLibrary

                            leftIndicator: TextBoxButton {
                                icon.name: canModifyMapLibrary
                                           ? "folder-plus"
                                           : "folder"

                                enabled: canModifyMapLibrary

                                onClicked: {
                                    selectMapFolder(Qt.platform.os === "android");
                                }

                                onPressAndHold: {
                                    selectMapFolder(true);
                                }
                            }

                            onCleared: {
                                text = appSettings.kDefaultMapLibraryPath;
                            }
                        }
                    }
                }
            }

            //------------------------------------------------------------------

            ListView {
                id: foldersListView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: _item.mapFolderNames.length > 1
                clip: true
                model: _item.mapFolderNames
                spacing: 5 * AppFramework.displayScaleFactor
                delegate: folderDelegate
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: !foldersListView.visible
            }

            //------------------------------------------------------------------

            ActionGroupLayout {
                Layout.fillWidth: true

                font: ControlsSingleton.font
                locale: ControlsSingleton.localeProperties.locale
                palette {
                    window: app.backgroundColor
                    windowText: app.textColor
                }

                actionGroup: ActionGroup {
                    Action {
                        text: qsTr("View map library")
                        icon.name: "collection"

                        onTriggered: {
                            if (portal.isOnline) {
                                showSignInOrMapsPage();
                            } else {
                                showMapsPage();
                            }
                        }

                        function showSignInOrMapsPage() {
                            portal.signInAction(qsTr("Please sign in to manage your map library"), showMapsPage);
                        }

                        function showMapsPage() {
                            _item.updateSettings();
                            app.mainStackView.push(mapLibraryPage);
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        function selectMapFolder(showStorageFolders) {
            var parameters = {
                title: qsTr("Map Library Folder")
            };

            if (_item.mapFolderNames.length > 0) {
                var folder = AppFramework.fileFolder(_item.mapFolderNames[0]);
                console.log(logCategory, arguments.callee.name, "library:", folder.url);
                parameters.folder = folder.url;
            }

            var popupComponent = showStorageFolders
                    ? storageFolderPopup
                    : folderDialog

            var popup = popupComponent.createObject(_item, parameters);
            popup.open();
        }

        //----------------------------------------------------------------------

        function splitFolders(text) {
            return text
            .trim()
            .split(kFolderSeparator)
            .filter(name => !!name && name.trim() > "");
        }

        //----------------------------------------------------------------------

        function addFolder(url) {
            console.log(logCategory, arguments.callee.name, "url:", url);

            var fileInfo = AppFramework.fileInfo(url);

            if (_item.mapFolderNames.indexOf(fileInfo.filePath) >= 0) {
                return;
            }

            var folders = _item.mapFolderNames.slice();
            folders.push(fileInfo.filePath);

            setFolders(folders);
        }

        //----------------------------------------------------------------------

        function removeFolder(path) {
            console.log(logCategory, arguments.callee.name, "path:", path);

            setFolders(_item.mapFolderNames.filter(name => name !== path));
        }

        //----------------------------------------------------------------------

        function setFolders(folders) {
            console.log(logCategory, arguments.callee.name, "folders:", JSON.stringify(folders, undefined, 2));

            mapLibraryTextField.text = [...new Set(folders)].join(kFolderSeparator);
        }

        //----------------------------------------------------------------------

        Component {
            id: folderDialog

            FileDialog {
                selectFolder: true
                selectExisting: true
                folder: shortcuts.home

                onAccepted: {
                    addFolder(folder);
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: storageFolderPopup

            StorageFolderPopup {

                onAccepted: {
                    addFolder(folder);
                }
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: folderDelegate

            Item {
                width: ListView.view.width
                height: folderLayout.height + folderLayout.anchors.margins * 2

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
                        color: app.textColor

                        MouseArea {
                            anchors.fill: parent

                            onPressAndHold: {
                                Qt.openUrlExternally(AppFramework.fileInfo(modelData).url);
                            }
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: modelData
                        color: app.textColor
                        horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font {
                            pointSize: 15
                        }
                    }

                    StyledImageButton {
                        color: app.textColor

                        visible: canModifyMapLibrary
                        icon.name: "trash"
                        padding: 3 * AppFramework.displayScaleFactor

                        onClicked: {
                            removeFolder(modelData);
                        }
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: mapLibraryPage

            MapLibraryPage {
            }
        }

        //----------------------------------------------------------------------

        function updateSettings() {
            if (canModifyMapLibrary) {
                var paths = mapLibraryTextField.text.trim();
                appSettings.mapLibraryPaths = paths;
            }
        }

        //----------------------------------------------------------------------
    }
}
