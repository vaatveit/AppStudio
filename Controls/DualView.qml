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

import QtQml 2.13
import QtQuick 2.13
import QtQuick.Controls 2.13

import ArcGIS.AppFramework 1.0

import "Singletons"

SplitView {
    id: control

    //--------------------------------------------------------------------------

    property Item leftItem
    property Item rightItem

    property Item topItem: leftItem
    property Item bottomItem: rightItem

    property real minimumRatio: 0.25
    property real maximumRatio: 1 - minimumRatio
    property real preferredRatio: 0.5

    property real horizontalRatio: preferredRatio
    property real verticalRatio: preferredRatio

    property real handleButtonSize: 30 * AppFramework.displayScaleFactor
    property real handleButtonHorizontalPosition: 0.5
    property real handleButtonVerticalPosition: 0.5

    //--------------------------------------------------------------------------

    readonly property string kGlyphHorizontal: ControlsSingleton.defaultGlyphSet.glyphChar("arrow-double-horizontal")
    readonly property string kGlyphVertical: ControlsSingleton.defaultGlyphSet.glyphChar("arrow-double-vertical")

    //--------------------------------------------------------------------------

    spacing: 8 * AppFramework.displayScaleFactor

    palette {
        //mid               // Pressed
        midlight: "#ccc"    // Hover
    }

    //--------------------------------------------------------------------------

    onOrientationChanged: {
        Qt.callLater(updateLayout);
    }

    //--------------------------------------------------------------------------

    handle: Rectangle {
        id: splitHandle

        implicitWidth: control.spacing
        implicitHeight: control.spacing

        readonly property bool pressed: splitHandle.SplitHandle.pressed || handleMouseArea.pressed
        property bool _pressed

        onPressedChanged: {
            if (pressed) {
                _pressed = true;
            } else if (_pressed) {
                _pressed = false;

                if (orientation === Qt.Horizontal) {
                    horizontalRatio = leftItem.width / control.width;
                } else {
                    verticalRatio = topItem.height / control.height;
                }
            }
        }

        color: (splitHandle.SplitHandle.pressed || handleMouseArea.pressed)
               ? control.palette.mid
               : (SplitHandle.hovered
                  ? control.palette.midlight
                  : control.palette.button)

        Rectangle {
            id: handleButton

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            width: handleButtonSize
            height: width
            radius: height / 2

            readonly property int orientation: control.orientation

            onOrientationChanged: {
                if (orientation === Qt.Horizontal) {
                    anchors.verticalCenterOffset = (handleButtonVerticalPosition - 0.5) * splitHandle.height;
                    anchors.horizontalCenterOffset = 0;
                } else {
                    anchors.verticalCenterOffset = 0;
                    anchors.horizontalCenterOffset = (handleButtonHorizontalPosition - 0.5) * splitHandle.width;
                }
            }

            color: (splitHandle.SplitHandle.pressed || handleMouseArea.pressed)
                   ? control.palette.mid
                   : ((splitHandle.SplitHandle.hovered || handleMouseArea.containsMouse)
                      ? control.palette.midlight
                      : control.palette.button)

            border {
                width: 1
                color: control.palette.midlight
            }

            Text {
                anchors.centerIn: parent

                text: orientation === Qt.Horizontal
                      ? kGlyphHorizontal
                      : kGlyphVertical
                color: control.palette.text
                font {
                    family: ControlsSingleton.defaultGlyphSet.font.family
                    pixelSize: handleButton.height * 0.8
                }
            }

            MouseArea {
                id: handleMouseArea

                anchors.fill: parent

                cursorShape: control.orientation === Qt.Horizontal
                             ? Qt.SplitHCursor
                             : Qt.SplitVCursor

                onPositionChanged: {
                    var ptControl = mapToItem(control, mouse.x, mouse.y);
                    var ptHandle = mapToItem(splitHandle, mouse.x, mouse.y);

                    if (control.orientation === Qt.Horizontal) {
                        leftItem.SplitView.preferredWidth = ptControl.x;
                        if (ptHandle.y > height && ptHandle.y < (splitHandle.height - height)) {
                            handleButton.anchors.verticalCenterOffset = (ptHandle.y - splitHandle.height / 2);
                            handleButtonVerticalPosition = handleButton.anchors.verticalCenterOffset / splitHandle.height + 0.5;
                        }
                    } else {
                        topItem.SplitView.preferredHeight = ptControl.y;
                        if (ptHandle.x > width && ptHandle.x < (splitHandle.width - width)) {
                            handleButton.anchors.horizontalCenterOffset = (ptHandle.x - splitHandle.width / 2);
                            handleButtonHorizontalPosition = handleButton.anchors.horizontalCenterOffset / splitHandle.width + 0.5;
                        }
                    }
                }

                onPressAndHold: {
                    if (control.orientation === Qt.Horizontal) {
                        horizontalRatio = preferredRatio;
                    } else {
                        verticalRatio = preferredRatio;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    function saveState() {
        var state = {
            horizontalRatio: horizontalRatio,
            verticalRatio: verticalRatio,
            handleButtonHorizontalPosition: handleButtonHorizontalPosition,
            handleButtonVerticalPosition: handleButtonVerticalPosition
        };

        console.log(logCategory, arguments.callee.name, "state:", JSON.stringify(state, undefined, 2));

        return state;
    }

    //--------------------------------------------------------------------------

    function restoreState(state) {
        if (typeof state !== "object" || state === null) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "state:", JSON.stringify(state, undefined, 2));

        horizontalRatio = state.horizontalRatio;
        verticalRatio = state.verticalRatio
        handleButtonHorizontalPosition = state.handleButtonHorizontalPosition;
        handleButtonVerticalPosition = state.handleButtonVerticalPosition;

        if (orientation === Qt.Horizontal) {
            leftItem.SplitView.preferredWidth = Qt.binding(() => control.width * (horizontalRatio > 0 ? horizontalRatio : preferredRatio));
        } else {
            topItem.SplitView.preferredHeight = Qt.binding(() => control.height * (verticalRatio > 0 ? verticalRatio : preferredRatio));
        }
    }

    //--------------------------------------------------------------------------

    function updateLayout() {
        if (orientation === Qt.Horizontal) {
            landscapeLayout();
        } else {
            portraitLayout();
        }
    }

    //--------------------------------------------------------------------------

    function landscapeLayout() {
        if (itemAt(0) !== leftItem) {
            moveItem(1, 0);
        }

        leftItem.SplitView.minimumHeight = undefined;
        leftItem.SplitView.maximumHeight = undefined;
        leftItem.SplitView.fillWidth = false;
        leftItem.SplitView.fillHeight = true;

        rightItem.SplitView.minimumHeight = undefined;
        rightItem.SplitView.maximumHeight = undefined;
        rightItem.SplitView.fillWidth = true;
        rightItem.SplitView.fillHeight = true;

        leftItem.SplitView.minimumWidth = Qt.binding(() => control.width * minimumRatio);
        leftItem.SplitView.maximumWidth = Qt.binding(() => rightItem.visible ? control.width * maximumRatio : Number.POSITIVE_INFINITY);
        leftItem.SplitView.preferredWidth = Qt.binding(() => control.width * (horizontalRatio > 0 ? horizontalRatio : preferredRatio));
    }

    //--------------------------------------------------------------------------

    function portraitLayout() {
        if (itemAt(0) !== topItem) {
            moveItem(1, 0);
        }

        topItem.SplitView.minimumWidth = undefined;
        topItem.SplitView.maximumWidth = undefined;
        topItem.SplitView.preferredWidth = undefined;
        topItem.SplitView.fillWidth = true;
        topItem.SplitView.fillHeight = false;

        bottomItem.SplitView.minimumWidth = undefined;
        bottomItem.SplitView.maximumWidth = undefined;
        bottomItem.SplitView.preferredWidth = undefined;
        bottomItem.SplitView.fillWidth = true;
        bottomItem.SplitView.fillHeight = true;

        topItem.SplitView.minimumHeight = Qt.binding(() => control.height * minimumRatio);
        topItem.SplitView.maximumHeight = Qt.binding(() => bottomItem.visible ? control.height * maximumRatio : Number.POSITIVE_INFINITY);
        topItem.SplitView.preferredHeight = Qt.binding(() => control.height * (verticalRatio > 0 ? verticalRatio : preferredRatio));
    }

    //--------------------------------------------------------------------------
}
