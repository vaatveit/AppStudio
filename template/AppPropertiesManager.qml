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

import ArcGIS.AppFramework 1.0

import "../Portal"

PropertiesManager {
    //--------------------------------------------------------------------------

    property App app
    property Portal portal

    //--------------------------------------------------------------------------

    readonly property string basemapsGroupQuery: value(kPropertyBasemapsGroupQuery) || ""
    readonly property string defaultBasemap: value(kPropertyDefaultBasemap) || ""

    readonly property bool usePortalTheme: value(kPropertyUsePortalTheme)

    //--------------------------------------------------------------------------

    readonly property string kPropertyBasemapsGroupQuery: "basemapsGroupQuery"
    readonly property string kPropertyDefaultBasemap: "defaultBasemap"

    readonly property string kPropertyUsePortalTheme: "usePortalTheme"

    //--------------------------------------------------------------------------

    orgProperties: portal.propertiesResource

    //--------------------------------------------------------------------------

    onInitialize: {
        properties.defaultBasemap = appInfoProperty(kPropertyDefaultBasemap);
    }

    //--------------------------------------------------------------------------

    onUpdated: {
        console.log(logCategory, "Properties updated -");
        console.log(logCategory, " - defaultBasemap:", defaultBasemap);
    }

    //--------------------------------------------------------------------------

    function appInfoProperty(name, defaultValue) {
        var value = app.info.propertyValue(name, defaultValue);

        return value > "" ? value : undefined;
    }

    //--------------------------------------------------------------------------
}
