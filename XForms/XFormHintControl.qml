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
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import "../Controls/Singletons"

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property XFormData formData
    property var labelControl

    property bool showHint: true
    property bool showGuidance: true

    property var hint
    property string hintText
    property string guidanceText

    readonly property var textValue: translationTextValue(hint, language)
    readonly property var guidanceValue: translationTextValue(hint, language, "guidance")
    readonly property string kHintIcon: "information-f"  // BPDS remove "lightbulb"
    readonly property bool hasGuidance: guidanceText > "" && guidanceText !== "-"

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    onTextValueChanged: {
        hintText = formData.createTextExpression(textValue);
    }

    onGuidanceValueChanged: {
        guidanceText = formData.createTextExpression(guidanceValue);
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredWidth: xform.style.buttonSize / 2
        Layout.preferredHeight: Layout.preferredWidth
        Layout.alignment: Qt.AlignTop

        active: showGuidance && hasGuidance
        visible: active

        XFormImageButton {
            implicitWidth: xform.style.buttonSize / 2
            implicitHeight: implicitWidth

            icon.name: kHintIcon
            color: xform.style.hintColor

            onClicked: {
                showGuidancePopup();
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true

        visible: showHint

        sourceComponent: hintTextComponent
    }

    //--------------------------------------------------------------------------

    function showGuidancePopup() {
        guidancePopup.createObject(control).open();
    }

    //--------------------------------------------------------------------------

    Component {
        id: hintTextComponent

        Text {
            anchors.fill: parent

            text: XFormJS.encodeHTMLEntities(hintText.trim())
            color: xform.style.hintColor
            font {
                pointSize: xform.style.hintPointSize
                bold: xform.style.hintBold
                family: xform.style.hintFontFamily
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: text > ""
            textFormat: Text.RichText
            horizontalAlignment: xform.localeInfo.textAlignment
            baseUrl: xform.baseUrl

            onLinkActivated: {
                xform.openLink(link);
            }

            MouseArea {
                anchors.fill: parent

                enabled: showGuidance && hasGuidance
                hoverEnabled: enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    var link = parent.linkAt(mouse.x, mouse.y);
                    if (link > "") {
                        xform.openLink(link);
                    } else {
                        showGuidancePopup();
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: guidancePopup

        XFormMessagePopup {
            parent: xform.parent

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            icon.name: kHintIcon
            title: labelControl ? labelControl.labelText : ""
            text: guidanceText
            baseUrl: xform.baseUrl
        }
    }

    //--------------------------------------------------------------------------
}
