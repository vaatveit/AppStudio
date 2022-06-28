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

/*
 * Avoids ListModel sort performance issues due to excessive model item moves
 * - Create array of indicies to model items
 * - Sort indices array based on a sortRole or sortCompare function
 * - Transpose sorted indices array into ordered swap index array
 * - Minimizes number of model item swaps to a maximum of 1 per model item
 * - Skip redundant swaps
 */

//------------------------------------------------------------------------------

/*
var parameters = {
    sortRole: <string>,
    sortOrder: Qt.AscendingOrder | Qt.DescendingOrder,
    sortCaseSensitivity: Qt.CaseInsensitive | Qt.CaseSensitive,
    sortCompare: <function(item1, item2, parameters)>,
    swapMethod: SwapMethodMove | SwapMethodClone
}
*/

//------------------------------------------------------------------------------

export const SwapMethodMove = 0
export const SwapMethodClone = 1

//------------------------------------------------------------------------------

export function sort(model, parameters) {
    if (!model) {
        throw "Invalid model";
    }

    if (typeof parameters !== "object") {
        throw "Invalid parameters";
    }

    if (!parameters.sortRole && typeof parameters.sortCompare !== "function") {
        throw "Invalid sortRole or sortCompare function";
    }

    const debug = !!parameters.debug;

    if (debug) {
        console.log("sort count:", model.count,
                    "parameters:", JSON.stringify(parameters, undefined, 2),
                    "sortCompare:", typeof parameters.sortCompare);

        console.time("sort");
    }

    _sort(model, parameters, debug);

    if (parameters.debug) {
        console.timeEnd("sort");
    }
}

//------------------------------------------------------------------------------

function _sort(model, parameters, debug) {
    const lessThan = parameters.sortOrder ? 1 : -1;
    const greaterThan = -lessThan;

    parameters.lessThan = lessThan;
    parameters.greaterThan = greaterThan;

    if (debug) {
        console.time("indices:create");
    }

    var indices = [...new Array(model.count).keys()];

    if (debug) {
        console.timeEnd("indices:create");
    }

    function sortRoleValue(index, sortRole) {
        const value = model.get(index)[sortRole];

        if (!parameters.sortCaseSensitivity && typeof value === "string") {
            return value.toLocaleLowerCase(); //.toLowerCase();
        } else {
            return value;
        }
    }

    function compareRole(index1, index2) {
        const value1 = sortRoleValue(index1, parameters.sortRole);
        const value2 = sortRoleValue(index2, parameters.sortRole);

        return value1 < value2
                ? lessThan
                : value1 > value2
                  ? greaterThan
                  : 0;
    }

    function compareItem(index1, index2) {
        return parameters.sortCompare(model.get(index1), model.get(index2), parameters);
    }

    const compare = typeof parameters.sortCompare === "function"
                          ? compareItem
                          : compareRole

    if (debug) {
        console.time("indices.sort");
    }

    indices.sort(compare);

    if (debug) {
        console.timeEnd("indices.sort");
    }

    if (debug) {
        console.time("swapIndices");
    }

    // TODO remove this hack when base offset no longer needed
    if (parameters.offset > 0) {
        indices = indices.filter(i => i >= parameters.offset);
        for (var i = parameters.offset - 1; i >= 0; i--) {
            indices.unshift(i);
        }
    }

    var swapIndices = indices
    .map((e, i) => { return { from: e, to: i }})
    .sort((i1, i2) => i1.from - i2.from)
    .map(e => e.to);

    if (debug) {
        console.timeEnd("swapIndices");
    }

    function cloneSwap(a, b) {
        var o = JSON.parse(JSON.stringify(model.get(a)));
        model.set(a, model.get(b));
        model.set(b, o);
    }

    function moveSwap(a, b) {
        if (a < b) {
            model.move(a, b, 1);
            model.move(b - 1, a, 1);
        }
        else if (a > b) {
            model.move(b, a, 1);
            model.move(a - 1, b, 1);
        }
    }

    var swap = parameters.swapMethod ? cloneSwap : moveSwap;
    var swapCount = 0;

    if (debug) {
        console.time("swap");
    }

    for (var iFrom = 0; iFrom < swapIndices.length; iFrom++) {
        var iTo = swapIndices[iFrom];

        if (iFrom === iTo) {
            continue;
        }

        do {
            if (compare(iFrom, iTo)) {
                swap(iFrom, iTo);
                swapCount++;
            }

            var t = swapIndices[iFrom];
            swapIndices[iFrom] = swapIndices[iTo]
            swapIndices[iTo] = t;

            iTo = swapIndices[iFrom];
        }
        while (iFrom !== iTo);
    }

    if (debug) {
        console.timeEnd("swap");
        console.log("swapCount:", swapCount);
    }
}

//------------------------------------------------------------------------------



