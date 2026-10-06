import 'dart:math';

import '../models/lat_lon.dart';
import '../models/pixel_point.dart';
import '../models/tile_point.dart';
import 'calculator.dart';

/// _mapLonEdge
const _mapLonEdge = 180 * 2;
// const _mapLatEdge = 90 * 2;

/// latLonToPixelPoint
PixelPoint latLonToPixelPoint({
  required LatLon latLon,
  required double mapScale,
}) {
  final mapSize = getMapSize(mapScale: mapScale);

  final unitX = mapSize / _mapLonEdge;
  final x = unitX * (latLon.lon + 180);

  final latRad = latLon.lat * pi / 180;
  final mercN = log(tan((pi / 4) + (latRad / 2)));
  final y = (mapSize / 2) - (mapSize * mercN / (2 * pi));

  return PixelPoint(x, y);
}

/// pixelPointToLatLon
LatLon pixelPointToLatLon({
  required PixelPoint pixelPoint,
  required double mapScale,
}) {
  final mapSize = getMapSize(mapScale: mapScale);
  final lon = pixelPoint.x / mapSize * _mapLonEdge - 180;
  final mercN = pi - 2 * pi * pixelPoint.y / mapSize;
  final lat = (2 * atan(exp(mercN)) - pi / 2) * 180 / pi;

  return LatLon(lat, lon);
}

/// latLonToTilePoint
TilePoint latLonToTilePoint({required LatLon latLon, required int zoom}) {
  final newScale = getMapScaleForZoom(zoom.toDouble());

  final center = latLonToPixelPoint(latLon: latLon, mapScale: newScale);

  final unitSize = getUnitSize(zoom: zoom.toDouble(), mapScale: newScale);

  final x = center.x ~/ unitSize;
  final y = center.y ~/ unitSize;

  return TilePoint(x, y, zoom.toInt());
}
