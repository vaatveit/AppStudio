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
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

XFormInfoView {
    id: coordinateInfo

    //--------------------------------------------------------------------------

    property var position: ({})
    property bool showAgeTimer: true

    property int llFormatIndex: 0
    property string llFormat: kLatLonFormats[llFormatIndex]
    property string latitude
    property string longitude
    property string altitude
    property int prjFormatIndex: 0
    property string prjText
    readonly property string prjLabel: kPrjFormats[prjFormatIndex].label

    property double positionTimestamp
    property double timeOffset: 0
    property real ageSeconds: Number.NaN
    property string ageText

    property var locale: xform.localeProperties.numberLocale

    //--------------------------------------------------------------------------

    readonly property var kLatLonFormats: ["dms", "ddm", "dd"]

    readonly property var kPrjFormats: [
        {
            label: qsTr("USNG"),
            format: XFormJS.formatUsngCoordinate,
        },
        {
            label: qsTr("MGRS"),
            format: XFormJS.formatMgrsCoordinate,
        },
        {
            label: qsTr("UTM/UPS"),
            format: XFormJS.formatUniversalCoordinate,
        },
    ]

    //--------------------------------------------------------------------------

    readonly property var kProperties: [

        {
            name: "ageText",
            label: qsTr("Time since last update"),
            source: coordinateInfo,
        },

        {
            name: "latitude",
            label: qsTr("Latitude"),
            llFormat: true
        },

        {
            name: "longitude",
            label: qsTr("Longitude"),
            llFormat: true
        },

        {
            name: "altitude",
            label: qsTr("Altitude"),
        },

        null,

        {
            name: "prjText",
            label: prjLabel,
            prjFormat: true
        },
    ]

    //--------------------------------------------------------------------------

    model: kProperties

    //--------------------------------------------------------------------------

    onAgeSecondsChanged: {
        if (isFinite(ageSeconds)) {
            ageText = qsTr("%1 s").arg(ageSeconds.toFixed(1));
        } else {
            ageText = "";
        }
    }

    onPositionChanged: {
        update();
    }

    onLlFormatChanged: {
        update();
    }

    onPrjFormatIndexChanged: {
        update();
    }

    function update() {
        if (!position) {
            return;
        }

        var coordinate = position.coordinate;

        if (!coordinate || !coordinate.isValid) {
            return;
        }

        latitude = XFormJS.formatLatitude(coordinate.latitude, llFormat);
        longitude = XFormJS.formatLongitude(coordinate.longitude, llFormat);
        altitude = XFormJS.toLocaleLengthString(coordinate.altitude, locale, 2);
        prjText = kPrjFormats[prjFormatIndex].format(coordinate);

        // timeOffset corrects for system clock running fast (or late)
        ageSeconds = (positionTimestamp - position.timestamp.valueOf()) / 1000 - timeOffset;

        if (showAgeTimer) {
            ageTimer.restart();
        }
    }

    //--------------------------------------------------------------------------

    dataDelegate: XFormInfoDataText {
        label: modelData.label
        value: coordinateInfo[modelData.name]

        onLabelClicked: {
            if (modelData.llFormat) {
                llFormatIndex = (llFormatIndex + 1) % kLatLonFormats.length;
            } else if (modelData.prjFormat) {
                prjFormatIndex = (prjFormatIndex + 1) % kPrjFormats.length;
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: ageTimer

        triggeredOnStart: true
        interval: 100
        repeat: true

        onTriggered: {
            ageSeconds += 0.1;
        }
    }

    //--------------------------------------------------------------------------
}
