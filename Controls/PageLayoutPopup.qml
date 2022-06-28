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

import "../Controls"

StyledPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    default property alias contentLayoutData: contentLayout.data

    property alias page: page
    property alias header: page.header
    property alias footer: page.footer

    property alias headerLayout: headerLayout
    property alias contentLayout: contentLayout
    property alias footerLayout: headerLayout

    property alias title: titleLabel.text
    property alias titleLabel: titleLabel
    property alias titleSeparator: titleSeparator

    property alias icon: iconImage.icon

    property int iconAnimation: PageLayoutPopup.IconAnimation.None

    //--------------------------------------------------------------------------

    enum IconAnimation {
        None = 0x00,
        Rotate = 0x01,
        Pulse = 0x02
    }

    //--------------------------------------------------------------------------

    signal iconClicked()
    signal iconPressAndHold()
    signal titleClicked()
    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor

    contentHeight: page.height

    //--------------------------------------------------------------------------

    Page {
        id: page

        width: popup.availableWidth

        background: null

        header: ColumnLayout {
            id: headerLayout

            width: page.availableWidth
            spacing: popup.spacing

            IconImage {
                id: iconImage

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                visible: icon.source > "" || icon.name > ""

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        iconClicked();
                    }

                    onPressAndHold: {
                        iconPressAndHold();
                    }
                }
            }

            PopupLabel {
                id: titleLabel

                Layout.fillWidth: true
                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                Layout.rightMargin: 10 * AppFramework.displayScaleFactor

                visible: text.length > 0

                font {
                    pointSize: 16
                    bold: true
                }

                mouseArea {
                    enabled: true
                    cursorShape: Qt.ArrowCursor
                }

                onClicked: {
                    titleClicked();
                }

                onPressAndHold: {
                    titlePressAndHold();
                }
            }

            HorizontalSeparator {
                id: titleSeparator

                Layout.fillWidth: true
                Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

                visible: titleLabel.visible
            }
        }

        contentHeight: contentLayout.height

        ColumnLayout {
            id: contentLayout

            width: page.availableWidth
            spacing: popup.spacing
        }

        footer: ColumnLayout {
            id: footerLayout

            width: page.availableWidth
            spacing: popup.spacing
        }
    }

    //--------------------------------------------------------------------------

    RotationAnimator {
        target: iconImage
        from: 0
        to: 360
        duration: 2000
        running: popup.visible && (iconAnimation & PageLayoutPopup.IconAnimation.Rotate)
        loops: Animation.Infinite

        onFinished: {
            target.rotation = from;
        }
    }

    PulseAnimation {
        target: iconImage

        running: popup.visible && (iconAnimation & PageLayoutPopup.IconAnimation.Pulse)
    }

    //--------------------------------------------------------------------------
}
