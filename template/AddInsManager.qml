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
    id: manager

    //--------------------------------------------------------------------------

    property alias addInsFolder: addInsFolder
    property alias servicesManager: servicesManager
    property alias services: servicesManager.services
    property bool enableInstalledAddIns

    //--------------------------------------------------------------------------

    signal started()

    //--------------------------------------------------------------------------

    onStarted: {
        console.log(logCategory, "Started");
    }

    //--------------------------------------------------------------------------

    function initialize() {
        
        var importPath = app.folder.filePath("Extensibility");
        
        console.log(logCategory, "Initializing add-ins importPath:", importPath);
        
        AppFramework.addImportPath(importPath);
        
        frameworkInitializer.active = true;

        servicesManager.enabled = true;
        servicesManager.initialize();
    }

    //--------------------------------------------------------------------------

    function start() {
        console.log(logCategory, "application.arguments:", JSON.stringify(Qt.application.arguments));
        
        var autoStartAddIn;
        
        for (var i = 1; i < Qt.application.arguments.length; i++) {
            var arg = Qt.application.arguments[i];
            
            switch (arg) {
            case "--addin":
                autoStartAddIn = Qt.application.arguments[++i];
                break;
            }
        }

        addInsFolder.update();

        started();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(manager, true)
    }

    //--------------------------------------------------------------------------

    Loader {
        id: frameworkInitializer

        active: false
        source: "AddInFrameworkInitializer.qml"

        onLoaded: {
            item.initialize(app);
            active = false;
            start();
        }
    }

    //--------------------------------------------------------------------------

    AddInsFolder {
        id: addInsFolder

        enabled: enableInstalledAddIns
        path: "~/ArcGIS/My Survey Add-Ins"
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInPage

        AddInPage {
            portal: app.portal
        }
    }

    //--------------------------------------------------------------------------

    function startAddIn(path) {
        console.log(logCategory, "Starting addIn:", path);

        mainStackView.push(addInPage,
                           {
                               addInPath: path
                           });
    }

    //--------------------------------------------------------------------------

    AddInServicesManager {
        id: servicesManager

        addInsFolder: addInsFolder
    }

    //--------------------------------------------------------------------------
}
