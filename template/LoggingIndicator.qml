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

import ArcGIS.AppFramework 1.0

import "../Controls"

Rectangle {
    id: indicator

    //--------------------------------------------------------------------------

    implicitWidth: 7 * AppFramework.displayScaleFactor
    implicitHeight: implicitWidth

    visible: AppFramework.logging.enabled

    color: "white"
    radius: height / 2
    border {
        width: 1 * AppFramework.displayScaleFactor
        color: "orange"
    }

    z: 9999

    //--------------------------------------------------------------------------

    Rectangle {
        id: pulseIndicator

        anchors {
            fill: parent
            margins: 1 * AppFramework.displayScaleFactor
        }

        color: "red"
        radius: height / 2
    }

    //--------------------------------------------------------------------------

    PulseAnimation {
        target: pulseIndicator
        running: indicator.visible
    }

    //--------------------------------------------------------------------------
}
