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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"
import "Singletons"

import "SurveyHelper.js" as Helper

ActionsPopup {
    id: popup

    //--------------------------------------------------------------------------

    property Portal portal
    property var surveyInfo
    property var itemInfo
    property bool requireUpdate

    //--------------------------------------------------------------------------

    signal openSurvey()
    signal updated()

    //--------------------------------------------------------------------------

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    spacing: 10 * AppFramework.displayScaleFactor

    title: requireUpdate
           ? qsTr("Update Required")
           : qsTr("Update Available")

    message: qsTr("A newer version of <b>%1</b> is available.").arg(itemInfo.title)

    icon {
        name: "exclamation-mark-triangle"
        color: Survey.kColorWarning
    }

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    Action {
        text: qsTr("Update form")   //BPDS changed text from "Update survey"
        //text: qsTr("Update survey (%1)").arg(Helper.displaySize(itemInfo.size))
        icon {
            name: "refresh"
        }

        onTriggered: {
            popup.close();
            downloadSurvey.download(itemInfo, true);
        }
    }

    Action {
        enabled: requireUpdate
        text: qsTr("Cancel")
        icon {
            name: "x-circle"
        }

        onTriggered: {
            popup.close();
        }
    }

    Action {
        enabled: !requireUpdate
        text: qsTr("Continue without update")
        icon {
            name: "move-up"
        }
        property real iconRotation: 90

        onTriggered: {
            popup.close();
            openSurvey();
        }
    }

    //--------------------------------------------------------------------------

    property DownloadSurvey downloadSurvey: DownloadSurvey {
        id: downloadSurvey

        parent: background

        portal: popup.portal
        progressPanel: progressPanel
        succeededPrompt: false

        onSucceeded: {
            updated();
            openSurvey();
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    property ProgressPanel progressPanel: ProgressPanel {
        id: progressPanel

        parent: background

        onVisibleChanged: {
            Platform.stayAwake = visible;
        }
    }

    //--------------------------------------------------------------------------
}
