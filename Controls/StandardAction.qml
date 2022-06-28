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
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import "Singletons"

Action {
    //--------------------------------------------------------------------------

    property int standardButton
    property int role: (typeof kStandardButtonRoles[standardButton] === "number")
                       ? kStandardButtonRoles[standardButton]
                       : DialogButtonBox.InvalidRole

    //--------------------------------------------------------------------------

    readonly property var kStandardButtonRoles: {
        0x00000000: DialogButtonBox.InvalidRole,        // NoButton
        0x00000400: DialogButtonBox.AcceptRole,         // OK
        0x00000800: DialogButtonBox.AcceptRole,         // Save
        0x00001000: DialogButtonBox.AcceptRole,         // SaveAll
        0x00002000: DialogButtonBox.AcceptRole,         // Open
        0x00004000: DialogButtonBox.YesRole,            // Yes
        0x00008000: DialogButtonBox.YesRole,            // YesToAll
        0x00010000: DialogButtonBox.NoRole,             // No
        0x00020000: DialogButtonBox.NoRole,             // NoToAll
        0x00040000: DialogButtonBox.RejectRole,         // Abort
        0x00080000: DialogButtonBox.AcceptRole,         // Retry
        0x00100000: DialogButtonBox.AcceptRole,         // Ignore
        0x00200000: DialogButtonBox.RejectRole,         // Close
        0x00400000: DialogButtonBox.RejectRole,         // Cancel
        0x00800000: DialogButtonBox.DestructiveRole,    // Discard
        0x01000000: DialogButtonBox.HelpRole,           // Help
        0x02000000: DialogButtonBox.ApplyRole,          // Apply
        0x04000000: DialogButtonBox.ResetRole,          // Reset
        0x08000000: DialogButtonBox.ResetRole,          // RestoreDefaults
    }

    //--------------------------------------------------------------------------

    text: StandardText.kStandardButtons[standardButton]
    icon.name: Icons.kStandardButtonIcons[standardButton]

    //--------------------------------------------------------------------------

}
