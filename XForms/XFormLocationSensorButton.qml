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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../Controls"
import "../Controls/Singletons"
import "Singletons"

Item {
    id: control

    //--------------------------------------------------------------------------

    property color color: xform.style.titleTextColor

    property XFormPositionSourceManager positionSourceManager
    property XFormGNSSStatusPages gnssStatusPages

    readonly property bool hasError: positionSourceManager && positionSourceManager.positionSource.sourceError !== PositionSource.NoError
    readonly property bool isConnecting: positionSourceManager && positionSourceManager.isConnecting
    readonly property bool isConnected: positionSourceManager && positionSourceManager.isConnected
    readonly property bool isWarmingUp: positionSourceManager && positionSourceManager.isWarmingUp

    property string errorIcon: "satellite-3"

    property int linkIconIndex: 0
    property int linkStep: 1
    property string linkIcon: "satellite-%1".arg(linkIconIndex)

    property int qualityIconIndex: 3
    property string qualityIcon: "satellite-%1-f".arg(qualityIconIndex)

    property var internalQualities: [50, 25, 10]
    property var externalQualities: [25, 10, 3]

    property int positionSourceType: XFormPositionSourceManager.PositionSourceType.System
    property var qualities: positionSourceType > XFormPositionSourceManager.PositionSourceType.System
                            ? externalQualities
                            : internalQualities

    property var position: ({})

    property bool debug: false

    //--------------------------------------------------------------------------

    visible: positionSourceManager && !positionSourceManager.onDetailedSettingsPage && (positionSourceManager.active || isConnecting)
    enabled: visible && button.icon.name

    //--------------------------------------------------------------------------

    onPositionChanged: {
        if (debug) {
            console.log(logCategory, "position:", JSON.stringify(position, undefined, 2));
        }

        if (position.positionSourceTypeValid) {
            positionSourceType = position.positionSourceType;
        }

        var qualityIndex = 3;

        if (position.horizontalAccuracyValid) {
            for (var i = 0; i < qualities.length; i++) {
                if (position.horizontalAccuracy > qualities[i]) {
                    qualityIndex = i;
                    break;
                }
            }
        }

        qualityIconIndex = qualityIndex;

        if (debug) {
            console.log(logCategory,
                        "connectionType:", positionSourceManager.controller.connectionType,
                        "positionSourceType:", positionSourceType,
                        "qualities:", JSON.stringify(qualities),
                        "qualityIconIndex:", qualityIconIndex);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    IconImage {
        anchors {
            fill: parent
            margins: button.padding
        }

        visible: isConnected && !isWarmingUp && !hasError
        glyphSet: MapSymbols.icons
        icon {
            name: "satellite-3-f"
            color: control.color
        }
        opacity: 0.4
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: button

        anchors.fill: parent

        color: control.color
        glyphSet: MapSymbols.icons
        icon {
            name: hasError
                  ? errorIcon
                  : isConnecting
                    ? linkIcon
                    : isWarmingUp
                      ? "satellite-%1".arg(positionSourceManager.positionCount % 4)
                      : isConnected
                        ? qualityIcon
                        : ""
        }

        padding: 7 * AppFramework.displayScaleFactor
        opacity: (isConnecting || hasError) ? 0.5 : 1

        onClicked: {
            forceActiveFocus();
            Qt.inputMethod.hide();

            if (gnssStatusPages) {
                gnssStatusPages.showGNSSStatus(xform.popoverStackView, xform);
            }
        }

        onPressAndHold: {
            debug = !debug;
        }

        PulseAnimation {
            target: button
            running: positionSourceManager.logger.isRecording && !positionSourceManager.logger.isPaused
        }
    }

    //--------------------------------------------------------------------------

    Text {
        anchors.fill: parent

        visible: hasError
        text: "!"
        color: xform.style.titleBackgroundColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        style: Text.Outline
        styleColor: color

        font {
            pixelSize: height * 0.7
            bold: true
        }

        Text {
            anchors.fill: parent

            text: parent.text
            color: control.color
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font {
                pixelSize: parent.font.pixelSize
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: 200
        repeat: true
        running: control.visible && isConnecting

        onTriggered: {
            var index = linkIconIndex + linkStep;
            if (index < 0) {
                index = 1;
                linkStep = 1;
            } else if (index > 3) {
                index = 2;
                linkStep = -1;
            }
            linkIconIndex = index;
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        function onNewPosition() {
            control.position = position;
        }
    }

    //--------------------------------------------------------------------------
}
