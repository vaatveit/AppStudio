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

import ArcGIS.AppFramework 1.0

import "../Portal"
import "XForm.js" as XFormJS

Item {
    id: _webhooks

    //--------------------------------------------------------------------------

    property Portal portal
    property var webhooks
    property bool debug: true

    //--------------------------------------------------------------------------

    readonly property string kEventAddData: "addData"
    readonly property string kEventEditData: "editData"

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(_webhooks, true)
    }

    //--------------------------------------------------------------------------

    onWebhooksChanged: {
        console.log("onWebhooksChanged:", JSON.stringify(webhooks));
    }

    //--------------------------------------------------------------------------

    function handleEvent(event, callback) {
        if (!Array.isArray(webhooks)) {
            console.error(logCategory, arguments.callee.name, "No webhooks defined");
            return;
        }

        console.log(logCategory, arguments.callee.name, "event:", event);

        webhooks.forEach(function (webhook) {
            if (handlesEvent(webhook, event)) {
                callback(webhook, event);
            }
        });
    }

    //--------------------------------------------------------------------------

    function handlesEvent(webhook, event) {
        if (!webhook.active) {
            console.log(logCategory, "Not active");
            return;
        }

        if (!Array.isArray(webhook.events)) {
            console.log(logCategory, "Events not an array");
            return;
        }

        if (webhook.events.indexOf(event) < 0) {
            console.log(logCategory, "Event not found:", event);
            return;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function submit(surveyInfo, featureService, applyEdits, response) {
        if (!Array.isArray(webhooks)) {
            console.log(logCategory, arguments.callee.name, "No webhooks defined");
            return;
        }

        function findEdits(layerId) {
            for (var edits of applyEdits) {
                if (edits.id === layerId) {
                    return edits;
                }
            }
        }

        function findEditsResponse(layerId) {
            for (var editsResponse of response) {
                if (editsResponse.id === layerId) {
                    return editsResponse;
                }
            }
        }

        function findRelated(edits, parentKey, keyField) {
            var features = [];

            if (Array.isArray(edits.adds)) {
                for (var add of edits.adds) {
                    if (add[keyField] === parentKey) {
                        features.push(add);
                    }
                }
            }

            if (Array.isArray(edits.updates)) {
                for (var update of edits.updates) {
                    if (update[keyField] === parentKey) {
                        features.push(update);
                    }
                }
            }

            return features;
        }

        function addRepeat(parentFeature, parentLayer, parentTable, relatedTable) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "parentLayer:", parentLayer.id, "parentTable:", parentTable.name, "relatedTable:", relatedTable.name);
            }

            var relatedLayer = featureService.findLayer(relatedTable.name);
            if (!relatedLayer) {
                console.error(logCategory, arguments.callee.name, "relatedLayer not found:", relatedTable.name);
                return;
            }

            var parentRelationship = featureService.findRelationship(parentLayer, relatedLayer);
            if (!parentRelationship) {
                console.error(logCategory, arguments.callee.name, "parentRelationship not found parentLayer:", parentLayer.name, "relatedLayer:", relatedLayer.name);
                return;
            }

            var childRelationship = featureService.findRelationship(relatedLayer, parentLayer);
            if (!childRelationship) {
                console.error(logCategory, arguments.callee.name, "childRelationship not found relatedLayer:", relatedLayer.name, "parentLayer:", parentLayer.name);
                return;
            }

            var edits = findEdits(relatedLayer.id);
            if (!edits) {
                console.log(logCategory, arguments.callee.name, "No edits for relatedLayer:", relatedLayer.id, relatedLayer.name);
                return;
            }

            var parentKeyField = parentRelationship.keyField;
            var childKeyField = childRelationship.keyField;

            var relatedFeatures = findRelated(edits, parentFeature[parentKeyField], childKeyField);
            if (!relatedFeatures.length) {
                return;
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "relatedFeatures:", relatedFeatures.length);
            }

            if (!parentFeature.repeats) {
                parentFeature.repeats = {};
            }

            parentFeature.repeats[relatedTable.name] = relatedFeatures;

            var relatedLayerInfo = {
                "id": relatedLayer.id,
                "name": relatedLayer.name
            };

            for (var relatedFeature of relatedFeatures) {
                relatedFeature.layerInfo = relatedLayerInfo;
                addRepeats(relatedFeature, relatedLayer, relatedTable);
                addAttachments(relatedFeature, relatedLayer, relatedTable, edits);
            }
        }

        function addRepeats(parentFeature, parentLayer, parentTable) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "parentTable:", parentTable.name, "relatedTables:", parentTable.relatedTables.length);
            }

            for (var relatedTable of parentTable.relatedTables) {
                addRepeat(parentFeature, parentLayer, parentTable, relatedTable);
            }
        }


        function addAttachments(feature, layer, table, edits) {
            var featureGlobalId = feature.attributes[layer.globalIdField];

            function findAttachments() {
                var attachments = [];

                function addAttachmentEdits(attachmentEdits, editResults) {
                    if (!Array.isArray(attachmentEdits) || !Array.isArray(editResults)) {
                        return;
                    }

                    for (var edit of attachmentEdits) {
                        if (edit.parentGlobalId !== featureGlobalId) {
                            continue;
                        }

                        var editResult = editResults.find(result => result.globalId === edit.globalId);

                        if (!editResult) {
                            console.error(logCategory, arguments.callee.name, "No edit result for edit:", edit.globalId)
                        }

                        var attachment = JSON.parse(JSON.stringify(edit));

                        delete attachment.uploadId;
                        attachment.id = editResult.objectId;
                        attachment.url = "%1/%2/%3/attachments/%4"
                        .arg(featureService.featureServiceInfo.url)
                        .arg(layer.id)
                        .arg(feature.result.objectId)
                        .arg(editResult.objectId);

                        attachments.push(attachment);
                    }
                }

                var editsAttachments = edits.attachments;
                if (!editsAttachments) {
                    return;
                }

                var editsResponse = findEditsResponse(edits.id);
                if (!editsResponse) {
                    console.error(logCategory, arguments.callee.name, "edits response not found for edits:", edits.id);
                    return;
                }

                var attachmentsResponse = editsResponse.attachments;
                if (!attachmentsResponse) {
                    console.error(logCategory, arguments.callee.name, "attachments response not found for edits:", edits.id);
                    return;
                }

                addAttachmentEdits(editsAttachments.adds, attachmentsResponse.addResults);
                addAttachmentEdits(editsAttachments.updates, attachmentsResponse.updateResults);

                if (Array.isArray(edits.updates)) {
                    for (var update of edits.updates) {
                        if (update[keyField] === parentKey) {
                            addAttachment(update);
                        }
                    }
                }

                return attachments;
            }

            var attachments = findAttachments();

            if (!attachments || !attachments.length) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "no attachments for featureGlobalId:", featureGlobalId);
                }
                return;
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "featureGlobalId:", featureGlobalId, "attachments:", attachments.length);
            }

            if (!feature.attachments) {
                feature.attachments = {};
            }

            for (var attachment of attachments) {
                var fieldName = attachment.keywords;
                if (!Array.isArray(feature.attachments[fieldName])) {
                    feature.attachments[fieldName] = [];
                }

                feature.attachments[fieldName].push(attachment);
            }
        }

        var _surveyInfo = {
            "formItemId": surveyInfo.itemId,
            "formTitle": surveyInfo.title,
            "serviceItemId": featureService.featureServiceInfo.itemId,
            "serviceUrl": featureService.featureServiceInfo.url
        }

        var rootEdits = applyEdits[0];
        var rootLayerId = rootEdits["id"];
        var rootLayer = featureService.findLayer(rootLayerId, true);
        var rootTable = featureService.schema.schema;
        var rootEvent;
        var rootFeature;

        if (Array.isArray(rootEdits.adds) && rootEdits.adds.length > 0) {
            rootEvent = kEventAddData;
            rootFeature = rootEdits.adds[0];
        } else if (Array.isArray(rootEdits.updates) && rootEdits.updates.length > 0) {
            rootEvent = kEventEditData;
            rootFeature = rootEdits.updates[0];
        }

        if (!rootFeature) {
            return;
        }

        rootFeature["layerInfo"] = {
            "id": rootLayer.id,
            "name": rootLayer.name
        }

        addRepeats(rootFeature, rootLayer, rootTable);
        addAttachments(rootFeature, rootLayer, rootTable, rootEdits);

        handleEvent(rootEvent, function (webhook, event) {

            var payload = {
                "eventType": rootEvent,
                "feature": rootFeature
            };

            if (webhook.includeServiceRequest) {
                payload["applyEdits"] = applyEdits;
            }

            if (webhook.includeServiceResponse) {
                payload["response"] = response;
            }

            if (webhook.includeSurveyInfo) {
                payload["surveyInfo"] = _surveyInfo;
            }

            sendRequest(webhook, event, payload);
        });
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: webhookRequest

        method: "POST"

        onReadyStateChanged: {
            if (readyState === NetworkRequest.DONE ) {
            }
        }

        function sendRequest(webhook, event, payload) {
            url = webhook.url;

            headers.json = {
                "Content-Type": "application/json",
                "X-Survey123-Event": event,
                "X-Survey123-Signature": webhook.secret,
                "X-Survey123-Delivery": AppFramework.createUuidString(1)
            };

            send(payload);
        }
    }

    //--------------------------------------------------------------------------

    function sendRequest(webhook, event, payload) {

        if (webhook.includePortalInfo) {
            var portalInfo = {
                "url": portal.portalUrl.toString(),
                "token": portal.token
            };

            payload.portalInfo = portalInfo;
        }

        if (webhook.includeUserInfo) {
            var userInfo = {
                "username": XFormJS.userProperty(app, 'username'),
                "firstName": XFormJS.userProperty(app, 'firstName'),
                "lastName": XFormJS.userProperty(app, 'lastName'),
                "fullName": XFormJS.userProperty(app, 'fullName'),
                "email": XFormJS.userProperty(app, 'email'),
            };

            payload.userInfo = userInfo;
        }

        console.log(logCategory, arguments.callee.name, "event:", event, "webhook:", JSON.stringify(webhook, undefined, 2), "payload:", JSON.stringify(payload, undefined, 2));

        var request = new XMLHttpRequest();

        request.onreadystatechange = function() {
            console.log("request.onreadystatechange event:", event, "readyState:", request.readyState);
        }

        request.open("POST", webhook.url);

        request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setRequestHeader("X-Survey123-Event", event);
        request.setRequestHeader("X-Survey123-Delivery", AppFramework.createUuidString(1));
        //request.setRequestHeader("X-Survey123-Signature", webhook.secret);

        var data = JSON.stringify(payload, undefined, 2);

        request.send(data);
    }

    //--------------------------------------------------------------------------
}

