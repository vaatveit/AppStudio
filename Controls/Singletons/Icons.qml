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

import ".."

IconSet {

    //--------------------------------------------------------------------------

    readonly property string kIconFile: "file"

    readonly property var kFileIcons: {
        "file-pdf": [ "pdf" ],
        "file-excel": [ "xls", "xlsx" ],
        "file-word": [ "doc", "docx" ],
        "file-image": [ "png", "jpg", "jpeg", "tif", "tiff", "gif" ],
        "file-video": [ "mov", "avi", "mp4", "mpg" ],
        "file-sound": [ "wav", "mp3", "ogg" ],
        "file-text": [ "txt", "log", "nmea", "json" ],
        "file-csv": [ "csv" ],
        "file-zip": [ "zip" ],
        "file-archive": [ "7z" ],
        "file-gpx": [ "gpx" ],
        "file-code": [ "xml" ],
        "file-cad": [ "dwg" ]
    }

    //--------------------------------------------------------------------------

    // StandardIcon.<name>

    readonly property var kStandardIcons: [
        "",                             // NoIcon = 0,
        "information",                  // Information = 1,
        "exclamation-mark-triangle",    // Warning = 2,
        "exclamation-mark-circle",      // Critical = 3,
        "question"                      // Question = 4
    ]

    // StandardButton.<name>

    readonly property var kStandardButtonIcons: {
        0x00000000: "",             // NoButton
        0x00000400: "check-circle", // OK
        0x00000800: "save",         // Save
        0x00001000: "save",         // SaveAll
        0x00002000: "launch",       // Open
        0x00004000: "check-circle", // Yes
        0x00008000: "check-circle", // YesToAll
        0x00010000: "x-circle",     // No
        0x00020000: "x-circle",     // NoToAll
        0x00040000: "",             // Abort
        0x00080000: "refresh",      // Retry
        0x00100000: "minus-circle", // Ignore
        0x00200000: "x-circle",     // Close
        0x00400000: "x-circle",     // Cancel
        0x00800000: "trash",        // Discard
        0x01000000: "question",     // Help
        0x02000000: "",             // Apply
        0x04000000: "reset",        // Reset
        0x08000000: "reset",        // RestoreDefaults
    }

    //--------------------------------------------------------------------------

    bold: ControlsSingleton.font.bold

    //--------------------------------------------------------------------------

    function fileIconName(suffix) {
        if (!suffix) {
            return kIconFile;
        }

        for (let [icon, suffixes] of Object.entries(kFileIcons)) {
            if (suffixes.indexOf(suffix.toLowerCase()) >= 0) {
                return icon;
            }
        }

        return kIconFile;
    }

    //--------------------------------------------------------------------------
}

