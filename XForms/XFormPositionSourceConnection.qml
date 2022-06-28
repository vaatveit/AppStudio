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

import "Sensors"

Item {
    id: positionSourceConnection

    property XFormPositionSourceManager positionSourceManager

    readonly property bool valid: positionSourceManager.valid
    readonly property int wkid: positionSourceManager.wkid

    property string errorString
    property string listener

    property bool emitNewPositionIfNoFix
    property bool stayActiveOnError
    property bool active

    property bool compassEnabled: positionSourceManager.compassEnabled

    property bool debug: positionSourceManager.debug

    //--------------------------------------------------------------------------

    readonly property bool compassAvailable: positionSourceManager.compassAvailable

    readonly property bool compassActive: compass.connectedToBackend
                                          ? compass.active
                                          : compassSimulator.active

    readonly property var /*CompassReading*/ compassReading: compass.connectedToBackend
                                                             ? compass.reading
                                                             : compassSimulator.reading

    readonly property real compassAzimuth: compassActive && compassReading
                                           ? compassReading.azimuth
                                           : Number.NaN

    readonly property real compassCalibrationLevel: compassActive && compassReading
                                                    ? compassReading.calibrationLevel
                                                    : 0

    readonly property real magneticDeclination: positionSourceManager.magneticDeclination
    readonly property real compassTrueAzimuth: compassAzimuth - magneticDeclination

    //--------------------------------------------------------------------------

    signal newPosition(var position)

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        stop();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(positionSourceConnection, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        function onNewPosition(position) {
            if (active) {
                positionSourceConnection.errorString = "";

                if (emitNewPositionIfNoFix || !positionSourceManager.isGNSS || position.fixTypeValid && position.fixType > 0) {
                    newPosition(position);
                }
            }
        }

        function onTcpError() {
            if (active) {
                positionSourceConnection.errorString = errorString;

                if (!stayActiveOnError && errorString > "") {
                    console.warn(logCategory, "Position manager error:", errorString, ", listener:", listener);
                    stop();
                }
            }
        }

        function onDeviceError() {
            if (active) {
                positionSourceConnection.errorString = errorString;

                if (!stayActiveOnError && errorString > "") {
                    console.warn(logCategory, "Position manager error:", errorString, ", listener:", listener);
                    stop();
                }
            }
        }

        function onNmeaLogFileError() {
            if (active) {
                positionSourceConnection.errorString = errorString;

                if (!stayActiveOnError && errorString > "") {
                    console.warn(logCategory, "Position manager error:", errorString, ", listener:", listener);
                    stop();
                }
            }
        }

        function onPositionSourceError() {
            if (active) {
                positionSourceConnection.errorString = errorString;

                if (!stayActiveOnError && errorString > "") {
                    console.warn(logCategory, "Position manager error:", errorString, ", listener:", listener);
                    stop();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function start() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "listener:", listener, "active:", active);
        }

        if (active) {
            if (debug) {
                console.warn(logCategory, arguments.callee.name,  "Connection already active - listener:", listener);
            }
            return;
        }

        if (!valid) {
            console.warn(logCategory, arguments.callee.name,  "positionSource not valid");
            return;
        }

        active = true;

        positionSourceManager.listen(listener);

        if (compassEnabled) {
            startCompass();
        }
    }

    //--------------------------------------------------------------------------

    function stop() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "listener:", listener, "active:", active);
        }

        if (!active) {
            if (debug) {
                console.warn(logCategory, arguments.callee.name, "Connection not active - listener:", listener);
            }
            return;
        }

        active = false;

        if (!valid) {
            console.warn(logCategory, arguments.callee.name,  "positionSource not valid");
            return;
        }

        positionSourceManager.release(listener);

        if (compassActive) {
            stopCompass();
        }
    }

    //--------------------------------------------------------------------------

    Compass {
        id: compass
    }

    CompassSimulator {
        id: compassSimulator
    }

    //--------------------------------------------------------------------------

    function startCompass() {
        if (compassActive) {
            return true;
        }

        console.log(logCategory, "Starting compass");

        if (compass.connectedToBackend) {
            compass.start();
        } else {
            compassSimulator.start();
        }

        positionSourceManager.compassActiveCount++;
    }

    //--------------------------------------------------------------------------

    function stopCompass() {
        if (!compassActive) {
            console.warn(logCategory, "Compass not active");
            return;
        }

        console.log(logCategory, "Stopping compass");

        if (compass.connectedToBackend) {
            compass.stop();
        } else {
            compassSimulator.stop();
        }

        positionSourceManager.compassActiveCount--;
    }

    //--------------------------------------------------------------------------
}
