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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.Multimedia 1.0

import "Singletons"
import "XForm.js" as XFormJS

import "../Controls"
import "../Controls/Singletons"
import "../template/SurveyHelper.js" as Helper

XFormControl {
    id: control

    //--------------------------------------------------------------------------

    property string type: "application"

    property bool captureStillImage: true
    property bool captureVideo: true
    readonly property bool showCapture: captureStillImage || captureVideo
    property string fileIconName: "file"
    property var fileFilter
    property string attachmentIconName: "attachment"

    //--------------------------------------------------------------------------

    readonly property var bindElement: binding.element

    property var mediatype

    readonly property bool isMultiline: Appearance.contains(appearance, Appearance.kMultiline)

    property FileFolder uploadsFolder: xform.attachmentsFolder

    property bool editing: false
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    readonly property int buttonSize: xform.style.buttonBarSize

    readonly property bool hasFiles: attachmentsModel.count > 0

    readonly property var kImagePreviewTypes: [
        "jpg", "jpeg", "jpf", "jpe", "png", "tif", "tiff",
        "bmp", "gif", "img", "jp2", "jpc", "j2k",
    ]

    readonly property bool iOS: Qt.platform.os === "ios"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    readOnly: !editable || binding.isReadOnly || editing

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        switch (type) {
        case "application":
            captureStillImage = false;
            captureVideo = false;
            break;

        case "video":
            attachmentIconName = "video";
            fileIconName = "file-video"
            captureStillImage = false;
            fileFilter = Body.kFileFilterVideo;
            break;

        case "*":
        default:
            break;
        }
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    XFormAttachmentsModel {
        id: attachmentsModel

        folder: uploadsFolder

        onCountChanged: {
            if (updateEnabled) {
                Qt.callLater(updateValue);
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        width: parent.width

        implicitHeight: controlsLayout.height

        Rectangle {
            anchors {
                fill: parent
                margins: -4 * AppFramework.displayScaleFactor
            }

            visible: dropArea.containsDrag
            color: xform.style.inputBackgroundColor
            border {
                width: xform.style.inputActiveBorderWidth
                color: xform.style.inputActiveBorderColor
            }
            radius: xform.style.inputBackgroundRadius
        }

        DropArea {
            id: dropArea

            anchors.fill: parent

            enabled: isMultiline || !hasFiles

            onDropped: {
                if (!drop.hasUrls) {
                    console.error(logCategory, "Not a url", drop.text);
                    return;
                }

                if (isMultiline) {
                    showAddFilesPopup(drop.urls);
                } else {
                    addFile(drop.urls[0]);
                }
            }
        }

        ColumnLayout {
            id: controlsLayout

            width: parent.width
            spacing: 5 * AppFramework.displayScaleFactor

            XFormText {
                Layout.fillWidth: true

                visible: attachmentsModel.count > 1
                text: qsTr("Files: %1 (%2)").arg(attachmentsModel.count).arg(Helper.displaySize(attachmentsModel.size))
                color: xform.style.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
                model: attachmentsModel

                delegate: attachmentComponent
            }

            XFormButtonBar {
                Layout.alignment: Qt.AlignCenter

                spacing: xform.style.buttonBarSize / 2
                leftPadding: visibleItemsCount > 1 ? spacing : padding
                rightPadding: leftPadding
                visible: !readOnly && (isMultiline || !hasFiles)

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    icon.name: attachmentIconName

                    adornment {
                        visible: isMultiline && hasFiles
                    }

                    onClicked: {
                        addAttachment();
                    }

                    onPressAndHold: {
                        Qt.openUrlExternally(uploadsFolder.url);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var value = attachmentsModel.join();

        console.log(logCategory, arguments.callee.name, "value:", value);

        formData.setValue(bindElement, value > "" ? value : undefined);

        xform.controlFocusChanged(this, false, bindElement);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];

            console.log(logCategory, arguments.callee.name, "editMode:", editMode);

            editing = editMode > formData.kEditModeAdd;
        } else {
            editing = false;
        }

        console.log(logCategory, arguments.callee.name, "value:", value, "readOnly:", readOnly);

        attachmentsModel.split(value);

        formData.setValue(bindElement, value);
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function addFiles(urls) {
        if (urls) {
            urls.forEach(addFile);
        }
    }

    //--------------------------------------------------------------------------

    function addFile(url) {
        if (attachmentsModel.fileExists(url)) {
            return;
        }

        var suffix = AppFramework.fileInfo(url).suffix.toLowerCase();
        if (Body.kFileTypesAll.indexOf(suffix) < 0) {
            console.log(logCategory, arguments.callee.name, "Unsupported suffix:", suffix, "url:", url);
            return;
        }

        url = copyFile(url);
        if (!url) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "url:", url);

        attachmentsModel.addFile(url);
    }

    //--------------------------------------------------------------------------

    function copyFile(url) {
        console.log(logCategory, arguments.callee.name, "url:", url);

        var sourceUrlInfo = AppFramework.urlInfo(url);
        var sourceFileInfo = AppFramework.fileInfo(sourceUrlInfo.localFile);

        var targetFileName = sourceFileInfo.baseName + "-" + AppFramework.createUuidString(2) + "." + sourceFileInfo.suffix;

        var targetFileInfo = uploadsFolder.fileInfo(targetFileName);

        console.log(logCategory, arguments.callee.name, "Copying source:", sourceFileInfo.filePath, "target:", targetFileInfo.filePath);

        if (!sourceFileInfo.folder.copyFile(sourceFileInfo.fileName, targetFileInfo.filePath)) {
            console.error(logCategory, arguments.callee.name, "Error copying file");
            return;
        }

        return targetFileInfo.url;
    }

    //--------------------------------------------------------------------------

    function addAttachment() {
        if (showCapture || iOS) {
            attachmentPopup.createObject(xform).open();
        } else {
            documentDialog.createObject(xform).open();
        }
    }

    Component {
        id: attachmentPopup

        ActionsPopup {
            icon.name: attachmentIconName
            prompt: qsTr("What would you like to attach?")
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            Action {
                enabled: captureStillImage
                text: qsTr("Take photo")
                icon.name: "camera"

                onTriggered: {
                    close();
                    var dialog = cameraDialog.createObject(control,
                                                           {
                                                               captureMode: CameraDialog.CameraCaptureModeStillImage
                                                           });
                    dialog.open();
                }
            }

            Action {
                enabled: captureVideo
                text: qsTr("Record video")
                icon.name: "video"

                onTriggered: {
                    close();
                    var dialog = cameraDialog.createObject(control,
                                                           {
                                                               captureMode: CameraDialog.CameraCaptureModeVideo
                                                           });
                    dialog.open();
                }
            }

            Action {
                text: qsTr("File")
                icon.name: fileIconName

                onTriggered: {
                    close();
                    documentDialog.createObject(control).open();
                }
            }

            Action {
                text: qsTr("Photo")
                icon.name: "image"
                enabled: iOS && (captureStillImage || !showCapture)

                onTriggered: {
                    showPictureChooser();
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: documentDialog

        DocumentDialog {
            title: qsTr("Select file")

            selectMultiple: isMultiline
            folder: AppFramework.resolvedPathUrl(AppFramework.standardPaths.standardLocations(StandardPaths.DocumentsLocation)[0])

            nameFilters: fileFilter > ""
                         ? [ fileFilter ]
                         : [
                               Body.kFileFilterAll,
                               Body.kFileFilterDocument,
                               Body.kFileFilterImage,
                               Body.kFileFilterVideo,
                               Body.kFileFilterAudio,
                               Body.kFileFilterOther,
                           ]

            onAccepted: {
                showAddFilesPopup(fileUrls);
            }
        }
    }

    //--------------------------------------------------------------------------

    function showAddFilesPopup(fileUrls) {
        if (!fileUrls || fileUrls.length < 1) {
            return;
        }

        var urls = [];
        fileUrls.forEach(url => urls.push(url));

        var popup = addFilesPopup.createObject(control,
                                               {
                                                   urls: urls
                                               });

        Qt.callLater(popup.open);
    }

    Component {
        id: addFilesPopup

        XFormMessagePopup {
            id: popup

            property var urls

            icon.name: "spinner"
            iconAnimation: PageLayoutPopup.IconAnimation.Rotate
            closePolicy: Popup.NoAutoClose

            Component.onCompleted: {
                Qt.callLater(copyNext);
            }

            function copyNext() {
                var url = urls.shift();

                if (!url) {
                    popup.close();
                    return;
                }

                var fileInfo = AppFramework.fileInfo(url);
                text = fileInfo.displayName;

                Qt.callLater(() => {
                                 addFile(url);
                                 Qt.callLater(copyNext);
                             });

            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: cameraDialog

        CameraDialog {
            parent: xform.parent

            onAccepted: {
                addFile(fileUrl);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: attachmentComponent

        Rectangle {
            id: attachementDelegate

            Layout.fillWidth: true

            implicitHeight: rowLayout.height + ControlsSingleton.inputTextPadding * 2

            color: xform.style.inputBackgroundColor
            clip: true

            border {
                width: xform.style.inputBorderWidth
                color: xform.style.inputBorderColor
            }

            radius: xform.style.inputBackgroundRadius

            RowLayout {
                id: rowLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: ControlsSingleton.inputTextPadding
                }

                spacing: ControlsSingleton.inputTextPadding

                XFormImageButton {
                    implicitWidth: xform.style.buttonSize
                    implicitHeight: xform.style.buttonSize

                    icon.name: fileIcon
                    color: xform.style.buttonColor

                    mouseArea.anchors.margins: -ControlsSingleton.inputTextPadding
                    background.anchors.margins: -ControlsSingleton.inputTextPadding
                    background.radius: attachementDelegate.radius

                    onClicked: {
                        var fileInfo = AppFramework.fileInfo(filePath);
                        if (AppFramework.clipboard.supportsShare) {
                            AppFramework.clipboard.share(fileInfo.url);
                        } else {
                            Qt.openUrlExternally(fileInfo.url);
                        }
                    }

                    onPressAndHold: {
                        Qt.openUrlExternally(url);
                    }

                    Loader {
                        anchors {
                            fill: parent
                            margins: -ControlsSingleton.inputTextPadding + attachementDelegate.border.width
                        }

                        active: kImagePreviewTypes.indexOf(fileSuffix.toLowerCase()) >= 0

                        sourceComponent: Image {
                            id: previewImage

                            fillMode: Image.PreserveAspectCrop
                            source: fileUrl
                            smooth: false
                            cache: false
                            autoTransform: true
                            asynchronous: true
                            sourceSize {
                                width: previewImage.width
                                height: previewImage.height
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true

                        text: displayName
                        color: xform.style.inputTextColor
                        font: xform.style.inputFont
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true

                        text: "(%1)".arg(Helper.displaySize(fileSize))
                        color: xform.style.inputTextColor
                        font
                        {
                            family: xform.style.fontFamily
                            pointSize: xform.style.inputPointSize * 0.7
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                XFormImageButton {
                    visible: !readOnly
                    icon.name: "trash"
                    mouseArea.anchors.margins: -ControlsSingleton.inputTextPadding
                    background.anchors.margins: -ControlsSingleton.inputTextPadding
                    background.radius: attachementDelegate.radius

                    onClicked: {
                        deletePopup.open();
                    }
                }

                XFormDeletePopup {
                    id: deletePopup

                    parent: xform

                    title: qsTr("Delete File")
                    prompt: qsTr("<b>%1</b> will be deleted from the survey.").arg(displayName)

                    onYes: {
                        Qt.callLater(attachementDelegate.deleteFile);
                    }
                }
            }

            function deleteFile() {
                attachmentsModel.removeFile(index);
            }
        }
    }

    //--------------------------------------------------------------------------
    // TODO: Improve implementation so a multiple copies are not made

    function showPictureChooser() {
        pictureChooser.openFileDialog();
    }

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: uploadsFolder
        outputPrefix: "photo"

        onAccepted: {
            var fileInfo = AppFramework.fileInfo(pictureUrl);
            addFile(fileInfo.url);
            uploadsFolder.removeFile(fileInfo.fileName);
        }
    }

    //--------------------------------------------------------------------------
}
