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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

XFormIconLabel {
    id: control

    //--------------------------------------------------------------------------

    icon {
        source: Icons.icon("exclamation-mark-circle", true)
        color: control.style.errorColor
    }

    label {
        color: control.style.errorColor
    }

    //--------------------------------------------------------------------------
}
