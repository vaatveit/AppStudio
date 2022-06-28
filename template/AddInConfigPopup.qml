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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"

PageLayoutPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    property AddIn addIn

    //--------------------------------------------------------------------------

    signal updateConfig()

    //--------------------------------------------------------------------------

    title: addIn.title
    width: 250 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    onOpened: {
        console.log(logCategory, "opened");

        addIn.config.log();
    }

    //--------------------------------------------------------------------------

    onAboutToHide: {
        console.log(logCategory, "aboutToHide");

        updateConfig()

        addIn.config.write();
        addIn.config.log();
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(addIn.dataFolder.url);
//        Qt.openUrlExternally(AppFramework.resolvedPathUrl(addIn.config.settings.path));
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    AppSwitch {
        Layout.fillWidth: true
        
        text: qsTr("Enabled")
        font: popup.font
        checked: addIn.config.enabled

        onCheckedChanged: {
            addIn.config.enabled = checked;
        }
    }

    //--------------------------------------------------------------------------
}
