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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0

import "../Controls"
import "../Controls/Singletons"
import "Singletons"

SwipeTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Debug")
    icon.name: "debug"
    glyphSet: MapSymbols.icons

    //--------------------------------------------------------------------------

    property XFormPositionSourceManager positionSourceManager
    readonly property XFormNmeaLogger nmeaLogger: positionSourceManager.logger
    readonly property NmeaSource nmeaSource: positionSourceManager.nmeaSource

    //--------------------------------------------------------------------------

    property bool isPaused: nmeaLogger ? nmeaLogger.isPaused : false
    property bool isRecording: nmeaLogger ? nmeaLogger.isRecording : false

    property color textColor: "black"

    property string fontFamily

    //--------------------------------------------------------------------------

    signal clear()

    //--------------------------------------------------------------------------

    onClear: {
        dataModel.clear();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: nmeaSource

        onReceivedNmeaData: {
            if (!isPaused) {
                var nmea = nmeaSource.receivedSentence.trim();

                dataModel.append({
                                     dataText: nmea,
                                     isValid: true
                                 });
            }

            if (dataModel.count > 100) {
                dataModel.remove(0);
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ListView {
            id: listView

            anchors.fill: parent
            anchors.margins: 5 * AppFramework.displayScaleFactor

            spacing: 3 * AppFramework.displayScaleFactor
            clip: true

            model: dataModel
            delegate: dataDelegate
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: dataModel

        onCountChanged: {
            if (count > 0) {
                listView.positionViewAtEnd();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dataDelegate

        Text {
            width: ListView.view.width

            text: dataText
            color: xform.style.textColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            font {
                pointSize: 12 * xform.style.textScaleFactor
                family: fontFamily
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.bottom
                }

                height: 1
                color: "#80808080"
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormButtonBarLayout {
        id: buttonBar

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            margins: 15 * AppFramework.displayScaleFactor
        }

        XFormImageButton {
            id: pauseButton

            icon.name: "pause-f"

            onClicked: {
                if (nmeaLogger) {
                    nmeaLogger.isPaused = !nmeaLogger.isPaused;
                } else {
                    isPaused = !isPaused;
                }

                buttonBar.fader.start();
            }

            PulseAnimation {
                target: pauseButton
                running: isPaused
            }
        }

        XFormImageButton {
            id: recordingButton

            // TODO: Replace with filled square icon name

            icon {
                name: isRecording
                    ? ""
                    : "circle-f"

                source: isRecording
                    ? Icons.bigIcon("square", true)
                    : ""
            }

            visible: nmeaLogger ? nmeaLogger.allowLogging : false
            color: xform.style.recordingColor

            onClicked: {
                if (nmeaLogger) {
                    nmeaLogger.isRecording = !nmeaLogger.isRecording;
                } else {
                    isRecording = !isRecording;
                }

                buttonBar.fader.start();
            }

            PulseAnimation {
                target: recordingButton
                running: isRecording && !isPaused
            }
        }

        XFormImageButton {
            icon.name: "x-circle-f"

            onClicked: {
                clear();

                buttonBar.fader.start();
            }
        }
    }

    //--------------------------------------------------------------------------
}

