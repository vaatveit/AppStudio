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

ColumnLayout {
    id: control

    //--------------------------------------------------------------------------

    property FileFolder fileFolder
    property string fileName
    property string suffix
    property string oldFileName
    property bool readOnly
    property int padding: 4 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    signal renamed(string newFileName)

    //--------------------------------------------------------------------------

    focus: false
    spacing: 0

    //--------------------------------------------------------------------------

    function open() {
        if (readOnly) {
            return;
        }

        var fileInfo = fileFolder.fileInfo(fileName);

        oldFileName = fileName;
        suffix = fileInfo.suffix;

        textField.text = fileInfo.baseName;
        textField.errorInput = false;
        textField.visible = true;
        textField.textInput.forceActiveFocus();
    }

    //--------------------------------------------------------------------------

    function close() {
        textField.visible = false;
        fileNameText.forceActiveFocus();
        Qt.inputMethod.hide();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    XFormText {
        id: fileNameText

        Layout.fillWidth: true
        Layout.bottomMargin: control.padding

        visible: !textField.visible
        text: fileName
        color: xform.style.textColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        MouseArea {
            anchors {
                fill: parent
            }

            enabled: !readOnly
            hoverEnabled: enabled
            cursorShape: enabled ? Qt.IBeamCursor : Qt.ArrowCursor

            onClicked: {
                open();
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormTextField {
        id: textField

        Layout.fillWidth: true
        Layout.bottomMargin: control.padding

        visible: false
        inputMethodHints: Qt.ImhNoPredictiveText

        textInput.onActiveFocusChanged: {
            if (!textInput.activeFocus) {
                visible = false;
            }
        }

        validator: RegExpValidator {
            regExp: /^[\w\-\_ \@\#\$\(\)\{\}\[\]]+$/
        }

        onKeysPressed: {
            switch (event.key) {
            case Qt.Key_Escape:
                close();
                break;
            }
        }

        onEditingFinished: {
            if (!text.trim()) {
                return;
            }

            var newFileName = text.trim() + "." + suffix;

            if (oldFileName === newFileName) {
                close();
                return;
            }

            console.log(logCategory, "Renaming: ", fileFolder.path, oldFileName, newFileName);

            if (fileFolder.renameFile(oldFileName, newFileName)) {
                console.log(logCategory, "Rename succeeded:", fileFolder.fileUrl(newFileName));

                renamed(newFileName);

                close();
            } else {
                console.error(logCategory, "Rename failed:", oldFileName, "=>", newFileName);
            }
        }
    }

    //--------------------------------------------------------------------------
}
