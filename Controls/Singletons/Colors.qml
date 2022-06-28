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

QtObject {

    //------------------------------------------------------------------------------

    readonly property color kTransparent: "transparent"

    //------------------------------------------------------------------------------

    function hex2rgba(color, factor) {
        var hex = Qt.lighter(color, 1).toString();

        var a = 255;
        var r = 128;
        var g = 128;
        var b = 128;

        var aOffset = 0;
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        if (!result) {
            result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            if (result) {
                aOffset  = 1;
                a = parseInt(result[1], 16);
            }
        }

        if (result) {
            r = parseInt(result[1 + aOffset], 16);
            g = parseInt(result[2 + aOffset], 16);
            b = parseInt(result[3 + aOffset], 16);
        }

        if (!factor) {
            factor = 1;
        }

        return {
            a: a / factor,
            r: r / factor,
            g: g / factor,
            b: b / factor
        }
    }

    //--------------------------------------------------------------------------

    function contrastColor(color, darkColor, lightColor) {

        function contrast(color) {
            var rgb = hex2rgba(color);
            return (Math.round(rgb.r * 299) + Math.round(rgb.g * 587) + Math.round(rgb.b * 114)) / 1000;
        }

        return (contrast(color) >= 128) ? (darkColor || 'black') : (lightColor || 'white');
    }

    //--------------------------------------------------------------------------

    function luminanace(r, g, b) {
        var rgb = [r, g, b].map(function (v) {
            v /= 255;

            return v <= 0.03928
                ? v / 12.92
                : Math.pow( (v + 0.055) / 1.055, 2.4 );
        });

        return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
    }

    //--------------------------------------------------------------------------
    // https://www.w3.org/TR/2008/REC-WCAG20-20081211/#visual-audio-contrast

    function contrastRatio(color1, color2) {
        var rgba1 = hex2rgba(color1);
        var rgba2 = hex2rgba(color2);

        var lum1 = luminanace(rgba1.r, rgba1.g, rgba1.b);
        var lum2 = luminanace(rgba2.r, rgba2.g, rgba2.b);

        var brightest = Math.max(lum1, lum2);
        var darkest = Math.min(lum1, lum2);

        return (brightest + 0.05) / (darkest + 0.05);
    }

    //--------------------------------------------------------------------------
}

