import 'package:dio/dio.dart';

import '../constants/constants.dart';
import '../debug/map_log.dart';
import '../models/tile_point.dart';
import 'cache_prov.dart';
import 'directory_prov.dart';

/// TileProvider
const tileProvider = TileProvider();

class TileProvider {
  const TileProvider();

  static String _user = '';
  static String _styleId = '';
  static String _accessToken = '';

  void init({
    required String user,
    required String styleId,
    required String accessToken,
  }) {
    _user = user;
    _styleId = styleId;
    _accessToken = accessToken;
  }

  void downloadAll(List<TilePoint> tiles) async {
    final limited = tiles.where((tile) => !cacheProvider.isDown(tile));
    final limited2 = limited.take(limited.length > 50 ? 50 : limited.length);
    await Future.wait(limited2.map(_checkAndDownload));
  }

  Future<void> _checkAndDownload(TilePoint tile) async {
    final isOnGoing = cacheProvider.isOnGoing(tile);
    if (isOnGoing) return;

    final isDown = cacheProvider.isDown(tile);
    if (isDown) return;
    mapLog.i('downloading: $tile');

    final path = tileProvider.path(tile);
    final url = _formUrl(tile);

    await _download(path: path, url: url, tile: tile);
  }

  String path(TilePoint tile) {
    return '${DirectoryProvider.directory}/${tile.fileName}';
  }

  String _formUrl(TilePoint tile) {
    var url = urlTemplate.replaceAll('{mapUser}', _user);
    url = url.replaceAll('{mapStyleId}', _styleId);
    url = url.replaceAll('{mapAccessToken}', _accessToken);
    url = url.replaceAll('{x}', '${tile.x}');
    url = url.replaceAll('{y}', '${tile.y}');
    url = url.replaceAll('{z}', '${tile.z}');
    return url;
  }

  Future<void> _download({
    required String path,
    required String url,
    required TilePoint tile,
  }) async {
    await cacheProvider.setOnGoing(tile);
    try {
      await dio.download(url, path).timeout(const Duration(seconds: 10));
      await cacheProvider.setDown(tile);
      await cacheProvider.clearOnGoing(tile);
    } catch (e) {
      await cacheProvider.clearOnGoing(tile);
      mapLog.e(e);
    }
  }
}

Dio? _dioInstace;
Dio get dio {
  _dioInstace ??= Dio();
  return _dioInstace!;
}
