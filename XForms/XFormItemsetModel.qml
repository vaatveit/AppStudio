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

import "XForm.js" as XFormJS

ListModel {
    //--------------------------------------------------------------------------

    readonly property var locale: xform.locale

    //--------------------------------------------------------------------------

    onLocaleChanged: {
        update();
    }

    //--------------------------------------------------------------------------

    function update() {
        for (var i = 0; i < count; i++) {
            var item = get(i);

            if (item.textRef) {
                setProperty(i, "label", xform.textLookup(item.textRef));

                var ref = { "@ref": item.textRef };

                setProperty(i, "image", xform.mediaValue(ref, "image").toString());
                setProperty(i, "audio", xform.mediaValue(ref, "audio").toString());
                setProperty(i, "video", xform.mediaValue(ref, "video").toString());
            }
        }
    }

    //--------------------------------------------------------------------------

    function addItems(items, randomize, valueProperty, textIdProperty) {
        //console.log(logCategory, arguments.callee.name, "items:", JSON.stringify(items, undefined, 2));

        if (randomize) {
            XFormJS.randomizeArray(items);
        }

        if (!valueProperty) {
            valueProperty = "value";
        }

        for (var item of items) {
            //console.log("item:", JSON.stringify(item, undefined, 2))

            var value = item[valueProperty];
            var textRef;
            var label;

            if (textIdProperty) {
                textRef = "jr:itext('%1')".arg(item[textIdProperty]);
                label = "";
            } else {
                switch (typeof item.label) {
                case "string":
                    label = item.label;
                    break;

                case "object":
                    label = "";
                    textRef = item.label["@ref"];
                    break;

                default:
                    label = "";
                    break;
                }
            }

            var modelItem = {
                value: value,
                textRef: textRef,
                label: label,
                image: "",
                audio: "",
                video: "",
            };

            //console.log("modelItem:", JSON.stringify(modelItem, undefined, 2))

            append(modelItem);
        }
    }

    //--------------------------------------------------------------------------

    function addItemsetItems(itemset) {
        addItems(itemset.hasFilter
                 ? itemset.filteredItems
                 : itemset.items,
                 itemset.randomize,
                 itemset.valueProperty,
                 itemset.labelProperty);
    }

    //--------------------------------------------------------------------------
}
