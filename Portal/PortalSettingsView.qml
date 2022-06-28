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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"
import "../template"

//------------------------------------------------------------------------------

Control {
    id: view

    //--------------------------------------------------------------------------

    property Portal portal
    property var portalsList: portal.portalsList

    property color bannerColor: "black"

    property bool showExtraInfo: false

    //--------------------------------------------------------------------------

    signal portalSelected(var portalInfo, int index)

    //--------------------------------------------------------------------------

    padding: 5 * AppFramework.displayScaleFactor

    font: ControlsSingleton.font

    palette {
        window: "transparent"
        windowText: "#3c3c3c"
        highlight: "#ecfbff"
        button: bannerColor
        link: "blue"
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        portalsList.read();
        portalsListView.currentIndex = portalsList.find(portal);
    }

    //--------------------------------------------------------------------------

    onPortalSelected: {
        if (portalInfo.url.toLowerCase() === portal.portalUrl.toString().toLowerCase()) {
            return;
        }

        console.log(logCategory, "portal change from:", portal.portalUrl, "to:", portalInfo.url);

        if (portal.signedIn) {
            var popup = portalSelectPopup.createObject(view,
                                                       {
                                                           index: index,
                                                           portalInfo: portalInfo
                                                       });
            popup.open();
        } else {
            setPortal(portalInfo);
            portalsListView.currentIndex = index;
        }
    }

    //--------------------------------------------------------------------------

    function setPortal(portalInfo) {
        portal.setPortal(portalInfo);
    }

    //--------------------------------------------------------------------------

    function addPortal() {
        addPortalPopup.createObject(view).open();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(view, true)
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        width: view.availableWidth
        height: view.availableHeight

        Label {
            Layout.fillWidth: true

            text: qsTr("Select your active ArcGIS connection")
            font {
                pointSize: 15
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    showExtraInfo = !showExtraInfo;
                }
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        ListView {
            id: portalsListView

            Layout.fillHeight: true
            Layout.fillWidth: true

            model: portal.portalsList.model
            spacing: 1 * AppFramework.displayScaleFactor
            clip: true

            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain);
            }

            delegate: Rectangle {
                width: portalRow.width
                height: Math.max(portalRow.height + 2 * AppFramework.displayScaleFactor * 4, 50 * AppFramework.displayScaleFactor)

                color: mouseArea.containsMouse
                       ? view.palette.highlight
                       : view.palette.window

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.bottom
                    }

                    height: 1 * AppFramework.displayScaleFactor
                    color: "#ddd"
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        portalSelected(portalsListView.model.get(index), index);
                    }

                    onPressAndHold: {
                        Qt.openUrlExternally(url);
                    }
                }

                RowLayout {
                    id: portalRow

                    anchors.verticalCenter: parent.verticalCenter
                    width: portalsListView.width

                    Item {
                        Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        StyledImage {
                            anchors.fill: parent

                            visible: index === portalsListView.currentIndex
                            source: Icons.icon("check")
                            color: view.palette.windowText
                        }
                    }

                    StyledImage {
                        Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        source: isPortal ? Icons.icon("portal") : Icons.icon("arcgis-online")
                        color: view.palette.windowText
                    }

                    StyledImage {
                        Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        source: supportsOAuth ? "images/oauth.png" : "images/builtin.png"
                        visible: source > "" && showExtraInfo
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: portalText.height

                        ColumnLayout {
                            id: portalText

                            width: parent.width

                            Label {
                                Layout.fillWidth: true

                                text: name
                                font {
                                    pointSize: 14
                                    bold: index == portalsListView.currentIndex
                                }
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                visible: index > 0 || showExtraInfo

                                Image {
                                    Layout.preferredWidth: 15 * AppFramework.displayScaleFactor
                                    Layout.preferredHeight: Layout.preferredWidth

                                    source: ignoreSslErrors ? "images/security_unlock.png" : "" //"images/security_lock.png"
                                    fillMode: Image.PreserveAspectFit
                                    visible: source > ""
                                }

                                Label {
                                    Layout.fillWidth: true

                                    text: url
                                    font {
                                        pointSize: 12
                                    }
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                            }

                            Flow {
                                Layout.fillWidth: true

                                visible: showExtraInfo

                                spacing: 5 * AppFramework.displayScaleFactor

                                Label {
                                    visible: networkAuthentication
                                    text: "NA"
                                }

                                Label {
                                    visible: externalUserAgent
                                    text: "EUA"
                                }

                                Label {
                                    visible: singleSignOn
                                    text: "SSO"
                                }
                            }
                        }
                    }

                    StyledImageButton {
                        Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        padding: 2 * AppFramework.displayScaleFactor
                        source: Icons.icon("trash")
                        visible: index > 0
                        color: view.palette.windowText

                        onClicked: {
                            var popup = portalDeletePopup.createObject(view,
                                                                       {
                                                                           index: index,
                                                                           portalInfo: portalsListView.model.get(index)
                                                                       });
                            popup.open();
                        }
                    }
                }
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        ActionGroupLayout {
            Layout.fillWidth: true

            font: ControlsSingleton.font
            locale: ControlsSingleton.localeProperties.locale
            palette {
                window: view.palette.window
                windowText: view.palette.windowText
            }

            actionGroup: ActionGroup {
                Action {
                    text: qsTr("Add connection")
                    icon.name: "plus"

                    onTriggered: {
                        addPortal();
                    }
                }

                Action {
                    enabled: showExtraInfo

                    text: qsTr("Clear connections")
                    icon.name: "trash"

                    onTriggered: {
                        portalsList.clear(true);
                        portal.reset();
                        portalsListView.currentIndex = 0;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalSelectPopup

        MessagePopup {
            property int index
            property var portalInfo

            parent: view

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Ok | StandardButton.Cancel
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            title: qsTr("Select Connection")
            text: qsTr("To select <b>%1</b> you must sign out of the active connection.").arg(portalInfo.name)

            okAction {
                icon {
                    name: "sign-out"
                }

                text: qsTr("Sign out and continue")
            }

            onAccepted:  {
                view.setPortal(portalInfo);
                portalsListView.currentIndex = index;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalDeletePopup

        MessagePopup {
            property int index
            property var portalInfo

            parent: view

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Ok | StandardButton.Cancel
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            title: qsTr("Remove Connection")
            text: qsTr("<b>%1</b> will be removed from your list of connections.").arg(portalInfo.name)

            okAction {
                icon {
                    name: "trash"
                    color: "#a80000"
                }

                text: qsTr("Remove")
            }

            onAccepted:  {
                if (index === portalsListView.currentIndex) {
                    portal.signOut();
                    view.setPortal(portalsList.model.get(0));
                    portalsListView.currentIndex = 0;
                }

                portalsList.remove(index);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addPortalPopup

        PortalAddPopup {
            parent: view

            portal: view.portal
            portalsList: view.portalsList
            showExtraInfo: view.showExtraInfo

            palette {
                windowText: view.palette.windowText
                button: view.palette.button
                link: view.palette.link
            }

            onPortalAdded: {
                portalSelected(portalInfo, index);
            }
        }
    }

    //--------------------------------------------------------------------------
}
