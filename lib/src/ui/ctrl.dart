part of '../map.dart';

/// MapCtrl
class MapCtrl {
  /// Reads the current zoom, or zero before the map is attached.
  double Function() _getZoom = () => 0.0;

  /// The current zoom level, or zero before the map is attached.
  double get zoom => _getZoom();

  /// animate to a location
  late void Function(LatLon, double) animateTo;

  /// preload tiles for your locations
  static void preload({
    required String user,
    required String styleId,
    required String accessToken,
    required List<LatLon> locations,
    bool debugMode = false,
  }) async {
    MapLog.debugMode = debugMode;

    await mainProvider.init(
      user: user,
      styleId: styleId,
      accessToken: accessToken,
    );

    preloadTiles(locations);
  }
}
