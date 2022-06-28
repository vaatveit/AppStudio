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

import QtQml 2.12
import QtQuick 2.12

import ArcGIS.AppFramework 1.0

import "Singletons"

Item {
    id: control

    //--------------------------------------------------------------------------

    property bool debug
    property alias logCategory: logCategory

    property XFormBinding binding
    property XFormData formData
    property var formElement

    property var appearance: Attribute.value(formElement, Attribute.kAppearance)
    property var constraint
    property bool readOnly: !editable || binding.isReadOnly

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    property bool initialized: false

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable
    readonly property bool hidden: parent.hidden

    //--------------------------------------------------------------------------

    implicitHeight: childrenRect.height

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, JSON.stringify(formElement));
        }

        constraint = formData.createConstraint(this, binding.element);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------
}
