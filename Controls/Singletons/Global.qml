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

pragma Singleton

import QtQuick 2.12

import ArcGIS.AppFramework 1.0

Item {
    id: global

    //--------------------------------------------------------------------------

    function setTimeout(callback, delay, ...params) {
        return timerComponent.createObject(global,
                                           {
                                               callback: callback,
                                               interval: delay,
                                               params: params
                                           } );
    }

    //--------------------------------------------------------------------------

    function setInterval(callback, delay, ...params) {
        return timerComponent.createObject(global,
                                           {
                                               callback: callback,
                                               interval: delay,
                                               params: params,
                                               repeat: true
                                           } );
    }

    //--------------------------------------------------------------------------

    function clearTimeout(timer) {
        if (!timer) {
            return;
        }

        timer.stop();
        timer.destroy();
    }

    //--------------------------------------------------------------------------

    function clearInterval(timer) {
        clearTimeout(timer);
    }

    //--------------------------------------------------------------------------

    Component {
        id: timerComponent

        Timer {
            property var callback
            property var params

            running: true
            repeat: false

            onTriggered: {
                callback(...params);
                destroy();
            }
        }
    }

    //--------------------------------------------------------------------------
}

