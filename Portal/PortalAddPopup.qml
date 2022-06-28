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
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"
import "../template"

//------------------------------------------------------------------------------

PageLayoutPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    property Portal portal
    property PortalsList portalsList
    property bool showUseExternalUserAgent: true
    property bool showExtraInfo: false
    property bool checkIfExists: true

    property alias url: portalUrlField.text
    property bool autoAdd: false

    property url pkiPortalUrl
    property bool pkiAuthentication
    property string pkiFile
    property string pkiFileName
    property alias passPhrase: passPhraseField.text
    property bool networkAuthentication

    readonly property bool busy: portalInfoRequest.isBusy

    //--------------------------------------------------------------------------

    property alias errorLabelText: errorLabel.text
    property var sslErrors
    property alias sslErrorText: sslErrorLabel.text

    //--------------------------------------------------------------------------

    readonly property string kDefaultPortal: "https://"
    readonly property string kPortalHelpUrl: "https://links.esri.com/survey123/UseWithEnterprise"
    readonly property color kColorError: "#a80000"

    //--------------------------------------------------------------------------

    signal portalAdded(var portalInfo, int index)
    signal rejected()

    //--------------------------------------------------------------------------

    width: Math.min(parent.width * 0.85, 400 * AppFramework.displayScaleFactor)
    
    icon.name: "portal"
    title: qsTr("Add Connection")
    titleLabel.font.pointSize: 18

    font {
        pointSize: 14
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (url > "" && autoAdd) {
            Qt.callLater(addPortalButton.tryClick);
        }
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        forceBuiltIn.visible = !forceBuiltIn.visible;
        showExtraInfo = !showExtraInfo;
        showUseExternalUserAgent = true;
    }

    //--------------------------------------------------------------------------

    onErrorLabelTextChanged: {
        Qt.callLater(portalUrlField.textInput.forceActiveFocus);
    }

    onSslErrorTextChanged: {
        Qt.callLater(portalUrlField.textInput.forceActiveFocus);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        Layout.fillWidth: true

        spacing: 5 * AppFramework.displayScaleFactor

        Label {
            Layout.fillWidth: true

            text: qsTr("ArcGIS connection URL")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    forceBuiltIn.visible = !forceBuiltIn.visible;
                }
            }
        }

        UrlTextBox {
            id: portalUrlField

            Layout.fillWidth: true

            text: kDefaultPortal

            readOnly: autoAdd
            enabled: !portalInfoRequest.isBusy
            placeholderText: qsTr("Example: https://webadaptor.example.com/arcgis")
            inputRequired: true

            onCleared: {
                clearErrors();
                text = kDefaultPortal;
            }
        }

        Label {
            Layout.fillWidth: true

            visible: pkiAuthentication
            text: qsTr("Certificate (*.pfx, *.p12)")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        RowLayout {
            id: pkiFileRowLayout
            Layout.fillWidth: true

            visible: pkiAuthentication

            TextBox {
                id: pkiFileField

                Layout.fillWidth: true

                text: pkiFileName
                placeholderText: qsTr("Select certificate")
                clip: true
                inputRequired: true
                _inputEmpty: length === 0
                readOnly: true

                leftIndicator: TextBoxButton {
                    icon.name: "folder-open"

                    onClicked: {
                        pkiDocumentDialog.open();
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true

            visible: pkiAuthentication
            text: qsTr("Password")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        TextBox {
            id: passPhraseField

            Layout.fillWidth: true

            visible: pkiAuthentication
            placeholderText: qsTr("Password")
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            inputRequired: true
            _inputEmpty: length === 0

            leftIndicator: TextBoxIcon {
                icon.name: "key"
            }
        }

        Label {
            Layout.fillWidth: true

            visible: networkAuthentication
            text: qsTr("Username")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        TextBox {
            id: userField

            Layout.fillWidth: true

            visible: networkAuthentication
            placeholderText: qsTr("DOMAIN\\username")
            inputMethodHints: Qt.ImhNoPredictiveText
            inputRequired: true
            _inputEmpty: length === 0
            onTextChanged: passwordField.text = ""

            leftIndicator: TextBoxIcon {
                icon.name: "user"
            }
        }

        Label {
            Layout.fillWidth: true

            visible: networkAuthentication
            text: qsTr("Password")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        TextBox {
            id: passwordField

            Layout.fillWidth: true

            visible: networkAuthentication
            placeholderText: qsTr("Password")
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            inputRequired: true
            _inputEmpty: length === 0

            leftIndicator: TextBoxIcon {
                icon.name: "key"
            }
        }

        AppSwitch {
            id: externalUserAgent

            Layout.fillWidth: true

            visible: !networkAuthentication && showUseExternalUserAgent
            checked: false //portal.singleInstanceSupport
            text: qsTr("Use external browser for sign in")
        }

        AppSwitch {
            id: sslCheckBox

            Layout.fillWidth: true

            visible: false
            checked: false
            text: qsTr("Ignore SSL errors")
        }

        AppSwitch {
            id: forceBuiltIn

            Layout.fillWidth: true

            visible: false
            checked: false
            text: "Force built-in authentication"
        }

        Label {
            id: errorLabel

            Layout.fillWidth: true

            visible: text > ""
            color: kColorError
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Label {
            id: sslErrorLabel

            Layout.fillWidth: true

            visible: text > ""
            text: errorsToText(sslErrors)
            color: kColorError
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.StyledText

            function errorsToText(errors) {
                if (!errors) {
                    return "";
                }

                function errorToText(error) {
                    return qsTr("Error %1: %2").arg(error.error).arg(error.errorString)
                }

                return errors.map(errorToText).join("<br>");
            }
        }

        Label {
            Layout.fillWidth: true

            text: qsTr('<a href="%1">Learn more</a>').arg(kPortalHelpUrl)
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: ControlsSingleton.localeProperties.isRightToLeft
                                 ? Label.AlignLeft
                                 : Label.AlignRight
            textFormat: Label.RichText

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 10 * AppFramework.displayScaleFactor

            ProgressBar {
                anchors.fill: parent

                indeterminate: true
                visible: busy
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
            }

            StyledButton {
                id: addPortalButton

                text: qsTr("Add")
                enabled: portalUrlField.text.substring(0, 4).toLocaleLowerCase() === "http" && !busy

                onClicked: {
                    if (checkIfExists && checkExists()) {
                        duplicatePortalItemMessage.open();
                    } else {
                        tryClick();
                    }
                }

                function checkExists() {
                    var portalInfo = portalsList.findByUrl(portalUrlField.text.trim());
                    if (portalInfo) {
                        portalAdded(portalInfo, -1);
                        popup.close();
                    }

                    return portalInfo;
                }

                function tryClick() {
                    clearErrors();

                    Networking.clearAccessCache();
                    Networking.pkcs12 = null;

                    if ( pkiAuthentication ) {
                        let pkcs12 = Networking.importPkcs12( pkiFileBinary.data, passPhrase );
                        if ( !pkcs12 ) {
                            errorLabelText = qsTr("Invalid certificate or password.");
                            return;
                        }

                        Networking.pkcs12 = pkcs12;
                    }

                    portalInfoRequest.sendRequest( portalUrlField.text.replace( /\/*\s*$/, "" ) );
                }
            }

            StyledButton {
                Layout.alignment: Qt.AlignHCenter

                text: qsTr("Cancel")

                onClicked: {
                    rejected();
                    popup.close();
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    //--------------------------------------------------------------------------

    MessagePopup {
        id: duplicatePortalItemMessage

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: view
        standardButtons: StandardButton.Ok
        standardIcon: StandardIcon.Warning
        text: qsTr("The connection has already been added.")
        title: qsTr("Unable to Add Connection")
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalInfoRequest

        property url portalUrl
        property string text
        property bool isBusy: readyState == NetworkRequest.ReadyStateProcessing || readyState == NetworkRequest.ReadyStateSending

        method: "POST"
        responseType: "json"
        ignoreSslErrors: sslCheckBox.checked

        onSslErrors: {
            popup.sslErrors = errors;
        }

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (status === 200) {

                    console.log(logCategory, "self:", JSON.stringify(response, undefined, 2));

                    if (response.isPortal && !response.supportsHostedServices) {
                        errorLabelText = qsTr("Survey123 requires a base ArcGIS Enterprise deployment.");
                    } else {
                        portalVersionRequest.send();
                        infoRequest.send();
                    }
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "addPortal error:", errorCode, errorText);

            switch (errorCode) {
            case 6:
                if (showExtraInfo) {
                    sslCheckBox.visible = true;
                }
                break;

            case 201:
                pkiAuthentication = true;
                pkiPortalUrl = portalUrl;
                break;

            case 204:
                networkAuthentication = true;
                break;
            }

            if (errorCode) {
                errorLabelText = "%1 (%2)".arg(errorText).arg(errorCode);
            } else {
                errorLabelText = "";
            }
        }

        function sendRequest(u) {
            portalUrl = u;
            url = portalUrl + "/sharing/rest/portals/self";
            popup.sslErrors = null;

            var formData = {
                f: "pjson"
            };

            if (networkAuthentication) {
                user = userField.text;
                password =  passwordField.text

                console.log(logCategory, "Setting network user:", user);
            } else {
                user = "";
                password = "";
            }

            send(formData);
        }

        function addPortal(version) {
            var info = response;

            var name = info.name;
            if (!(name > "")) {
                name = qsTr("%1 (%2)").arg(info.portalName).arg(portalUrl);
            }

            var singleSignOn = typeof info.user === "object" && !networkAuthentication && !pkiAuthentication;
            var supportsOAuth = info.supportsOAuth && !(forceBuiltIn.checked && forceBuiltIn.visible) && !networkAuthentication; // && !info.isPortal;

            var portalInfo = {
                url: portalUrl.toString(),
                name: name,
                ignoreSslErrors: sslCheckBox.checked,
                isPortal: info.isPortal,
                supportsOAuth: supportsOAuth,
                externalUserAgent: externalUserAgent.checked, // && supportsOAuth && portal.singleInstanceSupport,
                networkAuthentication: networkAuthentication,
                singleSignOn: singleSignOn
            };

            if (pkiAuthentication) {
                portalInfo.pkiAuthentication = true;
                portalInfo.pkiFile = pkiFile;
                portalInfo.pkiFileName = pkiFileName;
                portalInfo.passPhrase = passPhrase;
                portalInfo.rememberMe = true;
            }

            var portalIndex = portalsList.append(portalInfo);

            console.log(logCategory, "portalInfo:", JSON.stringify(portalsList.model.get(portalIndex), undefined, 2));

            portalAdded(portalInfo, portalIndex);

            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalVersionRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.currentVersion) {
                    console.log(logCategory, "Portal version:", response.currentVersion, "response:", JSON.stringify(response, undefined, 2));

                    if (portal.versionCompare(response.currentVersion, portal.minimumVersion) >= 0) {
                        portalInfoRequest.addPortal(response.currentVersion);
                    } else {
                        errorLabelText = portal.versionError.details;
                    }
                } else {
                    console.error(logCategory, "Invalid version response:", JSON.stringify(response, undefined, 2));
                    errorLabelText = qsTr("Invalid response from host")
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "portalVersionRequest error", errorText);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: infoRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest/info?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log(logCategory, "info:", JSON.stringify(response, undefined, 2));
            }
        }

        onErrorTextChanged: {
            console.log(logCategory, "infoRequest error", errorText);
            //addPortalError.text = errorText;
        }
    }

    //--------------------------------------------------------------------------

    DocumentDialog {
        id: pkiDocumentDialog

        onAccepted: {
            var fileInfo = AppFramework.fileInfo(fileUrl);

            pkiFile = fileInfo.folder.readFile(fileInfo.fileName, {
                                                   "encode": "base64"
                                               });

            pkiFileName = fileInfo.displayName;
            passPhrase = "";
        }
    }

    //--------------------------------------------------------------------------

    BinaryData {
        id: pkiFileBinary

        base64: pkiFile
    }

    //--------------------------------------------------------------------------

    function clearErrors() {
        errorLabelText = "";
        sslErrors = null;
    }

    //--------------------------------------------------------------------------
}
