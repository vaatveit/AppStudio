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

import * as ModelSort from "ModelSort.mjs";

//------------------------------------------------------------------------------

WorkerScript.onMessage = function(msg) {
    const debug = msg.debug;

    if (debug) {
        console.log("msg:", JSON.stringify(msg, undefined, 2));
        console.time("sortAsync");
    }

    let startTime = new Date();

    ModelSort.sort(msg.model, msg.parameters);

    msg.model.sync();

    let elapsed = new Date() - startTime;

    if (debug) {
        console.timeEnd("sortAsync");
    }

    WorkerScript.sendMessage({
        elapsed: elapsed,
        parameters: msg.parameters
    });
}

//------------------------------------------------------------------------------

