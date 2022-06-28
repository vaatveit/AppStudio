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

pragma Singleton

import QtQuick 2.12
import ArcGIS.AppFramework 1.0

import "."
import ".."

Item {
    id: singleton

    visible: false

    //--------------------------------------------------------------------------

    property font font: Qt.application.font
    property alias localeProperties: localeProperties

    //--------------------------------------------------------------------------

    property string backIconName: "chevron-left"
    property url backIcon: Icons.icon(backIconName)
    property real backIconPadding: 6 * AppFramework.displayScaleFactor

    property string closeIconName: "x"
    property url closeIcon: Icons.icon(closeIconName)
    property real closeIconPadding: 6 * AppFramework.displayScaleFactor

    property string menuIconName: "hamburger"
    property url menuIcon: Icons.icon(menuIconName)
    property real menuIconPadding: 6 * AppFramework.displayScaleFactor

    property real inputClearButtonOpacity: 0.3
    property string inputClearButtonIconName: "x-circle-f"
    property url inputClearButtonIcon: Icons.icon("x-circle", true)
    property alias inputFont: inputText.font
    property alias inputTextHeight: inputText.height
    property real inputTextPadding: 8 * AppFramework.displayScaleFactor
    property real inputHeight: inputText.height + 2 * inputTextPadding
    property alias inputTextColor: inputText.color

    property string shareIconName: Qt.platform.os === "ios" ? "share-ios" : "share"

    property alias defaultGlyphSet: defaultGlyphSet

    //--------------------------------------------------------------------------
    // Used to open links embedded in text. Can be overriden

    property var openLink: function (url) {
        Qt.openUrlExternally(url);
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        font.pointSize = 12;
    }

    //--------------------------------------------------------------------------

    LocaleProperties {
        id: localeProperties
    }

    //--------------------------------------------------------------------------

    Text {
        id: inputText

        color: "#303030"
        text: "AXjgy"
        font {
            family: singleton.font.family
            pointSize: 15
        }
    }

    //--------------------------------------------------------------------------

    GlyphSet {
        id: defaultGlyphSet

        source: "../glyphs/calcite-ui-icons-24.ttf"
    }

    //--------------------------------------------------------------------------
}

