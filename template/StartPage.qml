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

    property bool ready: true

    //--------------------------------------------------------------------------

    signal signedIn()
    signal startAnonymous()

    //--------------------------------------------------------------------------

    property var closeAction: function () {
        console.log(logCategory, arguments.callee.name);
    }

    //--------------------------------------------------------------------------

    color: backgroundColor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!portal.isOnline && portal.signedIn) {
            signedInTimer.start();
        }
    }

    //--------------------------------------------------------------------------

    function reset() {
        console.log(logCategory, arguments.callee.name);

        portal.signOut(true);
        portal.portalsList.clear(true);
        portal.reset();
    }

    //--------------------------------------------------------------------------

    Timer {
        id: signedInTimer

        // Short interval (1500) causes problems debugging.
        interval: 15000000

        onTriggered: {
            Qt.callLater(signedIn);
        }
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
            text: portal.user ? "Welcome " + portal.user.fullName : "Welcome to the Global CHE Network"
            color: "#edb14c"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 15
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


    //--------------------------------------------------------------------------

    /*
    StyledImage {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: buttonsLayout.top
            margins: 10 * AppFramework.displayScaleFactor
        }

        width: Math.min(parent.width, 200 * AppFramework.displayScaleFactor)

        // Image given above fails to load
        source: overlaySource

        color: textColor
        cache: false
        mipmap: true

        MouseArea {
            id: overlayMouseArea

            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                versionText.enabled = !versionText.enabled;
            }

            onPressAndHold: {
                reset();
            }
        }
    }
    */


    TabBar {
        id: startPageTabs
        // anchors.fill: backgroundImage

        width: parent.width
        anchors.top: welcomeBox.bottom

        background: null
        TabButton {
            id: loginTabButton
            text: qsTr("Login")
            background: null
            contentItem: Text {
                text: loginTabButton.text
                font: loginTabButton.font
                color: startPageTabs.currentIndex === 0 ?"#ffffff" : "#cccccc"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            font {
                pointSize: 15
            }
        }
        TabButton {
            id: registerTabButton
            text: qsTr("Register")
            background: null
            contentItem: Text {
                text: registerTabButton.text
                font: registerTabButton.font
                color: startPageTabs.currentIndex === 1 ?"#ffffff" : "#cccccc"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            font {
                pointSize: 15
            }
        }
    }

    StackLayout {
        width: backgroundImage.width
        anchors.top: startPageTabs.bottom
        anchors.bottom: backgroundImage.bottom

        currentIndex: startPageTabs.currentIndex

        ColumnLayout {
            id: loginTab

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            spacing: 10 * AppFramework.displayScaleFactor

            Glyph {
                Layout.alignment: Qt.AlignHCenter

                visible: !portal.isOnline
                name: "offline"
                color: textColor
            }

            AppText {
                Layout.fillWidth: true

                visible: !portal.isOnline
                text: qsTr("Your device is offline")
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font {
                    pointSize: 15
                }
            }

            TextField {
                Layout.preferredWidth: 0.8 * parent.width
                visible: !portal.user  //portal.loadStatus !== Enums.LoadStatusLoaded
                id: userText
                color: "#edb14c"
                placeholderText: "Account"
                placeholderTextColor: "grey"
                background: Rectangle {
                    color: "#000000"
                    radius: 4
                }
                //anchors.horizontalCenter: parent.horizontalCenter
                Layout.alignment: Qt.AlignHCenter
                width: parent.width * 0.8
                leftPadding: 10.0
                rightPadding: 10.0
                font {
                    pointSize: 15
                }
            }

            TextField {
                Layout.preferredWidth: 0.8 * parent.width
                visible: !portal.user  //portal.loadStatus !== Enums.LoadStatusLoaded
                id: pwdText
                color: "#edb14c"
                placeholderText: "Password"
                placeholderTextColor: "grey"
                background: Rectangle {
                    color: "#000000"
                    radius: 4
                }
                //anchors.horizontalCenter: parent.horizontalCenter
                Layout.alignment: Qt.AlignHCenter
                width: parent.width * 0.8
                leftPadding: 10.0
                rightPadding: 10.0
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                font {
                    pointSize: 15
                }
            }

            Button {
                id: loginButton
                text: "Login"

                contentItem: Text {
                    text: loginButton.text
                    font: loginButton.font
                    opacity: enabled ? 1.0 : 0.3
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                enabled: !portal.user && userText.text.length > 0 && pwdText.text.length > 0
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
                    console.log("login", userText.text, pwdText.text);
                    portal.setCredentials(userText.text, pwdText.text, true);
                }
            }

            Button {
                id: forgotButton
                text: "Forgot Password?"

                contentItem: Text {
                    text: forgotButton.text
                    font: forgotButton.font
                    opacity: enabled ? 1.0 : 0.3
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                enabled: true
                background: Rectangle {
                    color: "#000000"
                    radius: 4
                }
                width: parent.width * 0.4
                Layout.alignment: Qt.AlignHCenter
                onClicked:{
                    console.log("forgot password");
                    stackView.push(forgotPasswordPage);
                }
            }

            Glyph {
                id: signingInImage

                Layout.alignment: Qt.AlignHCenter

                visible: portal.isConnecting || portal.isSigningIn
                name: portal.isConnecting
                      ? portal.isPortal
                        ? "portal"
                        : "arcgis-online"
                : "sign-in"
                color: textColor

                PulseAnimation {
                    target: signingInImage
                    running: signingInImage.visible
                }
            }

            AppText {
                Layout.fillWidth: true

                visible: signingInImage.visible
                text: qsTr("Signing in to <b>%1</b>").arg(portal.name)
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font {
                    pointSize: 15
                }
            }

            // This seems necessary to correctly center the elements above
            Rectangle {
                Layout.topMargin: 25 * AppFramework.displayScaleFactor
                Layout.fillWidth: true
                Layout.preferredHeight: 45 * AppFramework.displayScaleFactor
                color: "transparent"
            }
        }

        Rectangle {
            id: registerTab
            anchors.fill: parent

            Component.onCompleted: {
                browserView.show();
            }

            // TRY WEBVIEW
            BrowserView {
             id: browserView
             anchors.fill: parent
             primaryColor:"#8f499c"
             foregroundColor: "#f7d4f4"
             url: "https://globalche.maps.arcgis.com/sharing/rest/oauth2/signup?client_id=QVuTzZ3CvcgTPNC9&response_type=token&expiration=20160&showSocialLogins=true&locale=en-us&redirect_uri=https%3A%2F%2Fexample-page-globalche.hub.arcgis.com%2Ftorii-provider-arcgis%2Fhub-redirect.html"
            }
        }

    }


    //--------------------------------------------------------------------------


    //--------------------------------------------------------------------------

    AppText {
        id: versionText

        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 2 * AppFramework.displayScaleFactor
        }

        enabled: false
        visible: enabled // || overlayMouseArea.containsMouse
        text: app.info.version + app.features.buildTypeSuffix
        color: textColor
        horizontalAlignment: Text.AlignHCenter
        font {
            pointSize: 11
        }
        opacity: enabled ? 1 : 0.5
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        function onSignedInChanged() {
            if (portal.signedIn) {
                page.signedIn();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalSettingsPage

        PortalSettingsPage {

            portal: page.portal

            bannerColor: app.titleBarBackgroundColor
            bannerTextColor: app.titleBarTextColor

            onClose: {
                stackView.pop()
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: forgotPasswordPage

        ForgotPasswordPage {
            onClose: {
                stackView.pop()
            }
        }
    }

}
