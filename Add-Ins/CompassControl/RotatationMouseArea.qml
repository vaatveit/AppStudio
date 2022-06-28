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

MouseArea {

    //--------------------------------------------------------------------------

    property var startRotation
    property real startAngle

    //--------------------------------------------------------------------------

    signal started(real angle)
    signal updated(real angle)
    signal finished(real angle)

    //--------------------------------------------------------------------------

    hoverEnabled: enabled
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    
    //--------------------------------------------------------------------------

    onPressed: {
        startRotation = Qt.point(mouse.y, mouse.y);
        startAngle = angleTo(x + width / 2, y + height / 2, mouse.x, mouse.y);

        started(startAngle);

        mouse.accepted = true;
    }
    
    //--------------------------------------------------------------------------

    onPositionChanged: {
        if (startRotation) {
            updateRotation(mouse);
        }
    }
    
    //--------------------------------------------------------------------------

    onReleased: {
        if (startRotation) {
            startRotation = undefined;
            finished(updateRotation(mouse));
        }
    }
    
    //--------------------------------------------------------------------------

    function angleTo(x1, y1, x2, y2) {
        var angle = Math.atan2(y1 - y2, x1 - x2) / Math.PI * 180.0 - 90;
        return (angle + 360.0) % 360.0;
    }
    
    //--------------------------------------------------------------------------

    function updateRotation(mouse) {
        var angle = angleTo(x + width / 2, y + height / 2, mouse.x, mouse.y);
        var dAngle = Math.round(startAngle - angle + 360.0) % 360;

        updated(dAngle);

        return dAngle;
    }

    //--------------------------------------------------------------------------
}
