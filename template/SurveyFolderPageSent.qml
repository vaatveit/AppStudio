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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "Singletons"
import "../XForms/Singletons"

SurveyFolderPage {
    //--------------------------------------------------------------------------

    folderName: qsTr("Sent")
    folderColor: Survey.kColorFolderSent
    statusFilter: XForms.Status.Submitted
    mapKey: Survey.kFolderSent

    //--------------------------------------------------------------------------

    folderAction {
        enabled: true
        text: qsTr("Empty")
        icon.name: "trash"

        onTriggered: {
            deletePopup.open();
        }
    }

    //--------------------------------------------------------------------------

    function emptySentFolder(){
        surveysDatabase.deleteSurveyBox(surveyInfo.name, XForms.Status.Submitted);
        closePage();
    }

    //--------------------------------------------------------------------------

    MessagePopup {
        id: deletePopup

        title: qsTr("Empty Folder")
        text: qsTr("All surveys in the Sent folder will be deleted from your device.")

        standardIcon: StandardIcon.Warning
        standardButtons: StandardButton.Yes | StandardButton.Cancel

        yesAction {
            icon {
                source: Icons.icon("trash")
                color: Survey.kColorWarning
            }
            text: qsTr("Empty")
        }

        onYes: {
            emptySentFolder();
        }
    }

    //--------------------------------------------------------------------------
}
