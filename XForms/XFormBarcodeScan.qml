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
import QtMultimedia 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0

import "../Controls"
import "../Controls/Singletons"

import "BarcodeControls"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property string title: qsTr("Scan")
    property string subtitle

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.9)

    property alias barcodeSettings: barcodeScanView.barcodeSettings

    //--------------------------------------------------------------------------

    signal codeScanned(string code)

    //--------------------------------------------------------------------------

    color: "#D0000000"

    //--------------------------------------------------------------------------

    onCodeScanned: {
        audio.play();
    }

    Audio {
        id: audio

        source: "audio/barcode-ok.mp3"
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            id: titleBar

            Layout.fillWidth: true

            property int buttonHeight: 35 * AppFramework.displayScaleFactor

            height: columnLayout.height + 5
            color: barBackgroundColor //"#80000000"

            ColumnLayout {
                id: columnLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2
                }

                RowLayout {
                    Layout.fillWidth: true

                    StyledImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        source: ControlsSingleton.backIcon
                        padding: ControlsSingleton.backIconPadding

                        color: xform.style.titleTextColor

                        onClicked: {
                            close();
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: title
                        font {
                            pointSize: xform.style.titlePointSize
                            family: xform.style.titleFontFamily
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: barTextColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    XFormImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        icon.name: "gear"
                        padding: ControlsSingleton.backIconPadding

                        color: xform.style.titleTextColor

                        onClicked: {
                            barcodeTypesPopup.createObject(page).open();
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true

                    text: subtitle
                    visible: text > ""
                    font {
                        pointSize: 12
                    }
                    horizontalAlignment: Text.AlignHCenter
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }
        }

        XFormBarcodeScanView {
            id: barcodeScanView

            Layout.fillWidth: true
            Layout.fillHeight: true

            onCodeScanned: {
                page.close();
                page.codeScanned(code);
            }
        }
    }

    //--------------------------------------------------------------------------

    function close() {
        parent.pop();
    }

    //--------------------------------------------------------------------------

    Component {
        id: barcodeTypesPopup

        BarcodeTypesPopup {
            decodeHints: barcodeScanView.decodeHints & ~BarcodeDecoder.DecodeHintTryHarder
            defaultDecodeHints: barcodeSettings.defaultDecodeHints

            onClosed: {
                barcodeScanView.decodeHints = decodeHints;
            }
        }
    }

    //--------------------------------------------------------------------------
}
