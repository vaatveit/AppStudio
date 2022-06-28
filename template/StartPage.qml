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
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

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

        interval: 1500

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

    Image {
        id: backgroundImage

        anchors.fill: parent

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

    //--------------------------------------------------------------------------

    StyledImage {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: buttonsLayout.top
            margins: 10 * AppFramework.displayScaleFactor
        }

        width: Math.min(parent.width, 200 * AppFramework.displayScaleFactor)

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

    Rectangle {
        anchors.fill: parent
        color: foregroundColor
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: buttonsLayout

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 10 * AppFramework.displayScaleFactor
        }

        width: Math.min(parent.width * 0.85, 350 * AppFramework.displayScaleFactor)

        spacing: 10 * AppFramework.displayScaleFactor

        AppText {
            Layout.fillWidth: true

            //visible: !!text
            text: portal.user ? portal.user.fullName : ""
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font {
                pointSize: 15
            }
        }

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

        //StartButton {
        //    Layout.fillWidth: true
//
        //    visible: ready && portal.isOnline && !portal.signedIn && !portal.isSigningIn
        //    text: qsTr("Sign in with <b>%1</b>").arg(portal.name)
        //    reverseColor: true
        //    showBorder: false
//
        //    onClicked: {
        //        if (portal.signedIn) {
        //            portal.signOut();
        //        }
        //        portal.signIn(undefined, true);
        //    }
       // }

        //StartButton {
        //    Layout.fillWidth: true

        //    visible: ready && portal.managementEnabled && portal.isOnline && !portal.signedIn && !portal.isSigningIn
        //    text: qsTr("Manage ArcGIS connections")

        //    palette {
        //        button: "transparent"
        //    }

        //    onClicked: {
        //        stackView.push(portalSettingsPage);
        //    }
        //}

        StartButton {
            Layout.fillWidth: true

            visible: ready && !portal.signedIn && !portal.isSigningIn && !app.config.requireSignIn
            text: qsTr("Click to Continue") // ")
            showBorder: false

            palette {
                button: "transparent"
            }

            onClicked: {
                startAnonymous();
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

        StyledImage {
            Layout.topMargin: 25 * AppFramework.displayScaleFactor
            Layout.fillWidth: true
            Layout.preferredHeight: 45 * AppFramework.displayScaleFactor

            source: footerSource
            color: textColor
            opacity: 0.5
            cache: false
            mipmap: true
        }
    }

    //--------------------------------------------------------------------------

    AppText {
        id: versionText

        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 2 * AppFramework.displayScaleFactor
        }

        enabled: false
        visible: enabled || overlayMouseArea.containsMouse
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

        onSignedInChanged: {
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
}
