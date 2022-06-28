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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "Singletons"

PageIndicator {
    id: control

    //--------------------------------------------------------------------------

    property DualView dualView

    property bool showIcon: true
    property bool showText: true

    property color tabsBorder: "red"
    property color selectedBackgroundColor: "transparent"
    property color backgroundColor: "transparent"
    property color tabsBorderColor: "transparent"

    property color selectedTextColor: "white"
    property color textColor: Qt.darker(selectedTextColor, 1.25)//"#b0b0b0"
    property color selectedIconColor: selectedTextColor
    property color iconColor: textColor
    property color selectedIndicatorColor: selectedTextColor
    property real selectedIndicatorSize: 7 * AppFramework.displayScaleFactor

    property real tabsPadding: 0//1 * AppFramework.displayScaleFactor
    property real iconSize: 25 * AppFramework.displayScaleFactor

    property bool fitToWidth: true
    readonly property int visibleCount: count
    property int indicatorCount: visibleCount
    property real indicatorWidth: visible && indicatorCount > 0
                                  ? fitToWidth
                                    ? calculateWidth(width, spacing, indicatorCount)
                                    : 40 * AppFramework.displayScaleFactor
    : 0


    //--------------------------------------------------------------------------

    count: 2
    currentIndex: dualView.currentIndex
    interactive: true
    bottomPadding: selectedIndicatorSize - 2 * AppFramework.displayScaleFactor

    font {
        family: ControlsSingleton.font.family
        pointSize: showIcon ? 11 : 13
    }

    onCurrentIndexChanged: {
        dualView.currentIndex = currentIndex;
    }

    Connections {
        target: dualView

        onCurrentIndexChanged: {
            currentIndex = dualView.currentIndex;
        }
    }

    //--------------------------------------------------------------------------

    function calculateWidth(width, spacing, count) {
        if (count <= 0) {
            return 0;
        }

        return (width - (count - 1) * spacing) / count;
    }

    //--------------------------------------------------------------------------

    delegate: Item {
        id: indicator

        readonly property Item tabItem: dualView.itemAt(index)
        readonly property bool isCurrentItem: tabItem.visible
        readonly property Item nextTabItem: dualView.itemAt(index ? 0 : 1)

        enabled: tabItem.enabled

        implicitWidth: indicatorWidth
        implicitHeight: indicatorLayout.height + indicatorLayout.anchors.topMargin * 2

        Rectangle {
            anchors {
                fill: parent
                margins: tabsPadding
            }
            
            color: isCurrentItem
                   ? selectedBackgroundColor
                   : backgroundColor

            border {
                color:  tabsBorderColor
                width: 1
            }

            radius: showIcon
                    ? 5 * AppFramework.displayScaleFactor
                    : height / 2

            Rectangle {
                anchors.fill: parent

                visible: mouseArea.containsMouse
                radius: parent.radius
                color: textColor
                opacity: 0.15
            }
            
            ColumnLayout {
                id: indicatorLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: tabsPadding
                    rightMargin: tabsPadding
                    top: parent.top
                    topMargin: 2 * AppFramework.displayScaleFactor
                }
                
                spacing: 0
                
                Item {
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    Layout.alignment: Qt.AlignCenter
                    
                    visible: showIcon
                    opacity: indicator.enabled ? 1 : 0.5

                    IconImage {
                        anchors.fill: parent

                        glyphSet: tabItem.glyphSet
                        icon {
                            name: tabItem.icon.name
                            source: tabItem.icon.source
                            color: isCurrentItem
                                   ? selectedIconColor
                                   : iconColor
                        }
                    }
                }
                
                Text {
                    id: indicatorText
                    
                    Layout.fillWidth: true
                    
                    visible: showText
                    text: dualView.itemAt(index).title
                    elide: ControlsSingleton.localeProperties.textElide
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: isCurrentItem
                           ? selectedTextColor
                           : textColor

                    font: control.font
                }
            }

            Rectangle {
                id: selectedIndicator

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: control.contentItem.height - indicatorLayout.anchors.topMargin
                }

                visible: isCurrentItem
                width: selectedIndicatorSize
                height: selectedIndicatorSize
                color: selectedIndicatorColor
                radius: height / 2
            }
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            enabled: dualView.itemAt(index).enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor: Qt.ForbiddenCursor

            onClicked: {
                tabItem.visible = !tabItem.visible;
                if (!tabItem.visible && !nextTabItem.visible) {
                    nextTabItem.visible = true;
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
