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

.pragma library

.import ArcGIS.AppFramework 1.0 as AF

//------------------------------------------------------------------------------

// see https://www.ngdc.noaa.gov/geomag-web/#declination

//------------------------------------------------------------------------------

function requestMagneticDeclination(coordinate, callback) {
    if (!coordinate.isValid) {
        return;
    }

    var requestUrl = "https://www.ngdc.noaa.gov/geomag-web/calculators/calculateDeclination?lat1=%1&lon1=%2&resultFormat=xml"
    .arg(coordinate.latitude.toString())
    .arg(coordinate.longitude.toString())

    var request = new XMLHttpRequest();

    request.onreadystatechange = function() {
        switch(request.readyState) {
        case XMLHttpRequest.DONE:
            callback(parseResponse(request.responseText));
            break;
        }
    }

    console.log("Requesting:", requestUrl);

    request.open("GET", requestUrl);
    request.send();
}

//--------------------------------------------------------------------------

function parseResponse(xml) {
    let json = AF.AppFramework.xmlToJson(xml);

    //console.log("result json:", JSON.stringify(json, undefined, 2));

    function parseResultValue(name) {
        let node = json.result[name];

        return {
            value: parseFloat(node["#text"]),
            units: node["@units"]
        };
    }

    let result = {
        declination: parseResultValue("declination"),
        declination_sv: parseResultValue("declination_sv"),
        declination_uncertainty: parseResultValue("declination_uncertainty"),
        elevation: parseResultValue("elevation"),
        elevation: parseResultValue("latitude"),
        elevation: parseResultValue("longitude")
    };

    console.log("result:", JSON.stringify(result, undefined, 2));

    return result;
}

//------------------------------------------------------------------------------
