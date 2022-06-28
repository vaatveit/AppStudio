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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.5
import QtLocation 5.13
import QtPositioning 5.13

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../../Controls"
import "../../Controls/Singletons"
import ".."

import "../XForm.js" as XFormJS

XFormMap {
    id: map
    
    //--------------------------------------------------------------------------

    property string settingsKeyGroup: "Location"
    property string mapKey: "map"
    property bool autoZoom: true
    
    property bool debug: false
    property Settings settings: app.settings

    //--------------------------------------------------------------------------

    implicitHeight: mapControls.height + 20 * AppFramework.displayScaleFactor

    localeProperties: app.localeProperties

    plugin: XFormMapPlugin {
        settings: map.mapSettings
        offline: !Networking.isOnline
    }
    
    mapSettings: XFormMapSettings {
        positionZoomLevel: 17
        sharedMapSources: app.mapSources
        defaultMapName: app.properties.defaultBasemap
    }

    mapControls {
        homeButton.visible: false
        minimumPositionMode: XFormMap.PositionMode.AutoPan
    }

    gesture {
        acceptedGestures: MapGestureArea.PinchGesture |
                          MapGestureArea.RotationGesture
    }
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        mapSettings.refresh();
        positionMode = XFormMap.PositionMode.AutoPan;
    }

    //--------------------------------------------------------------------------

    onSupportedMapTypesChanged: {
        Qt.callLater(updateMapType);
    }

    //--------------------------------------------------------------------------

    onMapTypeChanged: {
        saveMapType(mapKey, mapType);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(map, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            if (map.positionMode < XFormMap.PositionMode.AutoPan) {
                map.positionMode = XFormMap.PositionMode.AutoPan;
            }
            map.panTo(position.coordinate);
            if (autoZoom && map.supportedMapTypes.length > 0) {
                autoZoom = false;
                var geoShape = accuracyCircle(position);
                if (false && geoShape) {
                    fitViewportToGeoShape(geoShape, width * 0.3);
                } else {
                    zoomLevel = mapSettings.positionZoomLevel;
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    MouseArea {
        anchors {
            fill: parent
        }

        property url url

        onPressAndHold: {
            url = toArcGISViewerUrl(map.center, "Survey123 Location", "My Location", map.zoomLevel);
            AppFramework.clipboard.copy(url);
            Qt.openUrlExternally(url);
        }
    }

    //--------------------------------------------------------------------------

    function accuracyCircle(position) {
        var accuracy = 0;

        if (position.horizontalAccuracyValid && position.horizontalAccuracy > 0) {
            accuracy = position.horizontalAccuracy;
        } else if (position.positionAccuracyValid) {
            accuracy = position.positionAccuracy;
        }

        if (accuracy <= 0) {
            return;
        }

        var circle = QtPositioning.circle(position.coordinate, accuracy);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "accuracy:", accuracy, "circle:", circle);
        }

        return circle;
    }

    //--------------------------------------------------------------------------

    function updateMapType() {
        mapSettings.selectMapType(map, readMapType(mapKey));
    }

    //--------------------------------------------------------------------------

    function settingsKey(key) {
        return key > ""
                ? settingsKeyGroup + "/" + key
                : settingsKeyGroup;
    }

    //--------------------------------------------------------------------------

    function readMapType(key, defaultValue) {
        if (!defaultValue) {
            defaultValue = "";
        }

        if (!settings) {
            return defaultValue;
        }

        var name = settings.value(settingsKey(key), defaultValue);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "name:", name);
        }

        return name;
    }

    //--------------------------------------------------------------------------

    function saveMapType(key, mapType, defaultValue) {
        if (!settings) {
            return;
        }

        var name = map.mapSettings.mapTypeName(mapType);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "name:", name, "defaultValue:", defaultValue);
        }

        settings.setValue(settingsKey(key), name, defaultValue);
    }

    //--------------------------------------------------------------------------
    // https://doc.arcgis.com/en/arcgis-online/reference/use-url-parameters.htm

    function toArcGISViewerUrl(coordinate, title, label, level) {

        if (!(title > "")) {
            title  = "";
        }

        var url = "https://www.arcgis.com/home/webmap/viewer.html?center=%1,%2,4326&marker=%1,%2,4326,%3,,%4"
        .arg(coordinate.longitude.toString())
        .arg(coordinate.latitude.toString())
        .arg(XFormJS.replaceAll(title, " ", "%20"))
        .arg(XFormJS.replaceAll(label, " ", "%20"));

        if (level) {
            url += "&level=%1".arg(level);
        }

        return url;
    }

    //--------------------------------------------------------------------------
}
