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

import "SurveyHelper.js" as Helper
import "../Portal"
import "../Controls"
import "../Controls/Singletons"
import "Singletons"

ColumnLayout {
    id: panel

    //--------------------------------------------------------------------------

    property var parameters

    readonly property string itemId: Helper.getPropertyValue(parameters, Survey.kParameterItemId, "").trim()
    readonly property bool autoDownload: Helper.toBoolean(Helper.getPropertyValue(parameters, Survey.kParameterDownload, true))

    property alias itemInfo: portalItem.itemInfo
    readonly property url thumbnailUrl: !!itemInfo && itemInfo.thumbnail > ""
                                        ? portal.authenticatedImageUrl(portalItem.contentUrl + "/info/" + itemInfo.thumbnail)
                                        : ""
    property bool busy: false
    property bool accessDenied: false
    property bool notFound: false
    property Portal portal
    readonly property bool isOnline: portal.isOnline
    property alias progressPanel: downloadSurvey.progressPanel
    property bool debug: false

    property color backgroundColor: app.backgroundColor
    property color textColor: app.textColor
    property color accentColor: app.titleBarBackgroundColor
    property color linkColor: "darkblue"
    property color titleTextColor: Survey.kColorError

    //--------------------------------------------------------------------------

    signal downloaded()
    signal cleared()

    //--------------------------------------------------------------------------

    visible: !Helper.isEmpty(itemId) && !progressPanel.popup.visible

    //--------------------------------------------------------------------------

    onItemIdChanged: {
        console.log(logCategory, "itemId:", itemId);

        portalItem.itemInfo = null;

        if (!isOnline) {
            return;
        }

        update();
    }

    //--------------------------------------------------------------------------

    onIsOnlineChanged: {
        if (!Helper.isEmpty(itemInfo)) {
            return;
        }

        update();
    }

    //--------------------------------------------------------------------------

    function show(parameters) {
        console.log(logCategory, arguments.callee.name, "parameters:", JSON.stringify(parameters, undefined, 2));

        panel.parameters = parameters;
    }

    //--------------------------------------------------------------------------

    function update() {
        if (Helper.isEmpty(itemId)) {
            return;
        }

        busy = true;
        portalItem.itemId = itemId;
        portalItem.requestInfo();
    }

    //--------------------------------------------------------------------------

    function clear() {
        parameters = null;
        cleared();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(panel, true)
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: openParametersInfo.height + openParametersInfo.anchors.margins * 2

        color: backgroundColor
        radius: 2 * AppFramework.displayScaleFactor
        border {
            width: 1
            color: accentColor
        }

        ColumnLayout {
            id: openParametersInfo

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 5 * AppFramework.displayScaleFactor
            }

            AppBusyIndicator {
                Layout.alignment: Qt.AlignHCenter

                running: busy
                visible: running
            }

            ColumnLayout {
                Layout.fillWidth: true

                visible: !busy && Helper.isEmpty(itemInfo)

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Survey not found")
                    color: titleTextColor
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            //                showSignInOrDownloadPage();
                        }

                        onPressAndHold: {
                            if (openParametersDiagInfo.visible) {
                                clear();
                                openParametersDiagInfo.visible = false;
                            } else {
                                openParametersDiagInfo.visible = true;
                            }
                        }
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: notFound
                          ? qsTr('Survey id <b>%1</b> does not exist or is inaccessible.').arg(itemId)
                          : qsTr('Survey id <a href="%2/home/item.html?id=%1"><b>%1</b></a> has not been downloaded').arg(itemId).arg(app.portal.owningSystemUrl)

                    color: textColor
                    horizontalAlignment: Text.AlignHCenter
                    linkColor: isOnline ? linkColor: textColor
                    font {
                        pointSize: 14
                    }

                    onLinkActivated: {
                        if (isOnline) {
                            Qt.openUrlExternally(link);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    visible: accessDenied && portal.signedIn && isOnline

                    RoundedImage {
                        Layout.preferredHeight: 40 * AppFramework.displayScaleFactor
                        Layout.preferredWidth: Layout.preferredHeight

                        source: portal.userThumbnailUrl
                        border {
                            width: 1
                            color: "#40000000"
                        }
                        color: backgroundColor
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("<b>%1</b> (%2) does not have permission to download this survey.").arg(Helper.getPropertyValue(portal.user, "fullName")).arg(Helper.getPropertyValue(portal.user, "username"))
                        color: textColor
                    }
                }

                AppButton {
                    Layout.alignment: Qt.AlignHCenter

                    visible: isOnline && (accessDenied || !portal.signedIn)

                    text: portal.signedIn ? qsTr("Sign in as different user") : qsTr("Sign in to download")
                    textPointSize: 16
                    iconSource: Icons.bigIcon("sign-in")

                    onClicked: {
                        if (portal.signedIn) {
                            portal.signOut();
                        }
                        portal.signInAction(qsTr("Please sign in to download survey"));
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                visible: !busy && !Helper.isEmpty(itemInfo) && isOnline

                RowLayout {
                    Layout.fillWidth: true

                    Image {
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 66 * AppFramework.displayScaleFactor

                        fillMode: Image.PreserveAspectFit
                        source: thumbnailUrl

                        Rectangle {
                            anchors.fill: parent

                            color: "transparent"

                            border {
                                width: 1
                                color: "#40000000"
                            }
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("The survey <b>%1</b> has not been downloaded.").arg(Helper.getPropertyValue(itemInfo, "title", itemId))
                        color: textColor
                    }

                    StyledImageButton {
                        Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

                        visible: isOnline

                        source: Icons.icon("download")
                        color: textColor

                        onClicked: {
                            downloadSurvey.download(itemInfo);
                        }

                        onPressAndHold: {
                            clear();
                        }
                    }
                }
            }

            TextArea {
                id: openParametersDiagInfo

                Layout.fillWidth: true
                Layout.preferredHeight: 110 * AppFramework.displayScaleFactor

                visible: false
                text: parameters ? JSON.stringify(parameters, undefined, 2) : ""
                readOnly: true
            }

            AppText {
                Layout.fillWidth: true

                visible: !isOnline

                text: qsTr("Your device is offline. Please connect to a network to download surveys.")
                color: Survey.kColorError
                horizontalAlignment: Qt.AlignHCenter
            }
        }
    }

    //--------------------------------------------------------------------------

    resources: [
        PortalItem {
            id: portalItem

            portal: app.portal

            onFailed: {
                accessDenied = error.code === 403 && error.messageCode === "GWM_0003";
                notFound = error.code === 400 && error.messageCode === "CONT_0001";
                busy = false;
            }

            onItemInfoDownloaded: {
                if (debug) {
                    console.log(logCategory, "itemInfo:", JSON.stringify(itemInfo, undefined, 2));
                }

                busy = false;

                if (autoDownload) {
                    downloadSurvey.download(itemInfo);
                }
            }
        },

        DownloadSurvey {
            id: downloadSurvey

            portal: app.portal
            succeededPrompt: false
            debug: debug

            onSucceeded: {
                console.log("onSucceeded");
                downloaded();
                parameters = null;
            }
        }
    ]

    //--------------------------------------------------------------------------
}
