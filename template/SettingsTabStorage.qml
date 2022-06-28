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
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0

import "../Controls"
import "../Controls/Singletons"
import "SurveyHelper.js" as Helper
import "../XForms/Singletons"

SettingsTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Storage")
    description: qsTr("Manage local data")
    icon.name: "data"

    //--------------------------------------------------------------------------

    property string fontFamily: app.fontFamily

    property FileFolder logsFolder: app.logsFolder
    property FileFolder workFolder: app.workFolder
    property FileFolder cacheFolder: AppFramework.standardPaths.writableFolder(StandardPaths.GenericCacheLocation).folder("QtLocation/ArcGIS")
    property FileFolder attachmentsFolder: FileFolder {
        path: "~/ArcGIS/My Survey Attachments"
    }

    //--------------------------------------------------------------------------

    readonly property bool allowEmailData: app.config.enableDataRecovery
    property bool showDecryption

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        logsFolder.refresh();
        cacheFolder.refresh();
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        showDecryption = Qt.binding(() => surveysDatabase.keyEnabled);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(tab, true)
    }

    //--------------------------------------------------------------------------

    Item {
        id: tabItem

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 20 * AppFramework.displayScaleFactor

            //------------------------------------------------------------------

            Item {
                Layout.fillHeight: true
            }

            //--------------------------------------------------------------------------

            ActionGroupLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2 * AppFramework.displayScaleFactor

                font.family: fontFamily

                actionGroup: actionGroup
            }

            //------------------------------------------------------------------

            Item {
                Layout.fillHeight: true
            }

            //------------------------------------------------------------------
        }

        //----------------------------------------------------------------------

        ActionGroup {
            id: actionGroup

            Action {
                enabled: allowEmailData
                text: qsTr("Send Database")
                icon.name: "send"

                onTriggered: {
                    sendDataPopup.createObject(tabItem).open();
                }
            }

            Action {
                text: qsTr("Reinitialize Database")
                icon.name: "reset"

                onTriggered: {
                    var dataSize = AppFramework.fileInfo(surveysDatabase.databasePath).size
                            + attachmentsFolder.size;

                    showConfirmPopup(
                                text,
                                qsTr("The survey database will be reinitialized and all survey data will be deleted from this device."),
                                undefined,
                                qsTr("Do you want to continue?"),
                                function () {
                                    surveysDatabase.reinitialize();
                                    attachmentsFolder.removeFolder();
                                    attachmentsFolder.makeFolder();
                                    attachmentsFolder.refresh();
                                });
                }
            }

            Action {
                enabled: showDecryption

                text: qsTr("Disable Encryption")
                icon.name: "unlock"

                onTriggered: {
                    app.encryptionManager.showDisablePopup(mainStackView);
                }
            }

            Action {
                text: qsTr("Fix Database")
                icon.name: "hammer"

                onTriggered: {
                    showConfirmPopup(
                                text,
                                qsTr("This action will attempt to fix and reconnect the survey database."),
                                undefined,
                                qsTr("Do you want to continue?"),
                                function () {
                                    surveysDatabase.fixSurveysPath();
                                });
                }
            }

            Action {
                text: qsTr("Delete Sent Surveys")
                icon.name: "trash"

                onTriggered: {
                    var submittedCount = surveysDatabase.statusCount(undefined, XForms.Status.Submitted);

                    showConfirmPopup(
                                text,
                                qsTr("The Sent folder will be emptied for all surveys on this device.").arg(submittedCount),
                                qsTr("Surveys to delete: %1").arg(submittedCount),
                                qsTr("Do you want to continue?"),
                                function () {
                                    surveysDatabase.deleteSurveys(XForms.Status.Submitted);
                                });
                }
            }

            Action {
                enabled: cacheFolder.size > 0

                text: qsTr("Clear Map Cache")
                icon.name: "trash"

                onTriggered: {
                    console.log(logCategory, "Removing cache folder:", cacheFolder.path);
                    showConfirmPopup(
                                text,
                                qsTr("All cached map data will be deleted for all surveys."),
                                qsTr("Cache size: %1").arg(Helper.displaySize(cacheFolder.size)),
                                qsTr("Do you want to continue?"),
                                function () {
                                    cacheFolder.removeFolder();
                                    cacheFolder.refresh();
                                });
                }
            }

            Action {
                text: qsTr("Delete Log Files")
                icon.name: "trash"

                onTriggered: {
                    console.log(logCategory, "Removing logs folder:", logsFolder.path);
                    showConfirmPopup(
                                text,
                                qsTr("All log files in the logs folder will be deleted."),
                                qsTr("Files to delete: %1 (%2)").arg(logsFolder.fileNames().length).arg(Helper.displaySize(logsFolder.size)),
                                qsTr("Do you want to continue?"),
                                function () {
                                    logsFolder.removeFolder();
                                    logsFolder.makeFolder();
                                    logsFolder.refresh();
                                });
                }
            }
        }

        //--------------------------------------------------------------------------

        function showConfirmPopup(title, text, informativeText, prompt, yesHandler) {
            var popup = confirmPopup.createObject(tab,
                                                  {
                                                      title: title,
                                                      text: text,
                                                      informativeText: informativeText || "",
                                                      prompt: prompt
                                                  });

            popup.yes.connect(yesHandler);
            popup.open();
        }

        Component {
            id: confirmPopup

            MessagePopup {
                parent: app

                standardIcon: StandardIcon.Warning
                standardButtons: StandardButton.Yes | StandardButton.No
            }
        }

        //----------------------------------------------------------------------

        function sendData(share, includeAttachments) {
            var zip = true;

            surveysDatabase.close();

            var fileInfo = AppFramework.fileInfo(surveysDatabase.databasePath);

            if (zip) {
                workFolder.makeFolder();

                var zipFileInfo = workFolder.fileInfo(Helper.dateStamp() + ".zip");

                zipWriter.path = zipFileInfo.filePath;

                var zipPrefix = "Databases/";
                zipWriter.addFile(fileInfo.filePath, zipPrefix + fileInfo.fileName);

                if (includeAttachments) {
                    var prefix = "Attachments/";

                    var files = attachmentsFolder.fileNames();
                    files.forEach(function (fileName) {
                        var attachmentInfo = attachmentsFolder.fileInfo(fileName);
                        zipWriter.addFile(attachmentInfo.filePath, zipPrefix + attachmentInfo.fileName);
                    });
                }

                zipWriter.close();

                fileInfo = zipFileInfo;
            }

            console.log(logCategory, arguments.callee.name, "filePath:", fileInfo.filePath);

            if (share) {
                AppFramework.clipboard.share(fileInfo.url);
            } else {
                emailComposer.body = Helper.appInfoText(app, emailComposer.html);
                emailComposer.attachments = fileInfo.filePath;
                emailComposer.show();
            }

            surveysDatabase.open();
        }

        EmailComposer {
            id: emailComposer

            subject: qsTr("%1 Data").arg(app.info.title)
            html: Qt.platform.os === "ios"

            onErrorChanged: {
                console.error(logCategory, "EmailComposer error:", JSON.stringify(error));
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: sendDataPopup

            ActionsPopup {
                property bool share: false

                title: qsTr("Send Database")
                text: qsTr("The survey database contains all survey data stored on this device.")
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                icon {
                    name: "send"
                }

                Action {
                    text: qsTr("Email")
                    icon.name: "envelope"

                    onTriggered: {
                        sendData(false, false);
                        close();
                    }
                }

                Action {
                    text: qsTr("Email with attachments")
                    icon.name: "envelope"

                    onTriggered: {
                        sendData(false, true);
                        close();
                    }
                }

                Action {
                    enabled: AppFramework.clipboard.supportsShare
                    text: qsTr("Share")
                    icon.name: ControlsSingleton.shareIconName

                    onTriggered: {
                        sendData(true, false);
                        close();
                    }
                }

                Action {
                    enabled: AppFramework.clipboard.supportsShare
                    text: qsTr("Share with attachments")
                    icon.name: ControlsSingleton.shareIconName

                    onTriggered: {
                        sendData(true, true);
                        close();
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        ZipWriter {
            id: zipWriter
        }

        //----------------------------------------------------------------------
    }
}
