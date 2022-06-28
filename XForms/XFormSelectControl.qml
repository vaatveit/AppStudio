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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "Singletons"
import "../Controls"

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var groupLabel
    readonly property string imageMapSource: mediaValue(groupLabel, "image", language)

    property var label
    property var items
    property XFormItemset itemset
    property var constraint

    property bool relevant: parent.relevant
    readonly property bool editable: parent.editable
    readonly property bool hidden: parent.hidden

    property alias columns: selectPanel.columns
    property alias controlsGrid: selectPanel.controlsGrid
    property string valuesLabel
    property var currentValues
    readonly property bool isReadOnly: !editable || binding.isReadOnly

    property string appearance

    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property bool showCalculate: !isReadOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedValue, currentValues)

    readonly property bool minimal: Appearance.contains(appearance, Appearance.kMinimal)
    readonly property real padding: 4 * AppFramework.displayScaleFactor
    readonly property bool isImageMap: Appearance.contains(appearance, Appearance.kImageMap)
    readonly property bool showControls: !isImageMap
    property bool showImageMapLabel: debug

    readonly property color textColor: minimal
                                       ? xform.style.selectTextColor
                                       : xform.style.textColor

    readonly property color altTextColor: minimal
                                          ? xform.style.selectAltTextColor
                                          : xform.style.textColor

    property alias selectField: selectFieldLoader.item

    property string valueSeparator: ","

    property bool debug

    property bool ensureVisibleOnHeightChange

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            if (debug) {
                console.log(logCategory, "onCalculatedValueChanged:", JSON.stringify(binding.nodeset), "value:", JSON.stringify(calculatedValue));
            }

            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    onHeightChanged: {
        if (ensureVisibleOnHeightChange && selectField && selectPanel.visible) {
            ensureVisibleOnHeightChange = false;
            ensureVisible();
        }
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        function _ensureVisible() {
            xform.ensureItemVisible(control);
        }

        Qt.callLater(_ensureVisible);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: itemset

        onFilteredItemsChanged: {
            if (debug) {
                console.log(logCategory, "onFilterChanged for:", JSON.stringify(bindElement), "value:", value);
            }

            if (!formData.isInitializing(binding)) {
                setValue(undefined);
            }

            items = itemset.filteredItems;
        }
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.fillWidth: true

        spacing: 0

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: imageMapComponent
            active: isImageMap
        }

        Loader {
            id: selectFieldLoader

            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: selectFieldComponent
            active: minimal
            enabled: !isReadOnly
            visible: minimal && (checkControlsRepeater.count > 0 || valuesLabel > "")
        }

        XFormSelectPanel {
            id: selectPanel

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: minimal ? padding * 3 : 0
            }

            enabled: !isReadOnly
            visible: (!minimal || (selectField && selectField.dropdownVisible)) && showControls
            padding: control.padding
            radius : minimal ? selectField.radius : 0
            color: minimal ? selectField.color : "transparent"
            border {
                width: minimal ? selectField.border.width : 0
                color: minimal ? selectField.border.color : "transparent"
            }

            onVisibleChanged: {
                if (visible) {
                    ensureVisibleOnHeightChange = true;
                }
            }

            Repeater {
                id: checkControlsRepeater

                parent: controlsGrid
                model: control.items
                delegate: checkControl
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: checkControl

        XFormCheckControl {
            width: controlsGrid.columnWidth
            bindElement: control.bindElement
            label: modelData.label
            value: modelData.value
            appearance: control.appearance

            checkBox {
                checked: Array.isArray(currentValues) && currentValues.indexOf(value) >= 0

                textColor: changeReason === 3
                           ? control.altTextColor
                           : control.textColor

                indicatorColor: changeReason === 3
                                ? xform.style.selectAltIndicatorColor
                                : xform.style.selectIndicatorColor

                onClicked: {
                    checkValue(checkBox.checked, value);
                }

                onVisualFocusChanged: {
                    if (checkBox.visualFocus && !minimal) {
                        xform.ensureItemVisible(checkBox);
                    }
                }
            }

            onClicked: {
                valueModified(control);
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormRecalculateButton {
        Layout.alignment: Qt.AlignTop

        visible: showCalculate

        onClicked: {
            changeReason = 0;
            formData.triggerCalculate(bindElement);
            valueModified(control);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onLanguageChanged: {
            if (control.minimal) {
                var values = formData.value(control.bindElement);
                control.valuesLabel = control.createLabel(values);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectFieldComponent

        XFormSelectField {
            visible: minimal
            text: valuesLabel
            changeReason: control.changeReason
            count: checkControlsRepeater.count
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageMapComponent

        ColumnLayout {
            XFormText {
                Layout.fillWidth: true

                visible: showImageMapLabel
                text: valuesLabel
                horizontalAlignment: Text.AlignHCenter
                color: xform.style.labelColor
                font {
                    pointSize: xform.style.valuePointSize
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            ImageMap {
                id: imageMap

                Layout.fillWidth: true
                Layout.preferredHeight: xform.height / 2

                property bool selecting
                property bool initializing: true

                source: imageMapSource
                multipleSelection: true
                onSelectedIdsChanged: {
                    if (initializing) {
                        return;
                    }

                    selecting = true;
                    setValue(selectedIds, 1);
                    selecting = false;
                }

                Component.onCompleted: {
                    imageMap.select(currentValues);
                    initializing = false;
                }

                Connections {
                    target: control

                    onCurrentValuesChanged: {
                        if (imageMap.selecting) {
                            return;
                        }

                        imageMap.select(currentValues);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var _changeReason = changeReason;
        var _values = XFormJS.clone(currentValues);

        var values = valueToArray(value);

        currentValues = values;
        valuesLabel = createLabel(values);
        formData.setValue(bindElement, values);

        if (reason) {
            if (reason === 1 && _changeReason === 3 && isEqual(values, _values)) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "setValue == calculated:", JSON.stringify(values));
                }
                changeReason = 3;
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }
    }

    //--------------------------------------------------------------------------

    function checkValue(checked, value) {
        var checkedValues = valueToArray(formData.value(bindElement));

        var valueIndex = checkedValues.indexOf(value);
        if (checked) {
            if (valueIndex < 0) {
                checkedValues.push(value);
            }
        } else {
            if (valueIndex >= 0) {
                // delete checkedValues[valueIndex];
                checkedValues[valueIndex] = undefined;
            }
        }

        var newValues = checkedValues.filter(function(element) {
            return !XFormJS.isNullOrUndefined(element) && element > "";
        });

        if (newValues.length <= 0) {
            newValues = undefined;
        }

        valuesLabel = createLabel(newValues);

        //console.log("newValues:", JSON.stringify(newValues));

        currentValues = newValues;

        changeReason = 1;
        formData.setValue(bindElement, newValues);
    }

    //--------------------------------------------------------------------------

    function valueToArray(values) {
        if (XFormJS.isNullOrUndefined(values)) {
            return [];
        }

        if (Array.isArray(values)) {
            return values;
        }

        return values.toString().split(valueSeparator).filter(function(value) {
            return !XFormJS.isNullOrUndefined(value) && value > "";
        });
    }

    //--------------------------------------------------------------------------

    function createLabel(values) {
        var label = "";

        if (!values) {
            return label;
        }

        for (let value of values) {
            if (label > "") {
                label += ",";
            }

            label += lookupLabel(value);
        }

        return label;
    }

    //--------------------------------------------------------------------------

    function lookupLabel(value) {
        var label = "";

        if (XFormJS.isEmpty(value)) {
            return label;
        }

        var item = items.find(item => item.value === value);
        if (item) {
            label = textValue(item.label);
        }

        return label;
    }

    //--------------------------------------------------------------------------

    function isEqual(v1, v2) {
        var values1 = valueToArray(v1);
        var values2 = valueToArray(v2);

        for (var i = 0; i < values1.length; i++) {
            if (values2.indexOf(values1[i])) {
                return false;
            }
        }

        for (i = 0; i < values2.length; i++) {
            if (values1.indexOf(values2[i])) {
                return false;
            }
        }

        return true;
    }

    //--------------------------------------------------------------------------
}
