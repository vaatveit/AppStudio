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

import QtQml 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0
import QtWebView 1.15

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0
import ArcGIS.AppFramework.WebView 1.0
import Esri.ArcGISRuntime 100.13
import Esri.ArcGISRuntime.Toolkit 100.13


import "../Controls"
import "../Controls/Singletons"
import "../Portal"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    readonly property QC1.StackView stackView: QC1.Stack.view

    property Portal portal

    property bool tintBackground: backgroundColor != "#31872e"
    property color textColor: app.info.propertyValue("startTextColor", "white")
    property color backgroundColor: app.info.propertyValue("startBackgroundColor", "#e0e0df")
    property color foregroundColor: app.info.propertyValue("startForegroundColor", "transparent")

    property url backgroundSource: app.folder.fileUrl(app.info.propertyValue("startBackgroundImage", "images/start-background.jpg"))
    // Overlay image fails to load when specified below in StyledImage
    //property url overlaySource: app.folder.fileUrl(app.info.propertyValue("startOverlayImage", "images/start-overlay.svg"))
    //property url footerSource: app.folder.fileUrl(app.info.propertyValue("startFooterImage", "images/start-footer.svg"))
    property url footerSource: app.folder.fileUrl(app.info.propertyValue("startFooterImage", "images/URL_TAG_ON_LIGHT.png"))

    readonly property bool active: QC1.Stack.Active

    property string language: "en"

    //--------------------------------------------------------------------------

    property var closeAction: function () {
        console.log(logCategory, arguments.callee.name);
    }

    //--------------------------------------------------------------------------

    color: backgroundColor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("LanguagePage.onCompleted");
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: welcomeBox
        color: "#000000"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: welcomeText.height * 1.2

        AppText {
            id: welcomeText
            Layout.fillWidth: true
            text: qsTr("Meet CHAPP")
            color: "#edb14c"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 18
            }
            width: parent.width
            anchors {
                horizontalCenter: welcomeBox.horizontalCenter
                verticalCenter: welcomeBox.verticalCenter
            }
        }
    }

    Image {
        id: backgroundImage

        width: parent.width
        height: parent.height - welcomeBox.height

        anchors {
            top: welcomeBox.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        source: backgroundSource
        cache: false
        mipmap: true
        fillMode: Image.PreserveAspectCrop
        visible: source > "" && !colorOverlay.visible
    }

    Desaturate {
        id: desaturate

        anchors.fill: parent

        visible: false

        source: backgroundImage
        desaturation: 1
    }

    ColorOverlay {
        id: colorOverlay

        anchors.fill: source

        visible: tintBackground && backgroundImage.source > ""
        source: desaturate
        color: AppFramework.alphaColor(Qt.lighter(backgroundColor, 1.5), 0.3)
    }

    StyledImage {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Layout.topMargin: 25 * AppFramework.displayScaleFactor
        Layout.fillWidth: true
        Layout.preferredHeight: 45 * AppFramework.displayScaleFactor

        source: footerSource
        color: textColor
        opacity: 0.5
        cache: false
        mipmap: true
    }

    AppText {
        id: companionText
        Layout.fillWidth: true
        text: qsTr("The CHE Worker's Companion")
        color: "black"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        font {
            pointSize: 15
        }
        width: parent.width
        anchors {
            horizontalCenter: backgroundImage.horizontalCenter
            top: backgroundImage.top
            topMargin: 25 * AppFramework.displayScaleFactor

        }
    }

    Rectangle {
        id: inputRect

        width: backgroundImage.width * 0.8

        anchors {
            horizontalCenter: backgroundImage.horizontalCenter
            top: companionText.bottom
            topMargin: 25 * AppFramework.displayScaleFactor
        }

        AppText {
            id: chooseText
            Layout.fillWidth: true
            text: qsTr("Choose Your Language")
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 14
            }
            width: parent.width
            anchors {
                horizontalCenter: backgroundImage.horizontalCenter
                top: backgroundImage.top
                topMargin: 25 * AppFramework.displayScaleFactor

            }
        }

        Rectangle {
            id: horizontalLine

            width: parent.width;
            height: 2
            color: "brown"

            anchors {
                top: chooseText.bottom
                topMargin: 25 * AppFramework.displayScaleFactor
            }
        }

        ColumnLayout {
            id: buttonGroup
            width: parent.width

            anchors {
                top: horizontalLine.bottom
                topMargin: 25 * AppFramework.displayScaleFactor
            }

            RadioButton {
                id: englishBox
                checked: true
                text: "English"

                font {
                    pointSize: 14
                }

                indicator: Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    x: englishBox.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: "black"
                    color: "black"

                    Rectangle {
                        width: 14
                        height: 14
                        x: 6
                        y: 6
                        radius: 2
                        color: "white"
                        visible: englishBox.checked
                    }
                }

                contentItem: Text {
                    text: englishBox.text
                    font: englishBox.font
                    color: "black"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: englishBox.indicator.width + englishBox.spacing
                }

                onClicked: {
                    language = "en";
                }
            }

            RadioButton {
                id: spanishBox
                text: "Español"

                font {
                    pointSize: 14
                }

                indicator: Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    x: spanishBox.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: "black"
                    color: "black"

                    Rectangle {
                        width: 14
                        height: 14
                        x: 6
                        y: 6
                        radius: 2
                        color: "white"
                        visible: spanishBox.checked
                    }
                }

                contentItem: Text {
                    text: spanishBox.text
                    font: spanishBox.font
                    color: "black"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: spanishBox.indicator.width + spanishBox.spacing
                }

                onClicked: {
                    language = "es";
                }
            }

            RadioButton {
                id: frenchBox
                text: qsTr("Français")

                font {
                    pointSize: 14
                }

                indicator: Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    x: frenchBox.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: "black"
                    color: "black"

                    Rectangle {
                        width: 14
                        height: 14
                        x: 6
                        y: 6
                        radius: 2
                        color: "white"
                        visible: frenchBox.checked
                    }
                }

                contentItem: Text {
                    text: frenchBox.text
                    font: frenchBox.font
                    color: "black"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: frenchBox.indicator.width + frenchBox.spacing
                }

                onClicked: {
                    language = "fr";
                }
            }
        }

        Button {
            id: submitButton
            text: qsTr("Submit")

            anchors {
                top: buttonGroup.bottom
                topMargin: 25 * AppFramework.displayScaleFactor
                horizontalCenter: parent.horizontalCenter
            }

            contentItem: Text {
                text: submitButton.text
                font: submitButton.font
                opacity: enabled ? 1.0 : 0.3
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: "#edb14c"
                radius: 4
            }
            width: parent.width * 0.4
            Layout.alignment: Qt.AlignHCenter
            font {
                pointSize: 15
            }

            onClicked:{
                console.log("submit", language);

                stackView.pushHomePage(language);
            }
        }


    }




}
