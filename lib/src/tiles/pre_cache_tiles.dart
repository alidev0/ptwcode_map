import '../../ptwcode_map.dart';
import '../models/tile_point.dart';
import '../providers/tile_prov.dart';
import 'potential_tiles.dart';
import 'tile_manager.dart';

/// preloadTiles
void preCacheTiles(List<LatLon> locations) async {
  List<TilePoint> tiles = zoomTiles(zoom: 3);

  final markerTiles = potentialTiles(markers: locations);
  tiles.addAll(markerTiles);
  
  tiles = tiles.toSet().toList();
  tileProvider.downloadAll(tiles);
}
