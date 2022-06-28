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

import QtQml 2.12
import QtQuick 2.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"

import "XForm.js" as XFormJS

Map {
    id: map
    
    //--------------------------------------------------------------------------

    property XFormSettings formSettings
    property XFormMapSettings mapSettings

    property bool hasMaps: supportedMapTypes.length > 0
    readonly property bool isOnline: Networking.isOnline
    
    property string nodeset
    readonly property string savedMapName: formSettings.mapName(nodeset)
    property string mapName: savedMapName > "" ? savedMapName : styleMapName
    property string styleMapName

    property bool debug: true //false

    //--------------------------------------------------------------------------

    readonly property string kPropertyMapName: "styleMapName"

    //--------------------------------------------------------------------------

    plugin: XFormMapPlugin {
        settings: mapSettings
        offline: !isOnline
    }
    
    gesture {
        enabled: false
    }

    copyrightsVisible: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "onCompleted nodeset:", nodeset, "mapName:", mapName, "savedMapName:", savedMapName);
        }

        mapSourcesParameter.bind(mapSettings);
    }

    //--------------------------------------------------------------------------

    onSupportedMapTypesChanged: {
        if (debug) {
            console.log("onSupportedMapTypesChanged:", supportedMapTypes.length);
        }

        Qt.callLater(updateMapType);
    }

    //--------------------------------------------------------------------------

//    onStyleMapNameChanged: {
//        if (debug) {
//            console.log("onStyleMapNameChanged:", styleMapName);
//        }

//        Qt.callLater(updateMapType);
//    }

    //--------------------------------------------------------------------------

    onMapNameChanged: {
        if (debug) {
            console.log("onStyleMapNameChanged:", styleMapName);
        }

        Qt.callLater(updateMapType);
    }

    //--------------------------------------------------------------------------

    onActiveMapTypeChanged: { // Force update of min/max zoom levels
        minimumZoomLevel = -1;
        maximumZoomLevel = 9999;
    }

    //--------------------------------------------------------------------------

    onCopyrightLinkActivated: {
        Qt.openUrlExternally(link);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(map, true)
    }

    //--------------------------------------------------------------------------

    XFormMapSourcesParameter {
        id: mapSourcesParameter
    }

    //--------------------------------------------------------------------------

    function updateMapType() {
        if (!supportedMapTypes.length) {
            return;
        }

        console.log(logCategory, arguments.callee.name);

        if (mapName > "") {
            selectMapType(mapName);
        } else if (styleMapName > "") {
            selectMapType(styleMapName);
        } else {
            selectMapType("");
        }
    }

    //--------------------------------------------------------------------------

    function setMapType(mapType) {
        if (!mapType) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapType:", JSON.stringify(mapType, undefined, 2));
        }

        selectMapType(mapSettings.mapTypeName(mapType), true);
    }

    //--------------------------------------------------------------------------

    function selectMapType(name, store) {
        if (mapSettings.selectMapType(map, name)) {
            if (name > "" && store) {
                mapName = name;
                formSettings.setMapName(nodeset, name);
            }
        }
    }

    //--------------------------------------------------------------------------
}
