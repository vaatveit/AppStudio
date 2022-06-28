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

    //--------------------------------------------------------------------------

    readonly property var kCardinalDirectionNames: [
        qsTr("N"),
        qsTr("NNE"),
        qsTr("NE"),
        qsTr("ENE"),
        qsTr("E"),
        qsTr("ESE"),
        qsTr("SE"),
        qsTr("SSE"),
        qsTr("S"),
        qsTr("SSW"),
        qsTr("SW"),
        qsTr("WSW"),
        qsTr("W"),
        qsTr("WNW"),
        qsTr("NW"),
        qsTr("NNW")
    ];

    //--------------------------------------------------------------------------

    function cardinalDirectionName(degrees) {
        if (!isFinite(degrees)) {
            return "";
        }

        var index = Math.floor(((degrees / 22.5) + 0.5) + 720) % 360;
        return kCardinalDirectionNames[index % 16];
    }

    //--------------------------------------------------------------------------

    function distanceText(distance, measurementSystem, locale) {
        if (!locale) {
            locale = ControlsSingleton.localeProperties.numberLocale;
        }

        if (measurementSystem === undefined) {
            measurementSystem = locale.measurementSystem;
        }

        var factor;

        switch (measurementSystem) {
        case Locale.ImperialUSSystem:
        case Locale.ImperialUKSystem:
            var distanceFt = distance * 3.28084;
            if (distanceFt < 6) {
                return "%1 ft".arg((Math.round(distanceFt * 10) / 10).toLocaleString(locale, "f", 1))
            } else if (distanceFt < 1000) {
                return "%1 ft".arg(Math.round(distanceFt).toLocaleString(locale, "f", 0))
            } else {
                var distanceMiles = distance * 0.000621371;
                factor = distanceMiles < 10 ? 10 : 1;
                return "%1 mi".arg((Math.round(distanceMiles * factor) / factor).toLocaleString(locale, "f", distanceMiles < 10 ? 1 : 0))
            }

        default:
            if (distance < 10) {
                return "%1 m".arg((Math.round(distance * 10) / 10).toLocaleString(locale, "f", 1))
            } else if (distance < 1000) {
                return "%1 m".arg(Math.round(distance).toLocaleString(locale, "f", 0))
            } else {
                var distanceKm = distance / 1000;
                factor = distanceKm < 10 ? 10 : 1;
                return "%1 km".arg((Math.round(distanceKm * factor) / factor).toLocaleString(locale, "f", distanceKm < 10 ? 1 : 0))
            }
        }
    }

    //--------------------------------------------------------------------------
}

