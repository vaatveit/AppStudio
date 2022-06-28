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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

ActionsPopup {
    id: popup

    //--------------------------------------------------------------------------

    enum SortType {
        Alphabetical = 1,
        Time = 2,
        Distance = 4
    }

    //--------------------------------------------------------------------------

    property int sortTypes
    property int sortType
    property int sortOrder: Qt.AscendingOrder

    //--------------------------------------------------------------------------

    property alias ascendingAction: ascendingAction
    property alias descendingAction: descendingAction
    property alias newestAction: newestAction
    property alias oldestAction: oldestAction
    property alias nearestAction: nearestAction
    property alias farthestAction: farthestAction

    //--------------------------------------------------------------------------

    signal clicked(Action action)

    //--------------------------------------------------------------------------

    title: qsTr("Sort Order")
    
    icon {
        name: "switch"
    }

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    actionsLayout {
        onTriggered: {
            sortType = action.sortType;
            sortOrder = action.sortOrder;

            popup.clicked(action);
            popup.close();
        }
    }
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "actions:", actionGroup.actions.length);
        console.log(logCategory, "sortType:", sortType);
        console.log(logCategory, "sortOrder:", sortOrder);
        console.log(logCategory, "checkedAction:", actionGroup.checkedAction);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    SortAction {
        id: ascendingAction

        sortType: SortPopup.SortType.Alphabetical
        sortOrder: Qt.AscendingOrder
        enabled: sortTypes & sortType
        checked: sortType & popup.sortType && sortOrder === popup.sortOrder
        icon.name: "a-z-down"
        text: qsTr("Ascending")
    }

    SortAction {
        id: descendingAction

        sortType: SortPopup.SortType.Alphabetical
        sortOrder: Qt.DescendingOrder
        enabled: sortTypes & sortType
        checked: sortType & popup.sortType && sortOrder === popup.sortOrder
        icon.name: "a-z-up"
        text: qsTr("Descending")
    }

    SortAction {
        id: newestAction

        sortType: SortPopup.SortType.Time
        sortOrder: Qt.DescendingOrder
        enabled: sortTypes & sortType
        checked: (sortType & popup.sortType) && (sortOrder === popup.sortOrder)
        icon.name: "clock-down"
        text: qsTr("Newest")
    }

    SortAction {
        id: oldestAction

        sortType: SortPopup.SortType.Time
        sortOrder: Qt.AscendingOrder
        enabled: sortTypes & sortType
        checked: (sortType & popup.sortType) && (sortOrder === popup.sortOrder)
        icon.name: "clock-up"
        text: qsTr("Oldest")
    }

    SortAction {
        id: nearestAction

        sortType: SortPopup.SortType.Distance
        sortOrder: Qt.AscendingOrder
        enabled: sortTypes & sortType
        checked: (sortType & popup.sortType) && (sortOrder === popup.sortOrder)
        icon.name: "measure"
        text: qsTr("Nearest")
    }

    SortAction {
        id: farthestAction

        sortType: SortPopup.SortType.Distance
        sortOrder: Qt.DescendingOrder
        enabled: sortTypes & sortType
        checked: (sortType & popup.sortType) && (sortOrder === popup.sortOrder)
        icon.name: "measure"
        text: qsTr("Farthest")
    }

    //--------------------------------------------------------------------------
}
