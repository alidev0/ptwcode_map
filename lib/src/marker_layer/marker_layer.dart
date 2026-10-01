import 'package:flutter/material.dart';

import '../calculations/calculator.dart';
import '../calculations/lat_lon_cal.dart';
import '../models/circle.dart';
import '../models/marker.dart';
import '../ui/helper.dart';
import 'positioned_cluster.dart';
import 'positioned_marker.dart';

/// MarkerLayer
class MarkerLayer extends StatelessWidget {
  const MarkerLayer({
    super.key,
    required this.animateFromCircles,
    this.markerBuilder,
    required this.enableCluster,
    this.clusterBuilder,
    required this.markers,
  });

  final void Function(List<Circle> points) animateFromCircles;
  final Widget Function(double, Map<String, dynamic>?)? markerBuilder;
  final bool enableCluster;
  final Widget Function(int count, double size)? clusterBuilder;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    final mapScale = Helper.mapScaleOf(context);
    final center = Helper.centerOf(context);
    final clusterRad = Helper.clusterRadOf(context);

    var allCircles = markers
        .map(
          (el) => Circle(
            marker: el,
            clusterRad: clusterRad,
            pixel: latLonToPixelPoint(latLon: el.latLon, mapScale: mapScale),
          ),
        )
        .toList();

    List<Marker> newMarkes = [];
    List<List<Circle>> clusters = [];

    while (allCircles.isNotEmpty) {
      final circle1 = allCircles.first;

      List<Circle> cluster = [];
      for (var circle2 in allCircles) {
        if (!enableCluster) continue;
        if (circle1.isEqual(circle2)) continue;

        final intersects = circle1.intersects(circle2);
        if (!intersects) continue;

        if (cluster.isEmpty) cluster.add(circle1);
        cluster.add(circle2);
      }

      if (cluster.isNotEmpty) clusters.add(cluster);
      if (cluster.isEmpty) newMarkes.add(circle1.marker);

      allCircles.remove(circle1);

      for (Circle el1 in cluster) {
        allCircles.removeWhere((el2) => el1.isEqual(el2));
      }
    }

    return Stack(
      children: [
        ...newMarkes.map((marker) {
          return PositionedMarker(
            marker: marker,
            builder: markerBuilder,
            point: latLonToPixelPoint(
              latLon: marker.latLon,
              mapScale: mapScale,
            ),
            onTap: () {},
            mapCenter: center,
          );
        }),
        ...clusters.map((cluster) {
          return PositionedCluster(
            point: getCirclesPixelCentroid(cluster),
            onTap: () {
              animateFromCircles([
                getFurthestCircle(cluster),
                getCirclesCircleCentroid(cluster),
              ]);
            },
            count: cluster.length,
            mapCenter: center,
            builder: clusterBuilder,
          );
        }),
      ],
    );
  }
}
