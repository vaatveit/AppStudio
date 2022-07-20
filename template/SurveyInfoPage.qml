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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls/Singletons"
import "../Controls"
import "../XForms"
import "../XForms/Singletons"
import "../XForms/XForm.js" as XFormJS
import "SurveyHelper.js" as Helper
import "Singletons"

AppPage {
    id: surveyPage

    //--------------------------------------------------------------------------

    property alias surveyPath: surveyInfo.path
    property var parameters: ({})
    property alias itemsetsData: itemsetsData

    property bool deleted: false
    property bool collectEnabled: true
    property bool overviewEnabled: false
    property bool _overviewEnabled :false // TODO: Remove after overview beta

    property real imageScaleFactor: 0.75
    property int actionHeight: 70 * AppFramework.displayScaleFactor

    property QC1.StackView stackView: surveyPage.QC1.Stack.view

    readonly property bool isLandscape: app.features.enableSxS && width > height


    readonly property var kFolderActions: {
        "inbox": inboxAction,
        "drafts": draftsAction,
        "outbox": outboxAction,
        //"sent": sentAction,  ///Remove Sent Button? BPDS
        "all": overviewAction,
        "*": overviewAction,
    }

    readonly property string kGlyphCollect: "plus"
    readonly property string kGlyphInbox: "inbox"
    readonly property string kGlyphDrafts: "edit-attributes"
    readonly property string kGlyphOutbox: "outbox"
    readonly property string kGlyphSent: "send"
    readonly property string kGlyphOverview: "layers-reference"

    //--------------------------------------------------------------------------

    title: surveyInfo.title

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "parameters:", JSON.stringify(parameters, undefined, 2));

        collectEnabled = XFormJS.toBoolean(surveyInfo.collectInfo.enabled, true);
        overviewEnabled = XFormJS.toBoolean(surveyInfo.overviewInfo.enabled, false);
        _overviewEnabled = surveyInfo.settings.boolValue(surveyInfo.kKeyOverviewEnabled, false);


        if (surveyMapSources.autoRefresh) {
            surveyMapSources.autoRefresh = false;
            surveyMapSources.refresh();
        }

        if (!parameters) {
            parameters = {};
        } else if (parameters.folder > "") {
            var folder = parameters.folder.trim().toLowerCase();
            var folderAction = kFolderActions[folder];
            if (folderAction) {
                Qt.callLater(folderAction.triggered);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        surveyInfo.settings.setValue(surveyInfo.kKeyOverviewEnabled, _overviewEnabled, false);

        if (deleted) {
            surveysFolder.update();
        }
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        if (!overviewEnabled) {
            _overviewEnabled = !_overviewEnabled;
        }
    }

    //--------------------------------------------------------------------------

    actionComponent: AppDrawerButton {
        Action {
            text: qsTr("Delete Survey from mobile device")   // BPDS updated text
            icon {
                name: "trash"
                color: Survey.kColorWarning
            }

            onTriggered: {
                deleteSurveyPopup.createObject(surveyPage).open();
            }
        }

        Action {
            text: qsTr("Offline Maps")
            icon.name: "download"
            enabled: Networking.isOnline

            onTriggered: {
                stackView.push({
                                   item: downloadMaps,
                                   properties: {
                                       surveyPath: surveyPath,
                                       surveyInfoPage: surveyPage
                                   }
                               });
            }
        }

        Action {
            text: qsTr("Show QR Code")
            icon.name: "qr-code"
            enabled: surveyInfo.itemId > ""

            onTriggered: {
                showQRCode();
            }
        }
    }

    //--------------------------------------------------------------------------

    function restartSurvey() {
        var surveyPath = surveyPage.surveyPath;

        stackView.push({
                           item: surveyView,
                           replace: true,
                           properties: {
                               surveyPath: surveyPath,
                               surveyInfoPage: surveyPage,
                               rowid: null,
                               surveyMapSources: surveyMapSources
                           }
                       });
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveyPage, true)
    }

    //--------------------------------------------------------------------------

    XFormItemsetsData {
        id: itemsetsData
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo

        updateXFormInfo: true
    }

    //--------------------------------------------------------------------------

    SurveyMapSources {
        id: surveyMapSources

        portal: app.portal
        itemId: surveyInfo.itemId
        cacheFolder: surveyInfo.folder
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        readonly property int activationMode: appSettings.locationSensorActivationMode

        positionSourceManager: app.positionSourceManager
        stayActiveOnError: activationMode >= appSettings.kActivationModeInSurvey
        listener: "SurveyInfoPage"

        Component.onCompleted: {
            checkActivationMode();
        }

        onActivationModeChanged: {
            checkActivationMode();
        }

        function checkActivationMode() {
            if (activationMode >= appSettings.kActivationModeInSurvey) {
                start();
            } else {
                stop();
            }
        }
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Image {
            anchors {
                fill: parent
                margins: -contentMargins
            }

            visible: !app.appSettings.plainBackgrounds
            fillMode: Image.PreserveAspectCrop
            opacity: 0.1
            source: surveyInfo.thumbnail
        }

        GridLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
                bottomMargin: 0
            }

            columnSpacing: 10 * AppFramework.displayScaleFactor
            rowSpacing: columnSpacing
            columns: isLandscape ? 3 : 1
            layoutDirection: ControlsSingleton.localeProperties.layoutDirection

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: 10 * AppFramework.displayScaleFactor
                        layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 200 * AppFramework.displayScaleFactor * imageScaleFactor
                            Layout.preferredHeight: 133 * AppFramework.displayScaleFactor * imageScaleFactor
                            Layout.maximumWidth: 200 * AppFramework.displayScaleFactor * imageScaleFactor
                            Layout.maximumHeight: 133 * AppFramework.displayScaleFactor * imageScaleFactor

                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                            source: surveyInfo.thumbnail

                            Rectangle {
                                anchors.fill: parent

                                color: "transparent"
                                border {
                                    width: 1
                                    color: "#20000000"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onPressAndHold: {
                                    Qt.openUrlExternally(surveyInfo.folder.url);
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 4 * AppFramework.displayScaleFactor

                            AppText {
                                Layout.fillWidth: true

                                text: surveyInfo.snippet
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                color: "#323232" //textColor
                                visible: text > ""
                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                                font {
                                    pointSize: 16
                                    bold: true
                                }
                                maximumLineCount: 3
                                elide: ControlsSingleton.localeProperties.textElide

                                onLinkActivated: {
                                    Qt.openUrlExternally(link);
                                }
                            }

                            AppText {
                                Layout.fillWidth: true

                                text: qsTr("Version: %1").arg(surveyInfo.version)
                                visible: surveyInfo.version > ""
                                color: textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                            }

                            AppText {
                                Layout.fillWidth: true

                                text: qsTr("Owner: %1").arg(surveyInfo.owner)
                                visible: surveyInfo.owner > ""
                                color: textColor
                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment

                                MouseArea {
                                    anchors.fill: parent

                                    onPressAndHold: {
                                        var url = "%1/home/user.html?user=%2".arg(portal.portalUrl).arg(surveyInfo.owner);

                                        console.log("Opening user page:", url);

                                        Qt.openUrlExternally(url);
                                    }
                                }
                            }

                            AppText {
                                Layout.fillWidth: true

                                text: qsTr("Created: %1").arg(localeProperties.formatDateTime(surveyInfo.created, Locale.ShortFormat))
                                visible: surveyInfo.created > 0
                                color: textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                            }

                            AppText {
                                Layout.fillWidth: true

                                text: qsTr("Modified: %1").arg(localeProperties.formatDateTime(surveyInfo.modified, Locale.ShortFormat))
                                visible: surveyInfo.modified > 0
                                color: textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                            }
                        }
                    }

                    HorizontalSeparator {
                        Layout.fillWidth: true

                        visible: descriptionText.text > ""
                    }

                    ScrollView {
                        id: scrollView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        contentWidth: availableWidth

                        AppText {
                            id: descriptionText

                            width: scrollView.availableWidth
                            text: surveyInfo.description
                            textFormat: Text.RichText
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                            horizontalAlignment: ControlsSingleton.localeProperties.textAlignment

                            font {
                                pointSize: 18 //original size was 12  (BPDS)
                                bold: app.appSettings.boldText
                            }

                            onLinkActivated: {
                                Qt.openUrlExternally(link);
                            }
                        }
                    }
                }
            }

            VerticalSeparator {
                Layout.fillHeight: true

                visible: isLandscape
            }

            ListView {
                property int maxHeight: enabledCount() * (actionHeight + spacing)
                Layout.fillWidth: true
                //Layout.fillHeight: true
                Layout.preferredHeight: maxHeight

                model: actions.resources
                spacing: 0//5 * AppFramework.displayScaleFactor
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                //interactive: height < maxHeight


                delegate: actionDelegate

                function enabledCount() {
                    var count = 0;
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].enabled) {
                            count++;
                        }
                    }
                    return count;
                }
            }
        }
    }

    Component {
        id: inboxFolderPage

        SurveyFolderPageInbox {
        }
    }

    Component {
        id: draftsFolderPage

        SurveyFolderPageDrafts {
            // add surveyInfo reference to all of these SurveyListPage objects
        }
    }

    Component {
        id: sentFolderPage

        SurveyFolderPageSent {
        }
    }

    Component {
        id: overviewFolderPage

        SurveyFolderPageOverview {
        }
    }

    Component {
        id: downloadMaps

        DownloadMapsPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: actionDelegate

        Rectangle {
            id: actionBackgound

            width: parent.width
            height: visible ? actionHeight : 0
            color: mouseArea.containsMouse
                   ? mouseArea.pressed
                     ? backgroundColor
                     : "#e1f0fb"
            : "#fefefe" //"#20000000" : "transparent"

            radius: height / 2 //4 * AppFramework.displayScaleFactor
            visible: modelData.enabled
            border {
                width: 1
                color: borderColor
            }

            RowLayout {
                id: actionLayout

                anchors {
                    fill: parent
                    leftMargin: actionBackgound.radius / 2
                    rightMargin: actionBackgound.radius / 2
                    topMargin: actionBackgound.radius / 4
                    bottomMargin: actionBackgound.radius / 4
                }

                layoutDirection: ControlsSingleton.localeProperties.layoutDirection
                spacing: 5 * AppFramework.displayScaleFactor

                Item {
                    readonly property int iconMargin: 4 * AppFramework.displayScaleFactor

                    Layout.preferredWidth: actionBackgound.height - iconMargin * 2
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.leftMargin: ControlsSingleton.localeProperties.isLeftToRight
                                       ? -actionLayout.anchors.leftMargin + iconMargin
                                       : 0

                    Layout.rightMargin: ControlsSingleton.localeProperties.isRightToLeft
                                        ? -actionLayout.anchors.rightMargin + iconMargin
                                        : 0
                    Layout.topMargin: -actionLayout.anchors.topMargin + iconMargin
                    //Layout.bottomMargin: -actionLayout.anchors.bottomMargin * 2// + iconMargin

                    Rectangle {
                        anchors {
                            fill: parent
                        }

                        radius: height / 2
                        color: backgroundColor

                        border {
                            width: 1 * AppFramework.displayScaleFactor
                            color: modelData.iconBorderColor
                        }

                        Glyph {
                            anchors {
                                fill: parent
                                margins: 12 * AppFramework.displayScaleFactor
                            }

                            name: modelData.icon.name
                            color: foregroundColor
                        }
                    }
                }

                AppText {
                    id: actionText

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 5 * AppFramework.displayScaleFactor
                    Layout.rightMargin: Layout.leftMargin

                    text: modelData.text
                    color: (mouseArea.containsMouse && mouseArea.pressed)
                           ? modelData.foregroundColor
                           : textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: ControlsSingleton.localeProperties.textAlignment

                    font {
                        bold: true
                        pointSize: 18
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Column {
                    Layout.minimumWidth: 50 * AppFramework.displayScaleFactor

                    spacing: 2 * AppFramework.displayScaleFactor

                    CountIndicator {
                        anchors {
                            left: ControlsSingleton.localeProperties.isRightToLeft ? parent.left : undefined
                            right: ControlsSingleton.localeProperties.isLeftToRight ? parent.right : undefined
                        }

                        count: modelData.count
                        color: "transparent"
                        textColor: actionText.color
                        borderColor: "transparent"
                        textSize: 14
                    }

                    CountIndicator {
                        anchors {
                            left: ControlsSingleton.localeProperties.isRightToLeft ? parent.left : undefined
                            right: ControlsSingleton.localeProperties.isLeftToRight ? parent.right : undefined
                        }

                        color: Survey.kColorError
                        count: modelData.errorCount
                        textSize: 14
                    }
                }

                IconImage {
                    Layout.preferredWidth: 28 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    icon {
                        name: "chevron-right"
                        color: (mouseArea.containsMouse && mouseArea.pressed)
                               ? "white"
                               : actionText.color
                    }

                    mirror: ControlsSingleton.localeProperties.isRightToLeft
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    modelData.trigger();
                }

                onDoubleClicked: {
                }
            }
        }
    }

    Item {
        id: actions

        SurveyAction {
            id: collectAction

            enabled: collectEnabled
            backgroundColor: Survey.kColorCollect
            icon.name: kGlyphCollect
            text: qsTr("Continue")  // BPDS changed from "Collect" to "Start Here" to finally "Continue"
            tooltip: qsTr("Start collecting data")

            onTriggered: {
                stackView.push({
                                   item: surveyView,
                                   properties: {
                                       surveyPath: surveyPath,
                                       surveyInfoPage: surveyPage,
                                       rowid: null,
                                       surveyMapSources: surveyMapSources,
                                       parameters: parameters
                                   }
                               });
            }
        }

        SurveyAction {
            id: inboxAction

            count: surveysDatabase.statusCount(surveyPath, XForms.Status.Inbox, surveysDatabase.changed)
            backgroundColor: Survey.kColorFolderInbox

            text: qsTr("Inbox")
            tooltip: qsTr("Edit existing survey data")
            icon.name: kGlyphInbox
            enabled: count > 0 || (surveyInfo.queryInfo.mode > "" && Networking.isOnline)


            onTriggered: {
                stackView.push({
                                   item: inboxFolderPage,
                                   properties: {
                                       surveyPath: surveyPath,
                                       surveyInfoPage: surveyPage,
                                       surveyMapSources: surveyMapSources,
                                       parameters: parameters
                                   }
                               });
            }
        }

        SurveyAction {
            id: draftsAction

            count: surveysDatabase.statusCount(surveyPath, XForms.Status.Draft, surveysDatabase.changed)
            backgroundColor: Survey.kColorFolderDrafts

            text: qsTr("Drafts")
            tooltip: qsTr("Check draft collected data")
            icon.name: kGlyphDrafts
            enabled: count > 0

            onTriggered: {
                stackView.push({
                                   item: draftsFolderPage,
                                   properties: {
                                       surveyPath: surveyPath,
                                       surveyInfoPage: surveyPage,
                                       surveyMapSources: surveyMapSources,
                                       parameters: parameters
                                   }
                               });
            }
        }

        SurveyAction {
            id: outboxAction

            count: surveysDatabase.statusCount(surveyPath, XForms.Status.Complete, surveysDatabase.changed)
            errorCount: surveysDatabase.statusCount(surveyPath, XForms.Status.SubmitError, surveysDatabase.changed)
            backgroundColor: Survey.kColorFolderOutbox

            text: qsTr("Saved Forms (not sent)")
            tooltip: qsTr("Send your completed forms")  // BPDS updated text
            icon.name: kGlyphOutbox
            enabled: count > 0 || errorCount > 0

            onTriggered: {
                stackView.submitSurveys(
                            surveyPath,
                            false,
                            surveyInfo.isPublic,
                            parameters,
                            {
                                showErrorIcon: errorCount > 0
                            });
            }
        }

        // Commented out Sent Button (BPDS) --> This way can still paste EMAIL address as Favorite Answer
        //SurveyAction {
        //    id: sentAction

       //     count: surveysDatabase.statusCount(surveyPath, XForms.Status.Submitted, surveysDatabase.changed)
       //     backgroundColor: Survey.kColorFolderSent

       //     text: qsTr("Sent")
       //     tooltip: qsTr("Review sent survey data")
       //     icon.name: kGlyphSent
       //     enabled: count > 0

       //     onTriggered: {
       //         stackView.push({
       //                            item: sentFolderPage,
       //                            properties: {
       //                                surveyPath: surveyPath,
       //                                surveyInfoPage: surveyPage,
       //                                surveyMapSources: surveyMapSources,
       //                                parameters: parameters
       //                            }
       //                        });
       //     }
        //}

        SurveyAction {
            id: overviewAction

            count: surveysDatabase.surveyCount(surveyPath, surveysDatabase.changed)
            foregroundColor: Survey.kColorFolderOverview
            backgroundColor: "white"
            iconBorderColor: "#ccc"

            text: qsTr("Overview")
            tooltip: "Surveys overview"
            icon.name: kGlyphOverview
            enabled: overviewEnabled || _overviewEnabled

            onTriggered: {
                stackView.push({
                                   item: overviewFolderPage,
                                   properties: {
                                       surveyPath: surveyPath,
                                       surveyInfoPage: surveyPage,
                                       surveyMapSources: surveyMapSources,
                                       parameters: parameters
                                   }
                               });
            }
        }

    }

    //--------------------------------------------------------------------------

    Connections {
        id: signinConnections

        property Component showPage
        property var showProperties

        target: portal

        function onSignedInChanged() {
            if (portal.signedIn && signinConnections.showPage) {
                stackView.push({
                                   item: signinConnections.showPage,
                                   properties: signinConnections.showProperties
                               });
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: deleteSurveyPopup

        ActionsPopup {
            title: qsTr("Please Confirm Delete Form");  // BPDS updated text
            text: qsTr("The <b>%1</b> survey form and all survey records will be deleted from this device. All unsent data will be lost.").arg(surveyInfo.title);

            icon {
                name: "exclamation-mark-triangle"
                color: Survey.kColorWarning
            }

            Action {
                text: qsTr("Delete")
                icon {
                    name: "trash"
                    color: Survey.kColorWarning
                }

                onTriggered: {
                    deleteSurvey();
                    close();
                }
            }

            Action {
                text: qsTr("Cancel")
                icon.name: "x-circle"

                onTriggered: {
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurvey() {
        var surveyFolder = surveyInfo.fileInfo.folder;

        if (surveyFolder.folderName === "esriinfo") {
            surveyFolder.cdUp();
        }

        console.log("Delete Survey:", surveyFolder.path);

        surveysDatabase.deleteSurveyData(surveyPath);
        surveyFolder.removeFolder();

        deleted = true;
        parent.pop();
    }

    //--------------------------------------------------------------------------

    function showQRCode() {
        var url = Helper.createAppLink(
                    app.info.value("urlScheme"),
                    portal,
                    surveyInfo.itemInfo);

        console.log(logCategory, arguments.callee.name, "url:", url);

        var popup = qrCodePopup.createObject(surveyPage,
                                             {
                                                 title: surveyInfo.title,
                                                 value: url.toString(),
                                                 linkEnabled: false,
                                                 showValue: false
                                             });
        popup.open();
    }

    Component {
        id: qrCodePopup

        QRCodePopup {
        }
    }

    //--------------------------------------------------------------------------
}
