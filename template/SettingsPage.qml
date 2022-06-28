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
import QtQuick.Layouts 1.12
import QtQuick.Controls 1.4 as QC1
import QtSensors 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    title: qsTr("Settings")

    //--------------------------------------------------------------------------

    property AppSettings settings: app.appSettings
    property bool showBeta: false
    property bool showOrg: false
    property bool showCompass: false

    property QC1.StackView stackView: page.QC1.Stack.view

    //--------------------------------------------------------------------------

    Compass {
        id: compass
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        showBeta = true;
        showOrg = true;
        showCompass = true;
    }

    //--------------------------------------------------------------------------

    contentMargins: 0
    contentItem: ListTabView {
        id: settingsPageListTabView

        delegate: settingsDelegate

        SettingsTabPortal {
            enabled: app.portal.managementEnabled
        }

        SettingsTabMap {
        }

        SettingsTabLocation {
        }

        SettingsTabCompass {
            enabled: app.features.enableCompass && (app.positionSourceManager.compassAvailable || showCompass)
                     || settings.compassEnabled
        }

        SettingsTabAccessibility {
        }

        SettingsTabText {
        }

        SettingsTabUnits {
            enabled: showBeta || app.features.beta
        }

        SettingsTabOrg {
            enabled: showOrg && portal.signedIn
            portal: app.portal
        }

        SettingsTabAddIns {
            enabled: app.features.addIns
            portal: app.portal
        }

        SettingsTabStorage {
        }

        SettingsTabDiagnostics {
            enabled: app.config.enableDiagnostics
        }

        SettingsTabBeta {
            enabled: showBeta || app.features.beta
        }

        SettingsTabContainer {
            id: settingsTabContainer
        }

        onSelected: {
            stackView.push(settingsTabContainer,
                           {
                               settingsTab: item,
                               title: item.title,
                               settingsComponent: item.contentComponent,
                           });
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: settingsDelegate

        SettingsTabDelegate {
            listTabView: settingsPageListTabView
        }
    }

    //--------------------------------------------------------------------------
}
