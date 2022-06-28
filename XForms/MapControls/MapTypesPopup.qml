/* Copyright 2019 Esri
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
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls"
import "../../Controls/Singletons"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias map: mapTypesView.map

    property bool debug: false
    property alias page: page
    property alias header: page.header
    property alias footer: page.footer

    property string title: qsTr("Select a basemap")

    readonly property bool isBasicMap: map.plugin.name === "AppStudio" || !app.portal.signedIn

    //--------------------------------------------------------------------------

    signal titlePressAndHold()
    signal mapTypeChanged(var mapType)

    //--------------------------------------------------------------------------

    width: parent.width * 0.75
    height: parent.height * 0.75

    backgroundRectangle.color: "#f4f4f4";

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        filterLayout.visible = !filterLayout.visible;
        mapTypesView.showContentStatus = true;
    }

    //--------------------------------------------------------------------------

    header: ColumnLayout {
        spacing: 5 * AppFramework.displayScaleFactor

        XFormText {
            Layout.fillWidth: true

            visible: title > ""

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

        RowLayout {
            id: filterLayout

            Layout.fillWidth: true

            visible: false
            layoutDirection: ControlsSingleton.localeProperties.layoutDirection

            SortButton {
                id: sortButton

                Layout.preferredHeight: searchTextBox.height
                Layout.preferredWidth: Layout.preferredHeight

                onClicked: {
                    sortPopup.createObject(page).open();
                }
            }

            SearchTextBox {
                id: searchTextBox

                Layout.fillWidth: true

                font {
                    family: popup.font.family
                }

                onStart: {
                    mapTypesView.filter(text);
                }

                onEditingFinished: {
                    if (hasActiveFocus) {
                        mapTypesView.filter(text);
                    }
                }
            }

            StyledImageButton {
                id: filterButton

                Layout.preferredHeight: searchTextBox.height
                Layout.preferredWidth: Layout.preferredHeight

                visible: app.portal.signedIn // HACK to global property
                checkable: false
                checked: mapTypesView.isFiltered

                source: Icons.icon("filter", checked)
                padding: sortButton.padding

                onClicked: {
                    var filterPopup = mapTypesFilterPopup.createObject(mapTypesView);
                    filterPopup.open();
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

            MapTypesView {
                id: mapTypesView

                width: scrollView.availableWidth
                height: scrollView.availableHeight


                showBasicMaps: isBasicMap
                showSharedMaps: !isBasicMap
                showContentStatus: false

                onClicked: {
                    if (debug) {
                        console.log(logCategory, "mapType:", JSON.stringify(mapType, undefined, 2));
                    }

                    map.activeMapType = mapType;
                    mapTypeChanged(mapType);

                    popup.close();
                }

                onPressAndHold: {
                    console.log(logCategory, "mapType:", JSON.stringify(mapType, undefined, 2));
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypesFilterPopup

        MapTypesFilterPopup {
            basicBasemaps: mapTypesView.showBasicMaps
            sharedBasemaps: mapTypesView.showSharedMaps

            onAccepted: {
                mapTypesView.showBasicMaps = basicBasemaps;
                mapTypesView.showSharedMaps = sharedBasemaps;

                mapTypesView.filter();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sortPopup

        SortPopup {
            sortTypes: SortPopup.SortType.Alphabetical

            sortType: SortPopup.SortType.Alphabetical
            sortOrder: mapTypesView.sortOrder

            onSortOrderChanged: {
                mapTypesView.sortOrder;
            }

            onClicked: {
                mapTypesView.sort();
            }
        }
    }

    //--------------------------------------------------------------------------
}
