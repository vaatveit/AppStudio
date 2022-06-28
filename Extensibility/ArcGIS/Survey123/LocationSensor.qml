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

import QtQuick 2.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

AddInComponent {
    id: component

    //--------------------------------------------------------------------------

    readonly property bool active: _positionSourceConnection.active
    readonly property bool running: active // TODO remove
    property var position
    readonly property var positionSource: _positionSourceConnection.positionSourceManager.positionSource

    //--------------------------------------------------------------------------

    property var _positionSourceConnection

    //--------------------------------------------------------------------------

    signal started()
    signal stopped()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        clear();

        if (!_addIn) {
            return;
        }

        _positionSourceConnection = _addIn.context.createPositionSourceConnection(
                    this,
                    {
                        "listener": "AddIn: %1".arg(_addIn
                                                    ? _addIn.title > ""
                                                      ? _addIn.title
                                                      : AppFramework.typeOf(_addIn, true)
                                                    : "<Unknown>")
                    });
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        stop()
    }

    //--------------------------------------------------------------------------

    Connections {
        target: _positionSourceConnection

        ignoreUnknownSignals: true

        onNewPosition: {
            component.position = position;
        }
    }

    //--------------------------------------------------------------------------

    function start() {
        if (active) {
            console.warn(_logCategory, arguments.callee.name, "Already started");
            return;
        }

        function _start() {
            clear();
            _positionSourceConnection.start();
            started();
        }

        Qt.callLater(_start);
    }

    //--------------------------------------------------------------------------

    function stop() {
        if (!active) {
            console.warn(_logCategory, arguments.callee.name, "Not started");
            return;
        }

        _positionSourceConnection.stop();
        stopped();
    }

    //--------------------------------------------------------------------------

    function clear() {
        position = {
            "coordinate": QtPositioning.coordinate()
        }
    }

    //--------------------------------------------------------------------------
}
