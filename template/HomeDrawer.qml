/* Copyright 2019 Esri
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

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

AppDrawer {
    id: popup

    //--------------------------------------------------------------------------

    property Portal portal
    property var actions
    
    //--------------------------------------------------------------------------

    signal debugToggle()

    //--------------------------------------------------------------------------

    palette {
        base: "#eee"
        alternateBase: "#eee"
        text: "black"

        window: "#fefefe"
        windowText: "black"

        mid: "#ddd"
    }

    //--------------------------------------------------------------------------

    onDebugToggle: {
        offlineSwitch.visible = !offlineSwitch.visible;
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

        implicitHeight: userLayout.height + userLayout.anchors.margins * 2
        
        visible: portal.signedIn

        color: portal.isOnline ? popup.palette.base : popup.palette.alternateBase

        ColumnLayout {
            id: userLayout
            
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
                margins: 10 * AppFramework.displayScaleFactor
            }

            PortalUserView {
                Layout.fillWidth: true
                
                portal: popup.portal
                palette: popup.palette
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10 * AppFramework.displayScaleFactor
                Layout.bottomMargin: 10 * AppFramework.displayScaleFactor
                
                layoutDirection: localeProperties.layoutDirection
                
                Item {
                    Layout.fillWidth: true
                }
                
                AppButton {
                    text: qsTr("Sign out")
                    textPointSize: 15
                    
                    iconSource: Icons.bigIcon("sign-out")
                    
                    onClicked: {
                        confirmSignOut();
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                }
            }
        }
        
        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

        implicitHeight: offlineLayout.height + offlineLayout.anchors.margins * 2
        color: portal.isOnline ? popup.palette.base : popup.palette.alternateBase

        visible: !portal.signedIn

        ColumnLayout {
            id: offlineLayout

            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            IconImage {
                Layout.alignment: Qt.AlignHCenter

                icon {
                    name: portal.isOnline ? "online" : "offline"
                    color: "black"
                }
            }

            AppText {
                Layout.fillWidth: true

                text: portal.isOnline
                      ? qsTr("Your device is online")
                      : qsTr("Your device is offline")

                horizontalAlignment: Text.AlignHCenter
                font {
                    pointSize: 15
                }
            }

            AppButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

                iconSource: Icons.bigIcon("sign-in")
                text: qsTr("Sign in")
                textPointSize: 15
                visible: portal.isOnline

                onClicked: {
                    popup.close();
                    portal.signIn();
                }
            }
        }

        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------

    ActionsView {
        id: scrollView

        Layout.fillHeight: true
        Layout.fillWidth: true

        actions: popup.actions

        onTriggered: {
            popup.exit = null;
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    HorizontalSeparator {
        Layout.fillWidth: true

        opacity: 0.5
    }

    Switch {
        id: offlineSwitch

        Layout.alignment: Qt.AlignHCenter

        visible: false

        checked: portal.isOnline

        onClicked: {
            portal.isOnline = !portal.isOnline;
        }
    }

    //--------------------------------------------------------------------------

    AppText {
        Layout.fillWidth: true
        Layout.topMargin: 5 * AppFramework.displayScaleFactor
        Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

        text: qsTr("Version %1").arg(app.info.version + app.features.buildTypeSuffix)
        color: palette.windowText
        font {
            pointSize: 10
        }
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onPressAndHold: {
                debugToggle()
            }
        }
    }

    //--------------------------------------------------------------------------

    function confirmSignOut() {
        var confirmPopup = signoutPopupComponent.createObject(popup.parent);
        popup.close();
        confirmPopup.open();
    }

    Component {
        id: signoutPopupComponent

        PageLayoutPopup {
            id: signoutPopup

            spacing: 15 * AppFramework.displayScaleFactor

            width: 250 * AppFramework.displayScaleFactor
            bottomPadding: 1 * AppFramework.displayScaleFactor

            palette {
                window: "#eee"
                button: "white"
                light: "#f0fff0"
            }

            PortalUserIcon {
                Layout.alignment: Qt.AlignHCenter

                portal: popup.portal
                onlineIndicator.visible: false

                palette {
                    window: signoutPopup.palette.window
                    windowText: signoutPopup.palette.windowText
                }
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Sign Out")
                horizontalAlignment: Text.AlignHCenter

                font {
                    pointSize: 18
                    bold: true
                }
            }

            AppText {
                Layout.fillWidth: true

                visible: !portal.isOnline

                text: qsTr("Your device is offline. You will not be able to sign in again until you are online.")
                horizontalAlignment: Text.AlignHCenter
                color: "#a80000"

                font {
                    pointSize: 14
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: 4 * AppFramework.displayScaleFactor

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("You are signed in as")
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 14
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("<b>%1</b>").arg(portal.user.fullName || portal.username)
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 14
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("%1").arg(portal.username)
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 10
                    }
                }
            }

            ActionGroupLayout {
                Layout.fillWidth: true
                Layout.leftMargin: -signoutPopup.leftPadding + signoutPopup.backgroundRectangle.border.width
                Layout.rightMargin: -signoutPopup.rightPadding + signoutPopup.backgroundRectangle.border.width

                onTriggered: {
                    close();
                }

                actionGroup: ActionGroup {
                    Action {
                        text: qsTr("Sign out")
                        icon.name: "sign-out"

                        onTriggered: {
                            portal.signOut();
                        }
                    }

                    Action {
                        text: qsTr("Cancel")
                        icon.name: "undo"
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
