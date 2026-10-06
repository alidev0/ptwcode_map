import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'calculations/calculator.dart';
import 'calculations/lat_lon_cal.dart';
import 'calculations/zoom_scale.dart';
import 'constants/constants.dart';
import 'debug/debug_w.dart';
import 'debug/map_log.dart';
import 'marker_layer/marker_layer.dart';
import 'models/circle.dart';
import 'models/lat_lon.dart';
import 'models/marker.dart';
import 'models/pixel_point.dart';
import 'models/polyline.dart';
import 'models/tile_point.dart';
import 'providers/main_prov.dart';
import 'providers/tile_prov.dart';
import 'tiles/potential_tiles.dart';
import 'tiles/preload_tiles.dart';
import 'tiles/tile.dart';
import 'tiles/tile_manager.dart';
import 'ui/helper.dart';
import 'ui/my_anim.dart';
import 'ui/my_location.dart';
import 'ui/polyline_layer.dart';
import 'ui/top_indicator.dart';

part 'ui/ctrl.dart';

/// ptwcode map
class PTWCodeMap extends StatefulWidget {
  const PTWCodeMap({
    required this.ctrl,
    super.key,
    this.markers,
    this.markerBuilder,
    this.enableCluster = false,
    this.clusterBuilder,
    required this.user,
    required this.styleId,
    required this.accessToken,
    this.debugMode = false,
    this.gps,
    this.polylines,
    this.initPos,
    this.initZoom,
    this.width,
    this.height,
    this.enableTouch = true,
    this.northBound,
    this.southBound,
    this.eastBound,
    this.westBound,
    this.markerRadius = 16,
    this.clusterRadius = 16,
    this.placeMarkerAbovePolyline = true,
    this.heading,
  });

  final MapCtrl ctrl;
  final List<Marker>? markers;
  final Widget Function(double, Map<String, dynamic>?)? markerBuilder;
  final bool enableCluster;
  final Widget Function(int count, double size)? clusterBuilder;
  final String user;
  final String styleId;
  final String accessToken;
  final bool debugMode;
  final LatLon? gps;
  final List<Polyline>? polylines;
  final LatLon? initPos;
  final double? initZoom;
  final double? width;
  final double? height;
  final bool enableTouch;
  final LatLon? northBound;
  final LatLon? southBound;
  final LatLon? eastBound;
  final LatLon? westBound;
  final double markerRadius;
  final double clusterRadius;
  final bool placeMarkerAbovePolyline;
  final double? heading;

  @override
  State<PTWCodeMap> createState() => _PTWCodeMapState();
}

class _PTWCodeMapState extends State<PTWCodeMap> {
  late MyAnimCtrl _ctrl;

  List<TilePoint> _loadedTiles = [];

  var _zoom = 0.0;
  var _mapScale = 1.0;
  late PixelPoint _center;

  var _scaleMode = 1.0;
  var _dragMode = const Offset(0, 0);

  var _prevScale = 0.0;
  late LatLon _animToLatLon;
  List<double> _zoomAnimFromTo = [];

  Timer? _timer;

  LatLon get _initLatLon => LatLon(42.03763925181516, 16.641153557869984);
  PixelPoint get _initCenter => latLonToPixelPoint(
    latLon: LatLon(42.03763925181516, 16.641153557869984),
    mapScale: 1.0,
  );

