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

import QtQuick 2.12
import QtQuick.Controls 1.4

import ArcGIS.AppFramework 1.0

Component {
    id: settingsTabContainer

    AppPage {
        property Item settingsTab
        property AppSettings appSettings: app.appSettings

        property alias settingsComponent: loader.sourceComponent
        property alias settingsItem: loader.item

        signal loaderComplete();

        contentMargins: 0

        contentItem: Loader {
            id: loader
        }

        Component.onDestruction: {
            saveSettings();
        }

        onTitleClicked: {
            settingsTab.titleClicked();
        }

        onTitlePressAndHold: {
            settingsTab.titlePressAndHold();
        }

        Stack.onStatusChanged: {
            if (Stack.status == Stack.Active) {
                settingsTab.activated();
            } else if (Stack.status == Stack.Inactive) {
                settingsTab.deactivated();
            }
        }

        //--------------------------------------------------------------------------

        function saveSettings() {
            appSettings.write();
        }

        //--------------------------------------------------------------------------
    }
}
