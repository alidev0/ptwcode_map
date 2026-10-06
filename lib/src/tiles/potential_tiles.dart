import '../calculations/lat_lon_cal.dart';
import '../models/lat_lon.dart';
import '../models/tile_point.dart';

List<TilePoint> potentialTiles({List<LatLon>? markers}) {
  List<TilePoint> newList = [];

  if (markers != null) {
    final markerTiles = getMarkerTiles(markers: markers);
    newList.addAll(markerTiles);
  }

  /// remove duplicated models
  newList = newList.toSet().toList();

  return newList;
}

/// getMarkerTiles
List<TilePoint> getMarkerTiles({required List<LatLon> markers}) {
  List<TilePoint> list = [];

  final listOfZoom = [7, 11, 15];

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
