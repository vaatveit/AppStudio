/* Copyright 2019 Esri
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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.Survey123 1.0

import "Workarounds.js" as Workarounds

Control {
    id: control

    property alias text: textInput.text
    property color textColor: palette.text
    property alias color: textInput.color

    property string emptyText

    property color errorTextColor: "#A80000"
    property color errorBorderColor: "#A80000"
    property bool errorInput: (text !== emptyText && !acceptableInput) || (inputRequired && _inputEmpty)

    property string placeholderText
    property color placeholderTextColor: AppFramework.alphaColor(textColor, 0.5)

    property alias horizontalAlignment: textInput.horizontalAlignment
    property alias verticalAlignment: textInput.verticalAlignment
    property alias selectByMouse: textInput.selectByMouse
    property alias acceptableInput: textInput.acceptableInput
    property alias validator: textInput.validator
    property alias readOnly: textInput.readOnly
    property alias echoMode: textInput.echoMode
    property alias length: textInput.length
    property alias maximumLength: textInput.maximumLength
    property alias cursorPosition: textInput.cursorPosition

    property alias inputMask: textInput.inputMask
    property alias inputMethodHints: textInput.inputMethodHints
    property bool inputRequired: false
    property bool _inputEmpty: false

    property alias backgroundColor: backgroundRectangle.color
    property alias border: backgroundRectangle.border
    property color borderColor: "#bdbdbd"
    property color activeBorderColor: control.palette.highlight
    property alias radius: backgroundRectangle.radius

    property alias textInput: textInput
    property alias clearButton: clearButton
    property bool showClearButton: true

    property alias hasActiveFocus: textInput.activeFocus

    property Component leftIndicator
    property Component rightIndicator

    property Popup contextPopup: contextMenu
    readonly property bool contextPopupVisible: contextMenu && contextMenu.visible

    //--------------------------------------------------------------------------

    signal cleared(string previousText)
    signal accepted()
    signal editingFinished()
    signal textEdited()
    signal keysPressed(var event)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        textInput.accepted.connect(accepted);
        textInput.editingFinished.connect(editingFinished);
        textInput.textEdited.connect(textEdited);

        Workarounds.checkInputMethodHints(textInput, locale);
    }

    //--------------------------------------------------------------------------

    padding: 8 * AppFramework.displayScaleFactor
    leftPadding: padding
    rightPadding: padding
    topPadding: padding
    bottomPadding: padding

    spacing: 5 * AppFramework.displayScaleFactor

    focusPolicy: Qt.NoFocus //Qt.StrongFocus
    activeFocusOnTab: false// true
    focus: false

    locale: Survey123.locale
    font {
        family: Survey123.font.family
        pointSize: 15
    }

    //    onActiveFocusChanged: {
    //        if (activeFocus) {
    //            textInput.focus = true;
    //        }
    //    }

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        id: layout

        implicitWidth: 200 * AppFramework.displayScaleFactor
        implicitHeight: 40 * AppFramework.displayScaleFactor

        spacing: control.spacing
        layoutDirection: control.mirrored ? Qt.RightToLeft : Qt.LeftToRight

        Loader {
            Layout.fillHeight: true
            Layout.preferredWidth: (item && item.visible) ? -1 : 0

            sourceComponent: leftIndicator
            visible: item != null

            activeFocusOnTab: false
        }

        TextInput {
            id:  textInput
            Layout.fillWidth: true

            activeFocusOnTab: true

            width: parent.width
            font: control.font
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            color: errorInput ? errorTextColor : textColor
            selectionColor: control.palette.highlight
            selectedTextColor: control.palette.highlightedText
            selectByMouse: true


            onLengthChanged: {
                if (length > 0) {
                    _inputEmpty = false;
                }
            }

            onEditingFinished: {
                _inputEmpty = length == 0;
            }

            onInputMaskChanged: {
                emptyText = text;
            }

            Keys.onPressed: {
                keysPressed(event);
            }

            Loader {
                anchors.fill: parent
                active: textInput.inputMask > ""

                sourceComponent: MouseArea {
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true

                    onPressed: {
                        // console.log("Input mask active:", textInput.inputMask, "text:", JSON.stringify(textInput.text), "empty:", JSON.stringify(emptyText));

                        if (textInput.text == emptyText) {
                            textInput.cursorPosition = 0;
                            textInput.forceActiveFocus();
                        } else {
                            mouse.accepted = false;
                        }
                    }
                }
            }
        }

        Button {
            id: clearButton

            Layout.preferredWidth: textInput.height
            Layout.preferredHeight: textInput.height

            padding: 0
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            visible: showClearButton && textInput.length > 0 && !textInput.readOnly

            activeFocusOnTab: false

            icon {
                source: "images/x-circle-24-f.svg"
                color: AppFramework.alphaColor(textInput.color, 0.3)
                height: textInput.height
                width: height
            }

            display: AbstractButton.IconOnly
            background: Item {
                implicitWidth: 40 * AppFramework.displayScaleFactor
                implicitHeight: 40 * AppFramework.displayScaleFactor
            }

            onClicked: {
                var previousText = textInput.text;
                textInput.clear();
                cleared(previousText);
                textInput.forceActiveFocus();
                textInput.editingFinished();
            }
        }

        Loader {
            Layout.fillHeight: true
            Layout.preferredWidth: (item && item.visible) ? -1 : 0

            sourceComponent: rightIndicator
            visible: item
            activeFocusOnTab: false
        }
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: backgroundRectangle

        border {
            color: errorInput ? errorBorderColor : (textInput.activeFocus  || contextPopupVisible) ? activeBorderColor : borderColor
            width: ((textInput.activeFocus || contextPopupVisible) ? 2 : 1) * AppFramework.displayScaleFactor
        }

        radius: 2 * AppFramework.displayScaleFactor

        Text {
            x: control.leftPadding + textInput.x
            y: control.topPadding + textInput.y
            width: textInput.width
            height: textInput.height

            text: control.placeholderText
            font: control.font
            color: control.placeholderTextColor
            verticalAlignment: textInput.verticalAlignment
            visible: !textInput.length && !textInput.preeditText && (!textInput.activeFocus || textInput.horizontalAlignment !== Qt.AlignHCenter)
            elide: Text.ElideRight
            renderType: textInput.renderType
        }

        MouseArea {
            anchors.fill: parent

            acceptedButtons: Qt.RightButton

            onClicked: {
                if (contextPopup) {
                    if (typeof contextPopup.restoreFocus == "boolean") {
                        contextPopup.restoreFocus = textInput.activeFocus;
                    }
                    contextPopup.popup();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    TextBoxContextMenu {
        id: contextMenu

        inputControl: textInput
        locale: control.locale
    }

    //--------------------------------------------------------------------------
}
