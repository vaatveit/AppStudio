/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

HomeViewTab {

    //--------------------------------------------------------------------------

    title: "Gallery"
    iconSource: Icons.bigIcon("apps", false)

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInTilesModel

        type: kTypeTool
        mode: kToolModeTile

        addInsFolder: app.addInsFolder

        onUpdated: {
            galleryView.forceLayout();
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: galleryView.model.count

            AddInsGalleryView {
                id: galleryView

                model: addInTilesModel

                delegate: galleryDelegateComponent

                onClicked: {
                    var addInItem = addInTilesModel.get(index);
                    console.log("Add-In clicked:", index, addInItem.title);

                    addInSelected(addInItem);
                }

                onPressAndHold: {
                    console.log("Add-In pressAndHold:", index);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: galleryDelegateComponent

        GalleryDelegate {
            id: galleryDelegate

            onClicked: {
                GridView.view.clicked(index);
            }

            onPressAndHold: {
                GridView.view.pressAndHold(index);
            }
        }
    }

    //--------------------------------------------------------------------------
}
