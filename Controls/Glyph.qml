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

Control {
    id: control

    //--------------------------------------------------------------------------

    property string name
    property GlyphSet glyphSet: ControlsSingleton.defaultGlyphSet
    property string glyphChar: glyphSet.glyphChar(name)
    property alias debug: backgroundLoader.active
    property real fontScale: 1
    property alias color: control.palette.windowText
    property alias style: glyphText.style
    property alias styleColor: glyphText.styleColor
    property bool mirror

    //--------------------------------------------------------------------------

    implicitWidth: 35 * AppFramework.displayScaleFactor
    implicitHeight: implicitWidth

    font: glyphSet.font
    hoverEnabled: false

    //--------------------------------------------------------------------------

    contentItem: Item {
        Text {
            id: glyphText

            anchors.centerIn: parent

            text: glyphChar
            textFormat: Text.PlainText
            color: palette.windowText
            font {
                pixelSize: parent.height * fontScale
                family: control.font.family
            }
        }
    }
    
    //--------------------------------------------------------------------------

    background: Loader {
        id: backgroundLoader

        active: false

        sourceComponent: Rectangle {
            radius: height / 2
            color: "transparent"

            border {
                width: 1
                color: "red"
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: parent.width
                height: parent.border.width
                color: parent.border.color
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                width: parent.border.width
                height: parent.height
                color: parent.border.color
            }
        }
    }

    //--------------------------------------------------------------------------

    transform: mirror
               ? mirrorMatrix.createObject(control)
               : null

    //--------------------------------------------------------------------------

    Component {
        id: mirrorMatrix

        Matrix4x4 {
            matrix: Qt.matrix4x4(-1, 0, 0, control.width,
                                 0, 1, 0, 0,
                                 0, 0, 1, 0,
                                 0, 0, 0, 1)
        }
    }

    //--------------------------------------------------------------------------
}
