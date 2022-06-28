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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"

Item {
    id: button

    //--------------------------------------------------------------------------

    property alias icon: iconImage.icon
    property alias source: iconImage.icon.source // TODO Remove
    property real padding: 0
    property color color: checkable ? checked ? checkedColor : uncheckedColor : "transparent"
    property color checkedColor: "black"
    property color uncheckedColor: "#c0c0c0"
    property alias mirror: iconImage.mirror

    property bool checkable
    property bool checked

    //--------------------------------------------------------------------------

    signal clicked(var mouse);
    signal pressAndHold(var mouse)

    //--------------------------------------------------------------------------

    opacity: enabled ? 1 : 0.5

    implicitWidth: 36 * AppFramework.displayScaleFactor
    implicitHeight: 36 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Glow {
        id: glow

        anchors.fill: iconImage

        visible: checked && button.enabled
        color: button.color
        source: iconImage
        radius: 12 * AppFramework.displayScaleFactor
        samples: radius

        SequentialAnimation {
            running: glow.visible
            loops: Animation.Infinite

            OpacityAnimator {
                id: anim1
                target: glow
                duration: 750
                from: 0.1
                to: 1
                easing.type: Easing.InQuad
            }

            OpacityAnimator {
                target: glow
                duration: anim1.duration
                from: anim1.to
                to: anim1.from
                easing.type: Easing.OutQuad
            }
        }
    }

    IconImage {
        id: iconImage

        anchors {
            fill: parent
            margins: padding
        }

        icon.color: button.color
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            button.clicked(mouse);
        }

        onPressAndHold: {
            button.pressAndHold(mouse);
        }
    }

    //--------------------------------------------------------------------------
}
