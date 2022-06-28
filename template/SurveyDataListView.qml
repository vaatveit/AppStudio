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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../XForms/Singletons"
import "../XForms/XForm.js" as XFormJS
import "../XForms/XFormGeometry.js" as Geometry
import "SurveyHelper.js" as Helper

import "../Controls"
import "../Controls/Singletons"
import "Singletons"

ListView {
    id: listView

    //--------------------------------------------------------------------------

    property bool isActive: true

    property XFormMapSettings mapSettings
    property XFormPositionSourceConnection positionSourceConnection

    property bool debug: false
    property alias refreshHeader: refreshHeader

    property bool showZoomTo: false
    property bool showRouteTo: showZoomTo //&& isPointGeometry
    property bool showStatusIndicator: false
    property bool showErrorIcon: false
    property bool showIds: false

    readonly property real iconSize: 40 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    readonly property SurveyDataModel surveyDataModel: model.model
    property XFormSchema schema
    readonly property bool hasInstanceName: schema.schema.instanceName > ""

    readonly property bool isPointGeometry: surveyDataModel.isPointGeometry

    readonly property bool showDistanceAzimuth: showZoomTo && !!currentPosition //&& isPointGeometry
    property int positionSourceType: XFormPositionSourceManager.PositionSourceType.System
    property var currentPosition
    property var currentCoordinate

    property bool updateDistances: false
    property var distanceCoordinate: QtPositioning.coordinate()
    property real distanceThreshold: 1
    property int distanceUpdateInterval: 3000
    property bool firstDistanceUpdate: true
    readonly property real shortDistanceThreshold: positionSourceType > XFormPositionSourceManager.PositionSourceType.System
                                                   ? 0.5
                                                   : 1

    property color subTextColor: "#7f8183"

    property alias surveyDelegate: surveyDelegate

    property int highlightRowId: -1

    //--------------------------------------------------------------------------

    readonly property url kIconRouteTo: Icons.bigIcon("route-to")
    readonly property url kIconZoomTo: Icons.bigIcon("map")

    //--------------------------------------------------------------------------

    signal refreshed()
    signal clicked(var survey)
    signal deleteSurvey(var survey)
    signal pressAndHold(var survey)
    signal zoomTo(var survey)
    signal routeTo(var survey)
    signal distancesUpdated();

    //--------------------------------------------------------------------------

    objectName: AppFramework.typeOf(listView, true)

    clip: true
    spacing: 1 * AppFramework.displayScaleFactor
    boundsBehavior: refreshHeader.enabled
                    ? Flickable.DragAndOvershootBounds
                    : Flickable.StopAtBounds

    //--------------------------------------------------------------------------

    add: Transition {
        NumberAnimation {
            properties: "x,y"
        }
    }

    //--------------------------------------------------------------------------

    onIsActiveChanged: {
        console.log(objectName, "isActive:", isActive);

        if (!isActive) {
            updateDistanceTimer.stop();
        }
    }

    //--------------------------------------------------------------------------

    onRefreshed: {
        firstDistanceUpdate = true;
        updateDistancesChanged();
    }

    //--------------------------------------------------------------------------

    onCurrentCoordinateChanged: {
        if (!distanceCoordinate.isValid) {
            distanceCoordinate = Geometry.cloneCoordinate(currentCoordinate);
        } else if (distanceCoordinate.distanceTo(currentCoordinate) >= distanceThreshold) {
            distanceCoordinate = Geometry.cloneCoordinate(currentCoordinate);
        }
    }

    //--------------------------------------------------------------------------

    onDistanceCoordinateChanged: {
        if (!updateDistances || !isActive) {
            return;
        }

        if (firstDistanceUpdate && model.count > 0) {
            firstDistanceUpdate = false;
            Qt.callLater(updateModelDistances);
        } else {
            if ((new Date() - model.lastSorted + updateDistanceTimer.interval) >= updateDistanceTimer.interval) {
                updateDistanceTimer.start();
            }
        }
    }

    //--------------------------------------------------------------------------

    onUpdateDistancesChanged: {
        if (updateDistances) {
            Qt.callLater(updateModelDistances);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(listView, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            if (position.positionSourceTypeValid) {
                positionSourceType = position.positionSourceType;
            }

            currentPosition = position;
            currentCoordinate = currentPosition.coordinate;
        }
    }

    //--------------------------------------------------------------------------

    RefreshHeader {
        id: refreshHeader
    }

    ScrollBar.vertical: ScrollBar { }

    //--------------------------------------------------------------------------

    Component {
        id: surveyDelegate

        SwipeLayoutDelegate {
            id: swipeDelegate

            property int formStatus: status || 0
            readonly property bool canDelete: checkDelete(formStatus)
            readonly property bool hasSwipeActions: canDelete
                                                    || (showZoomTo && (coordinate.isValid || !isPointGeometry))
                                                    || (showRouteTo && coordinate.isValid)
            readonly property var rowData: model
            readonly property var coordinate: isPointGeometry
                                              ? surveyDataModel.getCoordinate(index)
                                              : nearestOnGeometry(surveyDataModel.getGeometry(index), currentCoordinate)
            readonly property bool isHighlighted: !!rowData && rowData.rowid === highlightRowId

            width: ListView.view.width
            clickSwipeToggle: false

            onClicked: {
                listView.currentIndex = index;
                listView.clicked(surveyDataModel.getSurvey(index));
            }

            onPressAndHold: {
                listView.currentIndex = index;
                listView.pressAndHold(surveyDataModel.getSurvey(index));
            }

            background: Rectangle {
                color: !swipeDelegate.behindLayout
                       ? "white"
                       : swipeDelegate.pressed
                         ? "#e1f0fb"
                         : swipeDelegate.hovered & !swipeDelegate.swipe.position
                           ? "#ecfbff"
                           : "white"

                Rectangle {
                    id: highlightBackground

                    anchors.fill: parent
                    color: "#e1f0fb"
                    visible: isHighlighted
                }

                PulseAnimation {
                    target: highlightBackground
                    running: isHighlighted
                    loops: 3

                    onFinished: {
                        target.visible = false;
                    }
                }
            }

            RowLayout {
                id: viewRow

                Layout.fillWidth: true
                Layout.leftMargin: swipeDelegate.padding


                Item {
                    Layout.fillHeight: true
                    Layout.topMargin: -10
                    Layout.bottomMargin: -10
                    Layout.leftMargin: -12 - swipeDelegate.leftInset

                    implicitWidth: 0

                    visible: showStatusIndicator

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }

                        width: 7

                        color: Survey.statusColor(formStatus)
                    }
                }

                //                Item {
                //                    Layout.alignment: Qt.AlignVCenter
                //                    implicitWidth: 2
                //                    implicitHeight: 2

                //                    visible: showStatusIndicator

                //                    Rectangle {
                //                        anchors.centerIn: parent

                //                        width: 8 * AppFramework.displayScaleFactor
                //                        height: width
                //                        color: Survey.statusColor(formStatus)
                //                        radius: height / 2
                //                    }
                //                }

                Item {
                    Layout.preferredWidth: 20 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignVCenter

                    visible: showErrorIcon

                    IconImage {
                        anchors.fill: parent

                        visible: formStatus === XForms.Status.SubmitError

                        icon {
                            name: "exclamation-mark-circle-f"
                            color: Survey.kColorError
                        }
                    }
                }

                DistanceAzimuthButton {
                    Layout.alignment: Qt.AlignCenter

                    visible: showDistanceAzimuth
                    measurementSystem: app.localeProperties.locale.measurementSystem
                    fromPosition: currentPosition
                    toCoordinate: coordinate
                    shortDistanceThreshold: listView.shortDistanceThreshold
                    compassAzimuth: positionSourceConnection.compassTrueAzimuth

                    palette {
                        window: app.backgroundColor
                        windowText: app.textColor
                    }

                    onClicked: {
                        listView.currentIndex = index;
                        console.log(logCategory, "zoomTo index:", index, "rowid:", rowData.rowid);
                        zoomTo(rowData);
                    }

                    onPressAndHold: {
                        listView.currentIndex = index;
                        routeTo(surveyDataModel.getSurvey(index));
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 3 * AppFramework.displayScaleFactor

                    AppText {
                        Layout.fillWidth: true

                        text: snippet || ""
                        font {
                            pointSize: 16 * app.textScaleFactor
                        }
                        color: textColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: updated > ""
                              ? qsTr("Modified %1").arg(new Date(updated).toLocaleString(undefined, Locale.ShortFormat))
                              : ""
                        font {
                            pointSize: 11 * app.textScaleFactor
                        }
                        color: subTextColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        visible:  text > ""
                    }

                    HorizontalSeparator {
                        Layout.fillWidth: true

                        visible: objectIdText.visible || globalIdText.visible
                    }

                    AppText {
                        id: objectIdText

                        Layout.fillWidth: true

                        property var value: showIds
                                            ? getMetaValue(!!rowData ? rowData.data : null, "objectidField", "objectid")
                                            : undefined

                        visible: showIds && !!value && !!text

                        text: value ? "Object ID: <b>%1</b>".arg(value) : ""

                        font {
                            pointSize: 11 * app.textScaleFactor
                            bold: objectIdMouseArea.containsMouse
                        }

                        color: subTextColor

                        MouseArea {
                            id: objectIdMouseArea

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                var valueText = "objectid:%1".arg(objectIdText.value);
                                console.log(logCategory, valueText);
                                AppFramework.clipboard.copy(valueText);
                            }
                        }
                    }

                    AppText {
                        id: globalIdText

                        Layout.fillWidth: true

                        property var value: showIds
                                            ? getMetaValue(!!rowData ? rowData.data : null, "globalidField", "globalid")
                                            : undefined

                        visible: showIds && !!value && !!text

                        text: value ? "Global ID: <b>%1</b>".arg(value) : ""

                        font {
                            pointSize: 11 * app.textScaleFactor
                            bold: globalIdMouseArea.containsMouse
                        }

                        color: subTextColor

                        MouseArea {
                            id: globalIdMouseArea

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                var valueText = "globalid:%1".arg(Helper.parseGuid(globalIdText.value));
                                console.log(logCategory, valueText);
                                AppFramework.clipboard.copy(valueText);
                            }
                        }
                    }
                }

                StyledImage {
                    Layout.preferredWidth: 20 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    visible: favorite > 0 ? true : false
                    source: Icons.icon("star")
                    color: textColor
                }

                StyledImageButton {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    mouseArea.anchors.margins: -viewRow.Layout.margins
                    background.anchors.margins: -viewRow.Layout.margins

                    visible: hasSwipeActions //&& swipeDelegate.swipe.position === 0

                    source: Icons.icon("ellipsis")
                    color: textColor

                    onClicked: {
                        swipeDelegate.swipeToggle();
                    }
                }
            }

            behindLayout: SwipeBehindLayout {
                color: "white"
                border {
                    width: 0
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: canDelete

                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }

                    backgroundColor: "tomato"

                    onClicked: {
                        listView.currentIndex = index;
                        deleteSurvey(surveyDataModel.getSurvey(index));
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: showRouteTo && coordinate.isValid

                    image {
                        source: kIconRouteTo
                        color: textColor
                    }

                    onClicked: {
                        listView.currentIndex = index;
                        routeTo(surveyDataModel.getSurvey(index));
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: showZoomTo && coordinate.isValid// || !isPointGeometry)

                    image {
                        source: kIconZoomTo
                        color: textColor
                    }

                    onClicked: {
                        listView.currentIndex = index;
                        zoomTo(surveyDataModel.getSurvey(index));
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function getMetaValue(surveyData, metaKey, defaultKey) {
        if (!surveyData || !surveyData[schema.instanceName]) {
            return;
        }

        var data = surveyData[schema.instanceName];

        var key;
        var metaData = data["__meta__"];
        if (metaData) {
            key = metaData[metaKey];
        }
        if (!key) {
            key = defaultKey;
        }

        return data[key];
    }

    //--------------------------------------------------------------------------

    function checkDelete(status) {
        switch(status) {
        case XForms.Status.Inbox:
            return false;

        case XForms.Status.Draft:
        case XForms.Status.Submitted:
        case XForms.Status.SubmitError:
        case XForms.Status.Complete:
        default:
            return true;
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: updateDistanceTimer

        triggeredOnStart: false
        repeat: false
        interval: distanceUpdateInterval

        onTriggered: {
            updateModelDistances();
        }
    }

    function roundDistance(value) {
        if (value < 100) {
            return value;
        } else if (value < 500) {
            return (Math.round(value * 10) / 10);
        } else if (value < 1000) {
            return Math.round(value);
        } else if (value < 10000) {
            return Math.round(value / 100) * 100;
        } else {
            return Math.round(value / 1000) * 1000;
        }
    }

    function updateModelDistances() {
        if (!surveyDataModel.count) {
            return;
        }

        if (!distanceCoordinate || !distanceCoordinate.isValid) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "#surveys:", surveyDataModel.count);
        console.time("updateModelDistances");

        // console.log(logCategory, arguments.callee.name, "from:", distanceCoordinate);

        for (var i = 0; i < surveyDataModel.count; i++) {
            var coordinate;

            if (isPointGeometry) {
                coordinate = surveyDataModel.getCoordinate(i);
            } else {
                coordinate = nearestOnGeometry(surveyDataModel.getGeometry(i), distanceCoordinate);
            }

            var distance = coordinate.isValid
                    ? distanceCoordinate.distanceTo(coordinate)
                    : Number.MAX_VALUE;

            //console.log(logCategory, arguments.callee.name, "i:", i, "to:", coordinate, "distance:", distance);

            surveyDataModel.setProperty(i, "distance", distance);
        }

        console.timeEnd("updateModelDistances");
        distancesUpdated();
    }

    //--------------------------------------------------------------------------

    function nearestOnGeometry(geometry, fromCoordinate) {
        if (!fromCoordinate || !fromCoordinate.isValid) {
            return QtPositioning.coordinate();
        }

        var coordinate = geometry.coordinate;
        if (fromCoordinate.distanceTo(coordinate) < 100000) {
            coordinate = Geometry.nearestOnPath(geometry.shape, fromCoordinate);
        }

        return coordinate;
    }

    //--------------------------------------------------------------------------

    function positionAtSurvey(rowid, mode) {
        if (mode === undefined) {
            mode = ListView.Center;
        }

        var items = model.items;

        for (var i = 0; i < items.count; i++) {
            if (items.get(i).model.rowid === rowid) {
                positionViewAtIndex(i, mode);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------
}
