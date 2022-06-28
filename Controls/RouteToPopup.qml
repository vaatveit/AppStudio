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
import QtQuick.Dialogs 1.2
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"

MessagePopup {
    //--------------------------------------------------------------------------

    property alias fromCoordinate: routeTo.fromCoordinate
    property var toCoordinate
    property alias routeTo: routeTo
    property real distance: (fromCoordinate && fromCoordinate.isValid)
                            ? fromCoordinate.distanceTo(toCoordinate)
                            : Number.NaN

    property string defaultActionIconName: "road-sign"

    //--------------------------------------------------------------------------

    signal routeToHandler(var handler)

    //--------------------------------------------------------------------------
    
    icon.name: "route-to"
    title: qsTr("Go To")
    text: "%1".arg(toCoordinate)
    detailedText: isFinite(distance)
                  ? Units.distanceText(distance)
                  : ""
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    //--------------------------------------------------------------------------

    RouteTo {
        id: routeTo
    }

    //--------------------------------------------------------------------------

    Action {
        enabled: AppFramework.isAppInstalled("arcgis-navigator://")
                 || AppFramework.isAppInstalled("com.esri.navigator")
        
        text: qsTr("ArcGIS Navigator")
        icon.source: "images/Navigator-color.svg"
        
        onTriggered: {
            routeToHandler(routeTo.routeToNavigator);
        }
    }
    
    Action {
        enabled: AppFramework.isAppInstalled("com.esri.trek2there")
                 || AppFramework.isAppInstalled("Esri.Trek2There")
                 || AppFramework.isAppInstalled("arcgis-trek2there://")
        
        text: qsTr("Trek2There")
        icon.source: "images/Trek2There.png"
        
        onTriggered: {
            routeToHandler(routeTo.routeToTrek2There);
        }
    }
    
    Action {
        enabled: !!Qt.platform.os.match(/osx|ios/)
        
        text: qsTr("Apple Maps")
        icon.name: defaultActionIconName

        onTriggered: {
            routeToHandler(routeTo.routeToAppleMaps);
        }
    }
    
    Action {
        enabled: !!Qt.platform.os.match(/windows/)
        
        text: qsTr("Drive to with Windows Maps")
        icon.name: "car"
        
        onTriggered: {
            routeToHandler(routeTo.driveToWindowsMaps);
        }
    }
    
    Action {
        enabled: !!Qt.platform.os.match(/windows/)
        
        text: qsTr("Walk to with Windows Maps")
        icon.name: "walking"
        
        onTriggered: {
            routeToHandler(routeTo.walkToWindowsMaps);
        }
    }
    
    Action {
        enabled: Networking.isOnline
                 || AppFramework.isAppInstalled("comgooglemaps://")
                 || AppFramework.isAppInstalled("comgooglemaps-x-callback://")
                 || AppFramework.isAppInstalled("com.google.android.apps.maps")

        
        text: qsTr("Google Maps")
        icon.name: defaultActionIconName
        
        onTriggered: {
            routeToHandler(routeTo.routeToGoogleMaps);
        }
    }
    
    Action {
        enabled: AppFramework.isAppInstalled("waze://")
                 || AppFramework.isAppInstalled("com.waze")
        
        text: qsTr("Waze")
        icon.name: defaultActionIconName

        onTriggered: {
            routeToHandler(routeTo.routeToWaze);
        }
    }

    //--------------------------------------------------------------------------
}
