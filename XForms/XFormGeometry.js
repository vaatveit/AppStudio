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

.pragma library

.import QtQml 2.12 as QML
.import QtPositioning 5.12 as QtPos
.import "XForm.js" as XFormJS

//------------------------------------------------------------------------------

function pointsToPath(points) {
    var path = [];

    if (!Array.isArray(points)) {
        return path;
    }

    var coordinate;

    points.forEach(function (point) {
        if (Array.isArray(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point[1], point[0]);
            if (coordinate.isValid) {
                path.push(coordinate);
            }
        } else if (isPointObject(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point.y, point.x);
            if (coordinate.isValid) {
                path.push(coordinate);
            }
        }
    });

    return path;
}

//------------------------------------------------------------------------------

function pointsToPathExtent(points) {
    var path = [];
    var extent = QtPos.QtPositioning.rectangle();

    if (!Array.isArray(points)) {
        return {
            path: path,
            extent: extent
        };
    }

    var coordinate;

    points.forEach(function (point) {
        if (Array.isArray(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point[1], point[0]);
        } else if (isPointObject(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point.y, point.x);
        }

        if (coordinate.isValid) {
            path.push(coordinate);

            if (extent.isValid) {
                extent.extendRectangle(coordinate);
            } else {
                extent = QtPos.QtPositioning.rectangle(coordinate, 0, 0);
            }
        }
    });

    return {
        path: path,
        extent: extent
    };
}

//------------------------------------------------------------------------------

function geopathLength(geopath, perimeter) {
    if (geopath.path.length < 2) {
        return;
    }

    if (geopath.path.length < 3 && perimeter) {
        return;
    }

    return perimeter
            ? geopath.length() // Qt default is to wrap the length
            : geopath.length(0, geopath.path.length);
}

//------------------------------------------------------------------------------

function pathArea(path) {
    if (path.length < 3) {
        return;
    }

    function signedArea(path, radius) {
        function toRadians(degrees) {
            return degrees / 180.0 * Math.PI;
        }

        function polarTriangleArea(tanPhi1, lambda1, tanPhi2, lambda2) {
            var deltaLambda = lambda1 - lambda2;
            var t = tanPhi1 * tanPhi2;

            return 2 * Math.atan2(t * Math.sin(deltaLambda), 1 + t * Math.cos(deltaLambda));
        }

        var total = 0;
        var coordinate = path[path.length - 1];
        var _tanPhi = Math.tan((Math.PI / 2 - toRadians(coordinate.latitude)) / 2);
        var _lambda = toRadians(coordinate.longitude);

        path.forEach(function (coordinate) {
            var tanPhi = Math.tan((Math.PI / 2 - toRadians(coordinate.latitude)) / 2);
            var lambda = toRadians(coordinate.longitude);

            total += polarTriangleArea(tanPhi, lambda, _tanPhi, _lambda);

            _tanPhi = tanPhi;
            _lambda = lambda;
        });

        return total * (radius * radius);
    }

    return Math.abs(signedArea(path, 6371009.0));
}

//--------------------------------------------------------------------------

function displayLength(length, locale) {
    switch (locale.measurementSystem) {
    case QML.Locale.ImperialUSSystem:
    case QML.Locale.ImperialUKSystem:
        var lengthFt = length * 3.28084;
        if (lengthFt < 1000) {
            return qsTr("%1 ft").arg(localeRound(lengthFt, 0, locale));
        } else {
            var lengthMiles = length * 0.000621371;
            return qsTr("%1 mi").arg(localeRound(lengthMiles, lengthMiles < 10 ? 1 : 0, locale));
        }

    default:
        if (length < 1000) {
            return qsTr("%1 m").arg(localeRound(length, 0, locale));
        } else {
            var lengthKm = length / 1000;
            return qsTr("%1 km").arg(localeRound(lengthKm, lengthKm < 10 ? 1 : 0, locale));
        }
    }
}

//--------------------------------------------------------------------------

function displayArea(area, locale) {
    switch (locale.measurementSystem) {
    case QML.Locale.ImperialUSSystem:
    case QML.Locale.ImperialUKSystem:
        var areaSquareFt = area * 10.7639;
        if (areaSquareFt < 1000) {
            return qsTr("%1 ft²").arg(localeRound(areaSquareFt, 0, locale));
        } else {
            var areaAcres = area * 0.000247105;
            return qsTr("%1 acres").arg(localeRound(areaAcres, areaAcres < 10 ? 2 : 1, locale));
        }

    default:
        if (area < 10000) {
            return qsTr("%1 m²").arg(localeRound(area, 0, locale));
        } else {
            var areaHectares = area / 10000;
            return qsTr("%1 hectares").arg(localeRound(areaHectares, areaHectares < 10 ? 2 : 1, locale))
        }
    }
}

