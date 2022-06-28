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

import ArcGIS.AppFramework 1.0

import "../Models"
import "../Controls"
import "../Controls/Singletons"
import "SurveyHelper.js" as Helper
import "Singletons"

HomeViewTab {
    id: tab

    //--------------------------------------------------------------------------
    property Settings settings: app.settings
    property alias galleryView: galleryView

    readonly property string searchText: searchUrlInfo.isValid && searchUrlInfo.scheme > ""
                                         ? ""
                                         : searchField.text

    property bool debug: true

    property var surveysToLoad: []

    //--------------------------------------------------------------------------

    readonly property string kSettingsGroup: "Home/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    //--------------------------------------------------------------------------

    title: qsTr("Global CHE Network")
    shortTitle: qsTr("Gallery")
    iconSource: Icons.bigIcon("apps", false)

    //--------------------------------------------------------------------------

    menu: AppMenu {
        id: appMenu

        showDownloadSurveys: true
    }

    //--------------------------------------------------------------------------

    actionGroup: homeActionGroup

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        readSettings();

        if (!surveysRefresh.busy) {
            // Qt.callLater(checkOpenParameters);
            Qt.callLater(loadSurveys);
        }
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        galleryView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        delegateModel.setSortProperty(settings.value(kSettingSortProperty, delegateModel.kPropertyTitle));
        delegateModel.setSortOrder(settings.value(kSettingSortOrder, Qt.AscendingOrder));

        console.log(logCategory, arguments.callee.name,
                    "sortProperty:", delegateModel.sortProperty,
                    "sortOrder:", delegateModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        console.log(logCategory, arguments.callee.name,
                    "sortProperty:", delegateModel.sortProperty,
                    "sortOrder:", delegateModel.sortOrder);

        settings.setValue(kSettingSortProperty, delegateModel.sortProperty);
        settings.setValue(kSettingSortOrder, delegateModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    function updateTiles() {
        console.time("updateTiles");

        tilesModel.clear();

        console.time("surveyTiles");

        for (var i = 0; i < surveysModel.count; i++) {
            var surveyItem = surveysModel.get(i);

            surveyItem.tileType = tilesModel.kTileTypeSurvey;

            tilesModel.append(surveyItem);
        }

        console.timeEnd("surveyTiles");

        console.time("addInTiles");

        for (i = 0; i < addInTilesModel.count; i++) {
            var addInItem = addInTilesModel.get(i);

            addInItem.tileType = tilesModel.kTileTypeAddIn;

            tilesModel.append(addInItem);
        }

        console.timeEnd("addInTiles");
        console.timeEnd("updateTiles");

        //galleryView.forceLayout();
    }

    //--------------------------------------------------------------------------

    function invalidateTiles() {
        Qt.callLater(updateTiles);
    }

    //--------------------------------------------------------------------------

    function refreshTiles() {
        for (var i = 0; i < surveysModel.count; i++) {
            var surveyItem = surveysModel.get(i);
            if (surveyItem.itemId > "") {
                var tileIndex = tilesModel.findByKeyValue("itemId", surveyItem.itemId);
                tilesModel.setProperty(tileIndex, "updateAvailable", surveyItem.updateAvailable);
                tilesModel.setProperty(tileIndex, "requireUpdate", surveyItem.requireUpdate);
            }
        }

        Qt.callLater(checkOpenParameters);
    }

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(tab, true)
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: tilesModel

        //----------------------------------------------------------------------

        readonly property string kTileTypeAddIn: "addin"
        readonly property string kTileTypeSurvey: "survey"

        //----------------------------------------------------------------------

        function findByKeyValue(key, value) {
            for (var i = 0; i < count; i++) {
                if (get(i)[key] === value) {
                    return i;
                }
            }

            return -1;
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    SortFilterDelegateModel {
        id: delegateModel

        //----------------------------------------------------------------------

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyModified: "modified"

        readonly property int sortType: sortPropertyToType(sortProperty)

        //----------------------------------------------------------------------

        property alias sortProperty: delegateModel.sortRole

        model: tilesModel
        delegate: tileDelegate

        sortRole: kPropertyTitle
        sortOrder: Qt.AscendingOrder

        filterRole: surveysModel.kPropertyTitle
        filterValue: searchText

        sortCaseSensitivity: Qt.CaseInsensitive

        //----------------------------------------------------------------------

        function sortPropertyToType(sortProperty) {
            switch (sortProperty) {
            case kPropertyTitle:
                return SortPopup.SortType.Alphabetical;

            case kPropertyModified:
                return SortPopup.SortType.Time;
            }
        }

        //----------------------------------------------------------------------

        function setSortProperty(value) {
            var propertyName;

            switch (value) {
            case SortPopup.SortType.Alphabetical:
            case kPropertyTitle:
                propertyName = kPropertyTitle;
                break;

            case SortPopup.SortType.Time:
            case kPropertyModified:
                propertyName = kPropertyModified;
                break;
            }

            if (propertyName) {
                sortProperty = propertyName;
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInTilesModel

        type: kTypeTool
        mode: kToolModeTile

        addInsFolder: app.addInsFolder

        onUpdated: {
            invalidateTiles();
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        formsFolder: surveysFolder

        onUpdated: {
            invalidateTiles();
            Qt.callLater(refreshTiles);
        }

        onRefreshed: {
            invalidateTiles(); // TODO Improve so only properties are updated
        }
    }

    SurveysRefresh {
        id: surveysRefresh

        model: surveysModel

        function onFinished() {
            updatesNotification.finished();
            Qt.callLater(refreshTiles);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        function onOpenParametersChanged() {
            if (app.openParameters) {
                checkOpenParameters();
            }
        }
    }

    function checkOpenParameters() {
        if (!app.openParameters) {
            return;
        }

        var itemId = Helper.getPropertyValue(app.openParameters, Survey.kParameterItemId, "").trim();

        if (!Helper.isEmpty(itemId)) {
            if (processParameters(JSON.parse(JSON.stringify(app.openParameters)))) {
                app.openParameters = null;
            }
        }
    }

    function processParameters(parameters) {
        if (!parameters) {
            console.error(logCategory, arguments.callee.name, "parameters:", parameters);
            return;
        }

        var itemId = Helper.getPropertyValue(parameters, Survey.kParameterItemId, "").trim();
        if (Helper.isEmpty(itemId)) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "parameters:", JSON.stringify(parameters, undefined, 2));

        var surveyItem = findSurveyItem(itemId);
        if (!surveyItem) {
            openParametersPanel.show(parameters);
            return;
        }

        parameters.itemId = surveyItem.itemId;
        var collect = (parameters.action || Survey.kActionCollect) === Survey.kActionCollect
                && !parameters.folder
                && !parameters.filter;

        if (!parameters.action && collect) {
            parameters.action = Survey.kActionCollect;
        }

        if (!parameters.folder && parameters.action !== Survey.kActionCollect) {
            parameters.folder = Survey.kFolderInbox;
        }

        //selected(app.surveysFolder.filePath(surveyItem.survey), collect, -1, parameters, surveyItem);

        return true;
    }

    function findSurveyItem(itemId) {
        console.log(logCategory, arguments.callee.name, "itemId:", itemId, "surveys:", surveysModel.count);

        for (var i = 0; i < surveysModel.count; i++) {
            var surveyItem = surveysModel.get(i);
            if (surveyItem.itemId === itemId) {
                return surveyItem;
            }
        }

        return null;
    }

    function loadSurveys()
    {
        var surveyItem = findSurveyItem("956d41ce275a4e16b53372de674cb2e1");
        if (!surveyItem) {
            surveysToLoad.push(JSON.parse('{"itemID":"956d41ce275a4e16b53372de674cb2e1"}'));
        }

        surveyItem = findSurveyItem("fd2873abc2804369837fb6ccd00e9135");
        if (!surveyItem) {
            surveysToLoad.push(JSON.parse('{"itemID":"fd2873abc2804369837fb6ccd00e9135"}'));
        }

        surveyItem = findSurveyItem("6ce0f5a6c5c54fea81a3ca0a08ec9ad9");
        if (!surveyItem) {
            surveysToLoad.push(JSON.parse('{"itemID":"6ce0f5a6c5c54fea81a3ca0a08ec9ad9"}'));
        }

        surveyItem = findSurveyItem("5f2bddd5a8d24e1f8863c4c75a50b071");
        if (!surveyItem) {
            surveysToLoad.push(JSON.parse('{"itemID":"5f2bddd5a8d24e1f8863c4c75a50b071"}'));
        }

        var surveyToLoad = surveysToLoad.pop();
        if (surveyToLoad)
        {
            processParameters(surveyToLoad);
        }
    }



    //--------------------------------------------------------------------------

    UrlInfo {
        id: searchUrlInfo
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        anchors {
            fill: parent
            topMargin: 8 * AppFramework.displayScaleFactor
        }

        spacing: 0

        UpdatesNotification {
            id: updatesNotification

            Layout.fillWidth: true
            Layout.topMargin: -layout.anchors.topMargin
            Layout.bottomMargin: layout.anchors.topMargin

            updatesAvailable: surveysModel.updatesAvailable
            busy: surveysRefresh.busy

            onClicked: {
                homeActionGroup.showDownloadPage(true);
            }

            onPressAndHold: {
                tab.debug = !tab.debug;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: layout.anchors.topMargin
            Layout.rightMargin: Layout.leftMargin

            spacing: 5 * AppFramework.displayScaleFactor
            layoutDirection: ControlsSingleton.localeProperties.layoutDirection

            SortButton {
                id: sortButton

                Layout.preferredHeight: searchField.height
                Layout.preferredWidth: Layout.preferredHeight

                sortType: delegateModel.sortType
                sortOrder: delegateModel.sortOrder

                onClicked: {
                    sortPopup.createObject(page).open();
                }
            }

            SearchField {
                id: searchField

                Layout.fillWidth: true

                focus: false

                scannerEnabled: true

                onTextChanged: {
                    searchUrlInfo.fromString(text);
                }

                onEntered: {
                    if (app.commandProcessor.parse(text)) {
                        text = "";
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: !galleryView.visible
        }

        GalleryView {
            id: galleryView

            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: model.count

            model: delegateModel


            progressBar {
                visible: surveysRefresh.busy
                value: surveysRefresh.progress
            }

            refreshHeader {
                enabled: surveysRefresh.enabled
                refreshing: surveysRefresh.busy
            }

            onRefresh: {
                surveysFolder.update();
                surveysRefresh.refresh();
            }

            onClicked: {
                var tileItem = model.get(index);

                switch (tileItem.tileType) {
                case tilesModel.kTileTypeAddIn:
                    addInSelected(tileItem);
                    break;

                case tilesModel.kTileTypeSurvey:
                    selected(app.surveysFolder.filePath(tileItem.path), false, -1, null, tileItem);
                    break;
                }
            }

            onPressAndHold: {
                var tileItem = model.get(index);

                switch (tileItem.tileType) {
                case tilesModel.kTileTypeAddIn:
                    break;

                case tilesModel.kTileTypeSurvey:
                    selected(app.surveysFolder.filePath(tileItem.path), true, -1, null, tileItem);
                    break;
                }
            }
        }

        NoSurveysView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            canDownload: !app.openParameters
            portal: app.portal
            visible: !galleryView.model.count && canDownload
            actionGroup: homeActionGroup
            searchText: tab.searchText
        }

        OpenParametersPanel {
            id: openParametersPanel

            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            portal: app.portal
            progressPanel: progressPanel

            onDownloaded: {
                console.log(logCategory, "Downloaded completed");
                var surveyToLoad = surveysToLoad.pop();
                if (surveyToLoad)
                {
                    console.log(logCategory, "Popped: ", JSON.stringify(surveyToLoad, undefined, 2));
                    processParameters(surveyToLoad);
                }
                else
                {
                    console.log(logCategory, "No more surveys to load");
                    Qt.callLater(surveysFolder.update);
                }
            }

            onCleared: {
                app.openParameters = null;
            }
        }
    }

    //--------------------------------------------------------------------------

    HomeActionGroup {
        id: homeActionGroup

        stackView: mainStackView
        showDownloadSurveys: true
        surveysModel: surveysModel
    }

    //--------------------------------------------------------------------------

    Component {
        id: tileDelegate

        Item {
            id: item

            property int _index: index
            property string _path: path
            property string _thumbnail: thumbnail
            property string _title: title
            property string _updateAvailable: updateAvailable

            Loader {
                id: loader

                property alias index: item._index
                property alias path: item._path
                property alias thumbnail: item._thumbnail
                property alias title: item._title
                property alias updateAvailable: item._updateAvailable

                asynchronous: false

                sourceComponent: {
                    var tileItem = model;
                    if (!tileItem) {
                        return;
                    }

                    switch (tileItem.tileType) {
                    case tilesModel.kTileTypeAddIn:
                        return addInTileDelegate;

                    case tilesModel.kTileTypeSurvey:
                        return surveyTileDelegate;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInTileDelegate

        GalleryDelegate {
            id: delegate

            galleryView: tab.galleryView

            clip: true

            background.clip: true

            Rectangle {
                parent: delegate.background

                anchors {
                    right: parent.right
                    rightMargin: -width / 2
                    bottom: parent.bottom
                    bottomMargin: -width / 2
                }

                width: 30 * AppFramework.displayScaleFactor

                height: width

                rotation: 45
                color: "#40000000"
                z: 999
            }

            onClicked: {
                galleryView.clicked(index);
            }

            onPressAndHold: {
                galleryView.pressAndHold(index);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyTileDelegate

        SurveysGalleryDelegate {
            galleryView: tab.galleryView
            debug: tab.debug
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sortPopup

        SortPopup {
            sortTypes: SortPopup.SortType.Alphabetical | SortPopup.SortType.Time

            sortType: delegateModel.sortType
            sortOrder: delegateModel.sortOrder

            onSortTypeChanged: {
                delegateModel.setSortProperty(sortType);
            }

            onSortOrderChanged: {
                delegateModel.sortOrder = sortOrder;
            }

            onClicked: {
                writeSettings();
            }
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel
    }

    //--------------------------------------------------------------------------
}
