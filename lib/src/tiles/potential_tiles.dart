import '../calculations/lat_lon_cal.dart';
import '../models/lat_lon.dart';
import '../models/tile_point.dart';

List<TilePoint> potentialTiles({List<LatLon>? markers, LatLon? gps}) {
  List<TilePoint> newList = [];

  if (markers != null) {
    final markerTiles = _getTiles(markers: markers);
    newList.addAll(markerTiles);
  }

  if (gps != null) {
    final gpsTiles = _getTiles(markers: [gps]);
    newList.addAll(gpsTiles);
  }

  /// remove duplicated models
  newList = newList.toSet().toList();

  return newList;
}

/// getMarkerTiles
List<TilePoint> _getTiles({required List<LatLon> markers}) {
  List<TilePoint> list = [];

  final listOfZoom = [6, 9, 12, 15, 17, 20]; // +3

  for (var zoom in listOfZoom) {
    for (LatLon marker in markers) {
      final tile = latLonToTilePoint(latLon: marker, zoom: zoom);

      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          list.add(TilePoint(tile.x - i, tile.y - j, tile.z));
        }
      }
    }
  }

  return list;
}