//--------------------------------------------------------------------------

function localeRound(value, decimals, locale) {
    if (!isFinite(value)) {
        return "--";
    }

    if (!decimals) {
        decimals = 0;
    }

    var p = Math.pow(10, decimals);

    return XFormJS.trimTrailingZeros((Math.round(value * p) / p).toLocaleString(locale, "f", decimals), locale);
}

//------------------------------------------------------------------------------

function isPointObject(o) {
    return o !== null & typeof o === "object" && o === null || isFinite(o.x) && isFinite(o.y);
}

//------------------------------------------------------------------------------

function isPointsArray(a, ignoreNulls) {
    if (!Array.isArray(a)) {
        return false;
    }

    var isPoints = a.length > 0;
    for (var i = 0; i < a.length && isPoints; i++) {
        var o = a[i];

        isPoints = (ignoreNulls && (o === null || o === undefined)) || isPointObject(o);
    }

    return isPoints;
}

//--------------------------------------------------------------------------

function cloneCoordinate(coordinate) {
    if (!coordinate) {
        return QtPos.QtPositioning.coordinate();
    }

    return QtPos.QtPositioning.coordinate(coordinate.latitude, coordinate.longitude, coordinate.altitude);
}

//--------------------------------------------------------------------------

function cloneRectangle(rectangle) {
    if (!rectangle) {
        return QtPos.QtPositioning.rectangle();
    }

    return QtPos.QtPositioning.rectangle(rectangle.topLeft, rectangle.bottomRight);
}

//--------------------------------------------------------------------------

// Naive MapPolygon centroid in flat earth approximation. This works
// best for small, simple shapes. A distance threshold can been set
// to reduce the number of close vertices (the centroid is biased
// towards regions with the most vertices, e.g. bends in the line)

function pathCentroid(path, threshold) {
    if (!path || path.length <= 0) {
        return QtPos.QtPositioning.coordinate();
    }

    var coordinate = path[0];
    var lastGood = path[0];
    var count = 1;

    var latitude = coordinate.latitude;
    var longitude = coordinate.longitude;

    for (var i = 1; i < path.length; i++) {
        coordinate = path[i];

        if (coordinate.isValid) {
            var distance = lastGood.distanceTo(coordinate);

            if (distance >= threshold) {
                lastGood = coordinate
                latitude += coordinate.latitude;
                longitude += coordinate.longitude;
                count++;
            }
        }
    }

    return QtPos.QtPositioning.coordinate(latitude/count, longitude/count);
}

//--------------------------------------------------------------------------
// TODO Calculate actual midpoint

function pathMidPoint(path) {
    if (!path || path.length <= 0) {
        return QtPos.QtPositioning.coordinate();
    }

    return path[~~(path.length/2)];
}

//------------------------------------------------------------------------------

function nearestOnPath(path, coordinate) {
    if (!path || !path.isValid || path.size() <= 0 || !coordinate || !coordinate.isValid) {
        return QtPos.QtPositioning.coordinate();
    }

    if (path.size() === 1) {
        return path.coordinateAt(0);
    }

    var distance = Number.MAX_VALUE;
    var nearest;

    function checkSegment(p, a, b) {
        var AB = Qt.vector2d(b.x - a.x, b.y - a.y );
        var AP = Qt.vector2d(p.x - a.x, p.y - a.y );
        var t = AP.dotProduct(AB) / (AB.x * AB.x + AB.y * AB.y);

        var point = t <= 0
                ? a
                : t >= 1
                  ? b
                  : Qt.point(a.x + AB.x * t, a.y + AB.y * t);

         var d = Qt.vector2d(point.x - p.x, point.y - p.y).length();

        if (d < distance) {
            distance = d;
            nearest = point;
        }
    }

    const point =  QtPos.QtPositioning.coordToMercator(coordinate);
    var point1 = QtPos.QtPositioning.coordToMercator(path.coordinateAt(0));
    var point2;

    for (var i = 1; i < path.size(); i++) {
        point2 = QtPos.QtPositioning.coordToMercator(path.coordinateAt(i));

        checkSegment(point, point1, point2);

        if (distance === 0) {
            break;
        }

        point1 = point2;
    }

    return QtPos.QtPositioning.mercatorToCoord(nearest);
}

//------------------------------------------------------------------------------
