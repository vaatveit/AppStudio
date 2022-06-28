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

import ArcGIS.AppFramework 1.0

Item {
    id: addIn

    implicitWidth: 480
    implicitHeight: 640

    //--------------------------------------------------------------------------

    property alias font: control.font
    property alias locale: control.locale
    property alias palette: control.palette

    property string title

    //--------------------------------------------------------------------------

    property var context

    property FileFolder surveyFolder: context.properties.surveyFolder || null

    readonly property ListModel formsModel: context.surveysModel
    readonly property Settings settings: context.addIn.settings
    readonly property FileFolder dataFolder: context.addIn.dataFolder

    //--------------------------------------------------------------------------

    signal settingsModified()

    //--------------------------------------------------------------------------

    objectName: "Survey123.AddIn"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "context id:", context.addIn.name);
    }

    //--------------------------------------------------------------------------

    onSettingsModified: {
        settings.synchronize();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: "Survey123.AddIn" //AppFramework.typeOf(addIn, true)
    }

    //--------------------------------------------------------------------------

    QtObject {
        id: internal

        readonly property bool inSurvey123: Survey123.app !== null
    }

    //--------------------------------------------------------------------------

    Control {
        id: control

        font: Survey123.font
        locale: Survey123.locale
        palette: Survey123.palette
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: errorText
            margins: -errorText.anchors.margins
        }

        visible: errorText.visible
        color: "red"
        z: errorText.z - 1
    }

    Text {
        id: errorText

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 5
        }

        visible: !internal.inSurvey123

        text: "Add-Ins must be run inside Survey123"

        font {
            pointSize: 20
            bold: true
        }

        color: "white"
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        horizontalAlignment: Text.AlignHCenter

        z: parent.z + 9999
    }

    //--------------------------------------------------------------------------

    function openSettings() {
        context.openPage("settings");
    }

    //--------------------------------------------------------------------------

    function doSomething(arg) {
        console.log("Do something");
    }

    //--------------------------------------------------------------------------
}

