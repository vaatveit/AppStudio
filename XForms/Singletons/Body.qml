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

pragma Singleton

import QtQml 2.12

QtObject {
    //--------------------------------------------------------------------------

    readonly property string kTypeGroup: "group"
    readonly property string kTypeLabel: "label"
    readonly property string kTypeHint: "hint"
    readonly property string kTypeInput: "input"
    readonly property string kTypeRepeat: "repeat"
    readonly property string kTypeSelect: "select"
    readonly property string kTypeSelect1: "select1"
    readonly property string kTypeUpload: "upload"
    readonly property string kTypeRange: "range"

    //--------------------------------------------------------------------------
    // body::esri:style

    readonly property string kEsriStyleAddIn: "addIn"
    readonly property string kEsriStyleMethod: "method"
    readonly property string kEsriStylePlaceholderText: "placeholderText"
    readonly property string kEsriStylePreviewHeight: "previewHeight"
    readonly property string kEsriStylePreviewMode: "previewMode"

    readonly property string kStyleCamera: "camera"
    readonly property string kStyleBrowse: "browse"
    readonly property string kStyleMap: "map"
    readonly property string kStyleFit: "fit"
    readonly property string kStyleCrop: "crop"
    readonly property string kStyleStretch: "stretch"

    //--------------------------------------------------------------------------
    // Multi value separator (select, upload)

    readonly property string kValueSeparator: ","

    //--------------------------------------------------------------------------
    // Special note names generated_note_<notename>

    readonly property string kNoteNameFormTitle: "form_title"

    //--------------------------------------------------------------------------

    readonly property var kReservedNotePrefixes: [
        "generated_note_form_",
        "generated_note_prompt_",
        "generated_note_folder_"
    ]

    readonly property var kReservedNoteNames: [
        kNoteNameFormTitle
    ]

    //--------------------------------------------------------------------------
    // File name filters

    readonly property string kFileFilterImage: qsTr("Images (%1)").arg(kFileTypesImage.map(suffix => "*." + suffix).join(" "))
    readonly property string kFileFilterVideo: qsTr("Videos (%1)").arg(kFileTypesVideo.map(suffix => "*." + suffix).join(" "))
    readonly property string kFileFilterAudio: qsTr("Audio (%1").arg(kFileTypesAudio.map(suffix => "*." + suffix).join(" "))
    readonly property string kFileFilterDocument: qsTr("Documents (%1)").arg(kFileTypesDocument.map(suffix => "*." + suffix).join(" "))
    readonly property string kFileFilterOther: qsTr("Other (%1)").arg(kFileTypesOther.map(suffix => "*." + suffix).join(" "))
    readonly property string kFileFilterAll: qsTr("All files (%1)").arg(kFileTypesAll.map(suffix => "*." + suffix).join(" "))

    //--------------------------------------------------------------------------
    // Supported attachment types
    // https://developers.arcgis.com/rest/services-reference/query-attachments-feature-service-layer-.htm

    // bmp, ecw, emf, eps, ps, gif, img, jp2, jpc, j2k, jpf, jpg, jpeg, jpe,
    // png, psd, raw, sid, tif, tiff, wmf, wps, avi, mpg, mpe, mpeg, mov,
    // wmv, aif, mid, rmi, mp2, mp3, mp4, pma, mpv2, qt, ra, ram, wav, wma,
    // doc, docx, dot, xls, xlsx, xlt, pdf, ppt, pptx, txt, zip, 7z, gz, gtar,
    // tar, tgz, vrml, gml, json, xml, mdb, geodatabase

    readonly property var kFileTypesImage: [
        "jpg", "jpeg", "jpf", "jpe", "png", "psd", "raw", "tif", "tiff",
        "bmp", "gif", "img", "jp2", "jpc", "j2k",
    ]

    readonly property var kFileTypesVideo: [
        "avi", "mpg", "mpe", "mpeg", "mov", "wmv",
        "mp4",  "mpv2", "qt",
    ]

    readonly property var kFileTypesAudio: [
        "wav", "mp3", "mp2", "pma", "ra", "ram", "aif", "wma"
    ]

    readonly property var kFileTypesDocument: [
        "doc", "docx", "dot", "xls", "xlsx", "xlt", "pdf", "ppt", "pptx",
        "csv", "txt", "wps",
    ]

    readonly property var kFileTypesOther: [
        "zip", "7z", "gz", "gtar", "tar", "tgz", "vrml", "gml", "json",
        "xml", "mdb", "geodatabase", "ps", "emf", "eps", "sid", "wmf",
        "pma", "rmi",  "mid", "ecw",
    ]

    readonly property var kFileTypesAll: kFileTypesImage
    .concat(kFileTypesVideo)
    .concat(kFileTypesAudio)
    .concat(kFileTypesDocument)
    .concat(kFileTypesOther)

    //--------------------------------------------------------------------------
}

