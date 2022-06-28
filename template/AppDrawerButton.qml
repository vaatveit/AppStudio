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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"
import "../Controls"

StyledImageButton {
    id: control

    //--------------------------------------------------------------------------

    property Component popup: actionsDrawer
    default property alias actions: actionGroup.actions

    //--------------------------------------------------------------------------

    source: ControlsSingleton.menuIcon
    color: app.titleBarTextColor
    padding: ControlsSingleton.menuIconPadding

    //--------------------------------------------------------------------------

    onClicked: {
        var popup = control.popup.createObject(control);
        popup.open();
    }

    //--------------------------------------------------------------------------

    ActionGroup {
        id: actionGroup
    }

    //--------------------------------------------------------------------------

    Component {
        id: actionsDrawer

        ActionsDrawer {
            id: popup

            actions: actionGroup.actions
        }
    }

    //--------------------------------------------------------------------------
}
