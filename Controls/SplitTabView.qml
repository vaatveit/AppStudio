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

import "Singletons"

Page {
    id: control

    //--------------------------------------------------------------------------

    default property alias contentItemData: dualView.contentData

    property alias footerControl: footerControl
    property alias footerBackground: footerBackground
    property alias footerLayout: footerLayout
    property alias footerSeparator: footerSeparator
    property real footerSpacing: 5 * AppFramework.displayScaleFactor

    property alias currentIndex: dualView.currentIndex

    property alias color: backgroundRect.color

    property alias tabs: tabIndicator
    property alias dualView: dualView

    //--------------------------------------------------------------------------

    font: ControlsSingleton.font
    clip: true

    //--------------------------------------------------------------------------

    contentItem: DualView {
        id: dualView
    }

    background: Rectangle {
        id: backgroundRect

        color: "white"
    }
    
    //--------------------------------------------------------------------------

    footer: Control {
        id: footerControl

        padding: 5 * AppFramework.displayScaleFactor
        topPadding: (footerSeparator.visible ? footerSeparator.height : 0) + footerControl.padding

        background: Rectangle {
            id: footerBackground

            color: "black"

            Rectangle {
                id: footerSeparator

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }

                visible: false
                height: 3 * AppFramework.displayScaleFactor
                color: "black"
            }
        }

        contentItem: RowLayout {
            id: footerLayout

            layoutDirection: ControlsSingleton.localeProperties.layoutDirection
            spacing: footerSpacing

            SplitTabIndicator {
                id: tabIndicator

                Layout.fillWidth: true

                spacing: footerSpacing
                dualView: dualView
                padding: 0

                font.family: control.font.family
            }
        }
    }

    //--------------------------------------------------------------------------
}
