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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls/Singletons"

AbstractButton {
    id: control

    //--------------------------------------------------------------------------

    property Map map: parent

    property real bearing: map.bearing
    property real size: 38 * AppFramework.displayScaleFactor

    property color color: "black"
    property color caretColor: color

    enum Mode {
        North = 0,
        Cardinal = 1,
        Degrees = 2,

        Count = 3
    }

    property int mode: NorthArrow.Mode.North

    //--------------------------------------------------------------------------

    readonly property string kGlyphCaretUp: ControlsSingleton.defaultGlyphSet.glyphChar("caret-up")

    //--------------------------------------------------------------------------

    signal reset()

    //--------------------------------------------------------------------------

    implicitWidth: size
    implicitHeight: size

    visible: bearing != 0
    z: parent.z + 1

    //--------------------------------------------------------------------------

    onReset: {
        map.bearing = 0;
    }

    onClicked: {
        reset();
    }

    onPressAndHold: {
        mode = (mode + 1) % NorthArrow.Mode.Count;
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        anchors.fill: parent

        rotation: mode === NorthArrow.Mode.North ? -bearing : 0

        Text {
            anchors {
                fill: parent
                margins: 2 * AppFramework.displayScaleFactor
            }

            text: mode === NorthArrow.Mode.North
                  ? Units.cardinalDirectionName(0)
                  : mode === NorthArrow.Mode.Cardinal
                    ? Units.cardinalDirectionName(bearing)
                    : "%1°".arg(Math.round(bearing))

            color: control.color
            fontSizeMode: Text.HorizontalFit
            font {
                bold: control.font.bold
                pixelSize: height * 0.4
                family: control.font.family
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }

                text: kGlyphCaretUp

                color: control.caretColor
                font {
                    family: ControlsSingleton.defaultGlyphSet.font.family
                    pixelSize: (control.height - parent.paintedHeight) / 2
                }

                scale: 1.4
            }
        }
    }

    //--------------------------------------------------------------------------

    background: Item {
        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }

        DropShadow {
            id: dropShadow

            anchors.fill: source

            horizontalOffset: 3 * AppFramework.displayScaleFactor
            verticalOffset: horizontalOffset

            radius: 5 * AppFramework.displayScaleFactor
            samples: 9
            color: "#40000000"
            source: background
            opacity: background.opacity
        }

        Rectangle {
            id: background

            anchors {
                fill: parent
            }

            radius: height / 2

            color: "#eeeeee"

            border {
                width : (bold ? 2 : 1) * AppFramework.displayScaleFactor
                color: "#ddd"
            }
        }
    }

    //--------------------------------------------------------------------------
}
