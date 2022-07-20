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

import QtQml 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 1.4 as QC1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.15

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../XForms"
import "../XForms/Singletons"
import "../Portal"
import "../Controls"
import "../Controls/Singletons"
import "Singletons"
import "SurveyHelper.js" as Helper

App {
    id: app

    readonly property bool isDesktop: (Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.platform.os === "linux" || Qt.platform.os === "osx")

    //--------------------------------------------------------------------------

    property string language: "default"

    property alias surveysFolder: surveysFolder
    property alias portal: portal
    property var userInfo

    property alias portalTheme: portalTheme

    readonly property alias textColor: portalTheme.bodyText
    readonly property alias linkColor: portalTheme.bodyLink
    readonly property alias backgroundColor: portalTheme.bodyBackground
    property string backgroundImage: app.folder.fileUrl(app.info.propertyValue("backgroundTextureImage", "images/texture.jpg"))

    readonly property alias titleBarTextColor: portalTheme.headerText
    readonly property alias titleBarBackgroundColor: portalTheme.headerBackground
    readonly property real titleBarHeight: 40 * AppFramework.displayScaleFactor
    readonly property alias footerTextColor: portalTheme.buttonText
    readonly property alias footerBackgroundColor: portalTheme.buttonBackground

    readonly property color formBackgroundColor: app.info.propertyValue("formBackgroundColor", "#f7f8f8")

    property alias surveysDatabase: surveysDatabase
    property alias positionSourceManager: positionSourceManager
    property alias gnssStatusPages: gnssStatusPages

    property bool busy: false

    property alias mapLibraryPaths: appSettings.mapLibraryPaths
    property int captureResolution: settings.numberValue("Camera/captureResolution", 0)

    property QC1.StackView activeStackView: mainStackView
    property alias mainStackView: mainStackView
    property int popoverStackDepth
    property var openParameters: null

    property alias metrics: metrics

    property var objectCache: ({})

    readonly property string kAutoSaveFileName: "autosave.json"

    property bool initialized: false
    property bool initializing: true

    readonly property string mapPlugin: appSettings.mapPlugin
    property alias mapSources: orgMapSources.mapSources

    //--------------------------------------------------------------------------

    readonly property LocaleProperties localeProperties: ControlsSingleton.localeProperties
    readonly property var locale: localeProperties.locale

    //--------------------------------------------------------------------------

    property alias appSettings: appSettings

    property alias fontFamily: appSettings.fontFamily
    property alias textScaleFactor: appSettings.textScaleFactor

    property alias alert: appAlert

    //--------------------------------------------------------------------------

    property alias config: appConfig
    property alias properties: propertiesManager
    property alias features: appFeatures
    property alias encryptionManager: encryptionManager

    //--------------------------------------------------------------------------

    property alias workFolder: workFolder
    property alias addInsManager: addInsManager
    property alias addInsFolder: addInsManager.addInsFolder
    property alias surveyAddIns: surveyAddIns

    property alias logsFolder: logsFolder
    property alias commandProcessor: commandProcessor

    //--------------------------------------------------------------------------

    property alias runtimeInfo: runtimeInfo

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "Initializing");

        if (isDesktop) {
            var size = appSettings.readSize(appSettings.kKeyApp);

            width = Math.min(Screen.desktopAvailableWidth,
                             size.width > 0 ? size.width : 400 * AppFramework.displayScaleFactor);
            height = Math.min(Screen.desktopAvailableHeight,
                              size.height > 0 ? size.height : 650 * AppFramework.displayScaleFactor);
        }

        fontManager.loadFonts();
        console.log(logCategory, "MapSymbols.icons:", MapSymbols.icons.font.family);
        console.log(logCategory, "MapSymbols.point:", MapSymbols.point.font.family);

        appSettings.read();
        features.read();

        ControlsSingleton.font.family = Qt.binding(function () { return appSettings.fontFamily; });
        ControlsSingleton.font.bold = Qt.binding(function () { return appSettings.boldText; });

        portal.readSettings();
        readUserInfo();

        Qt.callLater(initialize);
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        console.log(logCategory, "Terminating");

        if (isDesktop) {
            appSettings.writeSize(appSettings.kKeyApp, Qt.size(width, height));
        }
    }

    //--------------------------------------------------------------------------

    onLowMemory: {
       console.warn("Low memory");
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, arguments.callee.name);

        function clearInitializing() {
            Qt.callLater(() => { app.initializing = false; });
        }

        if (portal.isOnline && portal.canAutoSignIn()) {
            portal.connect(
                        function () {
                            console.log(logCategory, "Connection to portal resolved");
                            app.portal.autoSignIn();
                            clearInitializing();
                        },
                        function () {
                            console.log(logCategory, "Connection to portal rejected");
                            portal.restoreUser(userInfo);
                            clearInitializing();
                        });
        } else {
            portal.restoreUser(userInfo);
            clearInitializing();
        }

        // This opens a survey.  Defer this until after login.
        // Qt.callLater(requestCameraPermission);
    }

    //--------------------------------------------------------------------------

    Component {
        id: invalidDatabasePopup

        XFormErrorPopup {
            message: surveysDatabase.isDatabase
                     ? qsTr("The survey database is out of date and must be reinitialized. Please ensure all survey data has been submitted successfully before reinitializing the database.")
                     : qsTr("The survey database cannot be accessed and must be reinitialized.")
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(app, true)
    }

    //--------------------------------------------------------------------------

    onOpenUrl: {
        console.log(logCategory, "onOpenUrl url:", url);

        function processUrl(url) {
            console.log(logCategory, arguments.callee.name, "url:", url);

            var urlInfo = AppFramework.urlInfo(localeProperties.replaceNumbers(url, localeProperties.locale));

            if (!urlInfo.host.length || urlInfo.host.toLowerCase() === commandProcessor.appLinkHost) {
                selectPortal(Helper.getPropertyValue(urlInfo.queryParameters, Survey.kParameterPortalUrl, "").trim(),
                             function () {
                                 console.log(logCategory, "onOpenUrl parameters:", JSON.stringify(urlInfo.queryParameters, undefined, 2));

                                 openParameters = urlInfo.queryParameters;
                             });
            } else {
                commandProcessor.invoke(urlInfo);
            }
        }

        Qt.callLater(processUrl, url);
    }

    //--------------------------------------------------------------------------

    onLocaleChanged: {      

        // Error: A QmlLoggingCatgory was provided without a valid name
        // console.log(logCategory, "App locale changed to:", locale.name);

        // This leads to binding loop errors
        //if (locale.name !== localeProperties.kNeutralLocale.name) {
        //    console.log("Loading translations for :", locale.name);
        //    AppFramework.loadTranslator(app.info.json.translations, app.folder.path, locale.name);
        //}
    }

    //--------------------------------------------------------------------------

    backButtonAction: mainStackView.depth == 1 ? App.BackButtonQuit : App.BackButtonSignal

    onBackButtonClicked: {
        goBack();
    }

    /*
    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            event.accepted = true;
            goBack();
        }
    }
    */

    /*
      // Debug only back button on non-Android devices

    Button {
        anchors.centerIn: parent
        z: 999999
        text: "Back"
        onClicked: {
            goBack();
        }
    }
    */

    //--------------------------------------------------------------------------

    function goBack() {
        var stackView = activeStackView;

        if (!stackView) {
            console.log("goBack: No stackView");
            return false;
        }

        if (stackView.popoverStackView) {
            if (stackView.popoverStackView.depth > popoverStackDepth) {
                stackView = stackView.popoverStackView;
            }
        }

        if (stackView.depth <= 1) {
            console.log("goBack: At top of stackView closeAction:", typeof stackView.currentItem.closeAction);

            var closeAction = stackView.currentItem.closeAction;
            if (typeof closeAction === "function") {
                closeAction();
                return true;
            }

            return false;
        }

        var canGoBack = stackView.currentItem.canGoBack;

        var doPop;

        switch (typeof canGoBack) {
        case 'boolean' :
            doPop = canGoBack;
            break;

        case 'function' :
            doPop = canGoBack();
            break;

        default:
            doPop = true;
            break;
        }

        // console.log("stackView:", stackView.depth, "canGoBack:", typeof canGoBack, doPop);

        if (doPop) {
            stackView.pop(); //stackView.currentItem.id);
            return true;
        }

        return false;
    }

    //--------------------------------------------------------------------------

    AppConfig {
        id: appConfig

        app: app
    }

    //--------------------------------------------------------------------------

    AppSettings {
        id: appSettings

        app: app
    }

    //--------------------------------------------------------------------------

    AppFeatures {
        id: appFeatures

        app: app
        settings: app.settings
    }

    //--------------------------------------------------------------------------

    Metrics {
        id: metrics
    }

    //--------------------------------------------------------------------------

    FontManager {
        id: fontManager
    }

    //--------------------------------------------------------------------------

    QC1.StackView {
        id: mainStackView

        anchors {
            fill: parent
        }

        delegate: AppPageViewDelegate {}

        initialItem: startPage

        function pushHomePage(_language) {
            language = _language;
            console.log("pushHomePage", language)
            push(homePage);
        }

        function pushLanguagePage()
        {
            push(languagePage);
        }

        function restartSurvey() {
            var surveyPath = currentItem.surveyPath;

            push({
                     item: surveyView,
                     replace: true,
                     properties: {
                         surveyPath: surveyPath,
                         rowid: null
                     }
                 });
        }

        function submitSurveys(surveyPath, autoSubmit, isPublic, parameters, properties) {
            if (!properties) {
                properties = {};
            }

            properties.surveyPath = surveyPath;
            properties.autoSubmit = autoSubmit;
            properties.isPublic = isPublic;
            properties.parameters = parameters;

            push({
                     item: submitSurveysPage,
                     properties: properties,
                     replace: autoSubmit
                 });
        }

        LoggingIndicator {
            anchors {
                right: parent.right
                top: parent.top
                margins: 1 * AppFramework.displayScaleFactor
            }
        }
    }

    //--------------------------------------------------------------------------

    function showHomePage() {
        console.log(logCategory, arguments.callee.name, "Surveys folder:", surveysFolder.path);

        if (!surveysFolder.exists) {
            surveysFolder.makeFolder();
        }

        AppFramework.offlineStoragePath = surveysFolder.path;

        console.log(logCategory, "offlineStoragePath:", AppFramework.offlineStoragePath)

        addInsManager.initialize();
    }

    //--------------------------------------------------------------------------

    function initializeHome() {
        console.log(logCategory, arguments.callee.name);

        surveysDatabase.initialize();

        var surveysCount = surveysFolder.forms.length;

        if (!surveysDatabase.validateSchema()) {
            Qt.callLater(function () {
                console.error(logCategory, "Invalid Schmea");
                var dialog = invalidDatabasePopup.createObject(mainStackView);
                dialog.open();
            });
        }

        Qt.callLater(checkAutoSave);

        initialized = true;

        positionSourceConnection.checkActivationMode();
    }

    //--------------------------------------------------------------------------

    function surveySelected(surveyPath, pressAndHold, indicator, parameters, surveyInfo) {
        console.log(logCategory, arguments.callee.name, "surveyPath:", surveyPath, "updateAvailable:", surveyInfo.updateAvailable);

        function showSurvey() {
            var count = surveysDatabase.surveyCount(surveyPath);

            if (pressAndHold) {
                var surveyViewPage = {
                    item: surveyView,
                    properties: {
                        surveyPath: surveyPath,
                        rowid: null,
                        parameters: parameters
                    }
                }

                mainStackView.push(surveyViewPage);
            } else {
                var pageItem = surveyPage;

                if (parameters) {
                    var folder = Helper.getPropertyValue(parameters, Survey.kParameterFolder, "").trim().toLowerCase();
                    switch (folder) {
                    case Survey.kFolderInbox:
                        pageItem = inboxSurveysPage;
                        break;

                    case Survey.kFolderDrafts:
                        pageItem = draftSurveysPage;
                        break;

                    case Survey.kFolderOutbox:
                        pageItem = submitSurveysPage;
                        break;

                    case Survey.kFolderSent:
                        pageItem = sentSurveysPage;
                        break;

                    case Survey.kFolderOverview:
                    case "*":
                    default:
                        pageItem = overviewFolderPage;
                        break;
                    }
                }

                var surveyInfoPage = {
                    item: pageItem,
                    properties: {
                        surveyPath: surveyPath,
                        parameters: parameters
                    }
                };

                mainStackView.push(surveyInfoPage);
            }
        }

        if (surveyInfo.updateAvailable && portal.isOnline) {
            var fileInfo = AppFramework.fileInfo(surveyPath);
            var itemInfo = fileInfo.folder.readJsonFile(fileInfo.baseName + ".itemInfo");

            var requireSurveyUpdate = app.properties.value("requireSurveyUpdate", false);

            var popup = surveyUpdatePopup.createObject(
                        app,
                        {
                            surveyInfo: surveyInfo,
                            itemInfo: itemInfo,
                            requireUpdate: requireSurveyUpdate || surveyInfo.requireUpdate,
                        });

            popup.openSurvey.connect(showSurvey);
            popup.open();
        } else {
            showSurvey();
        }
    }

    // TODO Hack until a better way is implemented
    signal broadcastSurveyUpdate(string id)

    Component {
        id: surveyUpdatePopup

        SurveyUpdatePopup {
            portal: app.portal

            onUpdated: {
                broadcastSurveyUpdate(itemInfo.id);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: startPage

        StartPage {
            portal: app.portal
            ready: !initializing && !app.portal.isConnecting && !app.portal.errorPopup

            onSignedIn: {
                mainStackView.pushLanguagePage();
            }

            onStartAnonymous: {
                showHomePage();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: languagePage

        LanguagePage {
            portal: app.portal

            Component.onCompleted: {
                console.log("LanguagePage completed")
            }
        }
    }

    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------

    Component {
        id: homePage

        HomePage {
            portal: app.portal

            Component.onCompleted: {
                selected.connect(app.surveySelected);
                initializeHome();
            }

            onAddInSelected: {
                addInsManager.startAddIn(addInItem.path);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: downloadSurveysPage

        DownloadSurveysPage {
        }
    }

    Component {
        id: surveyPage

        SurveyInfoPage {
        }
    }

    Component {
        id: surveyView

        SurveyFormPage {
            onXformChanged: {
                if (xform) {
                    popoverStackDepth = mainStackView.depth;
                    activeStackView = xform;
                } else {
                    activeStackView = mainStackView;
                }
            }

            Component.onDestruction: {
                activeStackView = mainStackView;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: inboxSurveysPage

        SurveyFolderPageInbox {
            objectCache: app.objectCache
        }
    }

    Component {
        id: draftSurveysPage

        SurveyFolderPageDrafts {
        }
    }

    Component {
        id: submitSurveysPage

        SurveyFolderPageOutbox {
            objectCache: app.objectCache
        }
    }

    Component {
        id: sentSurveysPage

        SurveyFolderPageSent {
        }
    }

    Component {
        id: overviewFolderPage

        SurveyFolderPageOverview {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appAboutPage

        AboutPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appSettingsPage

        SettingsPage {
        }
    }

    //--------------------------------------------------------------------------

    XFormsFolder {
        id: surveysFolder

        path: "~/ArcGIS/My Surveys"
    }

    XFormsDatabase {
        id: surveysDatabase

        keyEnabled: key > ""
        key: encryptionManager.encryptionKey
        keyType: encryptionManager.encryptionKeyType
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: workFolder

        path: AppFramework.standardPaths.writableLocation(StandardPaths.TempLocation)

        Component.onCompleted: {
            console.log("workFolder:", path);
        }
    }

    FileFolder {
        id: logsFolder

        path: "~/ArcGIS/My Survey123/Logs"

        Component.onCompleted: {
            makeFolder();
            console.log("logsFolder:", path);
        }
    }

    //--------------------------------------------------------------------------

    Portal {
        id: portal

        property bool staySignedIn: settings.value(settingsGroup + "/staySignedIn", app.info.propertyValue("staySignedIn", true))
        property var actionCallback: null
        property Popup connectPopup: null
        property Popup errorPopup

        app: app
        settings: app.settings
        clientId: app.info.value("deployment").clientId
        defaultUserThumbnail: Icons.bigIcon("user")

        defaultPortalUrl: appConfig.portalUrl
        defaultPortalName: appConfig.portalName
        defaultNetworkAuthentication: appConfig.portalNetworkAuthentication
        defaultSingleSignOn: appConfig.portalSingleSignOn
        defaultSupportsOAuth: appConfig.portalSupportsOAuth

        propertiesResourceKey: appConfig.portalResourceKey
        managementEnabled: appConfig.enablePortalManagement

        onCredentialsRequest: {
            console.log("Show sign in page");
            mainStackView.push({
                                   item: portalSignInPage,
                                   immediate: false,
                                   properties: {
                                   }
                               });
        }

        function signInAction(reason, callback) {
            function resolved() {
                validateToken();

                if (signedIn) {
                    actionCallback = null;
                    callback();
                    return;
                }

                actionCallback = callback;
                signIn(reason);
            }

            function rejected() {
                actionCallback = null;
            }

            connect(resolved, rejected);
        }

        function connectAction(reason, callback) {
            console.log(logCategory, arguments.callee.name, reason);

            function resolved() {
                actionCallback = null;
                callback();
            }

            function rejected() {
                actionCallback = null;
            }

            if (!signedIn) {
                console.error(logCategory, arguments.callee.name, "Not signed in");
                rejected();
                return;
            }

            connect(resolved, rejected);
        }

        onSignedInChanged: {
            var callback = actionCallback;
            actionCallback = null;

            app.objectCache["lastGeocoderSearchUrl"] = undefined;

            if (signedIn) {
                if (staySignedIn) {
                    writeSignedInState();
                } else {
                    clearSignedInState();
                }
            } else {
                clearSignedInState();
            }

            if (signedIn) {
                userInfo = portal.user;
                userInfo.isPortal = portal.isPortal;
                userInfo.portalProperties = portal.propertiesResource;
                writeUserInfo();
            } else {
                clearUserInfo();
            }

            if (signedIn && mainStackView.currentItem && mainStackView.currentItem.isPortalSignInView) {
                if(user.orgId>"") {
                    //only pop login screen when user is not using free public account
                    mainStackView.pop();
                }
            }

            if (signedIn && callback) {
                callback();
            }
        }

        onConnecting: {
            if (debug) {
                console.log("connecting:", request.readyState);
            }

            switch (request.readyState) {
            case NetworkRequest.ReadyStateSending:
                if (connectPopup) {
                    connectPopup.close();
                }

                connectPopup = hostConnectPopup.createObject(app,
                                                             {
                                                                 request: request
                                                             });

                connectPopup.open();
                break;

            case NetworkRequest.ReadyStateComplete:
                if (connectPopup) {
                    connectPopup.close();
                    connectPopup = null;
                }
                break;
            }
        }

        onConnectError: {
            if (connectPopup) {
                connectPopup.close();
                connectPopup = null;
            }

            errorPopup = hostErrorPopup.createObject(app,
                                                     {
                                                         request: request,
                                                         error: error
                                                     });

            errorPopup.aboutToHide.connect(() => { errorPopup = null; });
            errorPopup.open();
        }
    }

    //--------------------------------------------------------------------------

    AppPropertiesManager {
        id: propertiesManager

        app: app
        portal: app.portal
    }

    //--------------------------------------------------------------------------

    OrgMapSources {
        id: orgMapSources

        portal: portal
        cacheFolder: surveysFolder
        groupQuery: app.properties.basemapsGroupQuery
    }

    //--------------------------------------------------------------------------

    PortalTheme {
        id: portalTheme

        portal: app.properties.usePortalTheme ? app.portal : null

        defaultBodyText: app.info.propertyValue("textColor", "black")
        defaultBodyBackground: app.info.propertyValue("backgroundColor", "lightgrey")

        defaultHeaderText: app.info.propertyValue("titleBarTextColor", "grey")
        defaultHeaderBackground: app.info.propertyValue("titleBarBackgroundColor", "white")
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalSignInPage

        PortalSignInView {
            property bool isPortalSignInView: true

            portal: app.portal
            bannerColor: app.titleBarBackgroundColor

            onRejected: {
                portal.actionCallback = null;
                mainStackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: hostConnectPopup

        PortalConnectPopup {
            portal: app.portal
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: hostErrorPopup

        PortalErrorPopup {
            portal: app.portal

            title: qsTr("Error connecting to %1").arg(portal.name)
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceManager {
        id: positionSourceManager

        connectionType: appSettings.locationSensorConnectionType
        activationMode: appSettings.locationSensorActivationMode
        storedDeviceName: appSettings.lastUsedDeviceName
        storedDeviceJSON: appSettings.lastUsedDeviceJSON
        hostname: appSettings.hostname
        port: Number(appSettings.port)

        nmeaLogFile: appSettings.nmeaLogFile
        updateInterval: appSettings.updateInterval
        repeat: appSettings.repeat

        name: appSettings.lastUsedDeviceLabel > ""
              ? appSettings.lastUsedDeviceLabel
              : appSettings.lastUsedDeviceName;

        altitudeType: appSettings.locationAltitudeType
        confidenceLevelType: appSettings.locationConfidenceLevelType
        customGeoidSeparation: appSettings.locationGeoidSeparation
        antennaHeight: appSettings.locationAntennaHeight
        wkid: appSettings.wkid

        compassEnabled: appSettings.compassEnabled
        magneticDeclination: appSettings.magneticDeclination

        logger {
            logFileLocation: logsFolder.path
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        readonly property int activationMode: appSettings.locationSensorActivationMode

        positionSourceManager: positionSourceManager
        stayActiveOnError: activationMode >= appSettings.kActivationModeAlways
        listener: "SurveyApp"
        compassEnabled: false

        onActivationModeChanged: {
            if (initialized) {
                checkActivationMode();
            }
        }

        function checkActivationMode() {
            if (activationMode >= appSettings.kActivationModeAlways) {
                start();
            } else {
                stop();
            }
        }
    }

    // -------------------------------------------------------------------------

    XFormGNSSStatusPages {
        id: gnssStatusPages

        positionSourceManager: positionSourceManager

        settingsTabContainer: SettingsTabContainer {}
        settingsTabLocation: SettingsTabLocation {}

        onAlert: {
            switch (alertType) {
            case XFormNmeaLogger.AlertType.Started:
                appAlert.positionSourceAlert(AppAlert.AlertType.RecordingStarted);
                break;
            case XFormNmeaLogger.AlertType.Stopped:
                appAlert.positionSourceAlert(AppAlert.AlertType.RecordingStopped);
                break;
            case XFormNmeaLogger.AlertType.Error:
                appAlert.positionSourceAlert(AppAlert.AlertType.FileIOError);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    PositionSourceMonitor {
        id: positionSourceMonitor

        positionSourceManager: positionSourceManager

        monitorNmeaData: appSettings.locationAlertsMonitorNmeaData
        maximumDataAge: appSettings.locationMaximumDataAge
        maximumPositionAge: appSettings.locationMaximumPositionAge

        onAlert: {
            appAlert.positionSourceAlert(alertType);
        }
    }

    //-------------------------------------------------------------------------

    Connections {
        target: Qt.application

        function onStateChanged() {
            switch (Qt.application.state) {
            case Qt.ApplicationActive:
                if (positionSourceManager.active && positionSourceManager.isGNSS && !positionSourceManager.isConnecting) {
                    reconnectTimer.start();
                }
                break;

            case Qt.ApplicationInactive:
            case Qt.ApplicationSuspended:
                if (reconnectTimer.running) {
                    reconnectTimer.stop();
                }
                break;
            }
        }
    }

    //-------------------------------------------------------------------------

    Timer {
        id: reconnectTimer

        property double startTime

        interval: appSettings.locationMaximumDataAge

        onRunningChanged: {
            if (running) {
                startTime = (new Date()).valueOf();
            }
        }

        onTriggered: {
            if (positionSourceManager.active && positionSourceManager.isGNSS && !positionSourceManager.isConnecting) {
                var now = new Date().valueOf();
                var dataAge = now - positionSourceMonitor.dataReceivedTime;

                if (dataAge > appSettings.locationMaximumDataAge) {
                    positionSourceManager.controller.fullDisconnect();
                    positionSourceManager.controller.reconnectNow();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    // Dummy to hack global properties

    Item {
        id: xform

        property alias popoverStackView: mainStackView
        property alias style: style
        property alias localeProperties: app.localeProperties
        property alias localeInfo: app.localeProperties
        readonly property var locale: app.localeProperties.locale

        XFormStyle {
            id: style

            fontFamily: app.fontFamily

            textScaleFactor: app.textScaleFactor

            titleTextColor: app.titleBarTextColor
            titleBackgroundColor: app.titleBarBackgroundColor
            linkColor: app.linkColor

            footerTextColor: app.footerTextColor
            footerBackgroundColor: app.footerBackgroundColor

            boldText: appSettings.boldText
            hapticFeedback: appSettings.hapticFeedback
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        visible: busy //|| portalSignInDialog.visible
        color: "#80000000"

        AppBusyIndicator {
            anchors.centerIn: parent
            running: busy
        }
    }

    //--------------------------------------------------------------------------

    AppAlert {
        id: appAlert
    }

    //--------------------------------------------------------------------------

    readonly property string kGroupInfo: "Info"
    readonly property string kKeyUserInfo: kGroupInfo + "/user"

    function readUserInfo() {
        var info;

        try {
            info = JSON.parse(settings.value(kKeyUserInfo, ""));
        } catch (e) {
            info = {};
        }

        if (!info || typeof info !== "object") {
            info = {};
        }

        userInfo = info;

        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(userInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function writeUserInfo() {
        if (!userInfo || typeof userInfo !== "object") {
            settings.remove(kKeyUserInfo);
            return;
        }

        var info = {
            username: userInfo.username,
            firstName: userInfo.firstName,
            lastName: userInfo.lastName,
            fullName: userInfo.fullName,
            email: userInfo.email,
            orgId: userInfo.orgId,
            isPortal: userInfo.isPortal,
            portalProperties: userInfo.portalProperties
        };

        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(info, undefined, 2));

        settings.setValue(kKeyUserInfo, JSON.stringify(info));
    }

    //--------------------------------------------------------------------------

    function clearUserInfo() {
        userInfo = undefined;
        settings.remove(kKeyUserInfo);
    }

    //--------------------------------------------------------------------------

    function readAutoSave() {
        if (!surveysFolder.fileExists(kAutoSaveFileName)) {
            return;
        }

        var data = surveysFolder.readJsonFile(kAutoSaveFileName);
        if (!data) {
            return;
        }

        if (!Object.keys(data).length) {
            return;
        }

        return data;
    }

    function writeAutoSave(data) {
        surveysFolder.writeJsonFile(kAutoSaveFileName, data);
    }

    function deleteAutoSave() {
        surveysFolder.removeFile(kAutoSaveFileName);
    }

    //--------------------------------------------------------------------------

    Component {
        id: recoveryPopup

        ActionsPopup {
            property var data

            signal discard()
            signal recover()

            icon {
                name: "exclamation-mark-triangle"
                color: Survey.kColorWarning
            }

            title: qsTr("Recovered Survey")
            text: qsTr("Survey123 closed unexpectedly. Data for the <b>%1</b> survey has been recovered.").arg(data.name)
            informativeText: data.snippet || ""

            Action {
                text: qsTr("Discard survey")

                icon {
                    name: "trash"
                    color: Survey.kColorWarning
                }

                onTriggered: {
                    discard();
                    close();
                }
            }

            Action {
                text: qsTr("Continue survey")
                icon {
                    name: "move-up"
                }
                property real iconRotation: 90

                onTriggered: {
                    recover();
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function checkAutoSave() {
        var data = app.readAutoSave();

        if (!data) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "data:", JSON.stringify(data, undefined, 2));

        function _continueSurvey() {
            var surveyViewPage = {
                item: surveyView,
                properties: {
                    surveyPath: data.path,
                    rowid: data.rowid > 0 ? data.rowid : -1,
                    rowData: data.data,
                    parameters: null
                }
            }

            mainStackView.push(surveyViewPage);
        }

        var popup = recoveryPopup.createObject(app,
                                               {
                                                   data: data
                                               });
        popup.discard.connect(deleteAutoSave);
        popup.recover.connect(_continueSurvey);
        popup.open();
    }

    //--------------------------------------------------------------------------

    ArcGISRuntimeInfo {
        id: runtimeInfo
    }

    ArcGISRuntimeAuthentication {
        onLicenseChanged: {
            runtimeInfo.update();
        }
    }

    //--------------------------------------------------------------------------

    AddInsManager {
        id: addInsManager

        enableInstalledAddIns: features.addIns

        onStarted: {
            mainStackView.pushHomePage();
        }

        /*
        if (autoStartAddIn) {
            console.log(logCategory, "autoStartAddIn:", JSON.stringify(autoStartAddIn));
            var fileInfo = addInsFolder.fileInfo(autoStartAddIn);
            if (autoStartAddIn > "" && fileInfo.exists) {
                startAddIn(fileInfo.filePath);
            } else {
                mainStackView.pushHomePage();
            }
        } else {
            mainStackView.pushHomePage();
        }
        */
    }

    //--------------------------------------------------------------------------

    SurveyAddIns {
        id: surveyAddIns

        addInsManager: app.addInsManager
    }

    //--------------------------------------------------------------------------

    EncryptionManager {
        id: encryptionManager

        portal: portal
        propertiesManager: app.properties
        surveysDatabase: surveysDatabase
    }

    //--------------------------------------------------------------------------

    CommandProcessor {
        id: commandProcessor

        app: app
        enableDiagnostics: app.config.enableDiagnostics
        logsFolder: app.logsFolder
    }

    //--------------------------------------------------------------------------

    function selectPortal(portalUrl, resolve, reject) {
        console.log(logCategory, arguments.callee.name, "portalUrl:", portalUrl);

        function _resolve() {
            Qt.callLater(resolve);
        }

        if (!portalUrl) {
            _resolve();
            return;
        }

        if (portal.portalUrl.toString().toLocaleLowerCase() === portalUrl.toLowerCase()) {
            _resolve();
            return;
        }

        portal.portalsList.read();

        var portalInfo = portal.portalsList.findByUrl(portalUrl);
        if (portalInfo) {
            portal.setPortal(portalInfo);
            _resolve();
            return;
        }

        function portalAdded(portalInfo) {
            portal.setPortal(portalInfo);
            _resolve();
        }

        var popup = portalAddPopup.createObject(app,
                                                {
                                                    url: portalUrl,
                                                    autoAdd: true
                                                });

        popup.portalAdded.connect(portalAdded);
        if (reject) {
            popup.rejected.connect(reject);
        }
        popup.open();
    }

    Component {
        id: portalAddPopup

        PortalAddPopup {
            portal: app.portal
            portalsList: app.portal.portalsList

            palette {
                window: app.backgroundColor
                windowText: app.textColor
                button: app.titleBarBackgroundColor
                buttonText: app.titleBarTextColor
            }
        }
    }

    //--------------------------------------------------------------------------
    // Font issue on Windows workaround #3229

    FileDialog {
        id: fileDialog

        visible: false
    }

    //--------------------------------------------------------------------------

    PermissionDialog {
        id: permissionDialog

        openSettingsWhenDenied: true;
    }

    function requestCameraPermission() {
        if (Permission.checkPermission(Permission.PermissionTypeCamera) !== Permission.PermissionResultGranted) {
            permissionDialog.permission = PermissionDialog.PermissionDialogTypeCamera;
            permissionDialog.open();
        }
          app.openUrl("arcgis-survey123://?itemID=956d41ce275a4e16b53372de674cb2e1");
    }

    //--------------------------------------------------------------------------
}
