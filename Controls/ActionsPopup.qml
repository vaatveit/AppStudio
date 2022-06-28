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

import "Singletons"

PageLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias text: textLabel.text
    property alias informativeText: informativeLabel.text
    property alias detailedText: detailedLabel.text
    property alias prompt: promptLabel.text

    property alias textLabel: textLabel
    property alias detailedLabel: detailedLabel
    property alias informativeLabel: informativeLabel
    property alias promptLabel: promptLabel

    property alias actionsLayout: actionsLayout
    property alias actionGroup: actionGroup

    property alias message: textLabel.text // TODO deprecate
    property alias question: promptLabel.text // TODO Deprecate

    property alias headerSeparator: headerSeparator
    property alias bodyLayout: bodyLayout

    property url baseUrl

    //--------------------------------------------------------------------------

    signal textClicked()
    signal textPressAndHold()
    signal detailedTextClicked()
    signal detailedTextPressAndHold()
    signal informativeTextClicked()
    signal informativeTextPressAndHold()
    signal promptClicked()
    signal promptPressAndHold()

    //--------------------------------------------------------------------------

    closePolicy: Popup.NoAutoClose
    width: Math.min(parent.width * 0.8, 350 * AppFramework.displayScaleFactor)

    titleSeparator.visible: false
    titleLabel.font.pointSize: 18
    spacing: 10 * AppFramework.displayScaleFactor

    palette {
        window: "#eee"
        button: "white"
        light: "#f0fff0"
    }

    padding: 1 * AppFramework.displayScaleFactor
    topPadding: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var objects = contentLayout.resources;

        for (var i = 0; i < objects.length; i++) {
            if (AppFramework.instanceOf(objects[i], "QQuickAction")) {
                actionGroup.addAction(objects[i]);
            }
        }
    }

    //--------------------------------------------------------------------------

    ActionGroup {
        id: actionGroup
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: popup.spacing

        spacing: popup.spacing

        PopupLabel {
            id: textLabel

            Layout.fillWidth: true
            Layout.leftMargin: 10 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: text > ""
            baseUrl: popup.baseUrl

            onClicked: {
                textClicked();
            }

            onPressAndHold: {
                textPressAndHold();
            }
        }

        PopupLabel {
            id: detailedLabel

            Layout.fillWidth: true
            Layout.leftMargin: 10 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: text > ""
            baseUrl: popup.baseUrl

            onClicked: {
                detailedTextClicked();
            }

            onPressAndHold: {
                detailedTextPressAndHold();
            }
        }

        PopupLabel {
            id: informativeLabel

            Layout.fillWidth: true
            Layout.leftMargin: 10 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: text > ""
            baseUrl: popup.baseUrl

            onClicked: {
                informativeTextClicked();
            }

            onPressAndHold: {
                informativeTextPressAndHold();
            }
        }

        PopupLabel {
            id: promptLabel

            Layout.fillWidth: true
            Layout.leftMargin: 10 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: text > ""
            baseUrl: popup.baseUrl

            onLinkActivated: {
                ControlsSingleton.openLink(link);
            }

            onClicked: {
                promptClicked();
            }

            onPressAndHold: {
                promptPressAndHold();
            }
        }

        Item {
            id: headerSeparator

            Layout.fillWidth: true

            HorizontalSeparator {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: -parent.Layout.leftMargin
                    rightMargin: -parent.Layout.rightMargin
                    top: parent.bottom
                    topMargin: contentLayout.spacing
                }

                opacity: 0.5
            }
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: bodyLayout

        Layout.fillWidth: true

        spacing: 0
        visible: children.length > 0
    }

    //--------------------------------------------------------------------------

    ActionGroupLayout {
        id: actionsLayout

        Layout.fillWidth: true
        Layout.topMargin: 2 * AppFramework.displayScaleFactor

        actionGroup: actionGroup
    }

    //--------------------------------------------------------------------------
}
