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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"
import "./SurveyHelper.js" as Helper

SettingsTab {
    id: addNmeaLogTab

    //--------------------------------------------------------------------------

    title: qsTr("Select File")

    //--------------------------------------------------------------------------

    property real listDelegateHeight: settingsTabLocation.listDelegateHeight
    property color listBackgroundColor: "#FAFAFA"

    property string logFileLocation: app.logsFolder.path
    property string fileName
    property url fileUrl

    readonly property bool isAndroid: Qt.platform.os === "android"
    readonly property bool isIOS: Qt.platform.os === "ios"

    //--------------------------------------------------------------------------

    signal showReceiverSettingsPage(var deviceName)
    signal clear()

    //--------------------------------------------------------------------------

    onClear: {
        fileName = "";
        fileUrl = "";
    }

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        // Internal properties -------------------------------------------------

        property bool initialized

        // ---------------------------------------------------------------------

        Component.onCompleted: {
            _item.initialized = true;

            controller.onDetailedSettingsPage = true;
        }

        // ---------------------------------------------------------------------

        Component.onDestruction: {
            controller.onDetailedSettingsPage = false;
            clear();
        }

        // ---------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent

            spacing: 0

            Accessible.role: Accessible.Pane

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addNmeaLogTab.listDelegateHeight
                color: addNmeaLogTab.listBackgroundColor

                AppTextField {
                    id: fileNameTextField

                    anchors.fill: parent
                    anchors.topMargin: 10 * AppFramework.displayScaleFactor
                    anchors.bottomMargin: 10 * AppFramework.displayScaleFactor
                    anchors.leftMargin: 10 * AppFramework.displayScaleFactor
                    anchors.rightMargin: 10 * AppFramework.displayScaleFactor

                    placeholderText: qsTr("NMEA log file")

                    text: fileName

                    readOnly: true

                    onCleared: addNmeaLogTab.clear()

                    leftIndicator: TextBoxButton {
                        icon.name: "folder-open"

                        onClicked: {
                            fileDialog.folder = fileFolder.url
                            fileDialog.open()
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            fileDialog.folder = fileFolder.url
                            fileDialog.open()
                        }
                    }
                }
            }

            // -----------------------------------------------------------------

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: addNmeaLogTab.listDelegateHeight
                color: addNmeaLogTab.listBackgroundColor

                AppButton {
                    enabled: fileUrl > ""
                    opacity: enabled ? 1 : 0.5

                    height: 40 * AppFramework.displayScaleFactor

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 10 * AppFramework.displayScaleFactor

                    text: qsTr("Add")

                    onClicked: {
                        var path = gnssSettings.fileUrlToPath(fileUrl)
                        gnssSettings.createNmeaLogFileSettings(path);
                        controller.nmeaLogFileSelected(path);
                        showReceiverSettingsPage(path);
                    }
                }
            }

            // -----------------------------------------------------------------

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // ---------------------------------------------------------------------

        DocumentDialog {
            id: fileDialog

            title: qsTr("Select a GPS log file")
            nameFilters: ["GPS log files (*.txt *.log *.nmea)"]
            folder: fileFolder.url

            onAccepted: {
                var url = fileUrl;

                var src = AppFramework.fileInfo(fileUrl);
                var dest = fileFolder.filePath(src.fileName);

                if (src.filePath !== dest) {
                    if (!src.folder.copyFile(src.fileName, dest)) {
                        dest = fileFolder.filePath("%1-%2.%3".arg(src.baseName).arg(Helper.dateStamp()).arg(src.suffix));

                        if (!src.folder.copyFile(src.fileName, dest)) {
                            clear();
                            errorPopup.open();
                            return;
                        }
                    }

                    url = AppFramework.fileInfo(dest).url;
                }

                addNmeaLogTab.fileUrl = url;
                addNmeaLogTab.fileName = gnssSettings.fileUrlToLabel(url);
            }
        }

        // ---------------------------------------------------------------------

        FileFolder {
            id: fileFolder

            path: logFileLocation
        }

        //--------------------------------------------------------------------------

        MessagePopup {
            id: errorPopup

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Ok

            title: qsTr("Unable to Add File")
            text: qsTr("Please select another NMEA log file.")
        }

        // ---------------------------------------------------------------------
    }
}
