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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls"
import "../../Controls/Singletons"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias basicBasemaps: basicCheckBox.checked
    property alias sharedBasemaps: sharedCheckBox.checked

    //--------------------------------------------------------------------------

    signal accepted()

    //--------------------------------------------------------------------------

    width: Math.min(parent.width * 0.95, 250 * AppFramework.displayScaleFactor)

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: availableWidth
        spacing: 10 * AppFramework.displayScaleFactor

        XFormText {
            Layout.fillWidth: true

            text: qsTr("Basemaps")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            font {
                pointSize: 16
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        XFormCheckBox {
            id: basicCheckBox

            Layout.fillWidth: true

            text: qsTr("Basic")
        }

        XFormCheckBox {
            id: sharedCheckBox

            Layout.fillWidth: true

            text: qsTr("Organization")
        }

        RoleButton {
            Layout.alignment: Qt.AlignHCenter

            buttonRole: DialogButtonBox.ApplyRole

            onClicked: {
                accepted();
                close();
            }
        }
    }

    //--------------------------------------------------------------------------
}
