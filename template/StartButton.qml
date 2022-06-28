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
import "../Controls/Singletons"

Button {
    id: control

    //--------------------------------------------------------------------------

    property bool reverseColor: false
    property bool showBorder: true

    property color textColor: app.info.propertyValue("startTextColor", "white")
    property color backgroundColor: app.info.propertyValue("startBackgroundColor", "#e0e0df")


    //--------------------------------------------------------------------------

    font: ControlsSingleton.font

    palette {
        button: reverseColor
                ? textColor
                : backgroundColor

        buttonText: reverseColor
                    ? backgroundColor
                    : textColor
    }

    padding: 16 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: backgroundRectangle

        color: palette.button
        radius: 8 * AppFramework.displayScaleFactor
        border {
            width: showBorder ? 1 * AppFramework.displayScaleFactor : 0
            color: palette.buttonText
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
    }

    //--------------------------------------------------------------------------

    contentItem: Label {
        text: control.text
        color: palette.buttonText
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font {
            pointSize: 15
        }
    }

    //--------------------------------------------------------------------------
}

