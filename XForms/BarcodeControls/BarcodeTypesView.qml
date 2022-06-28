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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0

GridView {
    id: gridView

    //--------------------------------------------------------------------------

    property int referenceWidth: 120 * AppFramework.displayScaleFactor
    property int cells: calcCells(width)
    property bool dynamicSpacing: false
    property int minimumSpacing: 8 * AppFramework.displayScaleFactor
    property int cellSize: 120 * AppFramework.displayScaleFactor

    property bool debug: false

    property int decodeHints: 0

    //--------------------------------------------------------------------------

    readonly property var barcodeTypes: [
        { decodeHint: BarcodeDecoder.DecodeHintQR_CODE,             name: "QR Code" },

        { decodeHint: BarcodeDecoder.DecodeHintCODE_39,             name: "Code-39" },
        { decodeHint: BarcodeDecoder.DecodeHintCODE_93,             name: "Code-93" },
        { decodeHint: BarcodeDecoder.DecodeHintCODE_128,            name: "Code-128" },

        { decodeHint: BarcodeDecoder.DecodeHintEAN_8,               name: "EAN-8" },
        { decodeHint: BarcodeDecoder.DecodeHintEAN_13,              name: "EAN-13" },

        { decodeHint: BarcodeDecoder.DecodeHintUPC_A,               name: "UPC-A" },
        { decodeHint: BarcodeDecoder.DecodeHintUPC_E,               name: "UPC-E" },
        { decodeHint: BarcodeDecoder.DecodeHintUPC_EAN_EXTENSION,   name: "UPC EAN Extension" },

        { decodeHint: BarcodeDecoder.DecodeHintAZTEC,               name: "Aztec" },
        { decodeHint: BarcodeDecoder.DecodeHintCODABAR,             name: "Codabar" },
        { decodeHint: BarcodeDecoder.DecodeHintDATA_MATRIX,         name: "Data Matrix" },
        { decodeHint: BarcodeDecoder.DecodeHintITF,                 name: "ITF" },
        { decodeHint: BarcodeDecoder.DecodeHintMAXICODE,            name: "MaxiCode" },
        { decodeHint: BarcodeDecoder.DecodeHintPDF_417,             name: "PDF417" },
        { decodeHint: BarcodeDecoder.DecodeHintRSS_14,              name: "RSS-14" },
        { decodeHint: BarcodeDecoder.DecodeHintRSS_EXPANDED,        name: "RSS Expanded" }
    ];

    //--------------------------------------------------------------------------

    cellWidth: width / cells
    cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth

    clip: true

    model: barcodeTypes
    delegate: barcodeTypeDelegate

    //--------------------------------------------------------------------------

    onDecodeHintsChanged: {
         console.log("decodeHints:", decodeHints);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(gridView, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: barcodeTypeDelegate

        Rectangle {
            width: cellWidth
            height: cellHeight

            color: "transparent"

            BarcodeTypeDelegate {
                anchors {
                    fill: parent
                    margins: 8 * AppFramework.displayScaleFactor
                }

                barcodeType: barcodeTypes[index]
                selected: !!(decodeHints & barcodeType.decodeHint)

                onClicked: {
                    if (decodeHints & barcodeType.decodeHint) {
                        decodeHints &= ~barcodeType.decodeHint;
                    } else {
                        decodeHints |= barcodeType.decodeHint;
                    }

                    if (decodeHints & BarcodeDecoder.DecodeHintPDF_417) {
                        if (barcodeType.decodeHint === BarcodeDecoder.DecodeHintPDF_417) {
                            decodeHints = BarcodeDecoder.DecodeHintPDF_417;
                        } else {
                            decodeHints &= ~BarcodeDecoder.DecodeHintPDF_417;
                        }
                    }

                    if (decodeHints & BarcodeDecoder.DecodeHintCODE_39) {
                        if (barcodeType.decodeHint === BarcodeDecoder.DecodeHintCODE_39) {
                            decodeHints = BarcodeDecoder.DecodeHintCODE_39;
                        } else {
                            decodeHints &= ~BarcodeDecoder.DecodeHintCODE_39;
                        }
                    }
                }

                onPressAndHold: {
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function calcCells(w) {
        if (dynamicSpacing) {
            return Math.max(1, Math.floor(w / (cellSize + minimumSpacing)));
        }

        var rw =  referenceWidth;
        var c = Math.max(1, Math.round(w / referenceWidth));

        var cw = w / c;

        if (cw > rw) {
            c++;
        }

        cw = w / c;

        if (c > 1 && cw < (rw * 0.85)) {
            c--;
        }

        cw = w / c;

        if (cw > rw) {
            c++;
        }

        return c;
    }

    //--------------------------------------------------------------------------
}