  @override
  void initState() {
    _center = _initCenter;
    widget.ctrl.animateTo = _animateTo;
    widget.ctrl._getZoom = () => _zoom;
    SchedulerBinding.instance.addPostFrameCallback((_) => _buildCallback());
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _buildCallback() async {
    await mainProvider.init(
      user: widget.user,
      styleId: widget.styleId,
      accessToken: widget.accessToken,
    );
    if (!mounted) return;

    _zoom = zoomRef;
    _prevScale = _mapScale;
    _periodicFire(Timer(Duration.zero, () {}));
    await Future.delayed(const Duration(milliseconds: 150));
    _periodicFire(Timer(Duration.zero, () {}));
    _timer = Timer.periodic(const Duration(milliseconds: 333), _periodicFire);
  }

  void _periodicFire(Timer _) async {
    _loadedTiles = await tileManager(
      center: _center,
      scale: _mapScale,
      zoom: _zoom,
      mapScale: _mapScale,
      gps: widget.gps,
    );

    if (!_isAnim) tileProvider.downloadAll(_loadedTiles);

    final potential = potentialTiles(
      markers: widget.markers?.map((el) => el.latLon).toList(),
    );

    tileProvider.downloadAll(potential);

    if (mounted) setState(() {});
  }

  var _isAnim = false;
  void _animateTo(LatLon latLon, double zoom, {bool direct = false}) async {
    if (_isAnim) return;
    _isAnim = true;

    _animToLatLon = latLon;
    _zoomAnimFromTo = [_zoom, zoom];

    if (direct) _animCalcs(1);
    if (direct) _isAnim = false;
    if (direct) return;

    final distance = getDistanceBtw2Points(
      point1: _center,
      point2: latLonToPixelPoint(latLon: latLon, mapScale: _mapScale),
    );

    final height = MediaQuery.of(context).size.height;
    final zoomDur = (_zoom - zoom).abs() <= 4 ? 200 : 1000;
    final distanceDur = distance < height * 4 ? 200 : 1000;
    final duration = max(zoomDur, distanceDur);
    _ctrl.animate(Duration(milliseconds: duration));
  }

  void _animateFromCircles(List<Circle> circles) {
    final distance = getDistanceBtw2Points(
      point1: circles.first.pixel,
      point2: circles.last.pixel,
    );

    /// (clusterRadius / distance) with how much scale does point need to get out of center radius
    final scale = _mapScale * ((widget.clusterRadius * 2.5) / distance);
    final zoom = scaleToZoom(
      scale: scale,
      zoomRef: zoomRef,
      scaleRef: scaleRef,
    );

    _animateTo(circles.last.latLng, zoom);
  }

  PixelPoint _latLonToPixelPoint(LatLon latLon) =>
      latLonToPixelPoint(latLon: latLon, mapScale: _mapScale);

  Size get _size => Size(
    widget.width ?? MediaQuery.of(context).size.width,
    widget.height ?? MediaQuery.of(context).size.height,
  );

  void _boundCheck() {
    final fullW = _size.width;
    final halfW = fullW / 2;
    final fullH = _size.height;
    final halfH = fullH / 2;

    final mapSize = getMapSize(mapScale: _mapScale);

    if (_center.x - (fullW / 2) < 0) _center.x = fullW / 2;
    if (_center.y - (fullH / 2) < 0) _center.y = fullH / 2;
    if (_center.x + halfW > mapSize) _center.x = mapSize - halfW;
    if (_center.y + halfH > mapSize) _center.y = mapSize - halfH;

    final northBound = widget.northBound;
    if (northBound != null) {
      final north = _latLonToPixelPoint(northBound);
      if (_center.y - halfH < north.y) _center.y = north.y + halfH;
    }

    final southBound = widget.southBound;
    if (southBound != null) {
      final south = _latLonToPixelPoint(southBound);
      if (_center.y + halfH > south.y) _center.y = south.y - halfH;
    }

    final westBound = widget.westBound;
    if (westBound != null) {
      final west = _latLonToPixelPoint(westBound);
      if (_center.x - halfW < west.x) _center.x = west.x + halfW;
    }

    final eastBound = widget.eastBound;
    if (eastBound != null) {
      final east = _latLonToPixelPoint(eastBound);
      if (_center.x + halfW > east.x) _center.x = east.x - halfW;
    }
  }

  bool get _canShrink {
    if (_zoom <= 3.1) return false;
    final mapSize = getMapSize(mapScale: _mapScale);

    if (mapSize <= _size.height) return false;

    final northBound = widget.northBound;
    final southBound = widget.southBound;

    if (northBound != null && southBound != null) {
      final north = _latLonToPixelPoint(northBound);
      final south = _latLonToPixelPoint(southBound);
      if (south.y - north.y < _size.height) return false;
    }

    final westBound = widget.westBound;
    final eastBound = widget.eastBound;

    if (westBound != null && eastBound != null) {
      final west = _latLonToPixelPoint(westBound);
      final east = _latLonToPixelPoint(eastBound);
      if (east.x - west.x < _size.width) return false;
    }

    return true;
  }

  void _keepCenterWhenScaling() {
    final scaleBy = _prevScale / _mapScale;
    _center = PixelPoint(_center.x / scaleBy, _center.y / scaleBy);
    _prevScale = _mapScale;
  }

  bool get _isDirect {
    return widget.initPos != null || widget.initZoom != null;
  }

  void _onBuild(MyAnimCtrl ctrl) {
    _ctrl = ctrl;

    if (_isDirect) {
      _animateTo(
        widget.initPos ?? _initLatLon,
        widget.initZoom ?? _zoom,
        direct: true,
      );
    }
  }

  void _animCalcs(double anim) {
    final isShrinking = _zoomAnimFromTo.last < _zoomAnimFromTo.first;

    if (isShrinking && !_canShrink) _zoomAnimFromTo.last = _zoom;
    _zoom = lerpDouble(_zoomAnimFromTo.first, _zoomAnimFromTo.last, anim)!;

    _mapScale = zoomToScale(scaleRef: scaleRef, zoom: _zoom, zoomRef: zoomRef);
    _keepCenterWhenScaling();

    final centerAnimTo = _latLonToPixelPoint(_animToLatLon);
    _center.x = lerpDouble(_center.x, centerAnimTo.x, anim)!;
    _center.y = lerpDouble(_center.y, centerAnimTo.y, anim)!;
    _boundCheck();
  }

  @override
  Widget build(BuildContext context) {
    MapLog.debugMode = widget.debugMode;

    Widget load = SizedBox.fromSize(
      size: _size,
      child: const Center(child: CircularProgressIndicator()),
    );

    if (_loadedTiles.isEmpty) return load;

    final markers = widget.markers;
    final polylines = widget.polylines;

    return MyAnim(
      onBuild: _onBuild,
      onDone: () {
        _isAnim = false;
        _animCalcs(1);
      },
      builder: (anim) {
        if (_isDirect && _center.isEqual(_initCenter)) return load;
        if (_isAnim) _animCalcs(anim);

        final polylinesLayer = polylines != null
            ? PolylineLayer(polylines: polylines)
            : const SizedBox();

        final markerLayer = markers != null
            ? MarkerLayer(
                animateFromCircles: _animateFromCircles,
                markerBuilder: widget.markerBuilder,
                enableCluster: widget.enableCluster,
                clusterBuilder: widget.clusterBuilder,
                markers: markers,
              )
            : const SizedBox();

        Widget current = Stack(
          children: [
            ..._loadedTiles.map(
              (model) => PositionedTile(zoom: _zoom, tile: model),
            ),
            if (widget.gps != null)
              MyLocation(
                pixelPoint: _latLonToPixelPoint(widget.gps!),
                heading: widget.heading ?? widget.gps!.heading,
              ),
            TopIndicator(tiles: _loadedTiles.length),
            widget.placeMarkerAbovePolyline ? polylinesLayer : markerLayer,
            widget.placeMarkerAbovePolyline ? markerLayer : polylinesLayer,
            if (MapLog.debugMode)
              DebugW(
                sizeRef: sizeRef,
                zoomRef: zoomRef,
                zoom: _zoom,
                loadedTiles: _loadedTiles,
              ),
          ],
        );

        if (widget.enableTouch) {
          current = GestureDetector(
            onScaleStart: (data) {
              _dragMode = data.focalPoint;
              _scaleMode = 1.0;
            },
            onScaleUpdate: (data) {
              if (_isAnim) return;

              /// panning
              if (data.scale != 1.0) {
                final scaleBy = _scaleMode - data.scale;
                // prevent touch disturbances
                if (scaleBy.abs() < 0.024) return;
                // check zoom bounds
                final expand = scaleBy < 0;
                final shrink = !expand;
                if (shrink && !_canShrink) return;

                _mapScale = expand ? _mapScale * 1.03 : _mapScale / 1.04;
                _zoom = scaleToZoom(
                  scale: _mapScale,
                  zoomRef: zoomRef,
                  scaleRef: scaleRef,
                );

                _keepCenterWhenScaling();

                _scaleMode = data.scale;
                _prevScale = _mapScale;
                _boundCheck();
              }

              /// dragging
              if (data.scale == 1.0) {
                final dragByX = data.focalPoint.dx - _dragMode.dx;
                if (dragByX < 0) _center.x += dragByX.abs();
                if (dragByX > 0) _center.x -= dragByX.abs();

                final dragByY = data.focalPoint.dy - _dragMode.dy;
                if (dragByY < 0) _center.y += dragByY.abs();
                if (dragByY > 0) _center.y -= dragByY.abs();

                _boundCheck();
                _dragMode = data.focalPoint;
              }
              setState(() {});
            },
            onDoubleTap: () {
              if (_isAnim) return;
              _zoom++;
              _mapScale = _mapScale * 2;
              _keepCenterWhenScaling();
              _boundCheck();
              setState(() {});
            },
            child: current,
          );
        }

        current = SizedBox.fromSize(size: _size, child: current);

        return Helper(
          mapScale: _mapScale,
          center: _center,
          size: _size,
          markerRad: widget.markerRadius,
          clusterRad: widget.clusterRadius,
          child: current,
        );
      },
    );
  }
}
