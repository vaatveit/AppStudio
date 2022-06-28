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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"
import "XForm.js" as XFormJS
import "Singletons"

Item {
    id: pictureChooser

    //--------------------------------------------------------------------------

    property string title: qsTr("Pictures")
    property FileFolder outputFolder
    property string outputPrefix: "image"
    property bool copyToOutputFolder: true

    property url pictureUrl

    readonly property bool iOS: Qt.platform.os === "ios"

    //--------------------------------------------------------------------------

    signal accepted()
    signal rejected()

    //--------------------------------------------------------------------------

    function open() {
        if (iOS) {
            openImageDialogPopup();
        } else {
            openDocumentDialog();
        }
    }

    //--------------------------------------------------------------------------

    function openImageDialogPopup() {
        var popup = imageDialogPopup.createObject(pictureChooser.parent);
        popup.open();
    }

    //--------------------------------------------------------------------------

    function openDocumentDialog() {
        var dialog = documentDialogComponent.createObject(pictureChooser.parent);
        dialog.open();
    }

    //--------------------------------------------------------------------------

    function openFileDialog() {
        var dialog = fileDialogComponent.createObject(pictureChooser.parent);
        dialog.open();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(pictureChooser, true);
    }

    //--------------------------------------------------------------------------

    onAccepted: {
        var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
        var picturePath = pictureUrlInfo.localFile;
        var assetInfo = AppFramework.urlInfo(picturePath);

        var outputFileName;

        var suffix = AppFramework.fileInfo(picturePath).suffix;
        var a = suffix.match(/&ext=(.+)/);
        if (Array.isArray(a) && a.length > 1) {
            suffix = a[1];
        }

        if (assetInfo.scheme === "assets-library") {
            pictureUrl = assetInfo.url;
        }

        outputFileName = outputPrefix + "-" + XFormJS.dateStamp() + "." + suffix;

        if (copyToOutputFolder) {
            var outputFileInfo = outputFolder.fileInfo(outputFileName);
            var copied = false;

            if (outputFileName.match(/\.hei(c|f)$/i)) {
                var copyParameters = {
                    "picturePath": picturePath,
                    "outputFileName": outputFileName
                };

                copied = imageObjectCopy(copyParameters);

                if (copied) {
                    outputFileName = copyParameters.outputFileName;
                }
            }

            if (!copied) {
                outputFolder.removeFile(outputFileName);
                outputFolder.copyFile(picturePath, outputFileInfo.filePath);
            }

            pictureUrl = outputFolder.fileUrl(outputFileName);
        }
    }

    //--------------------------------------------------------------------------

    onRejected: {
    }

    //--------------------------------------------------------------------------

    function imageObjectCopy(copyParameters) {
        if (!imageObject.load(copyParameters.picturePath)) {
            console.error(logCategory, arguments.callee.name, "Unable to load image:", copyParameters.picturePath);
            return false;
        }

        copyParameters.outputFileName = copyParameters.outputFileName.replace(/\.[a-z]*$/i, ".jpg");

        var outputFileInfo = outputFolder.fileInfo(copyParameters.outputFileName);

        outputFolder.removeFile(copyParameters.outputFileName);

        if (!imageObject.save(outputFileInfo.filePath)) {
            console.error(logCategory, arguments.callee.name, "Unable to save image:", outputFileInfo.filePath);
            return false;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageDialogPopup

        ActionsPopup {
            icon.name: "image"
            prompt: qsTr("Select image from?")
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            Action {
                text: qsTr("Photos")
                icon.name: "images"

                onTriggered: {
                    openFileDialog();
                    close();
                }
            }

            Action {
                text: qsTr("Files")
                icon.name: "file-image"

                onTriggered: {
                    openDocumentDialog();
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: documentDialogComponent

        DocumentDialog {
            title: pictureChooser.title

            nameFilters: [
                Body.kFileFilterImage,
                Body.kFileFilterAll
            ]

            onAccepted: {
                pictureUrl = fileUrl;
                pictureChooser.accepted();
            }

            onRejected: {
                pictureChooser.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: fileDialogComponent

        FileDialog {
            title: pictureChooser.title

            folder: iOS
                    ? "file:assets-library://"
                    : AppFramework.resolvedPathUrl(AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0])

            nameFilters: [
                Body.kFileFilterImage,
                Body.kFileFilterAll
            ]

            onAccepted: {
                pictureUrl = fileUrl;
                pictureChooser.accepted();
            }

            onRejected: {
                pictureChooser.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------
}

