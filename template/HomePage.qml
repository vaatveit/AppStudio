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
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as QC1

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "../Portal"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property alias currentTab: homeView.currentTab
    property Portal portal
    readonly property bool signedIn: portal.signedIn
    property bool canGoBack: !signedIn

    readonly property QC1.StackView pageStackView: QC1.Stack.view

    //--------------------------------------------------------------------------

    signal addInSelected(var addInItem)
    signal selected(string surveyPath, bool pressAndHold, int indicator, var parameters, var surveyInfo)

    //--------------------------------------------------------------------------

    title: homeView.currentTab
           ? homeView.currentTab.title
           : app.info.title//qsTr("My Survey123")//app.info.title

    layoutDirection: app.localeProperties.layoutDirection
    contentMargins: 0

    backButton {
        visible: canGoBack
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        currentTab.titleClicked();
    }

    onTitlePressAndHold: {
        currentTab.titlePressAndHold();
    }

    //--------------------------------------------------------------------------

    onSignedInChanged: {
        if (!signedIn && app.config.requireSignIn) {
            Qt.callLater(closePage);
        }
    }

    //--------------------------------------------------------------------------

    PortalLogoButton {
        parent: backButton.parent

        anchors.fill: parent

        visible: !backButton.visible && portalTheme.logoSmall > ""
    }

    //--------------------------------------------------------------------------

    actionComponent: PortalUserButton {
        id: userButton

        portal: page.portal
        popup: HomeDrawer {
            portal: userButton.portal
            actions: (currentTab && currentTab.actionGroup) ? currentTab.actionGroup : null

            onActionsChanged: {
                if (actions && typeof actions.stackView === "object") {
                    actions.stackView = pageStackView;
                }
            }
        }
        padding: 4 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    contentItem: HomeView {
        id: homeView
    }

    //--------------------------------------------------------------------------
}
