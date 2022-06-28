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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    title: qsTr("About %1").arg(app.info.title)

    //--------------------------------------------------------------------------

    property bool debug: false

    readonly property string kSurvey123Apps: "survey123_apps"
    readonly property string licenseAgreementText: qsTr("<a href=\"%1\">View license agreement</a>").arg("https://www.esri.com/legal/software-license")
    readonly property string descriptionText: qsTr("<p>Use Survey123 to capture reliable data with smart forms from familiar devices whilst either online or offline, attach photos to your surveys and use high-accuracy GNSS receivers. With surveys published to ArcGIS Online or ArcGIS Enterprise, data is securely uploaded to ArcGIS for further analysis.</p></p><a href=\"%1\">Learn more</a></p>").arg("https://www.esri.com/survey123")

    property bool useItemInfoAboutText: app.info.owner !== kSurvey123Apps

    property var locale: app.locale
    property var systemLocale: app.localeProperties.systemLocale

    property ArcGISRuntimeInfo runtimeInfo: app.runtimeInfo

    property int indentWidth: 15 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        debug = !debug;
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {

        spacing: 5 * AppFramework.displayScaleFactor

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            padding: 10 * AppFramework.displayScaleFactor
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Flickable {
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                contentWidth: aboutLayout.width
                contentHeight: aboutLayout.height

                ColumnLayout {
                    id: aboutLayout

                    width: scrollView.availableWidth

                    spacing: 8 * AppFramework.displayScaleFactor

                    AboutText {
                        text: qsTr("Version %1").arg(app.info.version + app.features.buildTypeSuffix)
                        font {
                            pointSize: 14
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }

                    AboutText {
                        text: useItemInfoAboutText ? app.info.description : descriptionText
                        textFormat: Text.RichText
                    }

                    HorizontalSeparator {
                        Layout.fillWidth: true
                    }

                    AboutText {
                        text: "Copyright © 2020 Esri Inc. All Rights Reserved."
                    }

                    /*
                    Image {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50 * AppFramework.displayScaleFactor

                        source: app.folder.fileUrl(app.info.propertyValue("companyLogo", ""))
                        fillMode: Image.PreserveAspectFit

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Qt.openUrlExternally(app.info.propertyValue("companyUrl", ""))
                            }
                        }
                    }
                    */

                    /*
                    HorizontalSeparator {
                        Layout.fillWidth: true
                    }
                    */

                    /*
                    AboutText {
                        text: qsTr("License Agreement")
                        font {
                            pointSize: 15
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }
                    */

                    AboutText {
                        text: useItemInfoAboutText ? app.info.licenseInfo : licenseAgreementText
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 5 * AppFramework.displayScaleFactor

                        HorizontalSeparator {
                            Layout.fillWidth: true
                        }

                        AboutLabelValue {
                            label: qsTr("AppFramework version:")
                            value: AppFramework.version

                            onPressAndHold: {
                                debug = !debug;
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 5 * AppFramework.displayScaleFactor
                            visible: debug

                            AboutLabelValue {
                                label: qsTr("Device architecture:")
                                value: (
                                           function () {

                                               var systemInformation = AppFramework.systemInformation;

                                               if (Qt.platform.os === "android" && systemInformation.unixMachine !== undefined) {
                                                   return systemInformation.unixMachine;
                                               }

                                               return AppFramework.currentCpuArchitecture;

                                               // -----------------------------------------------------------------
                                           }()
                                           )
                            }

                            AboutLabelValue {
                                label: qsTr("Build architecture:")
                                value: AppFramework.buildCpuArchitecture
                            }

                            AboutLabelValue {
                                label: qsTr("Qt version:")
                                value: AppFramework.qtVersion
                            }

                            AboutLabelValue {
                                label: qsTr("Operating system version:")
                                value: AppFramework.osVersion
                            }

                            AboutLabelValue {
                                label: qsTr("Kernel version:")
                                value: AppFramework.kernelVersion
                            }

                            AboutLabelValue {
                                label: qsTr("SSL library version:")
                                value: AppFramework.sslLibraryVersion
                            }

                            AboutLabelValue {
                                label: qsTr("Locale:")
                                value: "%1 %2".arg(locale.name).arg(locale.nativeLanguageName)
                            }

                            AboutLabelValue {
                                visible: locale.name !== systemLocale.name;
                                label: qsTr("System locale:")
                                value: "%1 %2".arg(systemLocale.name).arg(systemLocale.nativeLanguageName)
                            }

                            HorizontalSeparator {
                                Layout.fillWidth: true
                            }

                            AboutLabelValue {
                                label: qsTr("ArcGIS Runtime version:")
                                value: runtimeInfo.version
                            }

                            AboutLabelValue {
                                label: qsTr("License type:")
                                value:  "%1 (%2)".arg(runtimeInfo.licenseTypeString).arg(runtimeInfo.license.licenseType)
                            }

                            AboutLabelValue {
                                label: qsTr("License level:")
                                value:  "%1 (%2)".arg(runtimeInfo.licenseLevelString).arg(runtimeInfo.license.licenseLevel)
                            }

                            AboutLabelValue {
                                label: qsTr("License status:")
                                value:  "%1 (%2)".arg(runtimeInfo.licenseStatusString).arg(runtimeInfo.license.licenseStatus)
                            }

                            AboutLabelValue {
                                label: qsTr("License expiry:")
                                value:  runtimeInfo.license.permanent
                                        ? qsTr("Permanent")
                                        : localeProperties.formatDateTime(runtimeInfo.license.expiry)
                            }

                            HorizontalSeparator {
                                Layout.fillWidth: true
                            }

                            AboutLabelValue {
                                label: qsTr("Encryption enabled:")
                                value: surveysDatabase.keyEnabled
                            }

                            AboutLabelValue {
                                label: qsTr("User home path:")
                                value: AppFramework.userHomePath

                                onClicked: {
                                    Qt.openUrlExternally(AppFramework.userHomeFolder.url);
                                }
                            }

                            AboutLabelValue {
                                label: qsTr("Surveys folder:")
                                value: surveysFolder.path

                                onClicked: {
                                    Qt.openUrlExternally(surveysFolder.url);
                                }
                            }

                            AboutLabelValue {
                                label: qsTr("Maps library:")
                                value: surveysFolder.filePath("Maps")

                                onClicked: {
                                    Qt.openUrlExternally(surveysFolder.fileUrl("Maps"));
                                }
                            }

                            AboutLabelValue {
                                label: "Token expiry:"
                                value: localeProperties.formatDateTime(portal.expires)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            visible: debug
                            spacing: 5 * AppFramework.displayScaleFactor

                            HorizontalSeparator {
                                Layout.fillWidth: true
                            }

                            AboutLabelValue {
                                label: "AppFramework display scale factor:"
                                value: AppFramework.displayScaleFactor
                            }

                            AboutLabelValue {
                                label: "Screen:"
                                value: Screen.name
                            }

                            AboutLabelValue {
                                label: "Dimensions:"
                                value: "%1 x %2".arg(Screen.width).arg(Screen.height)
                            }

                            AboutLabelValue {
                                label: "Device pixel ratio:"
                                value: Screen.devicePixelRatio
                            }

                            AboutLabelValue {
                                label: "Pixel density:"
                                value: Screen.pixelDensity
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            visible: debug
                            spacing: 5 * AppFramework.displayScaleFactor

                            HorizontalSeparator {
                                Layout.fillWidth: true
                            }

                            AboutLabelValue {
                                label: qsTr("Available cameras:")
                                value: QtMultimedia.availableCameras.length
                            }

                            Repeater {
                                model: QtMultimedia.availableCameras

                                delegate: ColumnLayout {
                                    property var cameraInfo: QtMultimedia.availableCameras[index]

                                    Layout.fillWidth: true

                                    AboutLabelValue {
                                        label: qsTr("Camera %1:").arg(index + 1)
                                        value: cameraInfo.displayName
                                    }

                                    AboutLabelValue {
                                        Layout.leftMargin: indentWidth

                                        label: qsTr("Device ID:")
                                        value: cameraInfo.deviceId
                                    }

                                    AboutLabelValue {
                                        Layout.leftMargin: indentWidth

                                        label: qsTr("Position:")
                                        value: "%1 (%2)".arg(cameraInfo.position === Camera.FrontFace
                                               ? qsTr("Front facing")
                                               : cameraInfo.position === Camera.BackFace
                                                 ? qsTr("Back facing")
                                                 : qsTr("Unknown")).arg(cameraInfo.position)
                                    }

                                    AboutLabelValue {
                                        Layout.leftMargin: indentWidth

                                        label: qsTr("Orientation:")
                                        value: cameraInfo.orientation
                                    }
                                }
                            }

                        }
                    }
                }
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        PoweredByAppStudio {
            Layout.fillWidth: true

            font.family: app.fontFamily

            onPressAndHold: {
                debug = !debug;
            }
        }
    }

    //--------------------------------------------------------------------------
}
