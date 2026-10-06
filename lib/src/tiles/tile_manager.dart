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
  LatLon? gps,
}) async {
  List<TilePoint> newList = zoom3Tiles();

  final newZoom = zoom.floor();

  final centerTile = getCenterTile(
    center: center,
    zoom: newZoom.toDouble(),
    mapScale: mapScale,
  );

  final horizontalTiles = newZoom < 4
      ? <TilePoint>[]
      : _horizontalTiles(zoom: newZoom, centerTile: centerTile);

  newList.addAll(horizontalTiles);

  final verticalTiles = _verticalTiles(
    center: center,
    zoom: newZoom,
    centerTile: centerTile,
  );

  newList.addAll(verticalTiles);

  if (gps != null) {
    final gpsTiles = _gpsTiles(gps: gps);
    newList.addAll(gpsTiles);
  }

  /// remove duplicated models
  newList = newList.toSet().toList();

  /// sort tiles 3to22
  newList.sort((a, b) => a.z - b.z);

  return newList;
}

/// zoom3Tiles
List<TilePoint> zoom3Tiles() {
  List<TilePoint> list = [];

  for (var x = 0; x < 8; x++) {
    for (var y = 0; y < 8; y++) {
      list.add(TilePoint(x, y, 3));
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

    if (zoomIndex == zoom - 1) {
      final hList = _horizontalTiles(
        centerTile: TilePoint(theXIndex, theYIndex, zoomIndex),
        zoom: zoomIndex,
        expand: 1,
      );
      list.addAll(hList);
    }
  }

  return list;
}

/// _gpsTiless
List<TilePoint> _gpsTiles({required LatLon gps}) {
  List<TilePoint> list = [];

  final listOfZoom = [7, 11, 15];

  for (var zoom in listOfZoom) {
    final tile = latLonToTilePoint(latLon: gps, zoom: zoom);

    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        list.add(TilePoint(tile.x - i, tile.y - j, tile.z));
      }
    }
  }

  return list;
}
