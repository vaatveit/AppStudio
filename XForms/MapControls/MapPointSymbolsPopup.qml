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
import QtQml.Models 2.12
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0

import ".."
import "../Singletons"
import "../../Controls"
import "../../Controls/Singletons"
import "../../Models"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property bool debug: false
    property alias page: page
    property alias header: page.header
    property alias footer: page.footer

    property string title: qsTr("Select map symbol")
    property string currentName
    property alias currentIndex: gridView.currentIndex

    //--------------------------------------------------------------------------

    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    width: parent.width * 0.8
    height: parent.height * 0.75

    backgroundRectangle.color: "#f4f4f4"

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    onOpened: {
        var model = mapSymbolsModel;

        for (var i = 0; i < model.count; i++) {
            if (model.get(i).name === currentName) {
                currentIndex = i;
                gridView.positionViewAtIndex(i, GridView.Center);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        debug = !debug;
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: mapSymbolsModel

        Component.onCompleted: {
            for (let [key, value] of Object.entries(MapSymbols.point.names)) {
                append({
                           name: key
                       });
            }
        }
    }

    SortFilterDelegateModel {
        id: delegateModel

        model: mapSymbolsModel
        delegate: mapSymbolDelegate

        sortRole: "name"

        filterRole: "name"
        filterFunction: (item) => {
                            if (item.name === currentName) {
                                return true;
                            }

                            return _filterFunction(item);
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

        SearchTextBox {
            id: searchTextBox

            Layout.fillWidth: true

            onEditingFinished: {
                delegateModel.filterValue = text;
            }
        }

        Item {
            Layout.fillWidth: true
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

            clip: true

            GridView {
                id: gridView

                //--------------------------------------------------------------------------

                property int referenceWidth: 120 * AppFramework.displayScaleFactor
                property int cells: calcCells(width)
                property bool dynamicSpacing: false
                property int minimumSpacing: 8 * AppFramework.displayScaleFactor
                property int cellSize: 120 * AppFramework.displayScaleFactor

                //--------------------------------------------------------------------------

                width: scrollView.availableWidth
                height: scrollView.availableHeight

                cellWidth: width / cells
                cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth

                model: delegateModel

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

        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapSymbolDelegate

        Rectangle {
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            color: "transparent"

            MapPointSymbolDelegate {
                anchors {
                    fill: parent
                    margins: 8 * AppFramework.displayScaleFactor
                }

                name: model.name
                origin: MapSymbols.point.glyphOrigin(model.name)
                originVisible: popup.debug
                selected: model.name === currentName

                onClicked: {
                    currentIndex = index;
                    currentName = model.name;

                    popup.close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
