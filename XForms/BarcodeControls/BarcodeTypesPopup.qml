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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0

import ".."
import "../../Controls"
import "../../Controls/Singletons"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property bool debug: false
    property alias page: page
    property alias header: page.header
    property alias footer: page.footer

    property string title: qsTr("Select barcode types")

    property alias decodeHints: barcodeTypesView.decodeHints
    property int defaultDecodeHints: 0

    readonly property int kAllHints: (2 ** (BarcodeDecoder.BarcodeTypeUPC_EAN_EXTENSION + 1) - 1) & 0xFFFFFFFE & ~BarcodeDecoder.DecodeHintCODE_39 & ~BarcodeDecoder.DecodeHintPDF_417

    //--------------------------------------------------------------------------

    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    width: parent.width * 0.8
    height: parent.height * 0.75

    backgroundRectangle.color: "#f4f4f4"

    closePolicy: !decodeHints
                 ? Popup.NoAutoClose
                 : Popup.CloseOnEscape | Popup.CloseOnPressOutside

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        if (decodeHints !== kAllHints) {
            decodeHints = kAllHints;
        } else {
            decodeHints = 0;
        }
    }

    //--------------------------------------------------------------------------

    header: ColumnLayout {
        visible: title > ""
        spacing: 5 * AppFramework.displayScaleFactor

        XFormText {
            id: titleText

            Layout.fillWidth: true

            text: title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            color: popup.palette.windowText

            font {
                pointSize: 16
            }

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    titlePressAndHold();
                }
            }

        }

        Item {
            height: 1
        }
    }

    //--------------------------------------------------------------------------

    contentItem: Page {
        id: page

        background: null

        ScrollView {
            id: scrollView

            anchors.fill: parent

            BarcodeTypesView {
                id: barcodeTypesView

                width: scrollView.availableWidth
                height: scrollView.availableHeight
            }
        }
    }

    //--------------------------------------------------------------------------
}
