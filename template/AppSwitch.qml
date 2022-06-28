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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

Switch {
    id: control

    //--------------------------------------------------------------------------

    implicitHeight: Math.max(25 * AppFramework.displayScaleFactor, textControl.paintedHeight + 6 * AppFramework.displayScaleFactor)
    spacing: 10 * AppFramework.displayScaleFactor

    //locale: ControlsSingleton.localeProperties.locale

    palette {
        text: app.textColor
        dark: app.textColor
    }

    font {
        family: app.fontFamily
        pointSize: 12
        bold: app.appSettings.boldText
    }


    //--------------------------------------------------------------------------

    contentItem: Text {
        id: textControl

        opacity: control.enabled ? 1.0 : 0.3
        color: control.down
               ? control.palette.text
               : Qt.darker(control.palette.text, 2)

        text: control.text
        font: control.font

        verticalAlignment: Text.AlignVCenter

        leftPadding: control.spacing + (ControlsSingleton.localeProperties.isLeftToRight
                                        ? control.indicator.width
                                        : 0)
        rightPadding: control.spacing + (ControlsSingleton.localeProperties.isRightToLeft
                                         ? control.indicator.width
                                         : 0)

        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        onLinkActivated: {
            Qt.openUrlExternally(link);
        }
    }

    //--------------------------------------------------------------------------

}
