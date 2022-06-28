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

import QtQuick 2.5

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

Item {
    //--------------------------------------------------------------------------

    property string address: "239.255.255.250"
    property int port: 1900
    readonly property bool active: socket.valid
    
    signal messageReceived(var message, string address, int port);

    //--------------------------------------------------------------------------

    function start() {
        if (socket.bind(address, port, UdpSocket.BindModeShareAddress | UdpSocket.BindModeReuseAddressHint)) {
            socket.joinMulticastGroup(address);
        }
    }

    //--------------------------------------------------------------------------

    function stop() {
        socket.close();
    }

    //--------------------------------------------------------------------------

    function parse(datagram) {
        var lines = datagram.split("\n");

        if (lines.length <= 0) {
            return "Empty message";
        }

        var header = lines.shift();
        var tokens = header.match(/([A-Z\-]+)\s\*\sHTTP\/1\.1/);
        if (!tokens) {
            return "Invalid header:" + header;
        }

        var message = {
            type: tokens[1]
        };

        lines.forEach(function (line) {
            var i = line.indexOf(":");
            if (i > 0) {
                var key = line.substr(0, i).trim().toUpperCase();
                var value = line.substr(i + 1).trim();

                if (key > "") {
                    message[key] = value;
                }
            }
        });

        return message;
    }

    //--------------------------------------------------------------------------

    UdpSocket {
        id: socket

        onDatagramReceived: {
            //console.log("SSDPListener datagram:", datagram, address, port);

            var message = parse(datagram);

            if (typeof message === "object") {
                message.address = address;
                message.port = port;

                //console.log("SSDPListener message:", JSON.stringify(message, undefined, 2));

                messageReceived(message, address, port);
            } else {
                console.warn("SSDPListener invalid message:", address, port, message);
            }
        }

        onStateChanged: {
            console.log("SSDPListener status:", state);
        }

        onErrorChanged: {
            console.log("SSDPListener error:", error, errorString);
        }
    }

    //--------------------------------------------------------------------------
}
