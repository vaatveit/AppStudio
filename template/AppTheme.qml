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

import ArcGIS.AppFramework 1.0

Control {
    id: theme

    //--------------------------------------------------------------------------

    property App app
    property PropertiesManager propertiesManager

    property string fontFamily: Qt.application.font.family

    property color backgroundColor: "#202020"
    property color textColor: "#fefefe"
    property color highlightColor: "#00b2ff"
    property color selectedColor: "#fefefe"
    property color errorTextColor: "#FF0000"

    property color pageHeaderColor: "#303030"
    property color pageHeaderTextColor: "#fefefe"

    property color pageFooterColor: "#303030"
    property color pageFooterTextColor: "#fefefe"

    property bool debug: false

    //--------------------------------------------------------------------------

    palette {
        window: propertiesManager.value("themes.default.backgroundColor")
        windowText: propertiesManager.value("themes.default.textColor")
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "fontFamilies:", JSON.stringify(Qt.fontFamilies()));
        }

        read();

        console.log(logCategory, "palette:", JSON.stringify(palette, undefined, 2))
    }

    //--------------------------------------------------------------------------

    Connections {
        target: propertiesManager

        onInitialize: {
            initializeProperties(properties);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(theme, true);
    }

    //--------------------------------------------------------------------------

    function initializeProperties(properties) {
        properties.themes = {
            "default": {
                textColor: app.info.propertyValue("textColor", "black"),
                backgroundColor: app.info.propertyValue("backgroundColor", "lightgrey"),
                //backgroundTextureImage: app.folder.fileUrl(app.info.propertyValue("backgroundTextureImage", "images/texture.jpg")),

                titleBarTextColor: app.info.propertyValue("titleBarTextColor", "grey"),
                titleBarBackgroundColor: app.info.propertyValue("titleBarBackgroundColor", "white"),

                formBackgroundColor: app.info.propertyValue("formBackgroundColor", "#f7f8f8")
            }
        };
    }

    //--------------------------------------------------------------------------

    function read() {
        var family = app.info.propertyValue("fontFamily");
        if (family > "") {
            fontFamily = family;
        }
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("AppTheme -");
        console.log("*  fontFamily:", fontFamily);
    }

    //--------------------------------------------------------------------------
}
