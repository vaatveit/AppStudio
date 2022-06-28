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
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"
import "../XForms"
import "SurveyHelper.js" as Helper

SettingsTab {
    id: tab

    //--------------------------------------------------------------------------

    property QC1.StackView stackView: app.mainStackView
    property FileFolder logsFolder: app.logsFolder
    property bool showUserData: false

    //--------------------------------------------------------------------------

    title: qsTr("Diagnostics")
    description: qsTr("Enable debug logging")
    icon.name: "activity-monitor"

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        if (showUserData) {
            Qt.openUrlExternally(logsFolder.url);
        } else {
            showUserData = true;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(tab, true)
    }

    //--------------------------------------------------------------------------

    Item {
        Component.onCompleted: {
            AppFramework.logging.userData = app.settings.value("Logging/userData", "");
        }

        //--------------------------------------------------------------------------

        Connections {
            target: AppFramework.logging

            onOutputLocationChanged: {
                outputTextField.text = Qt.binding(function () {
                    return AppFramework.logging.outputLocation;
                });
            }
        }

        //--------------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 5 * AppFramework.displayScaleFactor

            AppSwitch {
                Layout.fillWidth: true

                text: checked
                      ? qsTr("Logging is on")
                      : qsTr("Logging is off")

                checked: AppFramework.logging.enabled
                enabled: AppFramework.logging || outputTextField.text > ""

                onCheckedChanged: {
                    forceActiveFocus();
                    if (checked) {
                        checkOutputLocation();
                    }
                    AppFramework.logging.enabled = checked;
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                AppText {
                    Layout.fillWidth: true
                    text: qsTr("Log output location")
                }

                AppTextField {
                    id: outputTextField

                    Layout.fillWidth: true

                    readOnly: AppFramework.logging.enabled
                    text: AppFramework.logging.outputLocation

                    leftIndicator: TextBoxButton {
                        visible: QtMultimedia.availableCameras.length > 0
                        icon.name: "qr-code"

                        onClicked: {
                            stackView.push({
                                               item: scanBarcodePage
                                           });
                        }
                    }

                    onEditingFinished: {
                        AppFramework.logging.outputLocation = text;
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    visible: userDataField.visible
                    text: qsTr("User data")
                }

                AppTextField {
                    id: userDataField

                    Layout.fillWidth: true

                    visible: showUserData || text > ""
                    text: AppFramework.logging.userData

                    onEditingFinished: {
                        AppFramework.logging.userData = text;
                        app.settings.setValue("Logging/userData", text);
                    }
                }

                ColumnLayout {
                    id: consolesLayout

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: !AppFramework.logging.enabled && Networking.isOnline

                    HorizontalSeparator {
                        Layout.fillWidth: true
                    }

                    AppText {
                        Layout.fillWidth: true
                        text: qsTr("Searching for AppStudio consoles")
                        visible: syslogDiscoveryAgent.model.count === 0 && syslogDiscoveryAgent.active
                    }

                    AppText {
                        Layout.fillWidth: true
                        text: qsTr("Select an AppStudio console")
                        visible: syslogDiscoveryAgent.model.count > 0
                    }

                    ProgressBar {
                        Layout.fillWidth: true

                        indeterminate: true
                        visible: syslogDiscoveryAgent.active
                    }

                    ListView {
                        id: consolesListView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: syslogDiscoveryAgent.model
                        clip: true
                        spacing: 5 * AppFramework.displayScaleFactor
                        delegate: consoleItem
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: !consolesLayout.visible
                }

                Flow {
                    Layout.fillWidth: true

                    spacing: 10 * AppFramework.displayScaleFactor

                    AppButton {
                        text: qsTr("Email")
                        textPointSize: 15
                        iconSource: Icons.icon("envelope")

                        onClicked: {
                            logFileDialog.share = false;
                            logFileDialog.open();
                        }
                    }

                    AppButton {
                        visible: AppFramework.clipboard.supportsShare
                        text: qsTr("Share")
                        textPointSize: 15
                        iconSource: Icons.icon(ControlsSingleton.shareIconName)

                        onClicked: {
                            logFileDialog.share = true;
                            logFileDialog.open();
                        }
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: consoleItem

            Rectangle {
                width: ListView.view.width
                height: consoleItemLayout.height + consoleItemLayout.anchors.margins * 2
                color: mouseArea.containsMouse ? "#ecfbff" : "white"
                border {
                    width: 1
                    color: "#80000000"
                }
                radius: 4 * AppFramework.displayScaleFactor


                RowLayout {
                    id: consoleItemLayout

                    anchors {
                        left: parent.left
                        right: parent.right
                        top : parent.top

                        margins: 5 * AppFramework.displayScaleFactor
                    }

                    Image {
                        Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        source: "images/AppConsole.png"
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        AppText {
                            Layout.fillWidth: true
                            text: displayName
                        }
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        AppFramework.logging.outputLocation = consolesListView.model.get(index).outputLocation;
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        SyslogDiscoveryAgent {
            id: syslogDiscoveryAgent

            Component.onCompleted: {
                start();
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: scanBarcodePage

            XFormBarcodeScan {
                barcodeSettings {
                    settings: app.settings
                    settingsKey: "diagnostics"
                }

                onCodeScanned: {
                    outputTextField.text = code.trim();
                    outputTextField.editingFinished();
                }
            }
        }

        //--------------------------------------------------------------------------

        DocumentDialog {
            id: logFileDialog

            property bool share: false

            title: qsTr("Select log file")

            folder: logsFolder.url
            selectMultiple: !share

            nameFilters: [
                qsTr("Logs (*.log *.nmea)"),
                qsTr("Console Logs (*.log)"),
                qsTr("NMEA Logs (*.nmea)"),
                qsTr("All files (*)")
            ]

            onAccepted: {
                if (share) {
                    shareLogFile(fileUrl);
                } else {
                    sendLogFiles(fileUrls);
                }
            }
        }

        //----------------------------------------------------------------------

        EmailComposer {
            id: emailComposer

            html: Qt.platform.os === "ios"

            onErrorChanged: {
                console.error(logCategory, "EmailComposer error:", JSON.stringify(error));
            }
        }

        //----------------------------------------------------------------------

        function shareLogFile(url) {
            console.log(logCategory, arguments.callee.name, "url:", url);

            AppFramework.clipboard.share(url);
        }

        //----------------------------------------------------------------------

        function sendLogFiles(urls) {
            console.log(logCategory, arguments.callee.name, "urls:", JSON.stringify(urls, undefined, 2));

            var attachments = [];
            var attachmentNames = [];

            for (var url of urls) {
                var fileInfo = AppFramework.fileInfo(url);

                attachments.push(url);
                attachmentNames.push(fileInfo.displayName);
            }

            emailComposer.subject = qsTr("%1 Log - %2").arg(app.info.title).arg(attachmentNames.join(", "));
            emailComposer.body = Helper.appInfoText(app, emailComposer.html);
            emailComposer.attachments = attachments;
            emailComposer.show();
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------


    //--------------------------------------------------------------------------

    function checkOutputLocation() {

        if (AppFramework.logging.outputLocation.toString()) {
            return;
        }

        var fileName = "%1.log"
        .arg(Helper.dateStamp());

        var fileInfo = logsFolder.fileInfo(fileName);
        AppFramework.logging.outputLocation = fileInfo.url;
    }

    //--------------------------------------------------------------------------
}
