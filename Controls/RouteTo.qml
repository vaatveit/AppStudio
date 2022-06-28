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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

QtObject {
    //--------------------------------------------------------------------------

    property var fromCoordinate
    
    //--------------------------------------------------------------------------
    
    function routeToNavigator(coordinate, callbackUrl, callbackPrompt) {
        var stop = "%1,%2".arg(coordinate.latitude).arg(coordinate.longitude);
        
        return "https://navigator.arcgis.app/?stop=%1&navigate=true&callback=%2&callbackprompt=%3"
        .arg(stop)
        .arg(callbackUrl)
        .arg(callbackPrompt);
    }
    
    //--------------------------------------------------------------------------
    
    function routeToTrek2There(coordinate, callbackUrl, callbackPrompt) {
        var stop = "%1,%2"
        .arg(coordinate.latitude.toString())
        .arg(coordinate.longitude.toString());
        
        return "arcgis-trek2there://?stop=%1".arg(stop);
    }
    
    //--------------------------------------------------------------------------
    
    function routeToAppleMaps(coordinate, callbackUrl, callbackPrompt) {
        var ll = "%1,%2"
        .arg(coordinate.latitude.toString())
        .arg(coordinate.longitude.toString());
        
        return "http://maps.apple.com/?daddr=%1".arg(ll);
    }
    
    //--------------------------------------------------------------------------
    
    function driveToWindowsMaps(coordinate, callbackUrl, callbackPrompt) {
        return "ms-drive-to:?destination.latitude=%1&destination.longitude=%2"
        .arg(coordinate.latitude.toString())
        .arg(coordinate.longitude.toString());
    }
    
    //--------------------------------------------------------------------------
    
    function walkToWindowsMaps(coordinate, callbackUrl, callbackPrompt) {
        return "ms-walk-to:?destination.latitude=%1&destination.longitude=%2"
        .arg(coordinate.latitude.toString())
        .arg(coordinate.longitude.toString());
    }
    
    //--------------------------------------------------------------------------
    
    function routeToGoogleMaps(coordinate, callbackUrl, callbackPrompt) {
        var daddr = "%1,%2".arg(coordinate.latitude).arg(coordinate.longitude);
        
        var url = "http://maps.google.com/maps?daddr=%1".arg(daddr);
        
        if (fromCoordinate && fromCoordinate.isValid) {
            var saddr = "%1,%2"
            .arg(fromCoordinate.latitude.toString())
            .arg(fromCoordinate.longitude.toString());
            
            url += "&saddr=%1".arg(saddr);
        }
        
        return url;
    }
    
    //--------------------------------------------------------------------------
    
    function routeToWaze(coordinate, callbackUrl, callbackPrompt) {
        return "https://waze.com/ul?ll=%1,%2&navigate=yes"
        .arg(coordinate.latitude.toString())
        .arg(coordinate.longitude.toString());
    }

    //--------------------------------------------------------------------------
}
