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

import ArcGIS.AppFramework 1.0

import "Singletons"

Loader {
    id: control

    //--------------------------------------------------------------------------

    property alias icon: action.icon
    property GlyphSet glyphSet: ControlsSingleton.defaultGlyphSet
    property bool mirror

    //--------------------------------------------------------------------------

    //    implicitWidth: 35 * AppFramework.displayScaleFactor
    //    implicitHeight: 35 * AppFramework.displayScaleFactor

    active: (glyphSet && icon.name) || icon.source
    
    sourceComponent: icon.name ? glyph : image

    //--------------------------------------------------------------------------

    Action {
        id: action
    }

    //--------------------------------------------------------------------------

    Component {
        id: image

        StyledImage {
            source: icon.source
            color: icon.color
            mirror: control.mirror
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: glyph

        Glyph {
            glyphSet: control.glyphSet
            name: icon.name
            color: icon.color === Colors.kTransparent ? "black" : icon.color
            mirror: control.mirror
        }
    }

    //--------------------------------------------------------------------------
}
