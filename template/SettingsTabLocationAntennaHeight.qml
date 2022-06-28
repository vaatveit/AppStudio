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

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

import "../XForms/XForm.js" as CC

SettingsTab {
    id: antennaHeightTab

    //--------------------------------------------------------------------------

    title: qsTr("Antenna Height")
    icon.name: "antenna-height"
    description: ""

    //--------------------------------------------------------------------------

    property string deviceType: ""
    property string deviceName: ""
    property string deviceLabel: ""

    //--------------------------------------------------------------------------

    readonly property AppSettings gnssSettings: appSettings
    readonly property bool isTheActiveSensor: deviceName === gnssSettings.kInternalPositionSourceName || controller.currentName === deviceName

    property bool initialized

    //--------------------------------------------------------------------------

    signal changed()

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        Component.onCompleted: {
            initialized = true;
        }

        Component.onDestruction: {
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Antenna height of receiver")

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("The distance from the antenna to the ground surface is subtracted from altitude values.")
                }

                Image {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200 * AppFramework.displayScaleFactor
                    Layout.maximumHeight: Layout.preferredHeight

                    source: "images/Antenna_Height.svg"
                    fillMode: Image.PreserveAspectFit
                }

                NumberField {
                    id: antennaHeightField

                    Layout.fillWidth: true

                    suffixText: CC.localeLengthSuffix(locale)

                    property var antennaHeight: gnssSettings.knownDevices[deviceName].antennaHeight
                    value: isFinite(antennaHeight) ? CC.toLocaleLength(antennaHeight, locale, 10) : undefined

                    onValueChanged: {
                        var val = CC.fromLocaleLength(value, locale, 10)
                        if (initialized && !gnssSettings.updating) {
                            gnssSettings.knownDevices[deviceName].antennaHeight = val;
                            if (isTheActiveSensor) {
                                gnssSettings.locationAntennaHeight = val;
                            }
                        }

                        changed();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
