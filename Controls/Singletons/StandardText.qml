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

    // StandardButton.<name>

    readonly property var kStandardButtons: {
        0x00000000: "",             // NoButton
        0x00000400: qsTr("OK"),     // OK
        0x00000800: qsTr("Save"),   // Save
        0x00001000: "",             // SaveAll
        0x00002000: qsTr("Open"),   // Open
        0x00004000: qsTr("Yes"),    // Yes
        0x00008000: "",             // YesToAll
        0x00010000: qsTr("No"),     // No
        0x00020000: "",             // NoToAll
        0x00040000: qsTr("Abort"),  // Abort
        0x00080000: qsTr("Retry"),  // Retry
        0x00100000: qsTr("Ignore"), // Ignore
        0x00200000: qsTr("Close"),  // Close
        0x00400000: qsTr("Cancel"), // Cancel
        0x00800000: qsTr("Discard"),// Discard
        0x01000000: qsTr("Help"),   // Help
        0x02000000: qsTr("Apply"),  // Apply
        0x04000000: qsTr("Reset"),  // Reset
        0x08000000: "",             // RestoreDefaults
    }

    //--------------------------------------------------------------------------
}

