/* Copyright 2019 Esri
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

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

PageLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property Portal portal

    //--------------------------------------------------------------------------

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    spacing: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    PortalUserView {
        Layout.fillWidth: true

        portal: popup.portal
        palette: popup.palette
    }

    //--------------------------------------------------------------------------

    HorizontalSeparator {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: localeProperties.layoutDirection

        Item {
            Layout.fillWidth: true
        }

        AppButton {
            text: qsTr("Sign out")
            textPointSize: 15

            iconSource: Icons.bigIcon("sign-out")

            onClicked: {
                portal.signOut();
                popup.close();
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------
}
