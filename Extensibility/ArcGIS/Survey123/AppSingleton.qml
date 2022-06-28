/* Copyright 2018 Esri
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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

Item {
    id: singleton

    //--------------------------------------------------------------------------

    property App app

    readonly property alias font: control.font
    readonly property alias locale: control.locale
    readonly property alias palette: control.palette

    readonly property alias forms: forms
    readonly property alias database: database

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("App singleton completed");
    }

    //--------------------------------------------------------------------------

    onAppChanged: {
        if (!app) {
            return;
        }

        console.log("App singleton initialized:", app);
    }

    //--------------------------------------------------------------------------

    QtObject {
        id: internal
    }

    //--------------------------------------------------------------------------

    Control {
        id: control

        locale: app ? app.locale : Qt.locale()

        font {
            family: app ? app.fontFamily : ""
            pointSize: 12
            bold: app ? app.appSettings.boldText : false
        }

        palette {
            window: app ? app.backgroundColor : "black"
            windowText: app ? app.textColor : "white"

            button: app ? app.titleBarBackgroundColor : "grey"
            buttonText: app ? app.titleBarTextColor : "white"
        }
    }

    //--------------------------------------------------------------------------

    Forms {
        id: forms

        app: singleton.app
    }

    //--------------------------------------------------------------------------

    Database {
        id: database

        app: singleton.app
    }

    //--------------------------------------------------------------------------
}

