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
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import "../../Controls"
import "../Singletons"

MapQuickItem {
    //--------------------------------------------------------------------------

    property GlyphSet glyphSet: MapSymbols.point
    property string name: MapSymbols.defaultPointSymbolName
    property real size: 50 * AppFramework.displayScaleFactor
    property point origin: glyphSet.glyphOrigin(name)

    property alias color: glyph.color
    property alias style: glyph.style
    property alias styleColor: glyph.styleColor

    //--------------------------------------------------------------------------

    anchorPoint {
        x: glyphItem.width * origin.x
        y: glyphItem.height * origin.y
    }
    
    sourceItem: Item {
        id: glyphItem

        width: size
        height: size

        Text {
            id: glyph

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: glyphSet.glyphChar(name)
            color: MapSymbols.defaultPointSymbolColor
            style: MapSymbols.defaultPointSymbolStyle
            styleColor: MapSymbols.defaultPointSymbolStyleColor

            font {
                family: glyphSet.font.family
                pixelSize: parent.height
            }
        }
    }

    //--------------------------------------------------------------------------
}
