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

pragma Singleton

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12

import "../../Controls"
import "../MapControls"

Item {
    //--------------------------------------------------------------------------

    property alias icons: icons

    property alias point: pointSymbols
    property string defaultPointSymbolName: "esri-pin-two"
    property color defaultPointSymbolColor: "#3e78b3"
    property int defaultPointSymbolStyle: Text.Outline
    property color defaultPointSymbolStyleColor: "white"

    //--------------------------------------------------------------------------

    GlyphSet {
        id: icons

        source: "../glyphs/Survey123-Icons.ttf"
    }

    GlyphSet {
        id: pointSymbols

        source: "../glyphs/calcite-point-symbols-21.ttf"
    }

    //--------------------------------------------------------------------------
}

