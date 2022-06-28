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
import QtQml 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../XForms"
import "../XForms/Singletons"

import "../XForms/XForm.js" as XFormJS
import "../template/SurveyHelper.js" as Helper

import "../Controls"
import "../Controls/Singletons"
import "Singletons"

SurveyFolderPage {
    id: page

    //--------------------------------------------------------------------------

    property var submitItems
    property bool autoSubmit: false
    property bool autoDelete: false

    property bool submitting: false
    property bool isPublic: false

    property alias objectCache: xformFeatureService.objectCache
    property int errors

    //--------------------------------------------------------------------------

    folderName: qsTr("Saved Forms")
    folderColor: Survey.kColorFolderOutbox
    statusFilter: XForms.Status.Complete
    statusFilter2: XForms.Status.SubmitError
    mapKey: Survey.kFolderOutbox
    showErrorIcon: true
    closeOnEmpty: true

    backButton {
        onClicked: {
            deleteSubmitted();
        }
    }

    //--------------------------------------------------------------------------

    folderAction {
        enabled: portal.isOnline && surveyDataModel.count > 0

        text: qsTr("Send")
        icon.name: "outbox"
        checkable: submitting

        onTriggered: {
            submitDatabase();
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (surveyDataModel.count < 1 && closeOnEmpty) {
            Qt.callLater(page.closePage);
        } else if (autoSubmit) {
            Qt.callLater(submitDatabase);
        }
    }

    Component.onDestruction: {
        deleteSubmitted();
    }

    //--------------------------------------------------------------------------

    onInitializeParameters: {
        console.log(logCategory, "onInitializeParameters:", mapKey);

        autoTriggerFolderAction = XFormJS.toBoolean(Helper.getPropertyValue(parameters, Survey.kParameterUpdate));
    }

    //--------------------------------------------------------------------------

    Rectangle {
        parent: app
        anchors.fill:  parent
        color: "#40000000"
        visible: submitting

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }
    }

    //--------------------------------------------------------------------------

    function submitDatabase() {
        console.log(logCategory, arguments.callee.name, "isPublic:", isPublic, "count:", surveyDataModel.count);

        if (surveyDataModel.count < 1) {
            return;
        }

        if (isPublic) {
            submitStart();
        } else {
            portal.signInAction(qsTr("Please sign in to send surveys"), submitStart);
        }
    }

    function submitStart() {
        if (!surveyDataModel.count) {
            return;
        }

        submitItems = [];
        for (var i = 0; i < surveyDataModel.count; i++) {
            submitItems.push(JSON.parse(JSON.stringify(surveyDataModel.get(i))));
        }

        submitting = true;
        progressPanel.open();
        errors = 0;
        submitNext();
    }

    function submitNext() {
        if (!submitItems.length) {
            submitComplete();
            return;
        }

        submitData(submitItems.shift());
    }

    function submitComplete() {
        submitting = false;
        showErrorIcon = errors > 0;
        if (errors) {
            progressPanel.closeError(
                        qsTr("Send Error"),
                        qsTr("Surveys not sent: %1").arg(errors));
        } else {
            progressPanel.close();
        }
        refreshList();
    }

    //--------------------------------------------------------------------------

    function submitData(row) {
        console.log(logCategory, arguments.callee.name, "rowid:", row.rowid, "name:", row.name, "data:", JSON.stringify(row.data, undefined, 2), "feature", row.feature);

        var surveyPath = row.path;

        xformFeatureService.setRow(row);

        if (xformFeatureService.isReady(surveyPath)) {
            xformFeatureService.serviceReady();
        } else {
            getServiceInfo(surveyPath);
        }
    }

    //--------------------------------------------------------------------------

    function getServiceInfo(surveyPath) {

        function setFeatureService(serviceInfo) {
            console.log("setFeatureService serviceInfo:", JSON.stringify(serviceInfo, undefined, 2));

            var itemId = serviceInfo.id ? serviceInfo.id : serviceInfo.itemId;
            var url = serviceInfo.url;
            var urlInfo = AppFramework.urlInfo(url);

            if (portal.ssl) {
                urlInfo.scheme = "https";
            }

            console.log("setFeatureService url:", urlInfo.url);

            xformFeatureService.surveyPath = surveyPath;
            if (itemId) {
                xformFeatureService.featureServiceItemId = itemId;
            }
            xformFeatureService.featureServiceUrl = urlInfo.url;
        }

        function getSurveyServiceInfo() {
            var submissionUrl = getSubmissionUrl(surveyPath);
            if (submissionUrl > "") {
                return {
                    url: submissionUrl
                };
            }

            // Fallback for backwards compatibility for old surveys

            console.warn("Falling back to serviceInfo in .info");

            var surveyInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".info");

            return surveyInfo.serviceInfo;
        }

        var surveyFileInfo = AppFramework.fileInfo(surveyPath);
        var surveyItemInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".itemInfo");

        progressPanel.title = qsTr("Getting service information");

        if (surveyItemInfo.id > "" && surveyItemInfo.type === "Form") {
            survey2ServiceRequest.requestUrl(surveyItemInfo.id,
                                             function (serviceItem) {
                                                 console.log("Survey2Service:", JSON.stringify(serviceItem, undefined, 2));

                                                 if (serviceItem) {
                                                     setFeatureService(serviceItem);
                                                 } else {
                                                     setFeatureService(getSurveyServiceInfo())
                                                 }
                                             },
                                             function (error) {
                                                 xformFeatureService.failed(error);
                                             });
        } else {
            setFeatureService(getSurveyServiceInfo())
        }
    }

    //--------------------------------------------------------------------------

    function getSubmissionUrl(surveyPath) {
        var xml = AppFramework.userHomeFolder.readTextFile(surveyPath);
        var json = AppFramework.xmlToJson(xml);

        var submission = {};

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;
        }

        console.log("submission:", JSON.stringify(submission, undefined, 2));

        return submission["@action"];
    }

    //--------------------------------------------------------------------------

    function deleteSubmitted() {
        if (autoDelete) {
            surveysDatabase.deleteSurveys(XForms.Status.Submitted);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: survey2ServiceRequest

        property var resolve
        property var reject

        portal: app.portal

        onSuccess: {
            console.log("Survey2Service:", JSON.stringify(response, undefined, 2));

            if (response.total > 0) {
                var relatedItem = response.relatedItems[0];
                resolve(relatedItem);
            } else {
                resolve();
            }
        }

        onFailed: {
            reject(error);
        }

        onProgressChanged: {
        }

        function requestUrl(itemId, _resolve, _reject) {
            resolve = _resolve;
            reject = _reject;

            url = portal.restUrl + "/content/items/" + itemId + "/relatedItems";

            sendRequest({
                            "relationshipType": "Survey2Service",
                            "direction": "forward"
                        });
        }
    }

    //--------------------------------------------------------------------------

    XFormFeatureService {
        id: xformFeatureService

        property string surveyPath
        property var rowId
        property string rowLabel
        property var rowFeatureData
        property var rowInstanceData
        property bool sentEnabled: true

        portal: app.portal
        schema: page.schema
        webhooks: _webhooks


        SurveyInfo {
            id: surveyInfo

            path: xformFeatureService.surveyPath

            onPathChanged: {
                readInfo();

                xformFeatureService.sentEnabled = XFormJS.toBoolean(sentInfo.enabled, true);
            }
        }

        XFormWebhooks {
            id: _webhooks

            portal: app.portal
            webhooks: surveyInfo.notificationsInfo.webhooks
        }

        onServiceReady: {
            console.log("Sending row:", rowId, rowLabel);

            progressPanel.title = qsTr("Sending %1").arg(rowLabel);
            //            applyData(rowFeatureData, rowInstanceData);
            applyData(rowInstanceData);
        }

        onApplied: {
            console.log("Feature service applied edits:", JSON.stringify(edits.summary, undefined, 2), "instanceData:", JSON.stringify(instanceData, undefined, 2));

            if (sentEnabled) {
                surveysDatabase.updateDataStatus(rowId, instanceData, XForms.Status.Submitted, JSON.stringify(edits.summary));
            } else {
                console.log("Deleting submitted survey:", rowId);
                surveysDatabase.deleteSurvey(rowId);
            }

            submitNext();
        }

        onFailed: {
            console.log("Feature service error:", JSON.stringify(error, undefined, 2));

            surveysDatabase.updateStatus(rowId, XForms.Status.SubmitError, JSON.stringify(error));
            errors++;
            featureServiceUrl = "";
            submitNext();
        }

        function isReady(path) {
            return surveyPath === path && featureServiceUrl > "" && featureServiceInfo;
        }

        function setRow(row) {
            rowId = row.rowid;
            rowLabel = row.snippet > "" ? row.snippet : "";
            rowFeatureData = row.feature;
            rowInstanceData = row.data;
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        parent: app
        message: xformFeatureService.progressMessage
        progressBar.value: xformFeatureService.progress
        icon.name: "upload"
        iconAnimation: PageLayoutPopup.IconAnimation.Pulse
    }

    //--------------------------------------------------------------------------
}
