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
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtMultimedia 5.12
import QtQuick.Window 2.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "SketchControl"
import "../Controls/Singletons"

import "XForm.js" as XFormJS

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property string title
    property url imageUrl
    property url temporaryAttachmentUrl
    property string temporaryAttachmentFileName: ""
    property FileFolder imagesFolder
    property string imagePrefix: "Sketch"

    property color titleTextColor: xform.style.titleTextColor
    property color toolColor: xform.style.titleTextColor
    property bool annotate: false

    property alias defaultImageUrl: sketchCanvas.defaultImageUrl
    property bool useExternalCamera: false
    property url externalCameraIcon
    property int preferredCameraPosition: Camera.UnspecifiedPosition
    property int captureResolution: xform.captureResolution
    property bool showCamera: true
    property bool showBrowse: true
    property bool showMap: true
    property bool autoAction: false

    property string appearance

    property bool betaMode: false

    //--------------------------------------------------------------------------

    signal saved(string path, url url)

    //--------------------------------------------------------------------------

    color: xform.style.titleBackgroundColor

    Component.onCompleted: {
        var fileInfo = AppFramework.fileInfo(imageUrl);
        if (fileInfo.exists) {
            sketchCanvas.load(fileInfo.filePath);
        }

        if (autoAction && !(imageUrl > "")) {
            if (showCamera) {
                Qt.callLater(cameraButton.clicked, null);
            } else if (showMap && !showBrowse) {
                Qt.callLater(mapButton.clicked, null);
            } else if (showBrowse) {
                Qt.callLater(folderButton.clicked, null);
            }
        }
    }

    //--------------------------------------------------------------------------

    Screen.onPrimaryOrientationChanged : {
        // 1: portrait
        // 2: landscape
        // if the orientation changes then need to reset everything and redraw the canvas as the dimensions.
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
        }

        //----------------------------------------------------------------------

        RowLayout {
            Layout.fillWidth: true

            XFormImageButton {
                Layout.preferredHeight: 40 * AppFramework.displayScaleFactor
                Layout.preferredWidth: 40 * AppFramework.displayScaleFactor

                source: ControlsSingleton.backIcon
                padding: ControlsSingleton.backIconPadding
                color: titleTextColor

                onClicked: {
                    page.parent.pop();
                    clearTemporaryAttachment();
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: title
                font {
                    pointSize: xform.style.titlePointSize
                    family: xform.style.titleFontFamily
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: titleTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        betaMode = !betaMode;
                    }
                }
            }

            Item {
                Layout.preferredHeight: 40 * AppFramework.displayScaleFactor
                Layout.preferredWidth: 40 * AppFramework.displayScaleFactor

                XFormImageButton {
                    anchors {
                        fill: parent
                        margins: ControlsSingleton.backIconPadding
                    }

                    color: titleTextColor
                    source: Icons.icon("erase")
                    enabled: !sketchCanvas.isNull
                    visible: enabled

                    onClicked: {
                        erasePopup.createObject(page).open();
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        XFormSketchCanvas {
            id: sketchCanvas

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: xform.style.signatureBackgroundColor

            workFolder: imagesFolder
        }

        //----------------------------------------------------------------------

        RowLayout {
            id: toolsLayout

            Layout.fillWidth: true
            Layout.leftMargin: 5 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin
            Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

            layoutDirection: xform.layoutDirection
            spacing: 10 * AppFramework.displayScaleFactor

            visible: !(Qt.platform.os === "android" && Qt.inputMethod.visible)

            XFormImageButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                source: Icons.icon("undo")
                color: toolColor
                mirror: xform.isRightToLeft

                onClicked: {
                    sketchCanvas.canvas.deleteLastSketch();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                id: cameraButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.alignment: Qt.AlignLeft


                visible: showCamera && QtMultimedia.availableCameras.length > 0 && canAnnotate
                source: useExternalCamera ? externalCameraIcon : Icons.icon("camera")
                color: useExternalCamera ? "transparent" : toolColor

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: useExternalCamera ? externalCameraPageComponent: cameraPageComponent,
                                                    properties: {
                                                        resolution: Qt.size(sketchCanvas.width, sketchCanvas.height)
                                                    }
                                                });
                }
            }

            Item {
                Layout.fillWidth: true
                visible: cameraButton.visible
            }

            XFormImageButton {
                id: folderButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                visible: showBrowse && canAnnotate
                source: Icons.icon("folder")
                color: toolColor

                onClicked: {
                    pictureChooser.open();
                }
            }

            Item {
                Layout.fillWidth: true
                visible: folderButton.visible
            }

            XFormImageButton {
                id: mapButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                source: Icons.icon("map")
                color: toolColor
                visible: showMap && Networking.isOnline && canAnnotate

                onClicked: {
                    Qt.inputMethod.hide();
                    xform.popoverStackView.push({
                                                    item: mapCapture,
                                                    properties: {
                                                    }
                                                });
                }
            }

            Item {
                Layout.fillWidth: true
                visible: mapButton.visible
            }

            SketchPenButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                canvas: sketchCanvas.canvas
            }

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.alignment: Qt.AlignRight

                source: Icons.icon("check")
                //enabled: !sketchCanvas.isNull
                visible: enabled

                color: toolColor

                onClicked: {
                    save();
                    page.parent.pop();
                }
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    Component {
        id: erasePopup

        XFormMessagePopup {
            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.No
            icon.name: "exclamation-mark-triangle"
            title: qsTr("Clear Canvas")
            prompt: qsTr("Are you sure you want to clear the canvas?")

            onYes: {
                sketchCanvas.clear();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: cameraPageComponent

        XFormCameraCapture {
            imagesFolder: page.imagesFolder
            imagePrefix: "$camera"
            preferredCameraPosition: page.preferredCameraPosition
            captureResolution: page.captureResolution

            title: title

            onCaptured: {
                clearTemporaryAttachment();
                sketchCanvas.resetPastedImageObject();
                sketchCanvas.pasteImage(url);
                sketchCanvas.lastLoadedImage = path;
                temporaryAttachmentUrl = path;
                temporaryAttachmentFileName = AppFramework.fileInfo(path).fileName;
            }
        }
    }

    Component {
        id: externalCameraPageComponent

        XFormExternalCameraCapture {
            imagesFolder: page.imagesFolder
            imagePrefix: "$camera"
            appearance: page.appearance

            title: title

            onCaptured: {
                clearTemporaryAttachment();
                sketchCanvas.resetPastedImageObject();
                sketchCanvas.pasteImage(url);
                sketchCanvas.lastLoadedImage = path;
                temporaryAttachmentUrl = path;
                temporaryAttachmentFileName = AppFramework.fileInfo(path).fileName;
            }
        }
    }

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: page.imagesFolder
        outputPrefix:  "$chooser"

        onAccepted: {
            clearTemporaryAttachment();
            sketchCanvas.resetPastedImageObject();
            var path = AppFramework.resolvedPath(pictureUrl);
            console.log(path)
            sketchCanvas.pasteImage(path);
            sketchCanvas.lastLoadedImage = path;
            temporaryAttachmentUrl = path;
            temporaryAttachmentFileName = AppFramework.fileInfo(path).fileName;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapCapture

        XFormMapCapture {
            positionSourceManager: positionSourceConnection.positionSourceManager

            map.plugin: XFormMapPlugin {
                settings: mapSettings
            }

            outputFolder: page.imagesFolder
            outputPrefix: "$mapcapture"

            onAccepted: {
                clearTemporaryAttachment();
                sketchCanvas.resetPastedImageObject();
                sketchCanvas.pasteImage(path);
                sketchCanvas.lastLoadedImage = path;
                temporaryAttachmentUrl = path;
                temporaryAttachmentFileName = AppFramework.fileInfo(path).fileName;
            }
        }
    }

    //--------------------------------------------------------------------------

    function save() {
        if (sketchCanvas.isNull) {
            console.log("Null sketch:", imagePrefix);
            return;
        }

        var imagePath;

        if (!(imageUrl > "")) {
            var imageName = imagePrefix + "-" + XFormJS.dateStamp() + ".jpg";

            imageUrl = imagesFolder.fileUrl(imageName);
        }

        var fileInfo = AppFramework.fileInfo(imageUrl);
        imagePath = fileInfo.filePath;

        console.log("save sketch url:", imageUrl, "path:", imagePath);

        if (!sketchCanvas.save(imagePath)) {
            console.error("Canvas not saved");
            return;
        }

        saved(imagePath, imageUrl);
        clearTemporaryAttachment();
    }

    //--------------------------------------------------------------------------

    function clearTemporaryAttachment(){
        imagesFolder.removeFile(temporaryAttachmentFileName);
    }

    //--------------------------------------------------------------------------

}
