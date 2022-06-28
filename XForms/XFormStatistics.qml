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

QtObject {
    //--------------------------------------------------------------------------

    property var bindings: ({})
    property int calculates
    property var controls: ({})
    property var expressions: ({})
    property var inlineItemsets: ({})
    property var itemsets: ({})
    property var events: ({})

    //--------------------------------------------------------------------------

    function add(object, key) {
        if (object.hasOwnProperty(key)) {
            object[key]++;
        } else {
            object[key] = 1;
        }
    }

    //--------------------------------------------------------------------------

    function addBinding(type) {
        add(bindings, type);
    }

    //--------------------------------------------------------------------------

    function addControl(type) {
        add(controls, type);
    }

    //--------------------------------------------------------------------------

    function addExpression(purpose) {
        add(expressions, purpose);
    }

    //--------------------------------------------------------------------------

    function addNodeItemset(nodeset, count) {
        inlineItemsets[nodeset.split("/").pop()] = count;
    }

    //--------------------------------------------------------------------------

    function event(name) {
        var event = events[name];
        if (event) {
            event.count = event.count + 1;
            return;
        }

        events[name] = {
            timestamp: new Date(),
            count: 1
        };
    }

    //--------------------------------------------------------------------------

    function eventEnd(name) {
        var event = events[name];
        if (!event) {
            console.error("Event not started:", name);
            return;
        }

        event.timestampEnd = new Date();
        event.duration = event.timestampEnd - event.timestamp;
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("Statistics");

        logKeyValues(" Bindings", bindings);
        console.log(" Calculates:", calculates);
        logKeyValues(" Controls", controls);
        logKeyValues(" Expressions", expressions);
        logKeyValues(" Inline itemsets", inlineItemsets);

        let keys = Object.keys(itemsets);
        console.log(" Itemsets:", keys.length);

        for (const key of keys) {
            console.log("  ", key, ":", itemsets[key].length);
        }

        logKeyValues(" Events", events);
    }

    //--------------------------------------------------------------------------

    function logKeyValues(name, o) {
        if (!o) {
            return;
        }

        let entries = Object.entries(o);

        console.log(name, ":", entries.length);
        if (!entries.length) {
            return
        }

        for (let [key, value] of entries) {
            if (typeof value === "object") {
                console.log(" ", key, ":", JSON.stringify(value, undefined, 2));
            } else {
                console.log(" ", key, ":", value);
            }
        }
    }

    //--------------------------------------------------------------------------
}
