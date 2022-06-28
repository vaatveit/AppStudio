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

import ArcGIS.AppFramework 1.0

QtObject {
    id: object

    property App app
    property Settings settings

    //--------------------------------------------------------------------------

    property int buildType: 0 // 0=Release, 1=Beta, 2=Alpha
    readonly property string buildTypeSuffix: kBuildTypeSuffix[buildType]

    property bool addIns: false
    property bool itemsetsDatabase: false
    property bool asyncFormLoader: false
    property bool enableCompass: false
    property bool enableSxS: false
    property bool enableGalleryFilter: false

    // ReferenceError: galleryFilter is not defined
    readonly property bool beta: addIns
                                 || itemsetsDatabase
                                 || asyncFormLoader
                                 || enableCompass
                                 || enableSxS
                                 // || galleryFilter

    //--------------------------------------------------------------------------

    readonly property var kBuildTypeSuffix: ["", "β", "α"]

    readonly property string kPrefix: "features"

    readonly property string kKeyAddIns: "addIns"
    readonly property string kKeyItemsetsDatabase: "itemsetsDatabase"
    readonly property string kKeyAsyncFormLoader: "asyncFormLoader"
    readonly property string kKeyEnableCompass: "enableCompass"
    readonly property string kKeyEnableSxS: "enableSxS"
    readonly property string kKeyEnableGalleryFilter: "enableGalleryFilter"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var title = app.info.title.toLowerCase();

        if (title.indexOf("beta") >= 0) {
            buildType = 1;
        } else if (title.indexOf("alpha") >= 0) {
            buildType = 2;
        }

        console.log(logCategory, "app buildType:", buildType, buildTypeSuffix);
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(object, true)
    }

    //--------------------------------------------------------------------------

    function featureKey(featureKey) {
        return "%1/%2".arg(kPrefix).arg(featureKey);
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log(logCategory, "Reading features configuration");

        addIns = settings.boolValue(featureKey(kKeyAddIns), false);
        itemsetsDatabase = settings.boolValue(featureKey(kKeyItemsetsDatabase), false);
        asyncFormLoader = settings.boolValue(featureKey(kKeyAsyncFormLoader), false);
        enableCompass = settings.boolValue(featureKey(kKeyEnableCompass), false);
        enableSxS = settings.boolValue(featureKey(kKeyEnableSxS), false);
        enableGalleryFilter = settings.boolValue(featureKey(kKeyEnableGalleryFilter), false);

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log(logCategory, "Writing features configuration");

        log();

        settings.setValue(featureKey(kKeyAddIns), addIns, false);
        settings.setValue(featureKey(kKeyItemsetsDatabase), itemsetsDatabase, false);
        settings.setValue(featureKey(kKeyAsyncFormLoader), asyncFormLoader, false);
        settings.setValue(featureKey(kKeyEnableCompass), enableCompass, false);
        settings.setValue(featureKey(kKeyEnableSxS), enableSxS, false);
        settings.setValue(featureKey(kKeyEnableGalleryFilter), enableGalleryFilter, false);
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "App features - beta:", beta);
        console.log(logCategory, "* Add-ins:", addIns);
        console.log(logCategory, "* Itemsets database:", itemsetsDatabase);
        console.log(logCategory, "* Async form loader:", asyncFormLoader);
        console.log(logCategory, "* Compass enabled:", enableCompass);
        console.log(logCategory, "* SxS enabled:", enableSxS);
        console.log(logCategory, "* Gallery filter enabled:", enableGalleryFilter);
    }

    //--------------------------------------------------------------------------
}

