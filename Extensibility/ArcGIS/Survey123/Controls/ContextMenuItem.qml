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

import QtQuick 2.12
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

MenuItem {
    id: menuItem

    //--------------------------------------------------------------------------

    property color highlightColor: menu.highlightColor
    property Shortcut shortcut: Shortcut {}

    //--------------------------------------------------------------------------

    rightPadding: 50 * AppFramework.displayScaleFactor + shortcutText.anchors.rightMargin

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        icon.height = contentItem.height * 0.8;
        icon.width = icon.height;
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        implicitWidth: menu.width - 5 * AppFramework.displayScaleFactor
        implicitHeight: 40 * AppFramework.displayScaleFactor

        opacity: enabled ? 1 : 0.3
        color: menuItem.highlighted ? highlightColor : "transparent"
    }

    //--------------------------------------------------------------------------

    Text {
        id: shortcutText

        anchors {
            right: parent.right
            rightMargin: 5 * AppFramework.displayScaleFactor
            top: parent.top
            bottom: parent.bottom
        }

        text: shortcut.nativeText
        font: menuItem.font
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        opacity: menuItem.enabled ? 1 : 0.3
    }

    //--------------------------------------------------------------------------
}
