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

Control {
    id: control

    //--------------------------------------------------------------------------

    property ActionGroup actionGroup
    property alias delegate: repeater.delegate

    //--------------------------------------------------------------------------

    signal triggered(Action action)

    //--------------------------------------------------------------------------

    palette {
        button: "white"
        buttonText: "black"

        highlight: "#ecfbff"
        highlightedText: "black"

        mid: "#e1f0fb"
        dark: "lightgrey"
        light: "#f0fff0"            // Accent
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        id: layout

        spacing: 1 * AppFramework.displayScaleFactor

        Repeater {
            id: repeater

            model: actionGroup.actions

            delegate: defaultDelegate
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: defaultDelegate

        ActionGroupButton {
            id: button

            Layout.fillWidth: true

            visible: repeater.model[index].enabled
            action: repeater.model[index]

            palette {
                button: palette.button
                light: palette.light
            }

            Connections {
                target: button.action

                function onTriggered() {
                    control.triggered(button.action);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
