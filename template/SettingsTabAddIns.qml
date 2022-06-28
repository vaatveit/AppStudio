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

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "../Portal"
import "../template/Singletons"
import "../Models"

SettingsTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Add-Ins")
    description: qsTr("View and manage add-ins")
    icon.name: "add-in"

    //--------------------------------------------------------------------------

    property Portal portal
    property bool debug: true

    property color textColor: "#323232"
    property color iconColor: "#505050"
    property real buttonSize: 30 * AppFramework.displayScaleFactor

    property bool allowEsriAddIns: true//settings.boolValue("AddIns/allowEsriAddIns", true)

    //--------------------------------------------------------------------------

    Item {
        id: tabContent

        //----------------------------------------------------------------------

        Item {
            anchors.fill: parent

            visible: addInsModel.count <= 0

            Image {
                anchors.fill: parent
                source: "images/no_data.png"
                fillMode: Image.PreserveAspectFit
                opacity: 0.5
            }
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 5 * AppFramework.displayScaleFactor

            AppText {
                Layout.fillWidth: true

                text: qsTr("Pull to refresh available add-ins")

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
                font {
                    pointSize: addInsModel.count > 0 ? 13 : 18
                    bold: addInsModel.count <= 0
                }
            }

            ListView {
                id: addInsView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8 * AppFramework.displayScaleFactor

                model: delegateModel
                spacing: 10 * AppFramework.displayScaleFactor
                clip: true

                RefreshHeader {
                    refreshing: addInItemsSearch.busy

                    onRefresh: {
                        portal.signInAction(qsTr("Please sign in to refresh add-ins"), addInItemsSearch.startSearch);
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        SortFilterDelegateModel {
            id: delegateModel

            model: addInsModel
            delegate: addInDelegateComponent

            sortRole: "title"
            sortOrder: Qt.AscendingOrder

            filterRole: "title"
        }

        //----------------------------------------------------------------------

        AddInsModel {
            id: addInsModel

            addInsFolder: app.addInsFolder
            includeDisabled: true
            includeInternal: false
        }

        //--------------------------------------------------------------------------

        AddInItemsSearch {
            id: addInItemsSearch

            portal: tab.portal
            addInsModel: addInsModel
            allowFromEsri: allowEsriAddIns
        }

        //--------------------------------------------------------------------------

        AddInDownload {
            id: addInDownload

            portal: tab.portal
            progressPanel: progressPanel
            workFolder: app.workFolder
            addInsFolder: app.addInsFolder
            debug: debug

            onSucceeded: {
                addInsModel.update(true);
                //                page.downloaded = true;
                //                //surveysFolder.update();
                //                searchModel.update();
            }
        }

        //--------------------------------------------------------------------------

        ProgressPanel {
            id: progressPanel
        }

        //----------------------------------------------------------------------

        Component {
            id: addInDelegateComponent

            SwipeLayoutDelegate {
                id: swipeDelegate

                property var addInItem: addInsModel.get(index)
                property int openDirection: SwipeDelegate.Right

                width: addInsView.width

                AddIn {
                    id: addIn

                    path: addInItem.path
                }

                Image {
                    Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                    source: path > ""
                            ? thumbnail
                            : portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemId + "/info/" + thumbnail)
                    fillMode: Image.PreserveAspectFit

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: -1
                        }

                        color: "transparent"
                        border {
                            width: 1
                            color: "#20000000"
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true

                    spacing: 3 * AppFramework.displayScaleFactor

                    AppText {
                        width: parent.width
                        text: title
                        font {
                            pointSize: 16 * app.textScaleFactor
                        }
                        color: textColor
                    }

                    AppText {
                        width: parent.width
                        text: addIn.version
                        font {
                            pointSize: 11 * app.textScaleFactor
                        }
                        color: textColor
                    }

                    AppText {
                        width: parent.width
                        text: qsTr("Modified: %1").arg(new Date(modified).toLocaleString(undefined, Locale.ShortFormat))
                        font {
                            pointSize: 11 * app.textScaleFactor
                        }
                        textFormat: Text.AutoText
                        color: textColor
                        visible: !internal && modified > 0
                    }
                }

                StyledImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    visible: addIn.hasSettingsPage

                    icon.name: "gear"
                    color: iconColor

                    onClicked: {
                        mainStackView.push(addInSettingsPage,
                                           {
                                               addIn: addIn
                                           });
                    }
                }

                StyledImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    visible: portal.signedIn && updateAvailable

                    icon.name: path > "" ? "refresh" : "download"
                    color: iconColor

                    onClicked: {
                        addInDownload.download(addInsModel.get(index));
                    }
                }

                StyledImage {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    visible: swipeDelegate.swipe.position === 0

                    source: Icons.icon("ellipsis")
                    color: iconColor
                }

                behindLayout: SwipeBehindShadowLayout {
                    SwipeDelegateButton {
                        Layout.fillHeight: true

                        visible: !addIn.internal && itemUrl > ""
                        image.source: Icons.bigIcon("web")

                        onClicked: {
                            Qt.openUrlExternally(itemUrl);
                        }
                    }

                    SwipeDelegateButton {
                        Layout.fillHeight: true

                        visible: addIn.path > ""
                        image.source: Icons.bigIcon("information")

                        onClicked: {
                            mainStackView.push(addInAboutPage,
                                               {
                                                   addIn: addIn
                                               });
                        }
                    }

                    SwipeDelegateButton {
                        Layout.fillHeight: true

                        visible: addIn.path > ""

                        image {
                            source: Icons.bigIcon("options")
                            color: addIn.config.enabled ? iconColor : "red"
                        }

                        onClicked: {
                            showAddInConfigPopup(addIn);
                        }
                    }

                    SwipeDelegateButton {
                        Layout.fillHeight: true

                        visible: !addIn.internal && addIn.path > ""
                        image {
                            source: Icons.bigIcon("trash")
                            color: "white"
                        }
                        backgroundColor: "tomato"

                        onClicked: {
                            confirmDelete(index);
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        function confirmDelete(index) {
            deletePopup.index = index;
            deletePopup.open();
        }

        MessagePopup {
            id: deletePopup

            property int index

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.Cancel

            title: qsTr("Delete Add-In")
            text: qsTr("The <b>%1</b> add-in will be deleted from this device.").arg(addInsModel.get(index).title)

            yesAction {
                icon {
                    source: Icons.icon("trash")
                    color: Survey.kColorWarning
                }
                text: qsTr("Delete")
            }

            onYes: {
                deleteAddIn();
            }

            function deleteAddIn() {
                var path = addInsModel.get(index).path;
                console.log("Delete add-in:", path);
                if (!addInsModel.addInsFolder.removeFolder(path, true)) {
                    console.error("Error deleting add-in:", path);
                }

                addInsModel.update(true);
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: addInAboutPage

            AddInAboutPage {
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: addInSettingsPage

            AddInSettingsPage {
            }
        }

        //----------------------------------------------------------------------

        function showAddInConfigPopup(addIn) {
            var component;

            switch (addIn.type) {
            case addIn.kTypeTool:
                component = addInToolConfigPopup;
                break;

            default:
                component = addInConfigPopup;
                break;
            }

            var popup = component.createObject(tabContent,
                                               {
                                                   addIn: addIn
                                               });
            popup.open();
        }

        Component {
            id: addInConfigPopup

            AddInConfigPopup {
            }
        }

        Component {
            id: addInToolConfigPopup

            AddInToolConfigPopup {
            }
        }

        //----------------------------------------------------------------------

        Connections {
            target: tab

            onTitlePressAndHold: {
                var popup = addInsSettingsPopup.createObject(tabContent);
                popup.open();
            }
        }

        Component {
            id: addInsSettingsPopup
            AddInsConfigPopup {
                settings: appSettings.settings
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------
}
