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

Item {
    //--------------------------------------------------------------------------

    property alias model: model
    property int defaultMaxAge: 10

    property string serviceType: "locationSensor"
    property string keyHostname: "LOCATION-SENSOR-HOSTNAME.ARCGIS.COM"
    property string keyPort: "LOCATION-SENSOR-PORT.ARCGIS.COM"

    //--------------------------------------------------------------------------

    function start() {
        listener.start();
    }

    //--------------------------------------------------------------------------

    function stop() {
        listener.stop();
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: model
        
        dynamicRoles: true
        
        function add(syslog) {
            var index = -1;
            for (var i = 0; i < count; i++) {
                if (get(i).address === syslog.address) {
                    index = i;
                    break;
                }
            }
            
            syslog.timestamp = new Date();

            if (index >= 0) {
                set(i, syslog);
            } else {
                append(syslog);
            }
        }

        function checkExpired() {
            var now = new Date();

            for (var i = count - 1; i >= 0; i--) {
                var syslog = get(i);

                if (!syslog.timestamp) {
                    continue;
                }

                var age = (now - syslog.timestamp) / 1000;
                if (age > syslog.maxAge) {
                    remove(i);
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    SSDPListener {
        id: listener

        onMessageReceived: {
            if (message.type !== "NOTIFY") {
                return;
            }

            if (!message.NT) {
                return;
            }

            var tokens = message.NT.match(/urn:([a-zA-Z0-9-\.]+):service:([a-zA-Z\.]+):([a-zA-Z0-9]*)/);
            if (!tokens) {
                return;
            }

            if (tokens[2].toLowerCase() !== serviceType.toLowerCase() ) {
                return;
            }

            message.address = address;
            message.port = message[keyPort];
            if (!message.port) {
                message.port = 2947;
            }
            message.hostname = message[keyHostname];
            if (!(message.hostname > "")) {
                message.hostname = message.address;
            }

            message.product = "";
            message.productVersion = ""

            if (message.SERVER > "") {
                var parts = message.SERVER.split(",");
                if (parts.length >= 3) {
                    var productParts = parts[2].split('/');
                    message.product = productParts[0].trim();
                    if (productParts.length > 1) {
                        message.productVersion = productParts[1].trim();
                    }
                }
            }

            message.productName = message.productVersion > ""
                    ? "%1 (%2)".arg(message.product).arg(message.productVersion)
                    : message.productName;

            message.displayName = "%1 %2:%3".arg(message.productName).arg(message.hostname).arg(message.port);

            var cacheControl = message["CACHE-CONTROL"];
            if (cacheControl) {
                tokens = cacheControl.match(/max-age=(\d+)\D*/);
                if (tokens) {
                    message.maxAge = Number(tokens[1]);
                }
            }

            if (!message.maxAge) {
                message.maxAge = defaultMaxAge;
            }

            model.add(message);
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: 5000
        repeat: true
        running: listener.active

        onTriggered: {
            model.checkExpired();
        }
    }

    //--------------------------------------------------------------------------
}
