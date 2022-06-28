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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as QC1
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"
import "../Controls"
import "../XForms"

SearchTextBox {
    id: control

    //--------------------------------------------------------------------------

    property QC1.StackView stackView: app.mainStackView
    property Settings settings: app.settings
    property string settingsKey: "searchField"

    property bool scannerEnabled: false
    property Component scannerPage: scanBarcodePage

    property string textSource

    //--------------------------------------------------------------------------

    font {
        pointSize: 16
        family: app.fontFamily
    }

    activeBorderColor: app.titleBarBackgroundColor

    //--------------------------------------------------------------------------

    rightIndicator: TextBoxButton {
        visible: scannerEnabled
                 && !control.text.length
                 && QtMultimedia.availableCameras.length > 0

        icon.name: "qr-code"

        onClicked: {
            stackView.push({
                               item: scannerPage
                           });
        }

        onPressAndHold: {
            // Select scanner
        }
    }

    //--------------------------------------------------------------------------

    onKeysPressed: {
        textSource = "";
    }

    //--------------------------------------------------------------------------

    Component {
        id: scanBarcodePage

        XFormBarcodeScan {
            barcodeSettings {
                settings: control.settings
                settingsKey: control.settingsKey
            }

            onCodeScanned: {
                control.textSource = "scanner";
                control.text = code.trim();
                control.editingFinished();
                control.entered();
            }
        }
    }

    //--------------------------------------------------------------------------
}
