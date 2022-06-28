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
import QtSensors 5.12

import ArcGIS.AppFramework 1.0


Item {
    id: compassSimulator

    //--------------------------------------------------------------------------

    property alias active: timer.running
    property alias reading: reading

    //--------------------------------------------------------------------------

    QtObject {
        id: reading

        property real azimuth: Number.NaN
        property real calibrationLevel
    }

    //--------------------------------------------------------------------------

    Timer {
        id: timer

        interval: 250
        repeat: true
        triggeredOnStart: true

        property int n

        onTriggered: {
            reading.azimuth = (reading.azimuth + Math.random() * (Math.random() >= 0.3 ? 1 : -1)) % 360;
            reading.calibrationLevel = Math.max(0, Math.min(1, reading.calibrationLevel + Math.random() / 50 * (Math.random() >= 0.5 ? 1 : -1)));
        }
    }

    //--------------------------------------------------------------------------

    function start() {
        reading.azimuth = 0;
        reading.calibrationLevel = 0.5;
        timer.start();
    }


    function stop() {
        timer.stop();
    }

    //--------------------------------------------------------------------------

}
