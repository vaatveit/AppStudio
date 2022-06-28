/* Copyright 2015 Esri
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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Controls"
import "../Controls/Singletons"
import "../template"

//------------------------------------------------------------------------------

FocusScope {
    id: inputArea

    property string pkiFile: ""
    property string pkiFileName: ""
    property alias passPhrase: passPhraseField.text
    property alias rememberMe: saveUserCheckBox.checked
    property bool hideCancel: false
    property string fontFamily

    property color signInButtonColor: "#0079c0" // "#e98d32"
    property color signInButtonBusyColor: "#84b9de"
    property color signInButtonHoverColor: "#015e95" // "#e36b00"

    property string certificateErrorText: ""

    property Settings settings: portal.settings

    signal rejected()

    visible: height > 20 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Networking.clearAccessCache();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn) {
                /*
                */
            }
        }

        onError: {
            console.log("PKISignInView.onError:", JSON.stringify(error, undefined, 2));
            portal.busy = false;
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "#efeeef"
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: columnLayout
            margins: -20 * AppFramework.displayScaleFactor
        }

        color: "#d9d8d9"
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: columnLayout

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 40 * AppFramework.displayScaleFactor
        }

        spacing: 5 * AppFramework.displayScaleFactor

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 10 * AppFramework.displayScaleFactor
        }

        Text {
            id: pkiFileText

            Layout.fillWidth: true

            text: qsTr( "Certificate (*.pfx, *.p12)" )
            horizontalAlignment: Text.AlignLeft
            font {
                pointSize: 16
                family: fontFamily
            }
        }

        RowLayout {
            id: pkiFileRowLayout
            Layout.fillWidth: true

            TextBox {
                id: pkiFileField

                Layout.fillWidth: true

                text: pkiFileName
                readOnly: true
                placeholderText: qsTr( "Select certificate" )
                font {
                    pointSize: 16
                    family: fontFamily
                }
                activeFocusOnTab: true
                focus: true
                inputMethodHints: Qt.ImhNoAutoUppercase + Qt.ImhNoPredictiveText + Qt.ImhSensitiveData
                textColor: "black"
                inputRequired: true
                _inputEmpty: length === 0

                leftIndicator: TextBoxButton {
                    icon.name: "folder-open"

                    onClicked: {
                        pkiDocumentDialog.open();
                    }
                }
            }
        }

        Text {
            id: passPhraseText

            Layout.fillWidth: true

            text: qsTr("Password")
            horizontalAlignment: Text.AlignLeft
            font {
                pointSize: 16
                family: fontFamily
            }
        }

        TextBox {
            id: passPhraseField

            Layout.fillWidth: true

            echoMode: TextInput.Password
            placeholderText: passPhraseText.text
            font {
                pointSize: 16
                family: fontFamily
            }
            activeFocusOnTab: true
            focus: true
            textColor: "black"
            inputRequired: true
            _inputEmpty: length === 0

            leftIndicator: TextBoxIcon {
                icon.name: "key"
            }

            onAccepted: {
                acceptButton.tryClick();
            }
        }

        Text {
            Layout.fillWidth: true

            text: certificateErrorText
            visible: certificateErrorText !== ""
            horizontalAlignment: Text.AlignLeft
            font {
                pointSize: 16
                family: fontFamily
            }
            color: "red"
        }

        Item {
            Layout.preferredHeight: 10 * AppFramework.displayScaleFactor
            Layout.fillWidth: true
        }

        AppSwitch {
            id: saveUserCheckBox

            Layout.fillWidth: true

            text: qsTr("Remember me")
            font {
                pointSize: 16
                family: fontFamily
            }
            visible: settings !== null

            onCheckedChanged: {
                certificateErrorText = "";

                if ( !checked ) {
                    pkiFile = pkiFile + "";
                    pkiFileName = pkiFileName + "";
                    passPhrase = passPhrase + "";
                    rememberMe = checked ? true : false;
                    portal.rememberMe = rememberMe;
                    portal.pkiFile = "";
                    portal.pkiFileName = "";
                    portal.passPhrase = "";
                    portal.writeUserSettings();
                }
            }
        }

        AppButton {
            id: acceptButton

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

            enabled: !busy && pkiFileName !== "" && passPhrase.trim() !== "" && portal.isOnline
            iconSource: Icons.bigIcon("sign-in")
            text: qsTr("Sign in")
            textPointSize: 15

            onClicked: {
                tryClick();
            }

            function tryClick() {
                if (!enabled) {
                    return;
                }

                certificateErrorText = "";

                let pkcs12 = Networking.importPkcs12( pkiFileBinary.data, passPhrase.trim() );
                if ( !pkcs12 ) {
                    certificateErrorText = qsTr( "Invalid certificate or password." );
                    return;
                }

                Networking.pkcs12 = pkcs12;

                portal.pkiAuthentication = true;
                portal.pkiFile = pkiFile;
                portal.pkiFileName = pkiFileName;
                portal.passPhrase = passPhrase;
                portal.rememberMe = rememberMe;
                portal.writeUserSettings();

                portal.builtInSignIn();
            }
        }
    }

    //--------------------------------------------------------------------------

    DocumentDialog {
        id: pkiDocumentDialog

        onAccepted: {
            certificateErrorText = "";
            passPhraseField.text = "";

            var fileInfo = AppFramework.fileInfo(fileUrl);

            pkiFile = fileInfo.folder.readFile(fileInfo.fileName, {
                                                   "encode": "base64"
                                               });

            pkiFileName = fileInfo.displayName;
        }
    }

    //--------------------------------------------------------------------------

    BinaryData {
        id: pkiFileBinary

        base64: pkiFile
    }

    //--------------------------------------------------------------------------

}
