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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

Item {
    id: control

    //--------------------------------------------------------------------------

    property alias to: slider.to
    property alias from: slider.from
    property alias stepSize: slider.stepSize
    property alias value: slider.value
    property alias text: appText.text

    property color checkedColor: app.titleBarBackgroundColor
    property color uncheckedColor: app.textColor

    //--------------------------------------------------------------------------

    implicitHeight: Math.max(25 * AppFramework.displayScaleFactor, appText.height + slider.height + column.spacing + 6 * AppFramework.displayScaleFactor)

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: 10 * AppFramework.displayScaleFactor

        AppText {
            id: appText

            Layout.fillWidth: true
        }

        Slider {
            id: slider

            Layout.fillWidth: true
            Layout.leftMargin: -6 * AppFramework.displayScaleFactor
            Layout.rightMargin: -6 * AppFramework.displayScaleFactor

            //--------------------------------------------------------------------------

            handle: Rectangle {
                id: handle

                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 22 * AppFramework.displayScaleFactor
                implicitHeight: 22 * AppFramework.displayScaleFactor
                radius: 12 * AppFramework.displayScaleFactor
                color: slider.enabled ? checkedColor : Qt.lighter(Qt.lighter(uncheckedColor))
            }

            //--------------------------------------------------------------------------

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: slider.availableWidth
                height: implicitHeight
                radius: 2
                color: slider.enabled ? Qt.lighter(uncheckedColor) : Qt.lighter(Qt.lighter(uncheckedColor))

                Rectangle {
                    x: control.isRightToLeft ? slider.visualPosition * parent.width : 0
                    width: control.isRightToLeft ? (1 - slider.visualPosition) * parent.width : slider.visualPosition * parent.width
                    height: parent.height
                    color: slider.enabled ? checkedColor : Qt.lighter(Qt.lighter(uncheckedColor))
                    radius: 2
                }
            }

            //--------------------------------------------------------------------------
        }
    }
}
