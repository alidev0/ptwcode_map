/// PixelPoint
class PixelPoint {
  PixelPoint(this.x, this.y);
  double x;
  double y;

  @override
  String toString() {
    return 'x: $x, y: $y';
  }

  bool isEqual(PixelPoint point) {
    return point.x == x && point.y == y;
  }
}
