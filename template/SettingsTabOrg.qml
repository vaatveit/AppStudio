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

import "../Controls"
import "../Controls/Singletons"
import "../Portal"

SettingsTab {

    //--------------------------------------------------------------------------

    property Portal portal

    //--------------------------------------------------------------------------

    title: qsTr("Organization")
    description: qsTr("View organization properties")
    icon.name: "organization"

    //--------------------------------------------------------------------------

    Item {
        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 5 * AppFramework.displayScaleFactor

            MultiLineTextBox {
                id: propertiesText

                Layout.fillWidth: true
                Layout.fillHeight: true

                readOnly: true
            }

            AppText {
                id: labelText
                Layout.fillWidth: true

                visible: text > ""
            }

            TabBar {
                id: tabBar

                Layout.fillWidth: true

                Component.onCompleted: {
                    currentIndexChanged();
                }

                TabButton {
                    text: qsTr("Active")
                }

                TabButton {
                    text: qsTr("Portal")
                }

                TabButton {
                    text: qsTr("App")
                }

                TabButton {
                    text: qsTr("Base")
                }

                onCurrentIndexChanged: {
                    switch (currentIndex) {
                    case 0:
                        showProperties(app.properties.activeProperties);
                        break;

                    case 1:
                        showProperties(app.properties.orgProperties, qsTr("Resource key: <b>%1</b>").arg(portal.appPropertiesKey));
                        break;

                    case 2:
                        showProperties(app.properties.appProperties);
                        break;

                    case 3:
                        showProperties(app.properties.baseProperties);
                        break;
                    }
                }

                function showProperties(properties, label) {
                    labelText.text = label || "";
                    propertiesText.text = JSON.stringify(properties, undefined, 2);
                }
            }

        }
    }

    //--------------------------------------------------------------------------
}
