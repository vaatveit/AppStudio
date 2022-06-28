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

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "../Portal"
import "../template/Singletons"

import "SurveyHelper.js" as Helper

Item {
    id: view

    //--------------------------------------------------------------------------

    property Portal portal
    property bool showLibraryIcon: true
    property ListModel mapPackages
    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    property bool debug: false

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            fill: parent
        }

        visible: mapPackages.count <= 0
        active: visible

        sourceComponent: Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 20 * AppFramework.displayScaleFactor
                    rightMargin: 20 * AppFramework.displayScaleFactor
                }

                spacing: 10 * AppFramework.displayScaleFactor

                Item {
                    Layout.fillHeight: true
                }

                IconImage {
                    Layout.alignment: Qt.AlignHCenter

                    icon {
                        name: portal.isOnline ? "online" : "offline"
                    }
                }

                AppText {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 50 * AppFramework.displayScaleFactor

                    text: portal.isOnline
                          ? qsTr("Your device is online")
                          : qsTr("Your device is offline")

                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 15
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("No maps have been downloaded for offline use.")

                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 15
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    visible: portal.isOnline
                    text: portal.signedIn
                          ? qsTr("There are no compatible maps available online to download.")
                          : qsTr("You are not signed in, there are no compatible public maps available online to download.")

                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 15
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            fill: parent
        }

        visible: mapPackages.count > 0
        active: visible

        sourceComponent: ScrollView {
            id: scrollView

            ListView {
                width: scrollView.availableWidth
                height: scrollView.availableHeight

                model: mapPackages

                spacing: AppFramework.displayScaleFactor * 5
                clip: true

                delegate: mapPackageDelegate
            }
        }
    }

    Component {
        id: mapPackageDelegate

        SwipeLayoutDelegate {
            id: delegate

            width: ListView.view.width

            Component.onCompleted: {
                if (portal.isOnline) {
                    mapPackage.requestItemInfo();
                }
            }

            Image {
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth * 133/200

                source: thumbnailUrl > "" ? thumbnailUrl : defaultMapThumbnail
                fillMode: Image.PreserveAspectFit

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border {
                        width: 1
                        color: "#20000000"
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: -3 * AppFramework.displayScaleFactor
                    }

                    width: 30 * AppFramework.displayScaleFactor
                    height: width

                    radius: 3
                    color: accentColor
                    border {
                        width: 1
                        color: "white"
                    }

                    visible: storeInLibrary && showLibraryIcon

                    StyledImage {
                        id: libraryImage

                        anchors {
                            fill: parent
                            margins: 3
                        }

                        source: "images/maps-folder.png"
                        color: "white"
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        var mapInfo = mapPackages.get(index);
                        console.log("mapInfo:", JSON.stringify(mapInfo, undefined, 2));

                        Qt.openUrlExternally(mapPackage.folder.url);
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.name > "" ? mapPackage.name : mapPackage.itemId
                    font {
                        bold: true
                        pointSize: 14
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                }

                AppText {
                    id: descriptionText

                    Layout.fillWidth: true

                    text: mapPackage.description
                    font {
                        pointSize: 12
                    }
                    elide: Text.ElideRight
                    color: textColor
                    visible: text > ""

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            descriptionText.elide = descriptionText.elide == Text.ElideNone
                                    ? Text.ElideRight
                                    : Text.ElideNone
                        }
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: Helper.displaySize(mapPackage.localSize)
                    font {
                        pointSize: 12
                    }
                    color: textColor
                    visible: mapPackage.isLocal
                }

                HorizontalSeparator {
                    Layout.fillWidth: true
                    visible: mapPackage.canDownload
                }

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.updateAvailable
                          ? qsTr("Update available %1").arg(mapPackage.updateDate.toLocaleString(undefined, Locale.ShortFormat))
                          : qsTr("Update not required")
                    font {
                        pointSize: 12
                    }
                    color: textColor
                    visible: mapPackage.canDownload && mapPackage.isLocal
                }

                AppText {
                    Layout.fillWidth: true

                    text: Helper.displaySize(mapPackage.updateSize)
                    font {
                        pointSize: 12
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                    visible: mapPackage.canDownload && (mapPackage.updateAvailable || !mapPackage.isLocal)
                }

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.errorText
                    visible: text > ""
                    color: "red"
                    font {
                        bold: true
                    }
                }
            }

            StyledImageButton {
                Layout.preferredWidth: delegate.buttonSize
                Layout.preferredHeight: delegate.buttonSize

                visible: mapPackage.canDownload
                icon.name: mapPackage.isLocal ? "refresh" : "download"

                onClicked: {
                    progressPanel.title = qsTr("Downloading map package");
                    progressPanel.message = mapPackage.name;
                    progressPanel.open();

                    mapPackage.requestDownload();
                }
            }

            StyledImageButton {
                Layout.preferredWidth: delegate.buttonSize
                Layout.preferredHeight: delegate.buttonSize

                visible: debug || mapPackage.isLocal && !mapPackage.isReadOnly
                icon.name: "ellipsis"
                color: app.textColor

                onClicked: {
                    delegate.swipeToggle();
                }
            }

            behindLayout: SwipeBehindShadowLayout {
                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: debug && itemId > ""

                    image {
                        source: Icons.bigIcon(portal.isPortal ? "portal" : "arcgis-online")
                    }

                    onClicked: {
                        var mapInfo = mapPackages.get(index);
                        console.log("mapInfo:", JSON.stringify(mapInfo, undefined, 2));

                        var url = portal.portalUrl + "/home/item.html?id=" + mapPackage.itemId;

                        console.log(url);
                        Qt.openUrlExternally(url);
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: debug && mapPackage.isLocal

                    image {
                        source: Icons.bigIcon("folder-open")
                    }

                    onClicked: {
                        var mapInfo = mapPackages.get(index);
                        console.log("mapInfo:", JSON.stringify(mapInfo, undefined, 2));

                        Qt.openUrlExternally(mapPackage.folder.url);
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: mapPackage.isLocal && !mapPackage.isReadOnly

                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }

                    backgroundColor: "tomato"

                    onClicked: {
                        var popup = confirmDeletePopup.createObject(view,
                                                                    {
                                                                        name: mapPackage.name
                                                                    });

                        popup.yes.connect(() => {
                                              console.log(logCategory, "delete index:", index);

                                              if (mapPackage.deleteLocal()) {
                                                  if (!mapPackage.itemId) {
                                                      mapPackages.remove(index);
                                                  }
                                              }
                                          });
                        popup.open();
                    }
                }
            }

            MapPackage {
                id: mapPackage

                portal: app.portal
                info: mapPackages.get(index)
                mapPlugin: view.mapPlugin

                onProgressChanged: {
                    progressPanel.progressBar.value = progress;
                }

                onDownloaded: {
                    progressPanel.close();
                }

                onFailed: {
                    progressPanel.closeError(qsTr("Download map package error"));
                }

                Connections {
                    target: mapPackage.portal

                    onSignedInChanged: {
                        if (portal.signedIn) {
                            mapPackage.requestItemInfo();
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: confirmDeletePopup

        MessagePopup {
            parent: app

            property string name

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.Cancel

            title: qsTr("Delete Map Package")
            text: qsTr("The map package <b>%1</b> will be deleted from this device.").arg(name)

            yesAction {
                icon {
                    name: "trash"
                    color: Survey.kColorWarning
                }
                text: qsTr("Delete")
            }
        }
    }

    //--------------------------------------------------------------------------
}
