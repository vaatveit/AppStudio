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

import ArcGIS.AppFramework 1.0

import ArcGIS.Survey123 1.0

AddInControl {
    id: addIn

    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    implicitHeight: control.height + control.anchors.margins * 2

    //--------------------------------------------------------------------------

    onUpdateValue: {
        console.log(logCategory, "updateValue:", value);
        control.value = isFinite(value) ? value : 0;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addIn, true)
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        color: "beige"
        radius: 5
        visible: addIn.debug

        border {
            color: "darkgrey"
            width: 2
        }
    }

    //--------------------------------------------------------------------------

    CompassControl {
        id: control

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }

        onValueChanged: {
            addIn.value = value;
        }
    }

    //--------------------------------------------------------------------------
}

