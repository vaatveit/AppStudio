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
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../XForms/Singletons"
import "../Controls"
import "../Controls/Singletons"
import "../Portal"
import "../Models"
import "SurveyHelper.js" as Helper
import "../XForms/XForm.js" as XFormJS
import "../XForms/XFormGeometry.js" as Geometry
import "Singletons"


AppPage {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property string surveyPath
    property alias surveyInfo: surveyInfo
    property string surveyTitle: surveyInfo.title
    property var surveyInfoPage
    property int statusFilter: -1
    property int statusFilter2: statusFilter

    property alias surveyDataModel: surveyDataModel
    property alias surveysDatabase: surveyDataModel.surveysDatabase

    property var excludeFields: [
        "__meta__",
        "globalid", "objectid",
        "uniquerowid", "parentrowid", "parentglobalid"
    ];

    property string folderName: "<Folder Name>"
    property color folderColor: Survey.kColorFolderOverview
    property alias folderAction: folderAction
    property bool autoTriggerFolderAction: false

    property bool closeOnEmpty: false
    property string emptyMessage: qsTr("%1 is empty").arg(folderName)
    readonly property bool isSearch: surveyDataModel.count > 0 && filterInfo.isFiltered

    property alias schema: schema
    readonly property bool hasInstanceName: schema.schema.instanceName > ""

    property alias formSettings: formSettings
    property alias mapSettings: mapSettings
    property alias positionSourceConnection: positionSourceConnection

    property bool refreshEnabled: false

    property string autoAction
    property alias swipeTabView: swipeTabView
    readonly property bool isActive: QC1.Stack.status === QC1.Stack.Active

    property bool collectEnabled: true
    property bool inboxViewEnabled: false
    property bool inboxEditEnabled: true
    property bool inboxCopyEnabled: false
    property bool sentEditEnabled: true
    property bool sentCopyEnabled: true

    property bool showExtraInfo: false
    property bool showMap: XFormJS.toBoolean(surveyInfo.foldersInfo.showMap, true)
    property bool showCollect: false
    property alias showStatusIndicator: surveyDataListView.showStatusIndicator
    property alias showErrorIcon: surveyDataListView.showErrorIcon
    property bool showMapTab: showMap && !!schema.schema.geometryField
    property Map map
    property bool isMapActive: isSplitLayout && splitMapTab.visible
                               || isSwipeLayout && swipeMapTab.isCurrentItem

    property SurveyMapSources surveyMapSources
    property string mapKey: Survey.kFolderOverview

    property var parameters: ({})

    property bool initialized
    property bool refreshWhenActivated

    property alias logCategory: logCategory

    property bool debug: false

    property SearchField searchField
    property int highlightRowId: -1

    //--------------------------------------------------------------------------

    property real aspectRatioThreshold: 1.2
    readonly property int orientation: ((width / height) >= aspectRatioThreshold) ? Qt.Horizontal : Qt.Vertical

    readonly property string kStateSplit: "split"
    readonly property string kStateSwipe: "swipe"

    readonly property bool isSplitLayout: state == kStateSplit
    readonly property bool isSwipeLayout: state == kStateSwipe

    property real minimumSplitWidth: 800 * AppFramework.displayScaleFactor
    property real minimumSplitHeight: 800 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    readonly property string kKeyGlobalId: "globalid"
    readonly property string kKeyObjectId: "objectid"
    readonly property string kKeyAny: "*"

    readonly property string kSettingsGroup: mapKey + "/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    //--------------------------------------------------------------------------

    signal initializeParameters()
    signal refresh()
    signal refreshed()

    //--------------------------------------------------------------------------

    contentMargins: 0

    title: folderName
    enabled: isActive
    state: kStateSwipe

    //--------------------------------------------------------------------------

    states: [
        State {
            name: kStateSplit

            StateChangeScript {
                script: splitLayout()
            }
        },

        State {
            name: kStateSwipe

            StateChangeScript {
                script: swipeLayout()
            }
        }
    ]

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "surveyPath:", surveyPath);

        positionSourceConnection.start();

        collectEnabled = XFormJS.toBoolean(surveyInfo.collectInfo.enabled, true);
        inboxViewEnabled = XFormJS.toBoolean(surveyInfo.queryInfo.viewEnabled, false);
        inboxEditEnabled = XFormJS.toBoolean(surveyInfo.queryInfo.editEnabled, true);
        inboxCopyEnabled = XFormJS.toBoolean(surveyInfo.queryInfo.copyEnabled, false);
        sentEditEnabled = XFormJS.toBoolean(surveyInfo.sentInfo.editEnabled, true);
        sentCopyEnabled = XFormJS.toBoolean(surveyInfo.sentInfo.copyEnabled, true);

        if (parameters) {
            console.log(logCategory, "initializeParameters:", JSON.stringify(parameters, undefined, 2));
            initializeParameters();
        }

        var xml = surveyInfo.folder.readTextFile(AppFramework.resolvedPath(surveyPath));
        var json = AppFramework.xmlToJson(xml);

        schema.update(json, true);
        mapSettings.refresh(surveyInfo.folder.path, surveyInfo.info.displayInfo ? surveyInfo.info.displayInfo.map : null);

        checkLayout();

        refreshList();
    }

    //--------------------------------------------------------------------------

    onInitializeParameters: {
        console.log(logCategory, "onInitializeParameters folder:", mapKey);

        var action = Helper.getPropertyValue(parameters, Survey.kParameterAction, "").toLowerCase().trim();

        switch (action) {
        case Survey.kActionEdit:
        case Survey.kActionView:
        case Survey.kActionCopy:
            autoAction = action;
            break;
        }
    }

    //--------------------------------------------------------------------------

    onIsActiveChanged: {
        console.log(logCategory, "isActive:", isActive, "refreshWhenActivated:", refreshWhenActivated);

        if (isActive && refreshWhenActivated) {
            refreshWhenActivated = false;
            Qt.callLater(refreshList);
        }
    }

    //--------------------------------------------------------------------------

    onRefreshed: {
        console.log(logCategory, "onRefreshed initialized:", initialized, "autoAction:", autoAction, "autoTriggerFolderAction:", autoTriggerFolderAction, "folderAction.enabled:", folderAction.enabled);

        if (initialized) {
            if (autoAction) {
                Qt.callLater(checkAutoAction);
            }
        } else {
            initialized = true;

            if (autoTriggerFolderAction && folderAction.enabled) {
                autoTriggerFolderAction = false;
                folderAction.trigger();
            } else if (autoAction) {
                Qt.callLater(checkAutoAction);
            }
        }
    }

    //--------------------------------------------------------------------------

    //    onTitleClicked: {
    //        if (showMapTab) {
    //            state = isSwipeLayout ? kStateSplit : kStateSwipe;
    //        }
    //    }

    onTitlePressAndHold: {
        showExtraInfo = !showExtraInfo;
    }

    //--------------------------------------------------------------------------

    onWidthChanged: {
        Qt.callLater(checkLayout);
    }

    onHeightChanged: {
        Qt.callLater(checkLayout);
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: app.positionSourceManager
        listener: AppFramework.typeOf(page)
    }

    //--------------------------------------------------------------------------

    function checkAutoAction() {
        if (!autoAction) {
            return;
        }

        var model = listViewModel.filterGroup;

        console.log(logCategory, arguments.callee.name, "count:", model.count, "autoAction:", autoAction);

        if (model.count === 1) {
            var survey = model.get(0).model;

            switch (autoAction) {
            case Survey.kActionEdit:
                editSurvey(survey, false, false, true);
                break;

            case Survey.kActionCopy:
                editSurvey(survey, true, false, true);
                break;

            case Survey.kActionView:
                editSurvey(survey, false, true, true);
                break;
            }

            autoAction = "";
            Qt.callLater(searchField.clearSearch);
        }
    }

    //--------------------------------------------------------------------------

    function checkLayout() {
        if (!app.features.enableSxS) {
            return;
        }

        if (showMapTab && (width >= minimumSplitWidth || height >= minimumSplitHeight)) {
            state = kStateSplit;
            mapView.activate();
        } else {
            state = kStateSwipe;
        }
    }

    //--------------------------------------------------------------------------

    function splitLayout() {
        console.log(arguments.callee.name);

        listView.parent = splitListTab;
        mapView.parent = splitMapTab;
    }

    //--------------------------------------------------------------------------

    function swipeLayout() {
        console.log(arguments.callee.name);

        listView.parent = swipeListTab;
        mapView.parent = swipeMapTab;
    }

    //--------------------------------------------------------------------------

    function setMessage(text, color) {
        messageText.text = text;
        if (color !== undefined) {
            messageText.color = color;
        }
    }

    //--------------------------------------------------------------------------

    function sort() {
        console.log(logCategory, arguments.callee.name);

        listViewModel.sort();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    SurveyDataModel {
        id: surveyDataModel

        signal filtered()

        schema: page.schema

        extraProperties: ({
                              isVisible: true,
                              distance: 0
                          })

        Component.onCompleted: {
            filterInfo.filterUpdated.connect(invalidateFilter);
        }

        onRefreshed: {
            invalidateFilter();
        }

        onAdded: {
            filterItem(index);
        }

        onUpdated: {
            filterItem(index);
        }

        function invalidateFilter() {
            Qt.callLater(filter);
        }

        function filter() {
            console.time("dataFilter");

            for (var i = 0; i < count; i++) {
                var item = get(i);
                item.isVisible = filterInfo.filterItem(item);
            }

            console.timeEnd("dataFilter");

            filtered();
        }

        function filterItem(index) {
            var item = get(index);
            item.isVisible = filterInfo.filterItem(item);
        }
    }

    //--------------------------------------------------------------------------

    SortFilterDelegateModel {
        id: listViewModel

        debug: page.debug
        model: surveyDataModel
        delegate: surveyDataListView.surveyDelegate

        sortRole: sortInfo.sortProperty
        sortOrder: sortInfo.sortOrder
        sortCaseSensitivity: Qt.CaseInsensitive

        filterFunction: item => !!item.isVisible;

        Component.onCompleted: {
            surveyDataModel.filtered.connect(invalidateFilter);
        }

        function getSurvey(index) {
            if (index < 0 || index >= count) {
                if (debug) {
                    console.warn(logCategory, arguments.callee.name, "index:", index, "count:", count);
                }
                return;
            }

            return get(index);
        }
    }

    //--------------------------------------------------------------------------

    QtObject {
        id: sortInfo

        //----------------------------------------------------------------------

        readonly property int sortType: sortPropertyToType(sortProperty)
        property string sortProperty: surveyDataModel.kPropertyUpdated
        property int sortOrder: Qt.DescendingOrder

        property bool debug: page.debug

        //----------------------------------------------------------------------

        Component.onCompleted: {
            readSettings();
        }

        //----------------------------------------------------------------------

        function readSettings() {
            var settings = formSettings.settings;

            setSortProperty(settings.value(kSettingSortProperty, surveyDataModel.kPropertyUpdated));
            setSortOrder(settings.value(kSettingSortOrder, Qt.DescendingOrder));

            console.log(logCategory, arguments.callee.name,
                        "sortProperty:", sortProperty,
                        "sortOrder:", sortOrder);
        }

        //----------------------------------------------------------------------

        function writeSettings() {
            console.log(logCategory, arguments.callee.name,
                        "sortProperty:", sortProperty,
                        "sortOrder:", sortOrder);

            var settings = formSettings.settings;

            settings.setValue(kSettingSortProperty, sortProperty);
            settings.setValue(kSettingSortOrder, sortOrder);
        }

        //----------------------------------------------------------------------

        function sortPropertyToType(sortProperty) {
            switch (sortProperty) {
            case surveyDataModel.kPropertySnippet:
                return SortPopup.SortType.Alphabetical;

            case surveyDataModel.kPropertyUpdated:
                return SortPopup.SortType.Time;

            case surveyDataModel.kPropertyDistance:
                return SortPopup.SortType.Distance;
            }
        }

        //----------------------------------------------------------------------

        function setSortProperty(value) {
            var propertyName;

            switch (value) {
            case SortPopup.SortType.Alphabetical:
            case surveyDataModel.kPropertySnippet:
                propertyName = surveyDataModel.kPropertySnippet;
                break;

            case SortPopup.SortType.Time:
            case surveyDataModel.kPropertyUpdated:
                propertyName = surveyDataModel.kPropertyUpdated;
                break;

            case SortPopup.SortType.Distance:
            case surveyDataModel.kPropertyDistance:
                propertyName = surveyDataModel.kPropertyDistance;
                break;
            }

            if (propertyName) {
                sortProperty = propertyName;
            }
        }

        //----------------------------------------------------------------------

        function setSortOrder(value) {
            var _sortOrder = Qt.AscendingOrder;

            switch (value) {
            case Qt.AscendingOrder:
            case Qt.DescendingOrder:
                _sortOrder = value;
                break;

            default:
                if (value > "" && value.toString().toLocaleString().startsWith("d")) {
                    _sortOrder = Qt.DescendingOrder;
                }
                break;
            }

            sortOrder = _sortOrder;
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    QtObject {
        id: filterInfo

        //----------------------------------------------------------------------

        readonly property bool isFiltered: !!searchText
        property string filterProperty: surveyDataModel.kPropertySnippet
        property int filterCaseSensitivity: Qt.CaseInsensitive
        property string filterText
        property string filterKey
        property string filterValue
        property var filterPattern: new RegExp(filterText, filterCaseSensitivity == Qt.CaseInsensitive ? "i" : undefined);

        property string searchText: filterText
        property var valueParser

        property bool debug: page.debug

        //----------------------------------------------------------------------

        signal filterUpdated()

        //----------------------------------------------------------------------

        onFilterUpdated: {
            console.log(logCategory, "filterUpdated:", JSON.stringify(filterInfo, undefined, 2));
        }

        //----------------------------------------------------------------------

        function setFilter(text) {
            console.log(logCategory, arguments.callee.name, "text:", text);

            var filter = parseFilter(text);

            if (!filter) {
                filterKey = "";
                filterValue = "";
                valueParser = null;
                filterText = text;
                searchText = filterText;

                filterUpdated();

                return;
            }

            if (filter.key === kKeyGlobalId) {
                filterKey = kKeyAny;
            } else {
                filterKey = filter.key;
            }

            filterValue = filter.value;
            valueParser = filter.valueParser;
            filterText = text;
            searchText = filter.displayValue;

            filterUpdated();
        }

        //----------------------------------------------------------------------

        function filterItem(item) {
            //console.log(logCategory, "rowid:", item.rowid, "snippet:", item.snippet, "updated:", item.updated, "distance:", item.distance);

            if (!filterText) {
                return true;
            }

            if (filterKey > "" && filterValue > "") {
                return keySearch(item, filterKey, filterValue, valueParser);
            }

            if (defaultFilterFunction(item, filterPattern)) {
                return true;
            }

            if (dataSearch(item.data, filterPattern)) {
                return true;
            }
        }

        //----------------------------------------------------------------------

        function dataSearch(data) {
            if (!data) {
                return;
            }

            switch (typeof data) {
            case "string":
                return data.search(filterPattern) >= 0;

            case "object":
                break;

            case "number":
            case "boolean":
                return false;

            default:
                return data.toString().search(filterPattern) >= 0;
            }

            if (data instanceof Date) {
                return data.toString().search(filterPattern) >= 0;
            }

            if (Array.isArray(data)) {
                for (var i = 0; i < data.length; i++) {
                    if (dataSearch(data[i], filterPattern)) {
                        return true;
                    }
                }
            }

            var keys = Object.keys(data);
            for (i = 0; i < keys.length; i++) {
                if (!excludeFields.includes(keys[i].toLowerCase())) {
                    if (dataSearch(data[keys[i]], filterPattern)) {
                        return true;
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        function defaultFilterFunction(item) {
            var value = item[filterProperty];
            if (value > "" && value.search(filterPattern) >= 0) {
                return true;
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    function parseFilter(text) {
        var tokens = text.match(/(?:(globalid):\s*{?\(?\s*((?:[\da-f]{8})-(?:[\da-f]{4})-(?:[\da-f]{4})-(?:[\da-f]{4})-(?:[\da-f]{12}))\s*\)?}?\s*)|(?:(globalid):\s*([\da-f]{32}))|(?:(objectid):\s*(\d+))|(?:field:(\w+):(.+))/i);

        if (!Array.isArray(tokens)) {
            return;
        }

        var filter = {};

        if (debug) {
            console.log(logCategory, arguments.callee.name, "tokens:", JSON.stringify(tokens, undefined, 2));
        }

        for (var i = 1; i < tokens.length; i += 2) {
            if (!tokens[i]) {
                continue;
            }

            filter.key = tokens[i].toLowerCase();
            filter.value = tokens[i + 1];
            filter.displayValue = filter.value;
            filter.valueParser = null;

            switch (filter.key) {
            case kKeyGlobalId:
                filter.value = Helper.parseGuid(filter.value);
                filter.valueParser = Helper.parseGuid;
                filter.displayValue = "Global ID: %1".arg(filter.value);
                break;

            case kKeyObjectId:
                filter.displayValue = "Object ID: %1".arg(filter.value);
                break;

            default:
                filter.value = filter.value.toLowerCase();
                break;
            }

            break;
        }

        console.log(logCategory, arguments.callee.name, "filter:", JSON.stringify(filter, undefined, 2));

        if (!filter.key || !filter.value) {
            return;
        }

        return filter;
    }

    //--------------------------------------------------------------------------

    function keySearch(data, searchKey, searchValue, valueParser) {
        if (!data || typeof data !== "object") {
            return;
        }

        for (const [key, value] of Object.entries(data)) {
            if (value > "" && (searchKey === kKeyAny || searchKey === key.toLowerCase())) {
                if (valueParser) {
                    if (searchValue === valueParser(value)) {
                        return true;
                    }
                } else {
                    if (searchValue === value.toString().toLowerCase()) {
                        return true;
                    }
                }
            }
        }

        for (const [key, value] of Object.entries(data)) {
            if (typeof value === "object") {
                if (keySearch(value, searchKey, searchValue, valueParser)) {
                    return true;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo

        path: surveyPath

        onPathChanged: {
            formSettings.initialize(folder, fileInfo.baseName);
        }
    }

    XFormSchema {
        id: schema
    }

    XFormSettings {
        id: formSettings
    }

    XFormMapSettings {
        id: mapSettings

        includeDefaultMaps: surveyInfo.includeDefaultMaps
        sharedMapSources: app.mapSources
        linkedMapSources: page.surveyMapSources ? page.surveyMapSources.mapSources : null
        defaultMapName: app.properties.defaultBasemap
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        SplitTabView {
            id: splitTabView

            anchors.fill: parent

            visible: isSplitLayout

            dualView {
                orientation: page.orientation

                leftItem: splitListTab
                rightItem: splitMapTab
                topItem: splitMapTab
                bottomItem: splitListTab
            }

            readonly property int buttonCount: tabs.visibleCount + (folderAction.enabled ? 1 : 0)
            readonly property real buttonWidth: tabs.calculateWidth(footerLayout.width, footerSpacing, buttonCount)

            font.family: app.fontFamily
            color: app.backgroundColor

            tabs {
                selectedTextColor: Colors.contrastColor(footerBackground.color)
                textColor: Colors.contrastColor(footerBackground.color, "#888", "#eee")
                //selectedIndicatorColor: folderColor
                indicatorWidth: splitTabView.buttonWidth

                font {
                    pointSize: 12
                }
            }

            footerControl {
                visible: showMapTab || folderAction.enabled
            }

            footerSeparator {
                visible: true
                color: folderColor
            }

            footerBackground {
                color: app.backgroundColor
            }

            footerLayout.children: [
                Item {
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop

                    visible: folderAction.enabled

                    implicitHeight: splitIndicatorLayout.height + splitIndicatorLayout.anchors.topMargin * 2
                    implicitWidth: splitTabView.buttonWidth

                    Rectangle {
                        anchors.fill: parent

                        visible: splitActionMouseArea.containsMouse
                        radius: 5 * AppFramework.displayScaleFactor
                        color: splitTabView.tabs.textColor
                        opacity: 0.15
                    }

                    MouseArea {
                        id: splitActionMouseArea

                        anchors.fill: parent

                        enabled: folderAction.enabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onClicked: {
                            folderAction.trigger();
                        }
                    }

                    ColumnLayout {
                        id: splitIndicatorLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 2 * AppFramework.displayScaleFactor
                        }

                        spacing: 0

                        IconImage {
                            id: swipeActionImage

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: splitTabView.tabs.iconSize
                            Layout.preferredHeight: splitTabView.tabs.iconSize

                            icon {
                                name: folderAction.icon.name
                                source: folderAction.icon.source
                                color: splitTabView.tabs.selectedIconColor
                            }
                            rotation: folderAction.iconRotation

                            RotationAnimator {
                                target: swipeActionImage

                                from: 0
                                to: 360
                                duration: 2000
                                running: folderAction.checked
                                loops: Animation.Infinite

                                onFinished: {
                                    target.rotation = folderAction.iconRotation;
                                }
                            }

                            PulseAnimation {
                                target: swipeActionImage
                                running: folderAction.checkable
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            text: folderAction.text
                            elide: ControlsSingleton.localeProperties.textElide
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: splitTabView.tabs.selectedTextColor
                            font: splitTabView.tabs.font
                        }
                    }
                }
            ]

            SplitTab {
                id: splitListTab

                title: qsTr("List")
                icon.name: "list"
            }

            SplitTab {
                id: splitMapTab

                title: qsTr("Map")
                icon.name: "map"
                visible: showMapTab
            }
        }

        SwipeTabView {
            id: swipeTabView

            anchors.fill: parent

            visible: isSwipeLayout

            readonly property int buttonCount: tabs.visibleCount + (folderAction.enabled ? 1 : 0)
            readonly property real buttonWidth: tabs.calculateWidth(footerLayout.width, footerSpacing, buttonCount)

            font.family: app.fontFamily
            color: app.backgroundColor

            interactive: false

            tabs {
                visible: showMapTab

                selectedTextColor: Colors.contrastColor(footerBackground.color)
                textColor: Colors.contrastColor(footerBackground.color, "#888", "#eee")
                //selectedIndicatorColor: folderColor
                indicatorWidth: swipeTabView.buttonWidth

                font {
                    pointSize: 12
                }
            }

            footerControl {
                visible: showMapTab || folderAction.enabled
            }

            footerSeparator {
                visible: true
                color: folderColor
            }

            footerBackground {
                color: app.backgroundColor
            }

            footerLayout.children: [
                Item {
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop

                    visible: folderAction.enabled

                    implicitHeight: swipeIndicatorLayout.height + swipeIndicatorLayout.anchors.topMargin * 2
                    implicitWidth: swipeTabView.buttonWidth

                    Action {
                        id: folderAction

                        property real iconRotation: 0

                        enabled: false
                    }

                    Rectangle {
                        anchors.fill: parent

                        visible: swipeActionMouseArea.containsMouse
                        radius: 5 * AppFramework.displayScaleFactor
                        color: swipeTabView.tabs.textColor
                        opacity: 0.15
                    }

                    MouseArea {
                        id: swipeActionMouseArea

                        anchors.fill: parent

                        enabled: folderAction.enabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onClicked: {
                            folderAction.trigger();
                        }
                    }

                    ColumnLayout {
                        id: swipeIndicatorLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 2 * AppFramework.displayScaleFactor
                        }

                        spacing: 0

                        IconImage {
                            id: splitActionImage

                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: swipeTabView.tabs.iconSize
                            Layout.preferredHeight: swipeTabView.tabs.iconSize

                            icon {
                                name: folderAction.icon.name
                                source: folderAction.icon.source
                                color: swipeTabView.tabs.selectedIconColor
                            }
                            rotation: folderAction.iconRotation

                            RotationAnimator {
                                target: splitActionImage

                                from: 0
                                to: 360
                                duration: 2000
                                running: folderAction.checked
                                loops: Animation.Infinite

                                onFinished: {
                                    target.rotation = folderAction.iconRotation;
                                }
                            }

                            PulseAnimation {
                                target: splitActionImage
                                running: folderAction.checkable
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            text: folderAction.text
                            elide: ControlsSingleton.localeProperties.textElide
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: swipeTabView.tabs.selectedTextColor
                            font: swipeTabView.tabs.font
                        }
                    }
                }
            ]

            SwipeTab {
                id: swipeListTab

                title: qsTr("List")
                icon.name: "list"

                Item {
                    id: listView

                    anchors.fill: parent

                    Text {
                        anchors.fill: parent
                        visible: !surveyDataModel.count && !searchField.text

                        font {
                            pointSize: 24
                            family: app.fontFamily
                        }
                        color: textColor
                        text: emptyMessage
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    ColumnLayout {
                        anchors.fill: parent

                        visible: surveyDataModel.count > 0 || searchField.text > ""
                        spacing: 4 * AppFramework.displayScaleFactor

                        RowLayout {
                            id: toolsLayout

                            Layout.fillWidth: true
                            Layout.topMargin: 4 * AppFramework.displayScaleFactor
                            Layout.leftMargin: 4 * AppFramework.displayScaleFactor
                            Layout.rightMargin: Layout.leftMargin

                            //visible: surveyDataModel.count > 1
                            spacing: 5 * AppFramework.displayScaleFactor
                            layoutDirection: ControlsSingleton.localeProperties.layoutDirection

                            SortButton {
                                Layout.preferredHeight: searchField.height
                                Layout.preferredWidth: Layout.preferredHeight

                                sortType: sortInfo.sortType
                                sortOrder: sortInfo.sortOrder

                                onClicked: {
                                    sortPopup.createObject(page).open();
                                }
                            }

                            SearchField {
                                id: searchField

                                Layout.fillWidth: true

                                scannerEnabled: true

                                Component.onCompleted: {
                                    page.searchField = searchField;

                                    if (parameters && parameters.filter > "") {
                                        text = parameters.filter.trim();
                                        editingFinished();
                                    }
                                }

                                onEditingFinished: {
                                    if (textSource === "scanner") {
                                        autoAction = Survey.kActionEdit;
                                    }

                                    filterInfo.setFilter(text);
                                }

                                function clearSearch() {
                                    console.log(logCategory, arguments.callee.name);

                                    text = "";
                                    textSource = "";
                                    filterInfo.setFilter(text);
                                }
                            }

                            Item {
                                Layout.preferredHeight: searchField.height
                                Layout.preferredWidth: Layout.preferredHeight

                                visible: false
                            }
                        }


                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 4 * AppFramework.displayScaleFactor

                            visible: messageText.text > ""
                            layoutDirection: ControlsSingleton.localeProperties.layoutDirection
                            spacing: 4 * AppFramework.displayScaleFactor

                            StyledImageButton {
                                Layout.preferredHeight: 30 * AppFramework.displayScaleFactor
                                Layout.preferredWidth: Layout.preferredHeight

                                source: Icons.icon("exclamation-mark-triangle")
                                color: Survey.kColorWarning
                            }

                            AppText {
                                id: messageText

                                Layout.fillWidth: true
                                Layout.margins: 6 * AppFramework.displayScaleFactor

                                horizontalAlignment: ControlsSingleton.localeProperties.textAlignment
                                font {
                                    pointSize: ControlsSingleton.inputFont.pointSize
                                }
                            }

                            InputClearButton {
                                Layout.preferredHeight: 30 * AppFramework.displayScaleFactor
                                Layout.preferredWidth: Layout.preferredHeight

                                onClicked: {
                                    messageText.text = "";
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 2 * AppFramework.displayScaleFactor

                            Control {
                                id: scrollView

                                anchors.fill: parent

                                visible: surveyDataListView.model.count > 0

                                SurveyDataListView {
                                    id: surveyDataListView

                                    width: scrollView.availableWidth
                                    height: scrollView.availableHeight

                                    schema: page.schema
                                    model: listViewModel
                                    mapSettings: page.mapSettings
                                    positionSourceConnection: page.positionSourceConnection
                                    showZoomTo: showMapTab
                                    updateDistances: showMapTab && sortInfo.sortType === SortPopup.SortType.Distance
                                    isActive: page.isActive && (isSwipeLayout && swipeListTab.isCurrentItem || isSplitLayout && splitListTab.visible)
                                    showIds: showExtraInfo
                                    highlightRowId: page.highlightRowId

                                    Component.onCompleted: {
                                        page.refreshed.connect(surveyDataListView.refreshed);
                                    }

                                    onClicked: {
                                        surveyClicked(survey);
                                    }

                                    onPressAndHold: {
                                    }

                                    onZoomTo: {
                                        zoomToSurvey(survey);
                                    }

                                    onRouteTo: {
                                        page.routeTo(survey);
                                    }

                                    onDeleteSurvey: {
                                        showDeletePopup(survey);
                                    }

                                    onDistancesUpdated: {
                                        if (isActive && sortInfo.sortType === SortPopup.SortType.Distance) {
                                            sort();
                                        }
                                    }

                                    refreshHeader {
                                        enabled: refreshEnabled
                                        onRefresh: page.refresh();
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent

                                visible: surveyDataListView.model.count < 1

                                AppText {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 25 * AppFramework.displayScaleFactor
                                    Layout.rightMargin: Layout.leftMargin

                                    font {
                                        pointSize: 18
                                    }
                                    color: isSearch
                                           ? app.textColor
                                           : app.textColor

                                    text: isSearch
                                          ? qsTr("No results found for <b>%1</b>").arg(filterInfo.searchText)
                                          : emptyMessage

                                    horizontalAlignment: Text.AlignHCenter

                                }
                            }
                        }
                    }
                }
            }

            SwipeTab {
                id: swipeMapTab

                title: qsTr("Map")
                icon.name: "map"
                visible: showMapTab

                onIsCurrentItemChanged: {
                    if (isCurrentItem) {
                        mapView.activate();
                    }
                }

                Item {
                    id: mapView

                    anchors.fill: parent

                    function activate() {
                        Qt.callLater(() => {
                                         mapViewLoader.active = true;
                                     });
                    }

                    Loader {
                        id: mapViewLoader

                        anchors.fill: parent

                        active: false

                        sourceComponent: SurveyDataMapView {
                            formSettings: page.formSettings
                            mapSettings: page.mapSettings
                            mapKey: page.mapKey
                            positionSourceConnection: page.positionSourceConnection
                            showCollect: page.collectEnabled && page.showCollect
                            isActive: page.isActive && (isSwipeLayout && swipeMapTab.isCurrentItem || isSplitLayout && splitMapTab.visible)
                            surveyDataModel: page.surveyDataModel
                            highlightRowId: page.highlightRowId

                            Component.onCompleted: {
                                page.map = map;
                            }

                            onClicked: {
                                surveyClicked(survey);
                                surveyDataListView.positionAtSurvey(survey.rowid);
                                highlight(survey.rowid);
                            }

                            onPressAndHold: {
                                surveyPressAndHold(survey);
                                surveyDataListView.positionAtSurvey(survey.rowid);
                                highlight(survey.rowid);
                            }

                            collectOverlay {
                                onCollect: {
                                    startSurvey(geometry);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function refreshList() {
        console.log(logCategory, arguments.callee.name);

        highlightRowId = -1;

        sortInfo.readSettings();

        surveyDataModel.statusFilter = statusFilter;
        surveyDataModel.statusFilter2 = statusFilter2;
        surveyDataModel.refresh(surveyPath);

        if (surveyDataModel.count <= 0 && closeOnEmpty) {
            page.closePage();
            return;
        }

        if (isSplitLayout) {
            mapCall("initialize");
        }
    }

    //--------------------------------------------------------------------------

    function surveyClicked(survey) {
        switch (survey.status) {
        case XForms.Status.Inbox:
            editInbox(survey);
            break;

        case XForms.Status.Submitted:
            editSubmitted(survey);
            break;

        case XForms.Status.SubmitError:
            editSubmitError(survey);
            break;

        case XForms.Status.Complete:
            editComplete(survey);
            break;

        default:
            editSurvey(survey);
            break;
        }
    }

    //--------------------------------------------------------------------------

    function surveyPressAndHold(survey) {
        var popup = surveyActionsPopup.createObject(page,
                                                    {
                                                        survey: survey
                                                    });
        popup.open();
    }

    //--------------------------------------------------------------------------

    function editSurvey(survey, clone, readOnly, replace) {
        var name = survey.name;
        var path = survey.path;
        var rowid = survey.rowid;
        var data = survey.data;
        var status = survey.status;

        var surveyPath = Helper.resolveSurveyPath(path, surveysFolder);

        if (!surveyPath) {
            var popup = loadErrorPopup.createObject(page,
                                                    {
                                                        name: name
                                                    });
            popup.open();

            return;
        }

        var stripFields = [
                    "parentglobalid",
                    "uniquerowid",
                    "parentrowid"
                ];

        function stripMetaData(o) {
            if (!o || (typeof o !== "object")) {
                return;
            }

            var keys = Object.keys(o);

            keys.forEach(function (key) {

                if (key === "__meta__") { // kKeyMetadata
                    var metaData = o[key];
                    var metaKey = metaData["globalIdField"]; // kMetaGlobalIdField
                    if (metaKey) {
                        console.log("Remove meta data value:", metaKey, "=", o[metaKey]);
                        o[metaKey] = undefined;
                    }

                    metaKey = metaData["objectIdField"]; // kMetaObjectIdField
                    if (metaKey) {
                        console.log("Remove meta data value:", metaKey, "=", o[metaKey]);
                        o[metaKey] = undefined;
                    }

                    o[key] = undefined;
                    return;
                }

                // TODO Need more reliable check for this or do it within the form

                stripFields.forEach(function (name) {
                    if (key === name) {
                        console.log("Remove data value:", name, "=", o[name]);
                        o[name] = undefined;
                    }
                });

                var value = o[key];

                if (Array.isArray(value)) {
                    value.forEach(function (e) {
                        stripMetaData(e);
                    });
                    return;
                }

                if (typeof value === "object") {
                    stripMetaData(value);
                }
            });
        }

        function clearFields(table, tableData) {
            console.log("Clearing:", table.name);

            for (var i = 0; i < table.fields.length; i++) {
                var field = table.fields[i];

                switch (field.type) {
                case "binary":
                    console.log("Clearing field:", field.name, "type:", field.type);
                    tableData[field.name] = undefined;
                    break;
                }
            }

            table.relatedTables.forEach(function (relatedTable) {
                var rows = tableData[table.name];
                if (Array.isArray(rows)) {
                    console.log("Clearing relatedTable:", relatedTable.name, "#rows:", rows.length);
                    rows.forEach(function (rowData) {
                        clearFields(relatedTable, rowData);
                    });
                }
            });
        }

        if (clone) {
            rowid = -1;
            status = -1;
            console.log("Removing meta and instance unique data from:", JSON.stringify(data, undefined, 2));

            stripMetaData(data);

            console.log("copied data:", JSON.stringify(data, undefined, 2));

            clearFields(schema.schema, data[schema.schema.name]);
        }

        console.log("editSurvey:", surveyPath, "rowid:", rowid, "name:", name, "path:", path, "data:", JSON.stringify(data, undefined, 2));

        var itemInfo = {
            item: surveyView,
            replace: !!replace,
            properties: {
                surveyPath: surveyPath,
                surveyInfoPage: surveyInfoPage,
                rowid: rowid,
                rowData: data,
                rowStatus: status,
                isCurrentFavorite: survey.favorite > 0,
                readOnly: !!readOnly
            }
        };

        // Only re-use map sources if folder page is not being replaced
        if (!itemInfo.replace) {
            itemInfo.properties.surveyMapSources = page.surveyMapSources;
        }

        page.QC1.Stack.view.push(itemInfo);

        refreshWhenActivated = true;
    }

    //--------------------------------------------------------------------------

    function startSurvey(geometry) {
        console.log(logCategory, arguments.callee.name, "geometry:", JSON.stringify(geometry, undefined, 2));

        page.QC1.Stack.view.push({
                                     item: surveyView,
                                     replace: false,
                                     properties: {
                                         surveyPath: surveyPath,
                                         surveyInfoPage: surveyInfoPage,
                                         surveyMapSources: page.surveyMapSources,
                                         rowid: null,
                                         parameters: {
                                             center: "%1,%2".arg(geometry.y).arg(geometry.x)
                                         }
                                     }
                                 });

        refreshWhenActivated = true;
    }

    //--------------------------------------------------------------------------

    function zoomToSurvey(survey) {
        if (mapViewLoader.status === Loader.Ready) {
            console.log(logCategory, arguments.callee.name, "ready");
            mapViewLoader.item.zoomTo(survey);
        } else {
            console.log(logCategory, arguments.callee.name, "load");
            mapViewLoader.loaded.connect(function() {
                Qt.callLater(mapViewLoader.item.zoomTo, survey);
            });
        }

        swipeTabView.currentIndex = 1;

        highlight(survey.rowid);
    }

    //--------------------------------------------------------------------------

    function zoomToExtent() {
        mapCall("zoomToExtent");
    }

    //--------------------------------------------------------------------------

    function mapCall(functionName, ...parameters) {
        if (mapViewLoader.status === Loader.Ready) {
            mapViewLoader.item[functionName](...parameters);
        } else {
            mapViewLoader.loaded.connect(function() {
                Qt.callLater(mapViewLoader.item[functionName], ...parameters);
            });
            mapView.activate();
        }
    }

    //--------------------------------------------------------------------------

    function highlight(rowid) {
        highlightRowId = -1;

        if (rowid >= 0) {
            Qt.callLater(() => {
                             highlightRowId = rowid;
                         });
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: loadErrorPopup

        MessagePopup {
            property string name

            title: qsTr("Load Error")
            text: qsTr("Unable to load survey <b>%1</b>.").arg(name)

            standardIcon: StandardIcon.Critical
            standardButtons: StandardButton.Ok
        }
    }

    //--------------------------------------------------------------------------

    function editComplete(survey) {
        var popup = editCompletePopup.createObject(page,
                                                   {
                                                       survey: survey
                                                   });
        popup.open();
    }

    Component {
        id: editCompletePopup

        MessagePopup {
            property var survey

            title: qsTr("Completed Survey")
            informativeText: survey.snippet || ""
            prompt: qsTr("Do you want to edit this survey?")

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.No

            onYes: {
                editSurvey(survey);
            }
        }
    }

    //--------------------------------------------------------------------------

    function editInbox(survey) {
        if (!inboxEditEnabled && !inboxCopyEnabled) {
            editSurvey(survey, false, true);
        } else if (inboxEditEnabled && !inboxViewEnabled && !inboxCopyEnabled) {
            editSurvey(survey);
        } else if (inboxCopyEnabled && !inboxViewEnabled && !inboxEditEnabled) {
            editSurvey(survey, true);
        } else {
            var popup = editInboxPopup.createObject(page,
                                                    {
                                                        survey: survey
                                                    });
            popup.open();
        }
    }

    Component {
        id: editInboxPopup

        ActionsPopup {
            property var survey

            icon.name: "inbox"

            title: qsTr("Inbox Survey")
            informativeText: survey ? survey.snippet || "" : ""

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            Action {
                enabled: inboxViewEnabled
                text: qsTr("View")
                icon.name: "view-visible"

                onTriggered: {
                    close();
                    editSurvey(survey, false, true);
                }
            }

            Action {
                enabled: inboxEditEnabled
                text: qsTr("Edit")
                icon.name: "edit-attributes"

                onTriggered: {
                    close();
                    editSurvey(survey);
                }
            }

            Action {
                enabled: inboxCopyEnabled
                text: qsTr("Copy data to a new survey")
                icon.name: "copy"

                onTriggered: {
                    close();
                    editSurvey(survey, true);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function editSubmitted(survey) {
        if (!sentEditEnabled && !sentCopyEnabled) {
            editSurvey(survey, false, true);

            return;
        }

        var popup = editSubmittedPopup.createObject(page,
                                                    {
                                                        survey: survey
                                                    });
        popup.open();
    }

    Component {
        id: editSubmittedPopup

        ActionsPopup {
            property var survey

            icon {
                name: "send"
            }

            title: qsTr("Sent Survey")
            informativeText: survey.snippet || ""

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            Action {
                text: qsTr("View")
                icon.name: "view-visible"

                onTriggered: {
                    close();
                    editSurvey(survey, false, true);
                }
            }

            Action {
                enabled: sentEditEnabled
                text: qsTr("Edit and resend")
                icon.name: "edit-attributes"

                onTriggered: {
                    close();
                    editSurvey(survey);
                }
            }

            Action {
                enabled: collectEnabled && sentCopyEnabled
                text: qsTr("Copy sent data to a new survey")
                icon.name: "copy"

                onTriggered: {
                    close();
                    editSurvey(survey, true);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function editSubmitError(survey) {
        var error = JSON.parse(survey.statusText);

        if (!error) {
            error = {
                message: survey.statusText > "" ? survey.statusText : qsTr("Unknown error")
            };
        } else {
            if (Array.isArray(error)) {
                error = error[0];
            }
        }

        console.log("error:", JSON.stringify(error, undefined, 2));

        var message = "";

        if (error.message) {
            message = error.message;
        } else if (error.description) {
            message = error.description;
        }

        var detailedText = message

        if (Array.isArray(error.adds)) {
            error.adds.forEach(function(add) {
                if (add.result.error){
                    detailedText += "\r\nAdd error code %1 - %2".arg(add.result.error.code).arg(add.result.error.description);
                }
            });
        }

        if (Array.isArray(error.updates)) {
            error.updates.forEach(function(update) {
                if (update.result.error) {
                    detailedText += "\r\nUpdate error code %1 - %2".arg(update.result.error.code).arg(update.result.error.description);
                }
            });
        }

        /*
        if (error.details) {
            error.details.forEach(function (detail) {
                if (detailedText > "") {
                    detailedText += "\r\n";
                }

                detailedText += detail;
            });
        }
        */

        var informativeText = survey.snippet || "";

        var popup = editSubmitErrorPopup.createObject(page,
                                                      {
                                                          survey: survey,
                                                          informativeText: informativeText,
                                                          detailedText: detailedText
                                                      });

        popup.open();
    }

    Component {
        id: editSubmitErrorPopup

        MessagePopup {
            property var survey

            title: qsTr("Send Error")
            text: qsTr("This survey could not be sent due to the following error:")
            prompt: qsTr("Do you want to edit this survey?")

            standardIcon: StandardIcon.Critical
            standardButtons: StandardButton.Yes | StandardButton.No

            onYes: {
                editSurvey(survey);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sortPopup

        SortPopup {
            sortTypes: SortPopup.SortType.Alphabetical
                       | (surveyDataModel.hasDateValues ? SortPopup.SortType.Time : 0)
                       | (showMapTab ? SortPopup.SortType.Distance : 0)

            sortType: sortInfo.sortType
            sortOrder: sortInfo.sortOrder

            onSortTypeChanged: {
                sortInfo.setSortProperty(sortType);
            }

            onSortOrderChanged: {
                sortInfo.setSortOrder(sortOrder);
            }

            onClicked: {
                sortInfo.writeSettings();
            }
        }
    }

    //--------------------------------------------------------------------------

    function routeTo(rowData, handler) {
        if (!rowData) {
            console.warn(logCategory, arguments.callee.name, "Empty data");
            return;
        }

        var geometry = rowData.geometry;
        if (!geometry) {
            geometry = surveyDataModel.dataGeometry(rowData.data);

            if (!geometry) {
                console.warn(logCategory, arguments.callee.name, "Empty geometry");
                return;
            }
        }

        var coordinate;

        if (surveyDataModel.isPointGeometry) {
            coordinate = geometry.coordinate;
        } else {
            coordinate = Geometry.nearestOnPath(geometry.shape, surveyDataListView.currentCoordinate);
        }

        if (!coordinate || !coordinate.isValid) {
            console.warn(logCategory, arguments.callee.name, "Invalid coordinate:", coordinate);
            return;
        }

        console.log(logCategory, arguments.callee.name, "coordinate:", coordinate);

        function _routeTo(handler) {
            var scheme = app.info.value("urlScheme") || "";
            var callbackUrl = "%1://".arg(scheme);
            var callbackPrompt = app.info.title;
            var url = handler(coordinate, callbackUrl, callbackPrompt);

            console.log(logCategory, arguments.callee.name, "url:", url);

            Qt.openUrlExternally(url);
        }

        if (handler) {
            _routeTo(handler);
        } else {
            var popup = routeToPopup.createObject(page,
                                                  {
                                                      toCoordinate: coordinate,
                                                      snippet: rowData.snippet || ""
                                                  });
            popup.routeToHandler.connect(_routeTo)
            popup.open();
        }
    }

    //--------------------------------------------------------------------------

    function showDeletePopup(survey) {
        var popup = deletePopup.createObject(page,
                                             {
                                                 survey: survey
                                             });
        popup.open();
    }

    //--------------------------------------------------------------------------

    function deleteSurvey(survey) {
        var rowid = survey.rowid;

        console.log(logCategory, arguments.callee.name, "rowid:", rowid);

        surveysDatabase.deleteSurvey(rowid);

        if (surveyDataModel.count <= 0) {
            closePage();
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: deletePopup

        MessagePopup {
            property var survey

            title: qsTr("Delete Record")
            text: qsTr("The survey record will be deleted from this device.")
            informativeText: survey ? survey.snippet || "" : ""

            standardIcon: StandardIcon.Warning
            standardButtons: StandardButton.Yes | StandardButton.Cancel

            yesAction {
                icon {
                    source: Icons.icon("trash")
                    color: Survey.kColorWarning
                }
                text: qsTr("Delete")
            }

            onYes: {
                deleteSurvey(survey);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: routeToPopup

        RouteToPopup {
            property string coordinateText: XFormJS.formatCoordinate(toCoordinate, mapSettings.coordinateFormat)
            property string snippet

            icon.source: surveyDataListView.kIconRouteTo
            fromCoordinate: surveyDataListView.currentCoordinate
            text: coordinateText
            informativeText: snippet
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyActionsPopup

        MessagePopup {
            id: popup

            property var survey

            standardIcon: StandardIcon.Question
            title: qsTr("Survey Action")
            informativeText: survey.snippet || ""

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            Action {
                enabled: surveyDataListView.checkDelete(survey.status)
                text: qsTr("Delete")
                icon {
                    name: "trash"
                    color: Survey.kColorWarning
                }

                onTriggered: {
                    showDeletePopup(survey);
                }
            }

            Action {
                enabled: surveyDataListView.showZoomTo
                text: qsTr("Zoom to")
                icon.name: "zoom-to-object"

                onTriggered: {
                    zoomToSurvey(survey);
                }
            }

            Action {
                enabled: surveyDataListView.showRouteTo
                text: qsTr("Go to")
                icon.source: surveyDataListView.kIconRouteTo

                onTriggered: {
                    routeTo(survey);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
