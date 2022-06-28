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

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "Singletons"

Rectangle {
    id: control

    //--------------------------------------------------------------------------

    property XForm xform

    property real buttonSize: 40 * AppFramework.displayScaleFactor
    property real padding: 2 * AppFramework.displayScaleFactor
    property real pageButtonPadding: 4 * AppFramework.displayScaleFactor
    property alias spacing: layout.spacing
    property bool readOnly: false

    property bool valid: true

    //--------------------------------------------------------------------------

    signal clicked()
    signal okClicked()
    signal okPressAndHold()
    signal printClicked()

    //--------------------------------------------------------------------------

    height: layout.height + padding * 2 + separator.height +  2 * AppFramework.displayScaleFactor

    color: xform.style.footerBackgroundColor

    //--------------------------------------------------------------------------

    Rectangle {
        id: separator

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        visible: parent.color === Colors.kTransparent
        height: visible ? 3 * AppFramework.displayScaleFactor : 0

        color: xform.style.titleBackgroundColor
    }

    HorizontalContrastLine {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        baseColor: separator.visible
                   ? separator.color
                   : control.color
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        onClicked: {
            control.clicked();
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            margins: control.padding
            topMargin: control.padding
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: separator.height / 2
        }

        layoutDirection: xform.layoutDirection

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            enabled: xform.pageNavigator.canGotoPrevious
            opacity: enabled ? 1 : 0

            icon.name: "chevron-left"
            mirror: xform.isRightToLeft
            padding: pageButtonPadding
            mouseArea.anchors.margins: -control.padding

            color: xform.style.footerTextColor

            onClicked: {
                forceActiveFocus()
                xform.pageNavigator.gotoPreviousPage();
            }

            onPressAndHold: {
                forceActiveFocus()
                xform.pageNavigator.gotoFirstPage();
            }
        }

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: xform.canPrint

            icon.name: "print"
            mouseArea.anchors.margins: -control.padding

            color: xform.style.footerTextColor

            onClicked: {
                forceActiveFocus()
                printClicked()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            XFormText {
                anchors{
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                visible: xform.pageNavigator.canGoto
                text: qsTr("%1 of %2").arg(xform.pageNavigator.currentPageNumber).arg(xform.pageNavigator.availableCount)
                font {
                    pointSize: 14
                }
                color: xform.style.footerTextColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    enabled: xform.pageNavigator.availableCount > 0
                    hoverEnabled: true
                    cursorShape: enabled
                                 ? Qt.PointingHandCursor
                                 : Qt.ArrowCursor
                    anchors {
                        fill: parent
                        margins: -control.padding
                    }

                    onClicked: {
                        xform.showPagesPopup();
                    }
                }
            }
        }

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: xform.pageNavigator.canGotoNext

            icon.name: "chevron-right"
            mirror: xform.isRightToLeft
            padding: pageButtonPadding
            mouseArea.anchors.margins: -control.padding

            color: xform.style.footerTextColor

            onClicked: {
                forceActiveFocus()
                xform.pageNavigator.gotoNextPage();
            }

            onPressAndHold: {
                forceActiveFocus()
                xform.pageNavigator.gotoLastPage();
            }
        }

        /*
        StyledImage {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: Layout.preferredHeight / 4

            visible: okButton.visible && xform.formData.editMode > xform.formData.kEditModeAdd

            source: "images/editMode.png"
            color: xform.style.footerTextColor
        }
        */

        StyledImageButton {
            id: okButton

            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: !readOnly && xform.pageNavigator.atLastPage

            icon.name: "check"
            mouseArea.anchors.margins: -control.padding

            color: valid ? xform.style.footerTextColor : Survey.kColorError
            //mirror: xform.localeProperties.isRightToLeft

            onClicked: {
                forceActiveFocus()
                okClicked();
            }

            onPressAndHold: {
                forceActiveFocus()
                okPressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------
}

