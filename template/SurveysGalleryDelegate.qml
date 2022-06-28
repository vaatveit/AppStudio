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

import ArcGIS.AppFramework 1.0

import "Singletons"
import "SurveyHelper.js" as Helper
import "../XForms/Singletons"
import "../Controls/Singletons"

GalleryDelegate {
    id: galleryDelegate

    //--------------------------------------------------------------------------

    property var surveyItem: galleryView.baseModel.get(index)

    readonly property int errorCount: surveysDatabase.statusCount(path, XForms.Status.SubmitError, surveysDatabase.changed)
    readonly property int inboxCount: surveysDatabase.statusCount(path, XForms.Status.Inbox, surveysDatabase.changed)
    readonly property int draftsCount: surveysDatabase.statusCount(path, XForms.Status.Draft, surveysDatabase.changed)
    readonly property int outboxCount: surveysDatabase.statusCount(path, XForms.Status.Complete, surveysDatabase.changed)

    //--------------------------------------------------------------------------

    updateAvailable: surveyItem ? surveyItem.updateAvailable : false

    //--------------------------------------------------------------------------

    Loader {
        parent: background

        anchors {
            left: indicatorsRow.layoutDirection === Qt.LeftToRight ? parent.left : undefined
            right: indicatorsRow.layoutDirection === Qt.RightToLeft ? parent.right : undefined
            bottom: parent.bottom
            margins: -5 * AppFramework.displayScaleFactor
        }

        active: debug

        sourceComponent: AccessIcon {
            // surveyItem may be undefined here
            access: surveyItem ? surveyItem.access : "";

            color: "#eeeeee"
            border {
                width: (updateAvailable ? 2 : 1) * AppFramework.displayScaleFactor
                color: updateAvailable ? "red" : "#ddd"
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: indicatorsRow
            margins: -2 * AppFramework.displayScaleFactor
        }
        
        visible: false
        radius: height / 2
        color: "#30000000"
    }

    //--------------------------------------------------------------------------

    Row {
        id: indicatorsRow

        anchors {
            left: indicatorsRow.layoutDirection === Qt.RightToLeft ? parent.left : undefined
            right: indicatorsRow.layoutDirection === Qt.LeftToRight ? parent.right : undefined

            top: parent.top
            topMargin: 2 * AppFramework.displayScaleFactor
        }
        
        spacing: 4 * AppFramework.displayScaleFactor
        layoutDirection: ControlsSingleton.localeProperties.layoutDirection
        
        CountIndicator {
            color: Survey.kColorError
            count: errorCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(0, Survey.kFolderOutbox);
            }
        }
        
        CountIndicator {
            color: Survey.kColorFolderInbox
            count: inboxCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(3, Survey.kFolderInbox);
            }
        }
        
        CountIndicator {
            color: Survey.kColorFolderDrafts
            count: draftsCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(1, Survey.kFolderDrafts);
            }
        }
        
        CountIndicator {
            color: Survey.kColorFolderOutbox
            count: outboxCount
            
            onClicked: {
                indicatorsRow.indicatorClicked(2, Survey.kFolderOutbox);
            }
        }
        /*
                CountIndicator {
                    color: Survey.kColorFolderSent
                    count: surveysDatabase.statusCount(path, XForms.Status.Submitted, surveysDatabase.changed)
                }
*/
        function indicatorClicked(indicator, folder) {
            if (surveyItem.survey) {
                var parameters = {
                    folder: folder
                }

                selected(app.surveysFolder.filePath(surveyItem.survey), false, indicator, parameters, surveyItem);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    onClicked: {
        galleryView.clicked(index);
    }
    
    //--------------------------------------------------------------------------

    onPressAndHold: {
        galleryView.pressAndHold(index);
    }

    //--------------------------------------------------------------------------
}
