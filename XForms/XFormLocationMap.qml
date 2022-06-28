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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "XForm.js" as XFormJS
import "../Controls"
import "../Controls/Singletons"
import "../XForms/GNSS"
import "MapControls"

SwipeTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Map")
    icon.name: "map"

    //--------------------------------------------------------------------------

    property XFormPositionSourceManager positionSourceManager
    readonly property PositioningSourcesController controller: positionSourceManager.controller

    property var position: ({})

    property string fontFamily
    property var locale: xform.locale

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: tab.positionSourceManager
        listener: "XFormLocationMap"

        onNewPosition: {
            tab.position = position;
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: container

        anchors.fill: parent

        LocationMap {
            id: map

            Layout.fillWidth: true
            Layout.fillHeight: true

            positionSourceConnection: positionSourceConnection
        }
    }

    //--------------------------------------------------------------------------
}
