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
import QtLocation 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../../Controls"
import "../../Controls/Singletons"
import "../Singletons"

//------------------------------------------------------------------------------

Item {
    id: delegate

    //--------------------------------------------------------------------------

    property alias dropShadow: dropShadow
    property string name
    property bool selected
    property color selectedColor: "#e1f0fb"
    property point origin: Qt.point(0.5, 0.5)
    property bool originVisible

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    height: 100 * AppFramework.displayScaleFactor
    width: height

    //--------------------------------------------------------------------------

    DropShadow {
        id: dropShadow

        anchors.fill: source
        horizontalOffset: 3 * AppFramework.displayScaleFactor
        verticalOffset: horizontalOffset

        radius: 5 * AppFramework.displayScaleFactor
        samples: 9
        color: "#12000000"
        source: rectangle
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: rectangle

        anchors.fill: parent

        color: selected ? selectedColor : "white"

        border {
            width: 1 * AppFramework.displayScaleFactor
            color: "#e5e5e5"
        }

        radius: 2 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: symbolItem

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: rectangle.border.width
        }

        height: width * 133/200
        clip: true

        color: selected ? selectedColor : "white"

        Glyph {
            id: symbolImage

            anchors {
                centerIn: parent
            }

            height: parent.height - 8 * AppFramework.displayScaleFactor
            width: height

            glyphSet: MapSymbols.point

            name: delegate.name

            scale: mouseArea.pressed
                   ? 0.95
                   : mouseArea.containsMouse
                     ? 1.05
                     : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        Rectangle {
            anchors.fill: symbolImage

            visible: originVisible

            color: "transparent"
            scale: symbolImage.scale

            border {
                width: 1
                color: "#ddd"
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: parent.height * origin.y
                }

                height: 1
                color: "red"
            }

            Rectangle {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    leftMargin: parent.width * origin.x
                }

                width: 1
                color: "red"
            }
        }
    }

    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea

        anchors {
            fill: parent
        }

        hoverEnabled: true
        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            delegate.clicked();
        }

        onPressAndHold: {
            delegate.pressAndHold();
        }
    }

    //--------------------------------------------------------------------------

    Text {
        id: nameText

        anchors {
            left: parent.left
            right: parent.right
            top: symbolItem.bottom
            bottom: parent.bottom
            margins: 4 * AppFramework.displayScaleFactor
        }

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: name
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 2
        //elide: Text.ElideRight
        color: "#303030"
        font {
            family: xform.style.fontFamily
            pixelSize: nameText.height / 2.1
        }
    }

    //--------------------------------------------------------------------------
}
