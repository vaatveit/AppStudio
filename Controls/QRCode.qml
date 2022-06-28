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

import QtQuick 2.12
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

import "QRCode.js" as QRCodeJS

Control {
    id: control

    //--------------------------------------------------------------------------

    property color backgroundColor: "white"
    property color foregroundColor: "black"
    property string level: kLevelL
    property string value
    property alias border: backgroundRectangle.border

    //--------------------------------------------------------------------------

    readonly property string kLevelL: "L"
    readonly property string kLevelM: "M"
    readonly property string kLevelQ: "Q"
    readonly property string kLevelH: "H"

    //--------------------------------------------------------------------------

    implicitWidth: 100 * AppFramework.displayScaleFactor
    implicitHeight: 100 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    contentItem: Canvas {
        id: canvas

        onPaint: {
            if (available) {
                var qr = QRCodeJS.get_qr();
                qr.canvas({
                              background : control.backgroundColor,
                              canvas : canvas,
                              foreground : control.foregroundColor,
                              level : control.level,
                              side : Math.min(canvas.width, canvas.height),
                              value : control.value
                          });
            }
        }

        onHeightChanged: {
            requestPaint();
        }

        onWidthChanged: {
            requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: backgroundRectangle

        color: backgroundColor
    }

    //--------------------------------------------------------------------------

    onBackgroundColorChanged: {
        canvas.requestPaint();
    }

    onForegroundColorChanged: {
        canvas.requestPaint();
    }

    onLevelChanged: {
        canvas.requestPaint();
    }

    onValueChanged: {
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------
}
