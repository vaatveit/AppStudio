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
import ArcGIS.AppFramework.Speech 1.0
import ArcGIS.AppFramework.Notifications 1.0

import "../Controls"
import "../Controls/Singletons"

Item {
    id: alerts

    //--------------------------------------------------------------------------

    enum AlertType {
        Connected = 1,
        Disconnected = 2,
        NoData = 3,
        NoPosition = 4,
        RecordingStarted = 5,
        RecordingStopped = 6,
        FileIOError = 7
    }

    //--------------------------------------------------------------------------

    property color infoTextColor: "white"
    property color infoBackgroundColor: "#4793ff"

    property color warningTextColor: "#333333"
    property color warningBackgroundColor: "#ffc87a"

    property color errorTextColor: "white"
    property color errorBackgroundColor: "#a80000"

    readonly property url kIconInformation: Icons.icon("information")
    readonly property url kIconWarning: Icons.icon("exclamation-mark-triangle")
    readonly property url kIconError: Icons.icon("exclamation-mark-circle")
    readonly property url kIconSatellite: Icons.bigIcon("satellite-3")

    property AppAlertPopup popup: null

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(alerts, true)
    }

    //--------------------------------------------------------------------------

    readonly property var kPositionAlertInfos: [
        {
            type: AppAlert.AlertType.Connected,
            icon: kIconInformation,
            sayMessage: qsTr("The location sensor is connected"),
            displayMessage: qsTr("Location sensor connected"),
            textColor: infoTextColor,
            backgroundColor: infoBackgroundColor,
            priority: true,
        },

        {
            type: AppAlert.AlertType.Disconnected,
            icon: kIconError,
            sayMessage: qsTr("The location sensor is disconnected"),
            displayMessage: qsTr("Location sensor disconnected"),
            textColor: errorTextColor,
            backgroundColor: errorBackgroundColor,
            priority: true,
        },

        {
            type: AppAlert.AlertType.NoData,
            icon: kIconWarning,
            sayMessage: qsTr("No data is being received from the location sensor"),
            displayMessage: qsTr("No data received"),
            textColor: warningTextColor,
            backgroundColor: warningBackgroundColor,
            priority: false,
        },

        {
            type: AppAlert.AlertType.NoPosition,
            icon: kIconWarning,
            sayMessage: qsTr("No positions are being received from the location sensor"),
            displayMessage: qsTr("No position received"),
            textColor: warningTextColor,
            backgroundColor: warningBackgroundColor,
            priority: false,
        },

        {
            type: AppAlert.AlertType.RecordingStarted,
            icon: kIconInformation,
            sayMessage: qsTr("Recording started"),
            displayMessage: qsTr("Recording started"),
            textColor: infoTextColor,
            backgroundColor: infoBackgroundColor,
            priority: true,
        },

        {
            type: AppAlert.AlertType.RecordingStopped,
            icon: kIconInformation,
            sayMessage: qsTr("Recording stopped"),
            displayMessage: qsTr("Recording stopped"),
            textColor: infoTextColor,
            backgroundColor: infoBackgroundColor,
            priority: true,
        },

        {
            type: AppAlert.AlertType.FileIOError,
            icon: kIconError,
            sayMessage: qsTr("Log file could not be opened"),
            displayMessage: qsTr("Unable to open log file"),
            textColor: errorTextColor,
            backgroundColor: errorBackgroundColor,
            priority: true,
        },
    ]

    //--------------------------------------------------------------------------

    function positionSourceAlert(alertType) {
        console.log(logCategory, arguments.callee.name, "alertType:", alertType);

        var alertInfo;

        for (var i = 0; i < kPositionAlertInfos.length; i++) {
            if (kPositionAlertInfos[i].type === alertType) {
                alertInfo = kPositionAlertInfos[i];
                break;
            }
        }

        var sayMessage;
        var icon;
        var displayMessage;
        var textColor;
        var backgroundColor;
        var priority;

        if (alertInfo) {
            icon = alertInfo.icon;
            sayMessage = alertInfo.sayMessage;
            displayMessage = alertInfo.displayMessage;
            textColor = alertInfo.textColor;
            backgroundColor = alertInfo.backgroundColor;
            priority = alertInfo.priority;
        } else {
            icon = kIconSatellite;
            sayMessage = qsTr("Position source alert %1").arg(alertType);
            displayMessage = qsTr("Position source alert %1").arg(alertType);
            textColor = warningTextColor;
            backgroundColor = warningBackgroundColor;
            priority = false;
        }

        if (app.appSettings.locationAlertsVibrate) {
            Vibration.vibrate();
        }

        if (app.appSettings.locationAlertsSpeech) {
            say(sayMessage, priority);
        }

        if (app.appSettings.locationAlertsVisual) {
            show(displayMessage, icon, textColor, backgroundColor, undefined, priority);
        }
    }

    //--------------------------------------------------------------------------

    function say(message, priority) {
        if (tts.state !== TextToSpeech.Ready && !priority) {
            return;
        }

        if (tts.state === TextToSpeech.Speaking) {
            tts.stop();
        }

        tts.say(message);
    }

    //--------------------------------------------------------------------------

    function show(message, icon, textColor, backgroundColor, duration, priority) {
        if (popup) {
            if (priority) {
                popup.close();
            } else {
                return;
            }
        }

        popup = alertPopup.createObject(parent,
                                        {
                                            icon: icon > "" ? icon: "",
                                            text: message,
                                            duration: duration > 0 ? duration : 3000,
                                            textColor: textColor,
                                            backgroundColor: backgroundColor
                                        });

        popup.open();
    }

    //--------------------------------------------------------------------------

    TextToSpeech {
        id: tts
    }

    //--------------------------------------------------------------------------

    Component {
        id: alertPopup

        AppAlertPopup {
            localeProperties: app.localeProperties

            onAboutToHide: {
                if (tts.state === TextToSpeech.Speaking) {
                    tts.stop();
                }
            }

            onClosed: {
                popup = null;
            }
        }
    }

    //--------------------------------------------------------------------------
}
