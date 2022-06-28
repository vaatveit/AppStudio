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
import ArcGIS.AppFramework.Positioning 1.0

import "../Controls"
import "../Controls/Singletons"
import "../XForms/GNSS"

import "XForm.js" as XFormJS

SwipeTab {
    id: gnssData

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

    readonly property var kReceiver: [
        {
            name: "deviceName",
            label: qsTr("Source"),
            source: this,
        },

        {
            name: "fixType",
            label: qsTr("Mode"),
            valueTransformer: gpsModeText,
        },

        null,
    ]

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
            name: "accuracyType",
            label: qsTr("Accuracy mode"),
            valueTransformer: accuracyText,
        },

        {
            name: "positionSourceInfo",
            property: "confidenceLevelType",
            label: qsTr("Confidence Level"),
            valueTransformer: confidenceLevelText,
        },

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

        {
            name: "positionAccuracy",
            label: qsTr("Position accuracy"),
            valueTransformer: linearValue,
        },

        null,

        {
            name: "latitudeError",
            label: qsTr("Latitude error"),
            valueTransformer: linearValue,
        },

        {
            name: "longitudeError",
            label: qsTr("Longitude error"),
            valueTransformer: linearValue,
        },

        {
            name: "altitudeError",
            label: qsTr("Altitude error"),
            valueTransformer: linearValue,
        },

        null,

        {
            name: "hdop",
            label: qsTr("HDOP"),
        },

        {
            name: "vdop",
            label: qsTr("VDOP"),
        },

        {
            name: "pdop",
            label: qsTr("PDOP"),
        },

        null,

        {
            name: "positionSourceInfo",
            property: "altitudeType",
            label: qsTr("Altitude reference"),
            valueTransformer: altitudeText,
        },

        {
            name: "geoidSeparation",
            label: qsTr("Geoid separation"),
            valueTransformer: linearValue,
        },

        {
            name: "positionSourceInfo",
            property: "geoidSeparationCustom",
            label: qsTr("Custom geoid separation"),
            valueTransformer: linearValue,
        },

        {
            name: "positionSourceInfo",
            property: "antennaHeight",
            label: qsTr("Antenna Height"),
            valueTransformer: linearValue,
        },

        null,

        {
            name: "differentialAge",
            label: qsTr("Differential age"),
            valueTransformer: secondsValue,
        },

        {
            name: "referenceStationId",
            label: qsTr("Reference station ID"),
        },
    ]

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: gnssData.positionSourceManager
        emitNewPositionIfNoFix: true
        stayActiveOnError: true
        listener: "XFormGNSSData"

        onNewPosition: {
            gnssData.position = position;
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ScrollView {
            id: container

            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: container.width

                spacing: 10 * AppFramework.displayScaleFactor

                XFormInfoView {
                    Layout.fillWidth: true

                    model: kReceiver

                    dataDelegate: receiverText
                }

                XFormInfoCoordinatesText {
                    Layout.fillWidth: true

                    positionTimestamp: gnssData.positionTimestamp
                    timeOffset: gnssData.timeOffset
                    position: gnssData.position
                    locale: gnssData.locale
                }

                XFormInfoView {
                    Layout.fillWidth: true

                    model: kProperties

                    dataDelegate: propertiesText
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: receiverText

        XFormInfoDataText {
            label: kReceiver[modelIndex].label
            value: dataValue(kReceiver[modelIndex]);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: propertiesText

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

        if (value && propertyInfo.property) {
            value = value[propertyInfo.property];
        }

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

    function secondsValue(seconds) {
        return qsTr("%1 s").arg(Math.round(seconds));
    }

    //--------------------------------------------------------------------------

    function gpsModeText(fixType) {
        switch (fixType) {
        case Position.NoFix:
            return qsTr("No Fix");

        case Position.GPS:
            return qsTr("GPS");

        case Position.DifferentialGPS:
            return qsTr("Differential GPS");

        case Position.PrecisePositioningService:
            return qsTr("Precise Positioning Service");

        case Position.RTKFixed:
            return qsTr("RTK Fixed");

        case Position.RTKFloat:
            return qsTr("RTK Float");

        case Position.Estimated:
            return qsTr("Estimated");

        case Position.Manual:
            return qsTr("Manual");

        case Position.Simulator:
            return qsTr("Simulator");

        case Position.Sbas:
            return qsTr("SBAS");

        default:
            return fixType;
        }
    }

    //--------------------------------------------------------------------------

    function accuracyText(accuracyType) {
        switch (accuracyType) {
        case Position.RMS:
            return qsTr("Error RMS");

        case Position.DOP:
            return qsTr("DOP Based");

        default:
            return accuracyType;
        }
    }

    //--------------------------------------------------------------------------

    function confidenceLevelText(confidenceLevelType) {
        switch (confidenceLevelType) {
        case 0:
            return qsTr("68%");

        case 1:
            return qsTr("95%");

        default:
            return confidenceLevelType;
        }
    }

    //--------------------------------------------------------------------------

    function altitudeText(altitudeType) {
        switch (altitudeType) {
        case 0:
            return qsTr("Mean sea level");

        case 1:
            return qsTr("Ellipsoid");

        default:
            return altitudeType;
        }
    }

    //--------------------------------------------------------------------------
}
