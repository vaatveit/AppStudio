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

import QtQml 2.13
import QtQuick 2.13

import ArcGIS.AppFramework 1.0

WorkerScript {
    id: workerScript
    
    //--------------------------------------------------------------------------

    property bool debug: false
    property bool running: false

    //--------------------------------------------------------------------------

    signal sorted()

    //--------------------------------------------------------------------------

    source: "ListModelSortWorker.mjs"
    
    //--------------------------------------------------------------------------

    onMessage: {
        if (debug) {
            console.log(logCategory, "messageObject:", JSON.stringify(messageObject, undefined, 2));
        }

        running = false;
        sorted();
    }

    //--------------------------------------------------------------------------

    function sort(model, parameters) {
        running = true;

        var msg = {
            debug: workerScript.debug,
            model: model,
            parameters: parameters
        };

        if (debug) {
            console.log(logCategory, arguments.callee.name, "msg:", JSON.stringify(msg, undefined, 2));
        }

        workerScript.sendMessage(msg);
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(workerScript, true)
    }

    //--------------------------------------------------------------------------
}
