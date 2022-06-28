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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls/Singletons"
import "../Controls"

ColumnLayout {
    //--------------------------------------------------------------------------

    property Portal portal
    property ActionGroup actionGroup
    property bool canDownload: true
    property string searchText
    readonly property bool isSearch: searchText > ""
    property color errorColor: "#a80000"

    //--------------------------------------------------------------------------

    visible: false
    spacing: 20 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 10 * AppFramework.displayScaleFactor

        opacity: 0

        OpacityAnimator on opacity {
            from: 0
            to: 1
            duration: 5000
        }

        Image {
            id: surveysImage

            anchors.fill: parent

            visible: false
            source: "images/surveys.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0

        }

        ColorOverlay {
            anchors.fill: source

            source: surveysImage
            color: AppFramework.alphaColor(Qt.lighter(app.titleBarBackgroundColor, 1.5), 0.3)
        }
    }
    
    AppText {
        id: messageText

        Layout.fillWidth: true
        Layout.leftMargin: 25 * AppFramework.displayScaleFactor
        Layout.rightMargin: Layout.leftMargin
        
        font {
            pointSize: 16
        }
        color: app.textColor

        text: isSearch
              ? qsTr("No results found")
              : qsTr("You don't have any surveys on your device.")

        horizontalAlignment: Text.AlignHCenter

    }
    
    AppText {
        Layout.fillWidth: true
        Layout.leftMargin: 25 * AppFramework.displayScaleFactor
        Layout.rightMargin: Layout.leftMargin
        Layout.bottomMargin: 25 * AppFramework.displayScaleFactor

        visible: !portal.isOnline && canDownload
        font {
            pointSize: 16
        }
        color: errorColor
        text: qsTr("Please connect to a network to download surveys.")
        horizontalAlignment: Text.AlignHCenter
    }
    
    AppButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 25 * AppFramework.displayScaleFactor
        
        visible: portal.isOnline && canDownload
        text: qsTr("Download surveys") + " "
        iconSource: Icons.bigIcon("download")
        textPointSize: 16
        
        onClicked: {
            actionGroup.showSignInOrDownloadPage();
        }
    }

    //--------------------------------------------------------------------------
}
