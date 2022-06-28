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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"


Item {
    id: progressPanel
    
    //--------------------------------------------------------------------------

    property alias title: progressPopup.title
    property alias message: messageText.text
    property alias progressBar: progressBar
    property alias icon: progressPopup.icon
    property alias iconAnimation: progressPopup.iconAnimation
    property alias popup: progressPopup

    //--------------------------------------------------------------------------

    function open() {
        progressBar.value = 0;
        progressPopup.open();
    }

    function close() {
        progressPopup.close();
    }

    function closeSuccess(text) {
        messagePopup.showInfo(text);
    }

    function closeWarning(text, warnings) {
        if (Array.isArray(warnings)) {
            var warningsText = "";
            warnings.forEach(function (element) {
                warningsText += element + "\n";
            });

            messagePopup.showWarning(text, undefined, warningsText);
        } else {
            messagePopup.showWarning(text, undefined, JSON.stringify(warnings, undefined, 2));
        }
    }

    function closeError(text, message, details, report) {
        messagePopup.showError(text, message, details, report);
    }

    //--------------------------------------------------------------------------

    PageLayoutPopup {
        id: progressPopup

        parent: app

        closePolicy: Popup.NoAutoClose
        width: Math.min(parent.width * 0.8, 400 * AppFramework.displayScaleFactor)

        spacing: 10 * AppFramework.displayScaleFactor
        margins: 20 * AppFramework.displayScaleFactor

        palette {
            window: "#eee"
            button: "white"
            light: "#f0fff0"
            dark: app.titleBarBackgroundColor
        }

        padding: 10 * AppFramework.displayScaleFactor

        icon.name: "refresh"
        iconAnimation: PageLayoutPopup.IconAnimation.Rotate
        titleSeparator.visible: false

        AppText {
            id: messageText

            Layout.fillWidth: true

            visible: text > ""
            font {
                pointSize: 16
            }

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        ProgressBar {
            id: progressBar

            Layout.fillWidth: true
            Layout.margins: 20 * AppFramework.displayScaleFactor

            height: 20 * AppFramework.displayScaleFactor

            from: 0
            to: 1
            indeterminate: value === from

            property alias minimumValue: progressBar.from
            property alias maximumValue: progressBar.to
        }
    }

    //--------------------------------------------------------------------------

    MessagePopup  {
        id: messagePopup

        parent: app
        width: scrollView.visible
               ? parent.width * 0.8
               : Math.min(parent.width * 0.8, 350 * AppFramework.displayScaleFactor)

        standardButtons: StandardButton.Ok
        headerSeparator.visible: scrollView.visible

        bodyLayout.children: [
            ScrollView {
                id: scrollView

                Layout.fillWidth: true
                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                Layout.rightMargin: Layout.leftMargin
                Layout.maximumHeight: ControlsSingleton.inputTextHeight * 10

                visible: scrollArea.text > ""

                TextArea {
                    id: scrollArea

                    width: scrollView.availableWidth

                    readOnly: true

                    font {
                        family: messagePopup.font.family
                        pointSize: ControlsSingleton.inputFont.pointSize
                    }

                    onLinkActivated: {
                        ControlsSingleton.openLink(link);
                    }
                }
            }
        ]

        Action {
            id: reportAction

            enabled: text > ""
            icon.name: "envelope"

            onTriggered: {
                messagePopup.close();
                messagePopup.reportError();
            }
        }

        function showInfo(text, informativeText, detailedText) {
            show(StandardIcon.Information, text, informativeText, detailedText);
        }

        function showError(text, informativeText, detailedText, report) {
            show(StandardIcon.Critical, text, informativeText, detailedText, report);
        }

        function showWarning(text, informativeText, detailedText) {
            show(StandardIcon.Warning, text, informativeText, detailedText);
        }

        function show(_icon, _text, _informativeText, _detailedText, report) {
            progressPopup.close();

            standardIcon = _icon;
            title = _text || "";
            informativeText = _informativeText || "";
            //detailedText = _detailedText || "";
            scrollArea.text = _detailedText || "";
            reportAction.text  = report
                    ? qsTr("Report this error")
                    : "";

            messagePopup.open();
        }

        function reportError() {
            var urlInfo = AppFramework.urlInfo("mailto:survey123@esri.com");

            urlInfo.queryParameters = {
                "subject": "ArcGIS Survey123 Service Error Report",
                "body": "Error Report Details\n\n" +
                        informativeText +
                        "\n\n" +
                        detailedText +
                        "\n\nOperating system: " + Qt.platform.os +
                        "\nApplication version: " + app.info.version +
                        "\nFramework version: " + AppFramework.version +
                        "\n\n[Please add any further comments here]"
            };

            Qt.openUrlExternally(urlInfo.url);
        }
    }

    //--------------------------------------------------------------------------
}
