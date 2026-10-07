import 'dart:math';

import '../calculations/calculator.dart';
import '../calculations/lat_lon_cal.dart';
import '../models/lat_lon.dart';
import '../models/pixel_point.dart';
import '../models/tile_point.dart';

/// tileManager
Future<List<TilePoint>> tileManager({
  required PixelPoint center,
  required double zoom,
  required double scale,
  required double mapScale,

  LatLon? target,
}) async {
  List<TilePoint> newList = zoomTiles(zoom: 3);

  final newZoom = zoom.floor();

  final centerTile = getCenterTile(
    center: center,
    zoom: newZoom.toDouble(),
    mapScale: mapScale,
  );

  final horizontalTiles = newZoom < 4
      ? <TilePoint>[]
      : _horizontalTiles(zoom: newZoom, centerTile: centerTile, expand: 2);

  newList.addAll(horizontalTiles);

  final verticalTiles = _verticalTiles(
    center: center,
    zoom: newZoom,
    centerTile: centerTile,
  );

  newList.addAll(verticalTiles);

  if (target != null) {
    final targetTiles = _getTargetTiles(target: target);
    newList.addAll(targetTiles);
  }

  /// remove duplicated models
  newList = newList.toSet().toList();

  /// sort tiles 3to22
  newList.sort((a, b) => a.z - b.z);

  return newList;
}

List<TilePoint> zoomTiles({int zoom = 3}) {
  final count = pow(2, zoom).toInt();

  List<TilePoint> list = [];

  for (var x = 0; x < count; x++) {
    for (var y = 0; y < count; y++) {
      list.add(TilePoint(x, y, zoom));
    }
  }

  return list;
}

/// _horizontalTiles
List<TilePoint> _horizontalTiles({
  required TilePoint centerTile,
  required int zoom,
  int expand = 2,
}) {
  List<List<int>> coords = [];
  for (var i = -expand; i <= expand; i++) {
    for (var j = -expand; j <= expand; j++) {
      coords.add([centerTile.x - i, centerTile.y - j]);
    }
  }

  List<TilePoint> list = [];
  for (var coord in coords) {
    list.add(TilePoint(coord.first, coord.last, zoom));
  }

  return list;
}

/// _verticalTiles
List<TilePoint> _verticalTiles({
  required TilePoint centerTile,
  required PixelPoint center,
  required int zoom,
}) {
  var zoomIndex = zoom;
  var theXIndex = centerTile.x;
  var theYIndex = centerTile.y;

  List<TilePoint> list = [];

  while (zoomIndex > 4) {
    if (theXIndex % 2 != 0) theXIndex--;
    if (theYIndex % 2 != 0) theYIndex--;

    theXIndex = theXIndex ~/ 2;
    theYIndex = theYIndex ~/ 2;
    zoomIndex--;

    list.add(TilePoint(theXIndex, theYIndex, zoomIndex));

    /// load zoom -1 horizontal tiles
    if (zoomIndex == zoom - 1) {
      final hTiles = _horizontalTiles(
        centerTile: TilePoint(theXIndex, theYIndex, zoomIndex),
        zoom: zoomIndex,
        expand: 1,
      );
      list.addAll(hTiles);
    }
  }

  return list;
}

/// _getTargetTiles
List<TilePoint> _getTargetTiles({required LatLon target, int expand = 1}) {
  List<TilePoint> list = [];

  var zoom = 22;

  while (zoom >= 3) {
    for (var i = -expand; i <= expand; i++) {
      for (var j = -expand; j <= expand; j++) {
        final tile = latLonToTilePoint(latLon: target, zoom: zoom);
        list.add(TilePoint(tile.x - i, tile.y - j, tile.z));
      }
    }
    zoom--;
  }

  return list;
}
