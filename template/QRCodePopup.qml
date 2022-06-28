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

import "../Controls"
import "../Controls/Singletons"

PageLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias value: qrCode.value
    readonly property UrlInfo urlInfo: AppFramework.urlInfo(value)
    readonly property bool isUrl: urlInfo.isValid && urlInfo.scheme > ""
    property bool linkEnabled: isUrl
    property bool showValue: false

    //--------------------------------------------------------------------------

    width: Math.min(parent.width * 0.80, 320 * AppFramework.displayScaleFactor)

    spacing: 10 * AppFramework.displayScaleFactor

    palette {
        window: app.backgroundColor
        windowText: app.textColor
        button: "white"
        light: "#f0fff0"
    }

    padding: 1 * AppFramework.displayScaleFactor
    topPadding: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        title = qsTr("Create QR Code");
        showValue = false;
        valueField.visible = true;
        valueField.text = value;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    TextBox {
        id: valueField

        Layout.fillWidth: true
        Layout.leftMargin: 10 * AppFramework.displayScaleFactor
        Layout.rightMargin: 10 * AppFramework.displayScaleFactor

        visible: false
        placeholderText: qsTr("QR code value")

        onTextChanged: {
            value = text.trim();
        }
    }

    RowLayout {
        id: eccLayout

        Layout.alignment: Qt.AlignHCenter

        visible: valueField.visible
        layoutDirection: app.localeProperties.layoutDirection
        spacing: 10 * AppFramework.displayScaleFactor

        AppText {
            text: qsTr("ECC Level")
        }

        Button {
            text: qrCode.kLevelL
            checked: qrCode.level === text
            implicitWidth: implicitHeight
        }

        Button {
            text: qrCode.kLevelM
            checked: qrCode.level === text
            implicitWidth: implicitHeight
        }

        Button {
            text: qrCode.kLevelQ
            checked: qrCode.level === text
            implicitWidth: implicitHeight
        }

        Button {
            text: qrCode.kLevelH
            checked: qrCode.level === text
            implicitWidth: implicitHeight
        }

        ButtonGroup {
            exclusive: true
            buttons: eccLayout.children

            onClicked: {
                qrCode.level = button.text;
            }
        }
    }

    //--------------------------------------------------------------------------

    QRCode {
        id: qrCode

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 200 * AppFramework.displayScaleFactor
        Layout.preferredWidth: Layout.preferredHeight

        visible: value > ""

        border {
            color: mouseArea.pressed
                   ? palette.dark
                   : mouseArea.containsMouse
                     ? palette.mid
                     : palette.light
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor

            onClicked: {
                AppFramework.clipboard.copy(qrCode);
            }
        }
    }

    //--------------------------------------------------------------------------

    AppText {
        Layout.fillWidth: true

        visible: showValue
        text: (isUrl && linkEnabled) ? '<a href="%1">%1</a>'.arg(value) : value
        horizontalAlignment: Text.AlignHCenter
        font {
            pointSize: 16
        }

        onLinkActivated: {
            Qt.openUrlExternally(link);
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    ActionGroupLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2 * AppFramework.displayScaleFactor

        actionGroup: actionGroup
    }

    //--------------------------------------------------------------------------

    ActionGroup {
        id: actionGroup

        Action {
            enabled: qrCode.visible
            text: qsTr("Copy QR code to clipboard")

            icon.name: "copy-to-clipboard"

            onTriggered: {
                AppFramework.clipboard.copy(qrCode);
                popup.close();
            }
        }

        Action {
            enabled: isUrl
            text: qsTr("Copy link to clipboard")

            icon.name: "copy-to-clipboard"

            onTriggered: {
                AppFramework.clipboard.copy(value);
                popup.close();
            }
        }

        Action {
            enabled: isUrl && linkEnabled
            text: qsTr("Open link")

            icon.name: "launch"

            onTriggered: {
                Qt.openUrlExternally(urlInfo.url);
                popup.close();
            }
        }

        Action {
            enabled: AppFramework.clipboard.supportsShare && value > ""
            text: qsTr("Share")
            icon.name: ControlsSingleton.shareIconName

            onTriggered: {
                AppFramework.clipboard.share(value);
            }
        }
    }

    //--------------------------------------------------------------------------
}
