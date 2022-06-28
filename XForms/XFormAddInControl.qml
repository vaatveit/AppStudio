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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "Singletons"
import "XForm.js" as XFormJS

XFormControl {
    id: control

    //--------------------------------------------------------------------------

    property string addInName
    property var addInItem
    readonly property var addInInstance: addInItem ? addInItem.instance : null
    readonly property var addInInfo: addInItem ? addInItem.addIn.addInInfo : {}
    readonly property var info: addInInfo.control || {}
    readonly property bool showClear: !!info.enableClear

    readonly property var value: addInInstance ? addInInstance.value : undefined
    property var calculatedValue
    property int changeReason // XForms.ChangeReason

    property XFormItemset itemset
    property XFormItemsetModel itemsetModel

    readonly property bool isEmpty: XFormJS.isEmpty(value)

    //--------------------------------------------------------------------------

    //debug: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "addInName:", addInName);
            console.log(logCategory, "formElement:", JSON.stringify(formElement, undefined, 2));
            console.log(logCategory, "binding:", JSON.stringify(binding.element, undefined, 2));
        }

        var addIn = xform.addIns.findInfo(addInName);

        var properties = {
            asynchronous: false,
            font: xform.style.inputFont
        }

        initializeItemset();
        initializeItemsetModel();

        if (addIn) {
            addInItem = xform.addIns.createInstance(addInName, controlContainer, properties);

            //addInItem.palette = Qt.binding(function () { return xform.style.inputPalette; })
            addInInstance.itemset.model = itemsetModel;
            addInInstance.properties = getProperties();
            addInInstance.enabled = Qt.binding(() => { return !control.readOnly; });
            addInInstance.opacity = Qt.binding(() => { return control.readOnly ? 0.5 : 1; });
        } else {
            properties.addInName = addInName;
            addInItem = xform.addIns.nullAddIn.createObject(control, properties);
        }

        if (addInItem) {
            addInItem.parent = controlContainer;
            addInItem.anchors.left = controlContainer.left;
            addInItem.anchors.right = controlContainer.right;
        }

        return addInItem;
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(binding.element);
        } else {
            setValue(undefined, XForms.ChangeReason.Calculated);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding.element && changeReason !== XForms.ChangeReason.User) {
            setValue(calculatedValue, XForms.ChangeReason.Calculated);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: addInInstance

        onValueChanged: {
            formData.setValue(binding.element, XFormJS.toBindingType(target.value, binding.element));
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: itemset

        onFilteredItemsChanged: {
            if (debug) {
                console.log(logCategory, "onFilterChanged for:", JSON.stringify(binding.element), "value:", value);
            }

            initializeItemsetModel();
            setValue(undefined, XForms.ChangeReason.Set);
        }
    }

    //--------------------------------------------------------------------------

    Binding {
        target: addInItem
        property: "palette"
        value: xform.style.inputPalette
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: controlLayout

        layoutDirection: xform.localeProperties.layoutDirection
        spacing: 5 * AppFramework.displayScaleFactor

        width: parent.width

        Item {
            id: controlContainer

            Layout.fillWidth: true
            Layout.preferredHeight: addInItem ? addInItem.implicitHeight : 100
        }

        XFormClearButton {
            Layout.alignment: Qt.AlignTop

            visible: showClear && !isEmpty && !readOnly

            onClicked: {
                setValue(undefined, XForms.ChangeReason.Set);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log(arguments.callee.name, "value:", value, "reason:", reason, "binding:", JSON.stringify(binding.element));
            console.trace();
        }

        formData.setValue(binding.element, XFormJS.toBindingType(value, binding.element));

        if (debug) {
            console.log(arguments.callee.name, "updateValue:", value, "instance:", addInInstance);
        }

        addInInstance.updateValue(value);
    }

    //--------------------------------------------------------------------------

    function initializeItemset() {
        var itemsetInfo = xform.createItemset(
                    control,
                    formElement,
                    appearance,
                    {
                        createLabelItems: false
                    });

        itemset = itemsetInfo.itemset;
    }

    //--------------------------------------------------------------------------

    function initializeItemsetModel() {
        if (!formElement.item && !formElement.itemset) {
            return null;
        }

        if (itemsetModel) {
            itemsetModel.clear();
        } else {
            itemsetModel = itemsetModelComponent.createObject(control);
        }

        //console.log(logCategory, "formElement:", JSON.stringify(formElement, undefined, 2));

        if (itemset) {
            itemsetModel.addItemsetItems(itemset);
        } else if (formElement.item) {
            itemsetModel.addItems(XFormJS.asArray(formElement.item));
        }

        itemsetModel.update();
    }

    //--------------------------------------------------------------------------

    Component {
        id: itemsetModelComponent

        XFormItemsetModel {
        }
    }

    //--------------------------------------------------------------------------

    function getProperties() {
        let attributes = {};

        for (let [key, value] of Object.entries(formElement)) {
            if (!key.startsWith("@")) {
                continue;
            }

            attributes[key.substr(1)] = value;
        }

        if (debug) {
            console.log(logCategory, "properties:", JSON.stringify(attributes, undefined, 2));
        }

        return attributes;
    }

    //--------------------------------------------------------------------------
}
