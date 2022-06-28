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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls"
import "../Controls/Singletons"

SwipeTab {
    id: locationData

    //--------------------------------------------------------------------------

    title: qsTr("Data")
    icon.name: "feature-details"

    //--------------------------------------------------------------------------

    property XFormPositionSourceManager positionSourceManager

    property var position: ({})

    readonly property double positionTimestamp: positionSourceManager.positionTimestamp
    readonly property double timeOffset: positionSourceManager.timeOffset

    readonly property string deviceName: positionSourceManager.name

    property string fontFamily: xform.style.fontFamily
    property var locale: xform.localeProperties.numberLocale

    //--------------------------------------------------------------------------

    readonly property XFormNmeaLogger nmeaLogger: positionSourceManager.logger

    //readonly property bool isValidLocation: !!position && !!position.coordinate && position.coordinate.isValid

    readonly property bool isRecording: nmeaLogger ? nmeaLogger.isRecording : false
    readonly property bool isPaused: nmeaLogger ? nmeaLogger.isPaused : false

    //--------------------------------------------------------------------------

    readonly property var kProperties: [
        null,

        {
            name: "speed",
            label: qsTr("Speed"),
            valueTransformer: speedValue,
        },

        {
            name: "verticalSpeed",
            label: qsTr("Vertical speed"),
            valueTransformer: speedValue,
        },

        null,

        {
            name: "direction",
            label: qsTr("Direction"),
            valueTransformer: angleValue,
        },

        {
            name: "magneticVariation",
            label: qsTr("Magnetic variation"),
            valueTransformer: angleValue,
        },

        null,

        {
            name: "horizontalAccuracy",
            label: qsTr("Horizontal accuracy"),
            valueTransformer: linearValue,
        },

        {
            name: "verticalAccuracy",
            label: qsTr("Vertical accuracy"),
            valueTransformer: linearValue,
        },
    ]

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: locationData.positionSourceManager
        emitNewPositionIfNoFix: true
        stayActiveOnError: true
        listener: "XFormLocationData"

        onNewPosition: {
            locationData.position = position;
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 5 * AppFramework.displayScaleFactor

        ScrollView {
            id: container

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: container.width

                spacing: 10 * AppFramework.displayScaleFactor

                XFormInfoCoordinatesText {
                    Layout.fillWidth: true

                    positionTimestamp: locationData.positionTimestamp
                    timeOffset: locationData.timeOffset
                    position: locationData.position
                    locale: locationData.locale
                }

                XFormInfoView {
                    Layout.fillWidth: true

                    model: kProperties

                    dataDelegate: infoText
                }
            }
        }

        //------------------------------------------------------------------

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                id: pauseButton

                visible: isRecording
                source: Icons.bigIcon("pause", true)

                onClicked: {
                    nmeaLogger.isPaused = !nmeaLogger.isPaused;
                }

                PulseAnimation {
                    target: pauseButton
                    running: isPaused
                }
            }

            XFormImageButton {
                id: recordingButton

                source: isRecording
                        ? Icons.bigIcon("square", true)
                        : Icons.bigIcon("circle-filled")

                color: xform.style.recordingColor

                onClicked: {
                    if (nmeaLogger) {
                        nmeaLogger.isRecording = !nmeaLogger.isRecording;
                    }
                }

                PulseAnimation {
                    target: recordingButton
                    running: isRecording && !isPaused
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        XFormText {
            Layout.fillWidth: true

            visible: nmeaLogger.isRecording
            text: qsTr("Log file: %1").arg(nmeaLogger.isRecording
                                           ? AppFramework.fileInfo(nmeaLogger.nmeaLogFile.path).fileName
                                           : "")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    Qt.openUrlExternally(AppFramework.fileInfo(nmeaLogger.nmeaLogFile.path).folder.url);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: infoText

        XFormInfoDataText {
            label: kProperties[modelIndex].label
            value: dataValue(kProperties[modelIndex]);
        }
    }

    //--------------------------------------------------------------------------

    function dataValue(propertyInfo) {
        var source = propertyInfo.source;
        var valid = true;

        if (!source) {
            source = position;
            valid = source[propertyInfo.name + "Valid"];
        }

        var value = source[propertyInfo.name];

        if (!valid || value === undefined || value === null || (typeof value === "number" && !isFinite(value))) {
            return;
        }

        if (propertyInfo.valueTransformer) {
            return propertyInfo.valueTransformer(value);
        } else {
            return value;
        }
    }

    //--------------------------------------------------------------------------

    function linearValue(metres) {
        return XFormJS.toLocaleLengthString(metres, locale);
    }

    //--------------------------------------------------------------------------

    function speedValue(metresPerSecond) {
        return XFormJS.toLocaleSpeedString(metresPerSecond, locale);
    }

    //--------------------------------------------------------------------------

    function angleValue(degrees) {
        return "%1°".arg(degrees);
    }

    //--------------------------------------------------------------------------
}
