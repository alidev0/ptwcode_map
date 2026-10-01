import 'package:flutter/material.dart';

import '../calculations/calculator.dart';
import '../models/pixel_point.dart';
import 'helper.dart';
import 'style.dart';

/// MyLocation
class MyLocation extends StatelessWidget {
  const MyLocation({
    super.key,
    required this.pixelPoint,
    required this.heading,
  });

  final PixelPoint pixelPoint;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    final fullSize = Helper.sizeOf(context);
    final fullW = fullSize.width;
    final fullH = fullSize.height;
    final center = Helper.centerOf(context);

    const size = 48.0;
    final blue = Colors.blue[900];
    const shape = BoxShape.circle;

    Widget current = Container(
      width: size / 4,
      height: size / 4,
      decoration: BoxDecoration(shape: shape, color: blue),
    );

    current = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: shape, color: blue900T30Color),
      child: current,
    );

    final angle = heading;
    if (angle != null) {
      Widget triangle = CustomPaint(painter: _Painter(x: 12, y: 8));
      triangle = SizedBox(width: 12, height: 8, child: triangle);
      current = Stack(
        alignment: Alignment.center,
        children: [current, Positioned(top: 8, child: triangle)],
      );
      current = SizedBox(width: size, height: size, child: current);
      current = Transform.rotate(angle: degreeToRadian(angle), child: current);
    }

    return Positioned(
      left: pixelPoint.x + (fullW / 2) - center.x - (size / 2),
      top: pixelPoint.y + (fullH / 2) - center.y - (size / 2),
      child: current,
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({required this.x, required this.y});

  final double x;
  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Colors.blue[900] ?? Colors.blue;

    canvas.drawPath(
      Path()
        ..moveTo(0, y)
        ..lineTo(x / 2, 0)
        ..lineTo(x, y)
        ..lineTo(0, y),
      Paint()
        ..color = blue
        ..strokeWidth = 1
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) => true;
}
