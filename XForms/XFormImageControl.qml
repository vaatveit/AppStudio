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
import QtPositioning 5.12
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

import "Singletons"
import "XForm.js" as XFormJS
import "../Controls"
import "../Controls/Singletons"

XFormGroupBox {
    id: imageControl

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var mediatype

    property FileFolder imagesFolder: xform.attachmentsFolder
    property alias attachmentsModel: attachmentsModel

    property alias imageIndex: attachmentsModel.currentIndex
    property alias imagesCount: attachmentsModel.count

    property alias imagePath: imageFileInfo.filePath
    property url imageUrl
    property string imagePrefix: "Image"
    readonly property bool hasImage: imageUrl > ""


    readonly property var appearance: Attribute.value(formElement, Attribute.kAppearance)
    readonly property bool canAnnotate: Appearance.contains(appearance, Appearance.kAnnotate)
    readonly property bool canDraw: Appearance.contains(appearance, Appearance.kDraw)
    readonly property bool canDrawOrAnnotate: canDraw || canAnnotate
    readonly property bool isMultiline: Appearance.contains(appearance, Appearance.kMultiline)

    property Component externalCameraPage: cameraAddInName > ""
                                           ? addInCameraPage
                                           : spikeCameraPage

    property string cameraAddInName
    readonly property bool isSpikeAppearance: XFormJS.contains(appearance, "spike")
                                              || XFormJS.contains(appearance, "spike-full-measure")
                                              || XFormJS.contains(appearance, "spike-point-to-point")
    property url externalCameraIcon: cameraAddInName > ""
                                     ? xform.addIns.icon(cameraAddInName)
                                     : "images/spike-icon.png"

    readonly property bool useExternalCamera: cameraAddInName > "" || isSpikeAppearance

    property bool showCamera: true
    property bool showBrowse: true
    property bool showMap: true
    property int preferredCameraPosition: Camera.UnspecifiedPosition
    property bool hasCamera: QtMultimedia.availableCameras.length > 0 || useExternalCamera

    property bool editing: false
    readonly property bool readOnly: !enabled || binding.isReadOnly || editing
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable
    readonly property bool hidden: parent.hidden

    readonly property int buttonSize: xform.style.buttonBarSize

    property var constraint
    property var calculatedValue
    property var defaultValue
    property url defaultImageUrl

    property real previewHeight: xform.style.imagePreviewHeight
    property alias fillMode: imagePreview.fillMode

    property bool debug: false

    property int maxPixels: xform.captureResolution
    property int maximumWatermarkedImageResolution: 1920 // iOS Only

    //--------------------------------------------------------------------------

    readonly property url kIconCamera: Icons.icon("camera")
    readonly property url kIconAnnotate: Icons.icon("pencil-mark", false)
    readonly property url kIconDraw: Icons.icon("brush-mark", false)
    readonly property url kIconFolder: Icons.icon("folder")
    readonly property url kIconRotate: Icons.icon("rotate")
    readonly property url kIconTrash: Icons.icon("trash")
    readonly property url kIconPrevious: Icons.icon("chevron-left")
    readonly property url kIconNext: Icons.icon("chevron-right")
    readonly property url kIconEllipsis: Icons.icon("ellipsis")
    readonly property url kIconView: Icons.icon("view-visible")
    readonly property url kIconRename: Icons.icon("form-field")

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, binding.element);

        imagePrefix = binding.nodeset;
        var i = imagePrefix.lastIndexOf("/");
        if (i >= 0) {
            imagePrefix = imagePrefix.substr(i + 1);
        }

        console.log(logCategory, logCategory, "imagePrefix:", imagePrefix);

        if (Appearance.contains(appearance, Appearance.kNew)
                || Appearance.contains(appearance, Appearance.kNewFront)
                || Appearance.contains(appearance, Appearance.kNewRear)) {
            showCamera = true;
            showBrowse = false;
            showMap = false;

            if (Appearance.contains(appearance, Appearance.kNewFront))  {
                preferredCameraPosition = Camera.FrontFace;
            } else if (Appearance.contains(appearance, Appearance.kNewRear)) {
                preferredCameraPosition = Camera.BackFace;
            }
        }

        if (!hasCamera && showCamera) {
            showCamera = false;
            showBrowse = true;
        }

        var maxPixelsParameter = binding.attribute(Bind.kParameterMaxPixels);
        if (maxPixelsParameter > "") {
            var value = parseInt(maxPixelsParameter);
            if (isFinite(value)) {
                maxPixels = value;
            }
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(imageControl, true)
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement) {
            //console.log(logCategory, "onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setDefaultValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    onImageIndexChanged: {
        if (imageIndex >= 0 && imageIndex < imagesCount) {
            var fileInfo = attachmentsModel.get(imageIndex);

            imagePath = attachmentsModel.folder.filePath(fileInfo.fileName);
            imageUrl = attachmentsModel.folder.fileUrl(fileInfo.fileName);
        } else {
            imagePath = "";
            imageUrl = "";
        }

        imagePreview.refresh();

        console.log(logCategory, "onImageIndexChanged:", imageIndex, "imagePath:", imagePath, "readOnly:", readOnly);
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        function _ensureVisible() {
            xform.ensureItemVisible(imageControl);
        }

        Qt.callLater(_ensureVisible);
    }

    //--------------------------------------------------------------------------

    XFormAttachmentsModel {
        id: attachmentsModel

        folder: imagesFolder

        onCountChanged: {
            if (updateEnabled) {
                Qt.callLater(updateValue);
            }
        }
    }

    //--------------------------------------------------------------------------

    function addFile(url) {
        if (attachmentsModel.addFile(url)) {
            imageIndex = imagesCount - 1;
        }

        imagePreview.refresh();
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        width: parent.width

        XFormText {
            Layout.fillWidth: true

            visible: imagesCount > 1
            text: qsTr("%1 of %2").arg(imageIndex + 1).arg(imagesCount)
            color: xform.style.textColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Image {
            id: imagePreview

            Layout.preferredWidth: parent.width
            Layout.maximumHeight: previewHeight > 0
                                  ? previewHeight
                                  : Number.POSITIVE_INFINITY

            autoTransform: true
            width: parent.width
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            source: imageUrl
            cache: false
            smooth: false
            asynchronous: true
            sourceSize {
                width: imagePreview.width
                height: previewHeight > 0
                        ? previewHeight
                        : xform.style.imagePreviewHeight
            }

            visible: source > ""

            Rectangle {
                anchors.centerIn: parent

                width: parent.fillMode === Image.PreserveAspectCrop
                       ? parent.width
                       : parent.paintedWidth

                height: parent.fillMode === Image.PreserveAspectCrop
                        ? parent.height
                        : parent.paintedHeight

                border {
                    width: xform.style.inputBorderWidth
                    color: xform.style.inputBorderColor
                }
                color: "transparent"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                cursorShape: containsMouse
                             ? Qt.PointingHandCursor
                             : Qt.ArrowCursor

                onClicked: {
                    if (canDrawOrAnnotate && !imageControl.readOnly) {
                        editImage();
                    } else {
                        previewImage();
                    }
                }

                onPressAndHold: {
                }
            }

            XFormRoundButton {
                anchors {
                    left: xform.localeProperties.isLeftToRight ? parent.left : undefined
                    right: xform.localeProperties.isRightToLeft ? parent.right : undefined
                    verticalCenter: parent.verticalCenter
                    margins: -imageControl.padding
                }

                visible: imagesCount > 1 && imageIndex > 0
                imageSource: kIconPrevious
                mirror: xform.localeProperties.isRightToLeft
                activeFocusOnPress: true

                onClicked: {
                    imageIndex--;
                }

                onPressAndHold: {
                    imageIndex = 0;
                }
            }

            XFormRoundButton {
                anchors {
                    left: xform.localeProperties.isRightToLeft ? parent.left : undefined
                    right: xform.localeProperties.isLeftToRight ? parent.right : undefined
                    verticalCenter: parent.verticalCenter
                    margins: -imageControl.padding
                }

                visible: imageIndex < (imagesCount - 1)
                imageSource: kIconNext
                mirror: xform.localeProperties.isRightToLeft
                activeFocusOnPress: true

                onClicked: {
                    imageIndex++;
                }

                onPressAndHold: {
                    imageIndex = imagesCount - 1;
                }
            }

            function refresh() {
                var url = imageUrl;
                imageUrl = "";
                imageUrl = url;

                ensureVisible();
            }
        }

        XFormFileRenameControl {
            id: renameControl

            Layout.fillWidth: true

            visible: hasImage
            fileName: imageFileInfo.fileName
            fileFolder: imagesFolder
            readOnly: imageControl.readOnly

            onRenamed: {
                var url = imagesFolder.fileUrl(newFileName);
                console.log(logCategory, "Renamed to url:", url);
                attachmentsModel.updateFile(imageIndex, url);
                imageIndexChanged();
                updateValue();
            }
        }

        XFormButtonBar {
            id: buttonBar

            Layout.alignment: Qt.AlignHCenter

            visible: !readOnly || isMultiline
            spacing: xform.style.buttonBarSize / 2
            leftPadding: visibleItemsCount > 1
                         ? spacing
                         : padding
            rightPadding: leftPadding

            XFormImageButton {
                id: drawButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize
                Layout.alignment: Qt.AlignHCenter

                source: canAnnotate
                        ? showCamera
                          ? kIconAnnotate
                          : kIconAnnotate
                : kIconDraw

                visible: canDrawOrAnnotate && !readOnly && (!imagePreview.visible || isMultiline)

                adornment {
                    visible: isMultiline && imagesCount > 0
                }

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: sketchPage,
                                                    properties: {
                                                        imageUrl: isMultiline
                                                                  ? ""
                                                                  : imageControl.imageUrl,
                                                        annotate: canAnnotate,
                                                        autoAction: canAnnotate
                                                    }
                                                });
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: showCamera && !canDrawOrAnnotate && !readOnly && (isMultiline || !hasImage)
                source: useExternalCamera ? externalCameraIcon : kIconCamera
                color: useExternalCamera ? "transparent" : xform.style.iconColor

                adornment {
                    visible: isMultiline && imagesCount > 0
                }

                onClicked: {
                    if (Appearance.contains(appearance, Appearance.kNative)) {
                        var dialog = cameraDialog.createObject(xform.parent);
                        dialog.open();
                    } else {
                        xform.popoverStackView.push({
                                                        item: useExternalCamera
                                                              ? externalCameraPage
                                                              : cameraPage,
                                                        properties: {
                                                        }
                                                    });
                    }
                }

                onPressAndHold: {
                    if (cameraAddInName > "") {
                        xform.popoverStackView.push({
                                                        item: addInSettingsPage,
                                                        properties: {
                                                        }
                                                    });
                    }
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconFolder

                visible: showBrowse && !canDrawOrAnnotate && !readOnly && (isMultiline || !hasImage)

                adornment {
                    visible: isMultiline && imagesCount > 0
                }

                onClicked: {
                    pictureChooser.open();
                }
            }

            XFormImageButton {
                id: deleteButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconTrash
                visible: !imageControl.readOnly && imagePreview.visible && !readOnly

                onClicked: {
                    deleteCurrentImage();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconEllipsis
                visible: imagePreview.visible && hasImage

                onClicked: {
                    actionsPopup.createObject(imageControl).open();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: imageControl.imagesFolder
        outputPrefix: imageControl.imagePrefix

        onAccepted: {
            var path = AppFramework.resolvedPath(pictureUrl);
            resizeImage(path);
            addFile(pictureUrl);
        }
    }

    Component {
        id: cameraPage

        XFormCameraCapture {
            id: cameraCapture

            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            makerNote: JSON.stringify({
                                          "nodeset": bindElement["@nodeset"]
                                      })

            title: textValue(formElement.label, "", "long")
            preferredCameraPosition: imageControl.preferredCameraPosition
            captureResolution: maxPixels
            autoClose: false
            debug: imageControl.debug

            onCaptured: {
                if (debug) {
                    console.log(logCategory, "onCaptured");
                }

                resizeImage(path);
                finalizeCapture(path, url);
            }

            function finalizeCapture(path, url) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "path:", path);
                }

                function finishedCapture() {
                    if (debug) {
                        console.log(logCategory, arguments.callee.name);
                    }

                    addFile(url);
                    closeControl();
                }

                watermarks.paintWatermarks(cameraCapture, path, location, compassAzimuth, finishedCapture);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: cameraDialog

        CameraDialog {
            parent: xform.parent

            title: textValue(formElement.label, "", "long")
            captureMode: CameraDialog.CameraCaptureModeStillImage
            captureToLocation: imagesFolder.fileUrl(imagePrefix + "-" + XFormJS.dateStamp(true) + ".jpg")

            onAccepted: {
                finalizeCapture(fileUrl);
            }

            function finalizeCapture(url) {
                var fileInfo = AppFramework.fileInfo(url);

                resizeImage(fileInfo.filePath);

                function finishedCapture() {
                    if (debug) {
                        console.log(logCategory, arguments.callee.name);
                    }

                    addFile(url);
                }

                watermarks.paintWatermarks(imageControl,
                                           fileInfo.filePath,
                                           QtPositioning.coordinate(),
                                           Number.NaN,
                                           finishedCapture);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInCameraPage

        XFormAddInCameraCapture {
            addInName: cameraAddInName
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            bodyElement: imageControl.formElement
            appearance: imageControl.appearance || ""
            surveyFolder: xform.sourceInfo.folder


            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                addFile(url);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        XFormAddInSettings {
            addInName: cameraAddInName
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: spikeCameraPage

        XFormExternalCameraCapture {
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            appearance: imageControl.appearance

            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                addFile(url);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sketchPage

        XFormSketchCapture {
            title: textValue(formElement.label, "", "long")

            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            defaultImageUrl: imageControl.defaultImageUrl
            useExternalCamera: imageControl.useExternalCamera
            externalCameraIcon: imageControl.externalCameraIcon
            appearance: imageControl.appearance
            preferredCameraPosition: imageControl.preferredCameraPosition
            captureResolution: maxPixels
            showCamera: imageControl.showCamera
            showBrowse: imageControl.showBrowse
            showMap: imageControl.showMap

            onSaved: {
                addFile(url);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: previewPage

        XFormImagePreview {
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: imageFileInfo
    }

    //--------------------------------------------------------------------------

    function deleteCurrentImage() {
        deletePopup.createObject(xform).open();
    }

    Component {
        id: deletePopup

        XFormDeletePopup {
            parent: xform

            title: qsTr("Delete Image")
            prompt: qsTr("<b>%1</b> will be deleted from the survey.").arg(attachmentsModel.fileName(imageIndex))

            onYes: {
                attachmentsModel.removeFile(imageIndex);
                if (attachmentsModel.count) {
                    imageIndexChanged();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: actionsPopup

        XFormMessagePopup {
            parent: xform

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            standardIcon: StandardIcon.Question

            title: qsTr("Image Options")

            Action {
                icon.source: kIconView
                text: qsTr("View")

                onTriggered: {
                    previewImage();
                }
            }

            Action {
                enabled: !readOnly && canDrawOrAnnotate
                icon.source: kIconAnnotate
                text: qsTr("Edit")

                onTriggered: {
                    editImage();
                }
            }

            Action {
                enabled: !readOnly
                icon.source: kIconRename
                text: qsTr("Rename")

                onTriggered: {
                    Qt.callLater(renameImage);
                }
            }

            Action {
                property bool iconMirror: true

                enabled: !readOnly && !canDrawOrAnnotate
                icon.source: kIconRotate
                text: qsTr("Rotate left")

                onTriggered: {
                    rotateImage(imagePath, -90);
                    imagePreview.refresh();
                }
            }

            Action {
                enabled: !readOnly && !canDrawOrAnnotate
                icon.source: kIconRotate
                text: qsTr("Rotate right")

                onTriggered: {
                    rotateImage(imagePath, 90);
                    imagePreview.refresh();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function renameImage() {
        Qt.callLater(renameControl.open);
    }

    //--------------------------------------------------------------------------

    function previewImage() {
        xform.popoverStackView.push({
                                        item: previewPage,
                                        properties: {
                                            imageUrl: imageControl.imageUrl,
                                        }
                                    });
    }

    //--------------------------------------------------------------------------

    function editImage() {
        xform.popoverStackView.push({
                                        item: sketchPage,
                                        properties: {
                                            imageUrl: imageControl.imageUrl,
                                            annotate: true
                                        }
                                    });
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    function resizeImage(path) {
        var captureResolution = maxPixels;

        if (captureResolution <= 0) {
            // Unrestricted image size
            if (Qt.platform.os !== "ios") {
                // do nothing
                return;
            }
            if (!watermarks.enabledWatermarksCount()) {
                return;
            }
            // If watermark is used, resize to a large image to avoid crash on iOS
            captureResolution = maximumWatermarkedImageResolution;
        }

        if (!captureResolution) {
            console.log(logCategory, "No image resize:", captureResolution);
            return;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, "Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log(logCategory, "File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error(logCategory, "Unable to load image:", path);
            return;
        }

        if (imageObject.width > imageObject.height) {
            if (imageObject.width <= captureResolution) {
                return;
            }
            imageObject.scaleToWidth(captureResolution);
        }
        else {
            if (imageObject.height <= captureResolution) {
                return;
            }
            imageObject.scaleToHeight(captureResolution)
        }

        //        console.log(logCategory, "Rescaling image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        if (!imageObject.save(path)) {
            console.error(logCategory, "Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        //        console.log(logCategory, "Scaled image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    function rotateImage(path, angle) {
        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, "Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log(logCategory, "File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error(logCategory, "Unable to load image:", path);
            return;
        }

        console.log(logCategory, "Rotating image:", angle, imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        imageObject.rotate(angle);

        if (!imageObject.save(path)) {
            console.error(logCategory, "Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        console.log(logCategory, "Rotated image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var value = attachmentsModel.join();

        console.log(logCategory, arguments.callee.name, "value:", value);

        formData.setValue(bindElement, value);

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

        attachmentsModel.split(value);
        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------

    function setDefaultValue(value) {
        defaultValue = value;

        if (defaultValue > "" && mediaFolder.fileExists(defaultValue)) {
            defaultImageUrl = mediaFolder.fileUrl(defaultValue);
        } else {
            defaultImageUrl = "";
        }

        console.log(logCategory, "image defaultValue:", defaultValue, "defaultImageUrl:", defaultImageUrl);
    }

    //--------------------------------------------------------------------------

    XFormImageWatermarks {
        id: watermarks

        debug: imageControl.debug
        element: imageControl.bindElement
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        property string previewHeightDefinition
        property string previewMode
        property string method

        element: formElement
        attribute: kAttributeStyle

        debug: imageControl.debug

        Component.onCompleted: {
            initialize();
        }

        function initialize(reset) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, JSON.stringify(element));
            }

            if (reset) {
                parseParameters();
            }

            bind(controlStyle, "previewHeightDefinition", Body.kEsriStylePreviewHeight);
            bind(controlStyle, undefined, Body.kEsriStylePreviewMode);
            bind(imageControl, "cameraAddInName", Body.kEsriStyleAddIn);
            bind(controlStyle, undefined, Body.kEsriStyleMethod);
        }

        onPreviewHeightDefinitionChanged: {
            previewHeight = toHeight(previewHeightDefinition, xform.style.imagePreviewHeight);
        }

        onPreviewModeChanged: {
            switch (previewMode.trim().toLocaleLowerCase()) {
            case Body.kStyleCrop:
                imageControl.fillMode = Image.PreserveAspectCrop;
                break;

            case Body.kStyleStretch:
                imageControl.fillMode = Image.Stretch;
                break;

            case Body.kStyleFit:
            default:
                imageControl.fillMode = Image.PreserveAspectFit;
            }
        }

        onMethodChanged: {
            let methods = method
            .toLowerCase()
            .split(",")
            .map(element => element.trim())
            .filter(element => element > "");

            if (debug) {
                console.log(logCategory, "method:", method, "methods:", JSON.stringify(methods));
            }

            if (methods.length > 0) {
                showCamera = methods.indexOf(Body.kStyleCamera) >= 0;
                showBrowse = methods.indexOf(Body.kStyleBrowse) >= 0;
                showMap = methods.indexOf(Body.kStyleMap) >= 0;

                if (!showCamera && !showBrowse && !showMap) {
                    showCamera = true;
                    showBrowse = true;
                    showMap = true;
                }
            } else {
                showCamera = true;
                showBrowse = true;
                showMap = true;
            }

            if (!hasCamera && showCamera) {
                showCamera = false;
                showBrowse = true;
            }
        }
    }

    //--------------------------------------------------------------------------
}
