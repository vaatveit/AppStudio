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
import ArcGIS.AppFramework.Platform 1.0

import "../Portal"
import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "../Models"

import "../template/SurveyHelper.js" as Helper


AppPage {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property bool downloaded: false
    property int updatesAvailable: 0
    property var updateIds: []
    property bool updatesFilter: false

    property var hasSurveysPage
    property Component noSurveysPage
    property bool debug: false

    property Settings settings: app.settings

    readonly property string kSettingsGroup: "DownloadSurveys/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    property color textColor: "#323232"
    property color iconColor: "#505050"
    property real buttonSize: 30 * AppFramework.displayScaleFactor

    property SurveysModel surveysModel

    readonly property bool signedIn: portal.signedIn

    //--------------------------------------------------------------------------

    backPage: surveysFolder.forms.length > 0 ? hasSurveysPage : noSurveysPage
    title: updatesFilter
           ? qsTr("Update Member Form")  // BPDS changed text from "Update Surveys"
           : qsTr("Download Member Form")    // BPDS changed text from "Download Surveys"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        readSettings();

        console.log(logCategory, "signedIn:", signedIn, "updatesFilter:", updatesFilter);
        if (signedIn || updatesFilter) {
            itemsModel.update();
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        writeSettings();

        surveysFolder.update();
        surveysModel.updateUpdatesAvailable();
    }

    //--------------------------------------------------------------------------

    onSignedInChanged: {
        if (signedIn) {
            itemsModel.update();
        }
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        listView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        debug = !debug;
    }

    //--------------------------------------------------------------------------

    onUpdatesFilterChanged: {
        delegateModel.invalidateFilter();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Rectangle {
            id: listArea

            anchors.fill: parent

            color: "transparent" //"#40ffffff"
            radius: 10

            Column {
                anchors {
                    fill: parent
                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 10 * AppFramework.displayScaleFactor
                visible: itemsModel.count == 0 && !searchRequest.active && signedIn

                AppText {
                    width: parent.width
                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: qsTr('<center>There are no surveys shared with <b>%2</b>.<br>%1</center>').arg(portal.user.username).arg(portal.user.fullName)
                    textFormat: Text.RichText

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                AppButton {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Refresh")
                    iconSource: Icons.bigIcon("refresh")
                    textPointSize: 16

                    onClicked: {
                        search();
                    }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                visible: itemsModel.count > 0

                RowLayout {
                    id: toolsLayout

                    Layout.fillWidth: true

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

                        busy: searchRequest.busy

                        progressBar {
                            visible: searchRequest.active && searchRequest.total > 0
                            value: searchRequest.count
                            from: 0
                            to: searchRequest.total
                        }

                        onEditingFinished: {
                            delegateModel.filterValue = text;
                        }

                        onCancel: {
                            searchRequest.cancel();
                        }
                    }

                    Item {
                        Layout.preferredHeight: searchField.height
                        Layout.preferredWidth: Layout.preferredHeight

                        StyledImageButton {
                            id: filterButton

                            anchors.fill: parent

                            visible: signedIn
                            checkable: true
                            checked: updatesFilter
                            checkedColor: page.headerBarColor

                            source: Icons.icon("filter", checked)
                            padding: sortButton.padding

                            onClicked: {
                                updatesFilter = !updatesFilter;
                            }
                        }
                    }
                }

                ListView {
                    id: listView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: delegateModel
                    spacing: 10 * AppFramework.displayScaleFactor
                    clip: true

                    move: Transition {
                        NumberAnimation {
                            properties: "x,y"
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "x,y"
                        }
                    }

                    RefreshHeader {
                        enabled: !searchRequest.active && signedIn
                        refreshing: searchRequest.active

                        onRefresh: {
                            search();
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        parent: listView

                        policy: ScrollBar.AsNeeded

                        anchors {
                            top: listView.top
                            right: parent.right
                            rightMargin: -5 * AppFramework.displayScaleFactor
                            bottom: listView.bottom
                        }

                        padding: 0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: -(page.contentMargins + 2 * AppFramework.displayScaleFactor)
                    Layout.rightMargin: Layout.leftMargin
                    Layout.bottomMargin: Layout.leftMargin
                    Layout.topMargin: page.contentMargins

                    implicitHeight: footerLayout.height + 2 * page.contentMargins

                    visible: portal.isOnline && (updatesAvailable > 0 || searchRequest.total > 0)

                    color: "#eee"

                    HorizontalSeparator {
                        id: updateSeparator

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        opacity: 0.5
                    }

                    RowLayout {
                        id: footerLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: page.contentMargins
                            verticalCenter: parent.verticalCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            visible: debug
                        }

                        AppButton {
                            id: updateButton

                            Layout.alignment: Qt.AlignHCenter

                            visible: updatesAvailable > 0
                            enabled: !searchRequest.active

                            text: qsTr("Download updates: %1").arg(updatesAvailable)
                            textPointSize: 15

                            iconSource: Icons.bigIcon("refresh")

                            onClicked: {
                                updateAll();
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            visible: debug

                            AppText {
                                anchors.fill: parent

                                visible: searchRequest.total > 0 && searchRequest.active || countMouseArea.containsMouse

                                text: searchRequest.active
                                      ? "%1/%2".arg(searchRequest.count).arg(searchRequest.total)
                                      : delegateModel.count == itemsModel.count
                                        ? itemsModel.count
                                        : "%1/%2".arg(delegateModel.count).arg(itemsModel.count)

                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter

                                font {
                                    pointSize: 11
                                    italic: searchRequest.active
                                }
                            }

                            MouseArea {
                                id: countMouseArea

                                anchors.fill: parent

                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            visible: searchRequest.active && itemsModel.count == 0
            color: page.backgroundColor

            AppText {
                id: searchingText

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                text: qsTr("Searching for surveys")
                color: "darkgrey"
                font {
                    pointSize: 18
                }
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            AppBusyIndicator {
                anchors {
                    top: searchingText.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 10 * AppFramework.displayScaleFactor
                }

                running: parent.visible
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: itemsModel

        dynamicRoles: true

        function findByKeyValue(key, value) {
            for (var i = 0; i < count; i++) {
                if (get(i)[key] === value) {
                    return i;
                }
            }

            return -1;
        }


        function update() {
            updatesAvailable = 0;
            updateIds = [];
            updateLocalPaths();

            searchRequest.start();
        }

        function updateLocalPaths() {
            for (var i = 0; i < count; i++) {
                updateLocalPath(get(i));
            }
        }

        function updateLocalPath(item) {
            item.isLocal = surveysFolder.fileExists(item.id);

            if (item.isLocal) {
                item.path = findForm(surveysFolder.folder(item.id));
            }
        }

        function updateItem(itemInfo) {
            var index = findByKeyValue("id", itemInfo.id);
            if (index >= 0) {
                var item = Helper.removeArrayProperties(itemInfo);

                item.updateAvailable = false;
                item.isLocal = true;
                item.path = findForm(surveysFolder.folder(itemInfo.id));

                set(index, item);
            }

            index = surveysModel.findByKeyValue("itemId", itemInfo.id);
            if (index >= 0) {
                surveysModel.setProperty(index, "itemModified", itemInfo.modified);
                surveysModel.setProperty(index, "updateAvailable", false);
            }
        }

        function findForm(folder) {
            var path;

            var files = folder.fileNames("*", true);
            files.forEach(function(fileName) {
                if (folder.fileInfo(fileName).suffix === "xml") {
                    path = folder.filePath(fileName);
                }
            });

            return path;
        }
    }

    //--------------------------------------------------------------------------

    SortFilterDelegateModel {
        id: delegateModel

        //----------------------------------------------------------------------

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyDate: "modified"

        readonly property int sortType: sortRoleToType(sortRole)

        //----------------------------------------------------------------------

        model: itemsModel
        delegate: surveyDelegateComponent

        sortRole: kPropertyDate
        sortOrder: Qt.DescendingOrder

        filterRole: kPropertyTitle
        filterFunction: filterItem

        //----------------------------------------------------------------------

        function filterItem(item) {
            if (updatesFilter && !item.updateAvailable) {
                return;
            }

            return _filterFunction(item);
        }

        //----------------------------------------------------------------------

        function sortRoleToType(role) {
            switch (role) {
            case kPropertyTitle:
                return SortPopup.SortType.Alphabetical;

            case kPropertyDate:
                return SortPopup.SortType.Time;
            }
        }

        //----------------------------------------------------------------------

        function setSortRole(value) {
            var role;

            switch (value) {
            case SortPopup.SortType.Alphabetical:
            case kPropertyTitle:
                role = kPropertyTitle;
                break;

            case SortPopup.SortType.Time:
            case kPropertyDate:
                role = kPropertyDate;
                break;
            }

            if (role) {
                sortRole = role;
            }
        }
    }

    //--------------------------------------------------------------------------

    PortalSearch {
        id: searchRequest

        property var idList
        property bool busy

        portal: page.portal
        sortField: delegateModel.sortRole
        sortOrder: delegateModel.sortOrder
        num: 50

        onResults: {
            results.forEach(function (result) {
                appendSurvey(result);
            });

            searchNext();
        }

        onFinished: {
            if (!cancelled && updateQuery()) {
                search();
            } else {
                busy = false;
            }
        }

        function start() {
            itemsModel.clear();

            updatesAvailable = 0;
            updateIds = [];
            idList = buildIdList();

            if (updateQuery()) {
                busy = true;
                search();
            }
        }

        function updateQuery() {
            var query = "";
            var idCount = 0;

            if (Array.isArray(idList)) {
                while (idList.length > 0 && idCount < num) {
                    if (idCount) {
                        query += " OR ";
                    }

                    query += "id:%1".arg(idList.shift());
                    idCount++;
                }

                if (idCount) {
                    if (debug) {
                        console.log(logCategory, arguments.callee.name, "idCount:", idCount, "query:", query);
                    }

                    q = query;
                    return idCount;
                }
            } else {
                return 0;
            }

            idList = null;

            if (signedIn) {
                query = portal.user.orgId > ""
                        ? '((NOT access:public) OR orgid:%1)'.arg(portal.user.orgId)
                        : 'NOT access:public';

                query += ' AND ((type:Form AND NOT tags:"draft" AND NOT typekeywords:draft) OR (type:"Code Sample" AND typekeywords:XForms AND tags:"xform"))';

                if (debug) {
                    console.log(logCategory, arguments.callee.name, "query:", query);
                }

                q = query;
                return -1;
            }

            q = "";
            return 0;
        }

        function buildIdList() {
            console.log(arguments.callee.name, "surveys:", surveysModel.count);

            var ids = [];

            for (var i = 0; i < surveysModel.count; i++) {
                var survey = surveysModel.get(i);
                if (survey.itemId > "" && (signedIn || survey.access === "public")) {
                    ids.push(survey.itemId);
                }
            }

            if (debug) {
                console.log(arguments.callee.name, "ids:", ids.length);
            }

            return ids;
        }

        function appendSurvey(itemInfo) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "id:", itemInfo.id, itemInfo.title);
            }

            if (itemsModel.findByKeyValue("id", itemInfo.id) >= 0) {
                return;
            }

            itemInfo.updateAvailable = false;
            itemInfo.isLocal = surveysFolder.fileExists(itemInfo.id);

            if (itemInfo.isLocal) {
                itemInfo.path = itemsModel.findForm(surveysFolder.folder(itemInfo.id));

                var surveysIndex = surveysModel.findByKeyValue("itemId", itemInfo.id);
                if (surveysIndex >= 0 && itemInfo.modified > surveysModel.get(surveysIndex).itemModified) {
                    itemInfo.updateAvailable = true;

                    updatesAvailable++;
                    updateIds.push(itemInfo.id);

                    surveysModel.setProperty(surveysIndex, "updateAvailable", true);
                }
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "isLocal:", itemInfo.isLocal, "updateAvailable:", itemInfo.updateAvailable, "id:", itemInfo.id, itemInfo.title);
            }

            itemsModel.append(Helper.removeArrayProperties(itemInfo));
        }
    }

    //--------------------------------------------------------------------------

    function search() {
        itemsModel.update();
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        delegateModel.setSortRole(settings.value(kSettingSortProperty, delegateModel.kPropertyDate));
        delegateModel.setSortOrder(settings.value(kSettingSortOrder, Qt.DescendingOrder));
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        settings.setValue(kSettingSortProperty, delegateModel.sortRole);
        settings.setValue(kSettingSortOrder, delegateModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyDelegateComponent

        SwipeLayoutDelegate {
            id: surveyDelegate

            //            property var surveyPath: index >= 0 ? listView.model.get(index).path : ""
            //            property var localSurvey: index >= 0 ? listView.model.get(index).isLocal : false
            //property var surveyPath: index >= 0 ? itemsModel.get(index).path : ""
            //property var localSurvey: index >= 0 ? itemsModel.get(index).isLocal : false

            implicitWidth: ListView.view.width

            ThumbnailImage {
                id: thumbnailImage

                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor

                Layout.preferredHeight: Layout.preferredWidth * 133/200

                defaultThumbnail: "images/default-survey-thumbnail.png"
                url: portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + id + "/info/" + thumbnail)
            }

            ColumnLayout {
                Layout.fillWidth: true

                AppText {
                    Layout.fillWidth: true

                    text: title
                    font {
                        pointSize: 16 * app.textScaleFactor
                        italic: debug && updateAvailable
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                }

                //                                Text {
                //                                    width: parent.width
                //                                    text: modelData.snippet > "" ? modelData.snippet : ""
                //                                    font {
                //                                        pointSize: 12
                //                                    }
                //                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                //                                    color: textColor
                //                                    visible: text > ""
                //                                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Modified: %1").arg(localeProperties.formatDateTime(new Date(modified), Locale.ShortFormat))

                    font {
                        pointSize: 11 * app.textScaleFactor
                    }
                    textFormat: Text.AutoText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: "#7f8183"
                }
            }

            StyledImageButton {
                id: downloadButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: Layout.preferredWidth

                icon.name: isLocal ? "refresh" : "download"
                color: iconColor

                onClicked: {
                    downloadSurvey.download(listView.model.get(index), isLocal);
                }
            }

            StyledImage {
                Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                visible: false //delegate.swipe.position === 0

                source: Icons.icon("ellipsis")
                color: app.textColor
            }

            /*
            behindLayout: SwipeBehindLayout {
                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image.source: Icons.bigIcon("map")

                    onClicked: {
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }
                    backgroundColor: "tomato"

                    onClicked: {
                        confirmDelete(index);
                    }
                }
            }
            */
        }
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurvey

        portal: page.portal
        progressPanel: progressPanel
        debug: page.debug
        succeededPrompt: false

        onSucceeded: {
            page.downloaded = true;
            itemsModel.updateItem(itemInfo);

            var index = updateIds.indexOf(itemInfo.id);
            if (index >= 0) {
                updateIds.splice(index, 1);
                updatesAvailable = updateIds.length;
            }

            if (!searchRequest.active) {
                if (updatesFilter) {
                    delegateModel.invalidateFilter();
                } else {
                    delegateModel.invalidate();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        onVisibleChanged: {
            Platform.stayAwake = visible;
        }
    }

    //--------------------------------------------------------------------------

    function updateAll() {
        downloadSurveys.downloadNext();
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurveys

        portal: page.portal
        progressPanel: progressPanel
        debug: page.debug
        succeededPrompt: false

        onSucceeded: {
            updatesAvailable = updateIds.length;

            itemsModel.updateItem(itemInfo);

            if (!downloadNext()) {
                page.downloaded = true;

                if (updatesFilter) {
                    page.closePage();
                } else {
                    delegateModel.invalidate();
                }
            }
        }

        function downloadNext() {
            if (updateIds.length < 1) {
                return;
            }

            var itemId = updateIds.shift();

            console.log(logCategory, "Downloading itemId:", itemId);

            var index = itemsModel.findByKeyValue("id", itemId);
            if (index < 0) {
                console.error(logCategory, "Not found itemId:", itemId);
                return;
            }

            var info = itemsModel.get(index);
            download(info);

            return info;
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
                delegateModel.setSortRole(sortType);
            }

            onSortOrderChanged: {
                delegateModel.setSortOrder(sortOrder);
            }
        }
    }

    //--------------------------------------------------------------------------
}
