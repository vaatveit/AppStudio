/* Copyright 2018 Esri
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

.pragma library

.import ArcGIS.AppFramework 1.0 as AF

//--------------------------------------------------------------------------

function findAddIn(object) {
    var addIn = findParent(object, "Survey123.AddIn", "AddIn");
    if (!addIn) {
        logParents(object);
    }

    return addIn;
}

//--------------------------------------------------------------------------

function findParent(object, objectName, typeName) {
    if (!object) {
        console.error(arguments.callee.name, "object not specifed");
        return;
    }

    var p = object.parent;
    while (p) {
        if ((typeName && AF.AppFramework.typeOf(p, true) === typeName)
                || (objectName && p.objectName === objectName)) {
            return p;
        }

        p = p.parent;
    }

    console.warn(arguments.callee.name, "Parent not found for:", object, "objectName:", objectName, "typeName:", typeName);

    return null;
}

//--------------------------------------------------------------------------

function logParents(object) {
    console.log("Parents of:", object, "objectName:", object.objectName, "typeOf:", AF.AppFramework.typeOf(object, true), AF.AppFramework.typeOf(object));

    var p = object.parent;

    var indent = "";
    while (p) {
        console.log(indent, "+- parent:", p, "objectName:", p.objectName, "typeOf: %1 (%2)".arg(AF.AppFramework.typeOf(p, true)).arg(AF.AppFramework.typeOf(p)));

        p = p.parent;
        indent += "  ";
    }
}

//------------------------------------------------------------------------------
