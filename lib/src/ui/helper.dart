import 'package:flutter/widgets.dart';

import '../models/pixel_point.dart';

class Helper extends InheritedWidget {
  const Helper({
    super.key,
    required this.mapScale,
    required this.center,
    required this.size,
    required this.markerRad,
    required this.clusterRad,
    required super.child,
  });

  final double mapScale;
  final PixelPoint center;
  final Size size;
  final double markerRad;
  final double clusterRad;

  static double mapScaleOf(BuildContext context) => _result(context).mapScale;
  static PixelPoint centerOf(BuildContext context) => _result(context).center;
  static Size sizeOf(BuildContext context) => _result(context).size;
  static double markerRadOf(BuildContext context) => _result(context).markerRad;
  static double clusterRadOf(BuildContext context) =>
      _result(context).clusterRad;

  static Helper _result(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<Helper>();
    assert(result != null, 'No $Helper found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(Helper oldWidget) => oldWidget.mapScale != mapScale;
}
