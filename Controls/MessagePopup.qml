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
import QtQuick.Dialogs 1.3

import ArcGIS.AppFramework 1.0

import "Singletons"

ActionsPopup {
    id: popup

    //--------------------------------------------------------------------------

    property int standardIcon: StandardIcon.NoIcon
    property int standardButtons: StandardButton.NoButton
    property bool closeOnTriggered: true

    //--------------------------------------------------------------------------

    property alias okAction: okAction
    property alias cancelAction: cancelAction
    property alias yesAction: yesAction
    property alias noAction: noAction
    property alias applyAction: applyAction
    property alias retryAction: retryAction
    property alias ignoreAction: ignoreAction
    property alias helpAction: helpAction
    property alias discardAction: discardAction
    property alias openAction: openAction
    property alias saveAction: saveAction
    property alias resetAction: resetAction

    //--------------------------------------------------------------------------

    signal triggered(Action action)
    signal accepted(Action action)
    signal rejected(Action action)
    signal yes(Action action)
    signal no(Action action)
    signal apply(Action action)
    signal help(Action action)
    signal discard(Action action)
    signal reset(Action action)

    //--------------------------------------------------------------------------

    readonly property var kStandardIconColors: [
        palette.windowText,             // NoIcon = 0,
        "#0000a8",                      // Information = 1,
        "#a80000",                      // Warning = 2,
        "#a80000",                      // Critical = 3,
        palette.windowText              // Question = 4
    ]

    //--------------------------------------------------------------------------

    icon {
        name: Icons.kStandardIcons[standardIcon]
        color: kStandardIconColors[standardIcon]
    }

    actionsLayout {
        onTriggered: {
            switch (action.role) {
            case DialogButtonBox.AcceptRole:
                accepted(action);
                break;

            case DialogButtonBox.RejectRole:
                rejected(action);
                break;

            case DialogButtonBox.DestructiveRole:
                discard(action);
                break;

            case DialogButtonBox.HelpRole:
                help(action);
                break;

            case DialogButtonBox.YesRole:
                yes(action);
                break;

            case DialogButtonBox.NoRole:
                no(action);
                break;

            case DialogButtonBox.ResetRole:
                reset(action);
                break;

            case DialogButtonBox.ApplyRole:
                apply(action);
                break;

            case DialogButtonBox.InvalidRole:
            case DialogButtonBox.ActionRole:
            default:
                break;
            }

            popup.triggered(action);
            if (closeOnTriggered) {
                close();
            }
        }
    }

    //--------------------------------------------------------------------------

    StandardAction {
        id: okAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Ok
    }

    StandardAction {
        id: saveAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Save
    }

    StandardAction {
        id: openAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Open
    }

    StandardAction {
        id: yesAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Yes
    }

    StandardAction {
        id: retryAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Retry
    }

    StandardAction {
        id: ignoreAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Ignore
    }

    StandardAction {
        id: applyAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Apply
    }

    StandardAction {
        id: cancelAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Cancel
    }

    StandardAction {
        id: noAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.No
    }

    StandardAction {
        id: discardAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Discard
    }

    StandardAction {
        id: resetAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Reset
    }

    StandardAction {
        id: helpAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Help
    }

    StandardAction {
        id: closeAction

        enabled: standardButtons & standardButton
        standardButton: StandardButton.Close
    }

    //--------------------------------------------------------------------------
}
