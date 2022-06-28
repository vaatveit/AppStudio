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

import ArcGIS.Survey123 1.0

AddInControl {
    id: addIn

    //--------------------------------------------------------------------------

    property bool debug: false
    property real margin: 35 * AppFramework.displayScaleFactor
    property bool clearEnabled: true
    property bool recalculateEnabled: false

    readonly property bool showMargin: !clearEnabled && !recalculateEnabled

    //--------------------------------------------------------------------------

    implicitHeight: rank.height + rank.anchors.margins * 2

    //--------------------------------------------------------------------------

    onUpdateValue: {
        console.log(logCategory, "updateValue:", value);

        if (!value) {
            addIn.value = undefined;
        }

        rank.setOrder(value);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addIn, true)
    }

    //--------------------------------------------------------------------------

    Rank {
        id: rank

        anchors {
            left: parent.left
            right: parent.right
        }

        palette: addIn.palette
        font: addIn.font
        layoutDirection: addIn.locale.textDirection

        leftPadding: showMargin || layoutDirection == Qt.LeftToRight
                     ? margin
                     : isNull
                       ? margin
                       : 0

        rightPadding: showMargin || layoutDirection == Qt.RightToLeft
                      ? margin
                      : isNull
                        ? margin
                        : 0


        model: addIn.itemset.model

        onChanged: {
            var values = [];

            for (var i = 0; i < items.count; i++) {
                values.push(items.get(i).model.value);
            }

            addIn.value = values.join(",");
        }

        background: Loader {
            active: addIn.debug

            sourceComponent: Rectangle {
                color: palette.window
                radius: 3

                border {
                    color: palette.mid
                    width: 1
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}

