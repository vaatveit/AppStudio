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
import QtQml.Models 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

Control  {
    id: control

    //--------------------------------------------------------------------------

    property ListModel model
    property alias items: visualModel.items
    property int layoutDirection: Qt.LeftToRight
    property bool isNull: true

    //--------------------------------------------------------------------------

    signal changed(DelegateModelGroup items)

    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    contentItem: Column {
        spacing: control.spacing

        move: Transition {
            NumberAnimation {
                properties: "x,y"
            }
        }

        Repeater {
            model: visualModel
        }
    }

    //--------------------------------------------------------------------------

    DelegateModel {
        id: visualModel

        model: control.model

        delegate: RankItem {
            width: parent.width

            font: control.font
            palette: control.palette
            items: visualModel.items
            layoutDirection: control.layoutDirection
            isNull: control.isNull

            onMoved: {
                control.isNull = false;
                control.changed(visualModel.items);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setOrder(values) {
        if (!values) {
            isNull = true;
            return;
        }

        if (!Array.isArray(values)) {
            values = values.split(",").map(value => value.trim()).filter(value => !!value);
        }

        isNull = !values.length;

        for (var i = 0; i < values.length; i++) {
            for (var j = 0; j < visualModel.items.count; j++) {
                if (i !== j && visualModel.items.get(j).model.value === values[i]) {
                    visualModel.items.move(j, i);
                    break;
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
