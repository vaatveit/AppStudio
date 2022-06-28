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
import QtQml.Models 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../XForms"
import "../XForms/Singletons"
import "../XForms/XFormGeometry.js" as Geometry
import "../XForms/MapControls"
import "SurveyHelper.js" as Helper
import "../Models"
import "../Controls"
import "../Controls/Singletons"
import "Singletons"

Item {
    id: mapView

    //--------------------------------------------------------------------------

    property bool isActive: true

    property bool debug: false
    property bool showDelete: true
    property SurveyDataModel surveyDataModel

    property XFormSettings formSettings
    property XFormMapSettings mapSettings
    property XFormPositionSourceConnection positionSourceConnection

    property alias map: map
    property alias graphicsOverlay: graphicsOverlay
    property alias supportedMapTypes: map.supportedMapTypes
    property string mapKey
    property var extent
    readonly property bool isExtentValid: !!extent && extent.center.isValid

    property int highlightRowId: -1
    property color highlightBorderColor: "white"

    property color labelTextColor: "black"
    property color labelStyleColor: "white"
    property color labelBackgroundColor: "white"
    property color labelBorderColor: "lightgrey"

    property color clusterTextColor: "white"
    property color clusterBorderColor: "lightgrey"

    property string markerName: mapSettings.pointSymbolName
    property string markerFontFamily: mapSettings.pointSymbolSet.font.family
    property string markerFontChar: mapSettings.pointSymbolSet.glyphChar(markerName)
    property real markerScale: 1.1

    readonly property real kDefaultLineWidth: 4
    property real lineWidth: kDefaultLineWidth
    property real highlightedLineWidth: 7

    // Clustering strategy: Point markers, polygons, and polylines are displayed
    // once the zoom level is greater than a given default zoom level. For zoom
    // levels below this threshold, clustering is used. Labels are displayed once
    // the default labelling zoom level is reached.
    //
    // Polygons and polylines follow additional rules:
    //
    // 1) We calculate the zoom level for which a given polygon/polyline is larger
    //    than a certain fraction of the screen dimensions. If the map zoom level is
    //    larger than this value, the polygon/polyline is drawn regardless of the
    //    default threshold. This ensures that the extent of large polygons/polylines
    //    are fully visible, while smaller polygons/polylines are still clustered.
    //
    // 2) The default zoom level to draw all features is modified (within a certain range)
    //    according to the size distribution of the polygons/polylines. We use the
    //    zoom level at which a polygon/polyline fills a certain fraction of the screen
    //    as an indicator of its size. We calculate the histogram of these zoom levels and
    //    use the zoom level where the peak of the histogram lies to determin the new default
    //    zoom level. This ensures that clustering can be used for larger zoom levels if
    //    the polygons/polylines are small, and vice versa. It also ensures that no (or
    //    fewer) "holes" appear, where a polygon/polyline is of similar size than its
    //    neighbours, which are displayed on the map, but just misses out on being drawn
    //    itself. Alternatively, instead of using a histogram, the median or a percentile
    //    could be used to determine the new default zoom level.
    //
    // 3) The label of a polygon/polyline is only drawn once the map zoom level is greater
    //    than the zoom level at which the polygon/polyline fills a certain fraction of
    //    the screen. This reduces the number of labels that are overlapping each other.

    property real defaultDetailedZoomLevel: 13.5
    property real defaultLabelsZoomLevel: 15.5

    property real detailedZoomLevelPoints: defaultDetailedZoomLevel
    property real labelsZoomLevelPoints: defaultLabelsZoomLevel

    property real detailedZoomLevelGeoshapes: defaultDetailedZoomLevel
    property real labelsZoomLevelGeoshapes: defaultLabelsZoomLevel

    property var tolerance: 30 * AppFramework.displayScaleFactor
    property var fractionToFit: 0.33
    property var distanceThreshold: 10

    readonly property string geometryType: surveyDataModel.geometryType
    readonly property bool isPointGeometry: surveyDataModel.isPointGeometry
    readonly property bool isPolylineGeometry: surveyDataModel.isPolylineGeometry
    readonly property bool isPolygonGeometry: surveyDataModel.isPolygonGeometry
    readonly property bool isPolyGeometry: surveyDataModel.isPolyGeometry

    readonly property bool showClusters: !isPointGeometry || map.zoomLevel < detailedZoomLevelPoints
    readonly property bool showLabels: !isPointGeometry || map.zoomLevel >= labelsZoomLevelPoints
    readonly property bool showPointMarkers: isPointGeometry && map.zoomLevel >= detailedZoomLevelPoints

    property var featureZoomLevels: []
    property var featureClustered: []

    //--------------------------------------------------------------------------

    property bool showCollect: false
    readonly property bool canCollect: showCollect && isPointGeometry
    property alias collectOverlay: collectOverlay

    //--------------------------------------------------------------------------

    signal clicked(var survey)
    signal pressAndHold(var survey)

    //--------------------------------------------------------------------------

    objectName: AppFramework.typeOf(mapView, true)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "onCompleted geometryType:", geometryType);

        Qt.callLater(initialize);
    }

    //--------------------------------------------------------------------------

    onSupportedMapTypesChanged: {
        if (supportedMapTypes.length) {
            map.mapSettings.selectMapType(map, formSettings.mapName(mapKey));
        }
    }

    //--------------------------------------------------------------------------

    onIsActiveChanged: {
        console.log(objectName, "isActive:", isActive);
    }

    //--------------------------------------------------------------------------

    Connections {
        target: surveyDataModel

        onFiltered: {
            console.log(logCategory, "Surveys filtered");
            invalidate();
        }
    }

    onWidthChanged: {
        if (isPolyGeometry) {
            invalidate();
        }
    }

    onHeightChanged: {
        if (isPolyGeometry) {
            invalidate();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapView, true)
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        //----------------------------------------------------------------------

        readonly property real roundedZoomLevel: Math.round(zoomLevel)

        //----------------------------------------------------------------------
        anchors {
            fill: parent
        }

        animationEnabled: false
        mapSettings: mapView.mapSettings
        minimumZoomLevel: 2

        positionSourceConnection: mapView.positionSourceConnection

        localeProperties: app.localeProperties

        plugin: XFormMapPlugin {
            settings: map.mapSettings
            offline: !Networking.isOnline
        }

        //----------------------------------------------------------------------

        MouseArea {
            id: mapMouseArea

            anchors.fill: parent

            enabled: isPolylineGeometry

            onClicked: {
                var rowData = findSurvey(mouse);
                if (rowData) {
                    mapView.clicked(rowData);
                }
            }

            onPressAndHold: {
                var rowData = findSurvey(mouse);
                if (rowData) {
                    mapView.pressAndHold(rowData);
                }
            }

            function findSurvey(mouse) {
                var coordinate = map.toCoordinate(mapToItem(map, mouse.x, mouse.y));
                var tolerance = toleranceWidth();

                for (var i = 0; i < surveyDataModel.count; i++) {
                    if (featureClustered[i]) {
                        continue;
                    }

                    var item = surveyDataModel.get(i);

                    if (!item.isVisible) {
                        continue;
                    }

                    var geometry = surveyDataModel.getGeometry(i);

                    if (surveyDataModel.geometryContains(geometry, coordinate, tolerance)) {
                        return item;
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        MapItemView {
            model: isPolygonGeometry ? surveyDataModel : null
            delegate: polygonMapItemComponent
        }

        MapItemView {
            model: isPolylineGeometry ? surveyDataModel : null
            delegate: polylineMapItemComponent
        }

        MapItemView {
            model: showPointMarkers ? surveyDataModel : null
            delegate: geopointMarkerComponent
        }

        MapItemView {
            model: showLabels ? surveyDataModel : null
            delegate: labelComponent
        }

        MapItemView {
            model: showClusters ? clustersModel : null
            delegate: clusterMapItemComponent
        }

        GraphicsOverlay {
            id: graphicsOverlay
        }

        //----------------------------------------------------------------------

        CollectOverlay {
            id: collectOverlay

            anchors.fill: parent

            visible: canCollect
            geometryType: mapView.geometryType
        }

        //----------------------------------------------------------------------

        onZoomLevelChanged: {
            invalidateClusters();
        }

        onMapTypeChanged: {
            formSettings.setMapName(mapKey, mapSettings.mapTypeName(mapType));
        }

        //----------------------------------------------------------------------

        mapControls {
            showZoomTo: isExtentValid
            zoomToButton.icon.name: "extent"

            onZoomTo: {
                zoomToExtent();
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    Component {
        id: polygonMapItemComponent

        MapPolygon {
            id: mapPolygon

            property var rowData: model //getSurvey(index)
            readonly property color _statusColor: rowData ? Survey.statusColor(rowData.status) : "transparent"
            readonly property bool isVisible: !!rowData && !!rowData.isVisible
            readonly property bool isHighlighted: !!rowData && rowData.rowid === highlightRowId

            visible: isVisible
                     && index >= 0
                     && (map.roundedZoomLevel >= featureZoomLevels[index]
                         || map.zoomLevel >= detailedZoomLevelGeoshapes)

            path: isVisible
                  ? surveyDataModel.getShape(index).perimeter
                  : []

            color: AppFramework.alphaColor(_statusColor, isHighlighted ? 0.75 : 0.33)
            border {
                color: _statusColor
                width: (isHighlighted ? highlightedLineWidth : lineWidth) * AppFramework.displayScaleFactor
            }

            MouseArea {
                anchors {
                    fill: parent
                }

                onClicked: {
                    if (isMouseInPolygon(mouse)) {
                        mouse.accepted = true;
                        mapView.clicked(rowData);
                    } else {
                        mouse.accepted = false;
                    }
                }

                onPressAndHold: {
                    if (isMouseInPolygon(mouse)) {
                        mouse.accepted = true;
                        mapView.pressAndHold(rowData);
                    } else {
                        mouse.accepted = false;
                    }
                }

                function isMouseInPolygon(mouse) {
                    var coordinate = map.toCoordinate(mapToItem(map, mouse.x, mouse.y));
                    var shape = surveyDataModel.getShape(index);
                    return shape.contains(coordinate);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: polylineMapItemComponent

        MapPolyline {
            id: mapPolyline

            property var rowData: model //getSurvey(index)
            readonly property color _statusColor: rowData ? Survey.statusColor(rowData.status) : "transparent"
            readonly property bool isVisible: !!rowData && !!rowData.isVisible
            readonly property bool isHighlighted: !!rowData && rowData.rowid === highlightRowId

            visible: isVisible
                     && index >= 0
                     && (map.roundedZoomLevel >= featureZoomLevels[index]
                         || map.zoomLevel >= detailedZoomLevelGeoshapes)

            path: isVisible
                  ? surveyDataModel.getShape(index).path
                  : []

            line {
                color: _statusColor
                width: (isHighlighted ? highlightedLineWidth : lineWidth) * AppFramework.displayScaleFactor
            }

            /*
            MouseArea {
                anchors {
                    fill: parent
                }

                onClicked: {
                    if (isMouseOnPolyline(mouse)) {
                        mouse.accepted = true;
                        mapView.clicked(rowData);
                    } else {
                        mouse.accepted = false;
                    }
                }

                onPressAndHold: {
                    if (isMouseOnPolyline(mouse)) {
                        mouse.accepted = true;
                        mapView.pressAndHold(rowData);
                    } else {
                        mouse.accepted = false;
                    }
                }

                function isMouseOnPolyline(mouse) {
                    var coordinate = map.toCoordinate(mapToItem(map, mouse.x, mouse.y));
                    var shape = surveyDataModel.getShape(index);

                    shape.width = toleranceWidth();
                    return shape.contains(coordinate);
                }
            }
            */
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointMarkerComponent

        MapQuickItem {
            id: mapItem

            property var rowData: model //getSurvey(index)
            readonly property int rowStatus: rowData ? rowData.status : -1
            readonly property color _statusColor: rowData ? Survey.statusColor(rowData.status) : "transparent"
            readonly property bool isVisible: !!rowData && !!rowData.isVisible
            readonly property bool isHighlighted: !!rowData && rowData.rowid === highlightRowId

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height
            }

            visible: isVisible && rowStatus >= 0
            coordinate: surveyDataModel.getCoordinate(index)

            sourceItem: Text {
                id: mapMarker

                height: 40 * AppFramework.displayScaleFactor

                text: markerFontChar
                color: _statusColor
                font {
                    family: markerFontFamily
                    pixelSize: height
                }
                scale: markerScale
                style: (isHighlighted || markerMouseArea.containsMouse)
                       ? Text.Outline
                       : Text.Raised
                styleColor: (isHighlighted || markerMouseArea.containsMouse)
                            ? highlightBorderColor
                            : Qt.lighter(_statusColor, 1.5)

                MouseArea {
                    id: markerMouseArea

                    anchors.centerIn: parent

                    width: parent.paintedWidth
                    height: parent.paintedHeight

                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        mapView.clicked(rowData);
                    }

                    onPressAndHold: {
                        mapView.pressAndHold(rowData);
                    }
                }

                PulseAnimation {
                    target: mapMarker
                    running: isHighlighted
                    loops: 3
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: labelComponent

        MapQuickItem {
            id: mapItem

            property var rowData: model //getSurvey(index)
            readonly property bool isVisible: !!rowData && !!rowData.isVisible
            readonly property bool isHighlighted: !!rowData && rowData.rowid === highlightRowId

            anchorPoint {
                x: mapText.width/2
                y: 0
            }

            visible: isVisible
                     && index >= 0
                     && (map.roundedZoomLevel >= featureZoomLevels[index]
                         || isPointGeometry)

            coordinate: surveyDataModel.getCoordinate(index)

            sourceItem: Text {
                id: mapText

                width: 100 * AppFramework.displayScaleFactor
                text: rowData ? rowData.snippet || "" : ""
                color: labelTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: app.fontFamily
                    pointSize: 11
                    bold: isHighlighted || labelMouseArea.containsMouse
                }

                Rectangle {
                    id: mapTextBackground

                    anchors {
                        centerIn: parent
                    }

                    width: parent.paintedWidth + parent.paintedHeight / 2
                    height: parent.paintedHeight + 6
                    radius: (parent.paintedHeight / (parent.lineCount || 0)) / 3

                    color: labelBackgroundColor
                    border {
                        color: labelBorderColor
                        width: 1
                    }

                    opacity: (isHighlighted || labelMouseArea.containsMouse) ? 1 : 0.5
                    z: parent.z - 1
                }

                MouseArea {
                    id: labelMouseArea

                    anchors {
                        fill: parent
                    }

                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        mapView.clicked(rowData);
                    }

                    onPressAndHold: {
                        mapView.pressAndHold(rowData);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: clusterMapItemComponent

        MapQuickItem {
            id: mapItem

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height/2
            }

            coordinate: QtPositioning.coordinate(cy, cx)
            sourceItem: Rectangle {
                id: mapMarker

                property int size: Math.max(countText.paintedHeight + 8 * AppFramework.displayScaleFactor, countText.paintedWidth + 16 * AppFramework.displayScaleFactor)
                height: size
                width: size
                color: Survey.statusColor(status)
                border {
                    color: clusterMouseArea.containsMouse
                           ? highlightBorderColor
                           : clusterBorderColor
                    width: 1
                }
                radius: height / 2

                Text {
                    id: countText
                    anchors.centerIn: parent

                    text: count
                    color: clusterTextColor

                    font {
                        bold: clusterMouseArea.containsMouse
                        pointSize: 12
                        family: app.fontFamily
                    }
                }

                MouseArea {
                    id: clusterMouseArea

                    anchors {
                        fill: parent
                    }

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        var clusterExtent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));
                        map.zoomToRectangle(clusterExtent, isPointGeometry ? labelsZoomLevelPoints : labelsZoomLevelGeoshapes);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ClustersModel {
        id: clustersModel

        function update() {
            var mapZoomLevel = Math.round(map.zoomLevel);

            if (mapZoomLevel === level) {
                return;
            }

            console.time("cluster");

            initialize(mapZoomLevel);

            if (featureClustered.length != surveyDataModel.count) {
                featureClustered.length = 0;
                featureClustered.length = surveyDataModel.count;
            }

            var clusterZoomLevel = isPointGeometry ? detailedZoomLevelPoints : detailedZoomLevelGeoshapes;
            for (var i = 0; i < surveyDataModel.count; i++) {

                var cell;

                if (map.zoomLevel < clusterZoomLevel
                        && (isPointGeometry || isFinite(featureZoomLevels[i]) && mapZoomLevel < featureZoomLevels[i])
                        && surveyDataModel.get(i).isVisible) {
                    if (isPointGeometry) {
                        cell = addPoint(surveyDataModel.getCoordinate(i));
                    } else {
                        cell = addShape(surveyDataModel.getShape(i));
                    }

                    if (cell) {
                        var status = surveyDataModel.get(i).status;
                        if (cell.status === undefined) {
                            cell.status = status;
                        } else if (cell.status !== status) {
                            cell.status = -1;
                        }
                    }

                    featureClustered[i] = true;
                } else {
                    featureClustered[i] = false;
                }
            }

            finalize();

            console.timeEnd("cluster");
        }
    }

    //--------------------------------------------------------------------------

    function getSurvey(index) {
        var item = surveyDataModel.get(index);
        if (item && item.isVisible) {
            return item;
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, arguments.callee.name);

        console.time("initialize");

        updateZoomLevels();
        zoomToExtent();

        console.timeEnd("initialize");
    }

    //--------------------------------------------------------------------------

    function invalidate() {
        Qt.callLater(refresh);
    }

    //--------------------------------------------------------------------------

    function invalidateClusters() {
        Qt.callLater(clustersModel.update);
    }

    //--------------------------------------------------------------------------

    function refresh() {
        console.log(logCategory, arguments.callee.name);

        console.time("refresh");

        updateZoomLevels();
        clustersModel.reset();

        if (showClusters) {
            clustersModel.update();
        }

        console.timeEnd("refresh");
    }

    //--------------------------------------------------------------------------
    // Set up the pertinent points of features, i.e. the point itself or the feature centroid,
    // the zoom levels for which individual features should be displayed, and derive the
    // default zoom level to display all features

    function updateZoomLevels() {
        detailedZoomLevelGeoshapes = defaultDetailedZoomLevel;
        labelsZoomLevelGeoshapes = defaultLabelsZoomLevel;

        featureZoomLevels.length = 0;
        featureZoomLevels.length = surveyDataModel.count;

        var visibleExtent = QtPositioning.rectangle();

        for (var i = 0; i < surveyDataModel.count; i++) {
            if (!surveyDataModel.get(i).isVisible) {
                continue;
            }

            if (isPointGeometry) {
                featureZoomLevels[i] = labelsZoomLevelPoints;
                var coordinate = surveyDataModel.getCoordinate(i);
                if (coordinate.isValid) {
                    if (visibleExtent.isValid) {
                        visibleExtent.extendRectangle(coordinate);
                    } else {
                        visibleExtent = QtPositioning.rectangle(coordinate, 0, 0);
                    }
                }
            } else if (isPolyGeometry) {
                var extent = surveyDataModel.getExtent(i);
                featureZoomLevels[i] = extentZoomLevel(extent, fractionToFit);
                if (extent.isValid) {
                    if (visibleExtent.isValid) {
                        visibleExtent = visibleExtent.united(extent);
                    } else {
                        visibleExtent = extent;
                    }
                }
            }
        }

        mapView.extent = visibleExtent;

        if (isPolyGeometry) {
            var binSize = 1;
            var lowerBoundExtension = 2
            var upperBoundExtension = 2
            var peakAtShift = 1.5

            var offset = labelsZoomLevelGeoshapes - detailedZoomLevelGeoshapes;
            var peakAt = zoomLevelClusteredAt(featureZoomLevels, binSize);

            if (peakAt < detailedZoomLevelGeoshapes - lowerBoundExtension) {
                detailedZoomLevelGeoshapes = detailedZoomLevelGeoshapes - lowerBoundExtension - peakAtShift + 0.5;
            } else if (peakAt > detailedZoomLevelGeoshapes + upperBoundExtension) {
                detailedZoomLevelGeoshapes = detailedZoomLevelGeoshapes + upperBoundExtension - peakAtShift + 0.5;
            } else {
                detailedZoomLevelGeoshapes = peakAt - peakAtShift;
            }

            labelsZoomLevelGeoshapes = detailedZoomLevelGeoshapes + offset;
        }
    }

    //--------------------------------------------------------------------------
    // Derive the zoom level from the web mercator projection formula so that the bounding
    // box of the map polygon or polyline fits within the given fraction of the map.
    // See https://en.wikipedia.org/wiki/Web_Mercator_projection for the projection formula.
    // Take the difference of the (x,y) coordinates of two points after projection and solve
    // for zoom level.

    // Use QtPositioning.coordToMercator() ?
    // https://doc.qt.io/qt-5/qml-qtpositioning-qtpositioning.html#coordToMercator-method

    function extentZoomLevel(extent, fractionToFit) {

        if (!map.height || !map.width) {
            return 0;
        }

        if (!extent || !extent.isValid || extent.isEmpty) {
            return detailedZoomLevelGeoshapes;
        }

        var zoomX = 360.0 / extent.width * map.width / 256 * fractionToFit;

        var topLeft = extent.topLeft;
        var bottomRight = extent.bottomRight;

        var tanYMin = Math.tan((bottomRight.latitude / 2) * Math.PI / 180 + Math.PI/4 );
        var tanYMax = Math.tan((topLeft.latitude / 2) * Math.PI / 180 + Math.PI/4 );
        var zoomY = 2 * Math.PI / Math.log(tanYMax / tanYMin) * map.height / 256 * fractionToFit;

        return Math.round(Math.log( Math.min(zoomX, zoomY) ) / Math.LN2);
    }

    //--------------------------------------------------------------------------
    // Calculate the zoom level for which most polygons should be displayed

    function zoomLevelClusteredAt(array, binSize) {
        const filtered = array.filter( val => isFinite(val) );
        const minZoomLevel = Math.min(...filtered);
        const maxZoomLevel = Math.max(...filtered);

        const nbins = (maxZoomLevel - minZoomLevel + 1) / binSize;
        const histo = new Array(nbins).fill(0);

        filtered.forEach(function createHisto(val) {
            if (isFinite(val)) {
                histo[Math.round((val - minZoomLevel) / binSize)]++;
            }
        })

        const indexOfMaxValue = histo.indexOf(Math.max(...histo));
        const maxValue = minZoomLevel + indexOfMaxValue * binSize;

        return maxValue;
    }

    //--------------------------------------------------------------------------

    function toleranceWidth() {
        var coord1 = map.toCoordinate(Qt.point(0, 0));
        var coord2 = map.toCoordinate(Qt.point(tolerance, tolerance));

        return coord1.distanceTo(coord2);
    }

    //--------------------------------------------------------------------------

    function zoomTo(rowData) {
        console.log(logCategory, arguments.callee.name);

        if (!(rowData && rowData.data)) {
            console.warn(logCategory, arguments.callee.name, "Empty row")
            return;
        }

        var geometry = rowData.geometry;
        if (!geometry) {
            geometry = surveyDataModel.dataGeometry(rowData.data);

            if (!geometry) {
                console.warn(logCategory, arguments.callee.name, "Empty geometry")
                return;
            }
        }

        if (isPointGeometry) {
            if (geometry.coordinate.isValid) {
                var minZoomLevel = Math.max(labelsZoomLevelPoints, map.mapSettings.previewZoomLevel);
                if (map.zoomLevel < minZoomLevel) {
                    map.zoomToCoordinate(geometry.coordinate, minZoomLevel);
                } else {
                    map.panTo(geometry.coordinate);
                }
            }
        } else if (isPolyGeometry) {
            if (geometry.shape && geometry.shape.isValid) {
                map.zoomToRectangle(geometry.shape.boundingGeoRectangle(), labelsZoomLevelPoints);
            }
        }
    }

    //--------------------------------------------------------------------------

    function zoomToExtent() {
        if (isExtentValid) {
            console.info(logCategory, arguments.callee.name, "extent:", extent);
            map.zoomToRectangle(extent, map.mapSettings.previewZoomLevel);
        } else {
            console.warn(logCategory, arguments.callee.name, "Invalid extent");
            map.zoomToDefault();
        }
    }

    //--------------------------------------------------------------------------
}
