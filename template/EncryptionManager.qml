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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"
import "../XForms"
import "../XForms/XForm.js" as XFormJS

Item {
    id: manager

    //--------------------------------------------------------------------------

    property Portal portal
    property AppPropertiesManager propertiesManager
    property XFormsDatabase surveysDatabase
    property XFormSqlDatabase database: surveysDatabase.database
    readonly property bool isDatabase: surveysDatabase.isDatabase

    readonly property SecureSettings secureSettings: portal.secureSettings
    readonly property bool signedIn: portal.signedIn
    readonly property bool requireEncryption: enabled && propertiesManager.value("requireEncryption", false);

    property bool encryptionEnabled: encryptionKey  > ""
    property string encryptionKey: secureSettings.value(kSettingEncryptionKey, "")
    property string encryptionKeyType: "hex"

    property bool debug: true

    //--------------------------------------------------------------------------

    readonly property color kColorWarning: "#a80000"

    readonly property string kSettingEncryptionKey: "Encryption/key"

    //--------------------------------------------------------------------------

    signal failed(string action, string message)

    //--------------------------------------------------------------------------

    onRequireEncryptionChanged: {
        Qt.callLater(checkEncryption);
    }

    onIsDatabaseChanged: {
        if (isDatabase) {
            Qt.callLater(checkEncryption);
        }
    }

    onEncryptionEnabledChanged: {
        console.log("encryptionEnabled:", encryptionEnabled);
    }

    onEncryptionKeyChanged: {
        if (debug) {
            console.log("encryptionKey:", encryptionKey);
        }
    }

    //--------------------------------------------------------------------------

    onFailed: {
        console.error(logCategory, "Error action:", action, "message:", message);
    }

    //--------------------------------------------------------------------------

    function checkEncryption() {

        console.log(logCategory, arguments.callee.name, "requireEncryption:", requireEncryption);

        if (!requireEncryption) {
            return;
        }

        // TODO check if secure storage is supported

        console.log(logCategory, arguments.callee.name, "encryptionEnabled:", encryptionEnabled);

        if (encryptionEnabled) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "isDatabase:", isDatabase);
        if (!isDatabase) {
            return;
        }

        encryptPopup.createObject(manager.parent).open();
    }

    //--------------------------------------------------------------------------

    function enableEncryption() {
        console.log(logCategory, arguments.callee.name);

        var key = encryptionKey.trim();

        if (!key) {
            console.log(logCategory, arguments.callee.name, "Creating encyrption key");
            key = AppFramework.createUuidString(2);
        }

        surveysDatabase.close();

        database.open();

        var sqlPragma = "PRAGMA %1rekey".arg(encryptionKeyType);
        var query = database.executeSql("%1='%2'".arg(sqlPragma).arg(key));
        if (!!query && query.error) {
            failed(sqlPragma, query.error.toString());
            return;
        }

        console.log(logCategory, arguments.callee.name, sqlPragma, "completed");

        query = database.executeSql("VACUUM");

        if (!!query && query.error) {
            failed("VACUUM", query.error.toString());
            return;
        }

        console.log(logCategory, arguments.callee.name, "VACUUM completed");

        database.close();

        encryptionKey = key;

        secureSettings.setValue(kSettingEncryptionKey, encryptionKey);

        surveysDatabase.open();

        console.log(logCategory, arguments.callee.name, "encryption completed");
    }

    //--------------------------------------------------------------------------

    function showDisablePopup(owner) {
        decryptPopup.createObject(owner).open();
    }

    //--------------------------------------------------------------------------

    function disableEncryption() {
        console.log(logCategory, arguments.callee.name);

        if (!encryptionEnabled) {
            return;
        }

        var sqlPragma = "PRAGMA %1rekey".arg(encryptionKeyType);
        var query = database.executeSql("%1=''".arg(sqlPragma));
        if (!!query && query.error) {
            failed(sqlPragma, query.error.toString());
            return;
        }

        console.log(logCategory, arguments.callee.name, sqlPragma, "completed");

        query = database.executeSql("VACUUM");
        if (!!query && query.error) {
            failed("VACUUM", query.error.toString());
            return;
        }

        console.log(logCategory, arguments.callee.name, "VACUUM completed");

        surveysDatabase.close();

        encryptionKey = "";

        secureSettings.remove(kSettingEncryptionKey);

        surveysDatabase.open();

        console.log(logCategory, arguments.callee.name, "encryption removed");
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(manager, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: encryptPopup

        ActionsPopup {
            title: qsTr("Encryption Required")
            text: qsTr("You are signed in to an organization that requires encryption to be enabled.")

            icon {
                name: "exclamation-mark-triangle"
                color: kColorWarning
            }

            onTitlePressAndHold: {
                Qt.openUrlExternally(surveysDatabase.folder.url);
            }

            Action {
                text: qsTr("Enable encryption")
                icon {
                    name: "lock"
                    color: kColorWarning
                }

                onTriggered: {
                    enableEncryption();
                    close();
                }
            }

            Action {
                text: qsTr("Sign out without enabling encryption")
                icon.name: "sign-out"

                onTriggered: {
                    portal.signOut();
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: decryptPopup

        ActionsPopup {
            title: qsTr("Disable Encryption")
            prompt: qsTr("What would you like to do?")

            icon {
                source: Icons.icon("exclamation-mark-triangle")
                color: kColorWarning
            }

            onTitlePressAndHold: {
                Qt.openUrlExternally(surveysDatabase.folder.url);
            }

            Action {
                text: qsTr("Disable encryption")
                icon {
                    name: "unlock"
                    color: kColorWarning
                }

                onTriggered: {
                    portal.signOut();
                    disableEncryption();
                    close();
                }
            }

            Action {
                text: qsTr("Cancel")
                icon.name: "x-circle"

                onTriggered: {
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}

