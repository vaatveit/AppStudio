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

import "XForm.js" as XFormJS
import "../Controls"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property XFormPageNavigator pageNavigator
    readonly property var availablePages: pageNavigator.availablePages

    property bool showPageNumber: false
    property bool showCurrentPage: true

    //--------------------------------------------------------------------------

    signal pageSelected(var page, bool close)

    //--------------------------------------------------------------------------

    contentWidth: 250 * AppFramework.displayScaleFactor
    contentHeight: Math.min(layout.implicitHeight, parent.height * 0.7)

    //--------------------------------------------------------------------------

    onPageSelected: {
        pageNavigator.gotoPage(page);

        if (close) {
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: availableWidth
        height: availableHeight
        spacing: 5 * AppFramework.displayScaleFactor

        XFormText {
            Layout.fillWidth: true

            text: qsTr("Go to page")

            color: popup.style.popupTextColor
            font {
                family: popup.font.family
                pointSize: popup.style.popupTitlePointSize
                bold: true
            }

            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    showCurrentPage = !showCurrentPage;
                }
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            ListView {
                id: listView

                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                width: scrollView.availableWidth
                spacing: layout.spacing

                model: availablePages
                delegate: pageDelegate
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: pageDelegate

        Rectangle {
            readonly property XFormCollapsibleGroupControl page: model.modelData
            readonly property int pageNumber: pageNavigator.pages.indexOf(page) + 1

            width: ListView.view.width
            height: layout.height + 2 * layout.anchors.margins

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    pageSelected(page, true);
                }

                onPressAndHold: {
                    pageSelected(page, false);
                }
            }

            color: mouseArea.pressed
                   ? style.popupPressedColor
                   : mouseArea.containsMouse
                     ? style.popupHoverColor
                     : popup.backgroundRectangle.color

            radius: 3 * AppFramework.displayScaleFactor

            RowLayout {
                id: layout

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: 8 * AppFramework.displayScaleFactor
                    verticalCenter: parent.verticalCenter
                }

                layoutDirection: xform.layoutDirection
                spacing: 5 * AppFramework.displayScaleFactor

                Item {
                    Layout.preferredHeight: 25 * AppFramework.displayScaleFactor
                    Layout.preferredWidth: Layout.preferredHeight

                   visible: showCurrentPage

                    Glyph {
                        anchors {
                            fill: parent
                        }

                        visible: pageNumber === pageNavigator.currentPageNumber
                        name: "check"
                        color: popup.style.popupTextColor
                    }
                }

                XFormText {
                    Layout.minimumWidth: 30 * AppFramework.displayScaleFactor
                    Layout.fillHeight: true

                    visible: showPageNumber
                    text: pageNumber

                    color: popup.style.popupTextColor
                    font {
                        family: popup.font.family
                        pointSize: 16 * popup.style.textScaleFactor
                    }

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

               XFormText {
                    Layout.fillWidth: true

                    text: page.labelControl
                          ? XFormJS.stripHtml(page.labelControl.labelText)
                          : qsTr("Page %1").arg(pageNumber)

                    color: popup.style.popupTextColor
                    font {
                        family: popup.font.family
                        pointSize: 16 * popup.style.textScaleFactor
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 3
                    horizontalAlignment: xform.localeInfo.textAlignment
                    elide: xform.localeInfo.textElide
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
