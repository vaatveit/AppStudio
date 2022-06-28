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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

Item {
    id: gnssStatusPages

    //--------------------------------------------------------------------------
    // Public properties

    property XFormPositionSourceManager positionSourceManager
    property var xform

    // set these to provide access to location settings
    property var settingsTabContainer
    property var settingsTabLocation

    // Allow access to settings UI
    property bool allowSettingsAccess: !positionSourceManager.onSettingsPage

    //--------------------------------------------------------------------------
    // Internal properties

    property bool showing

    signal alert(int alertType)

    //--------------------------------------------------------------------------

    anchors.fill: parent
    z: 9999

    //--------------------------------------------------------------------------

    function showGNSSStatus(stackView, xform) {
        if (showing || !stackView) {
            return;
        }

        forceActiveFocus();
        Qt.inputMethod.hide();

        gnssStatusPages.xform = xform
        stackView.push(positionSourceManager.isGNSS
                       ? gnssInfoPage
                       : locationInfoPage);

        showing = true;
    }

    //--------------------------------------------------------------------------

    Component {
        id: locationInfoPage

        XFormLocationInfoPageIntegrated {
            positionSourceManager: gnssStatusPages.positionSourceManager

            settingsTabContainer: gnssStatusPages.settingsTabContainer
            settingsTabLocation: gnssStatusPages.settingsTabLocation
            allowSettingsAccess: gnssStatusPages.allowSettingsAccess

            Component.onDestruction: {
                showing = false;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: gnssInfoPage

        XFormLocationInfoPageGNSS {
            positionSourceManager: gnssStatusPages.positionSourceManager

            settingsTabContainer: gnssStatusPages.settingsTabContainer
            settingsTabLocation: gnssStatusPages.settingsTabLocation
            allowSettingsAccess: gnssStatusPages.allowSettingsAccess

            Component.onDestruction: {
                showing = false;
            }
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        id: nmeaLogger

        target: gnssStatusPages.positionSourceManager.logger

        function onAlert() {
            gnssStatusPages.alert(alertType);
        }
    }

    //--------------------------------------------------------------------------
}
