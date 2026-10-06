import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ptwcode_map/ptwcode_map.dart';

import '../locations.dart';
import 'style.dart';

class Bottom extends StatelessWidget {
  const Bottom({
    super.key,
    required this.ctrl,
    required this.activeMarkers,
    required this.onTapSwitchMarkers,
    required this.debugMode,
    required this.toggleDebugMode,
    required this.clusterMode,
    required this.toggleClusterMode,
    required this.onTapSwitchLines,
  });

  final MapCtrl ctrl;
  final List<LatLon> activeMarkers;
  final Function() onTapSwitchMarkers;
  final bool debugMode;
  final Function() toggleDebugMode;
  final bool clusterMode;
  final Function() toggleClusterMode;
  final Function() onTapSwitchLines;

  @override
  Widget build(BuildContext context) {
    final mQ = MediaQuery.of(context);
    var gap = max(mQ.padding.bottom, mQ.viewInsets.bottom);
    gap = max(gap, 8);

    const blue = Colors.blue;
    const shape = BoxShape.circle;
    final border = Border.all(color: Colors.white);

    Widget iconButton(IconData icon, Function() fun) {
      Widget curr = Icon(icon, color: Colors.white, size: 24);
      curr = Center(child: curr);

      final decor = BoxDecoration(color: blue, shape: shape, border: border);
      curr = DecoratedBox(decoration: decor, child: curr);

      curr = SizedBox(width: 56, height: 56, child: curr);
      curr = Padding(padding: const EdgeInsets.all(4), child: curr);
      return GestureDetector(onTap: fun, child: curr);
    }

    Widget button(String text, LatLon latLon, double zoom) {
      final isActive = activeMarkers.contains(latLon);

      Widget curr = Text(text, style: textStyle);
      curr = FittedBox(fit: BoxFit.scaleDown, child: curr);
      curr = Center(child: curr);
      curr = Padding(padding: const EdgeInsets.all(4), child: curr);

      curr = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.blue,
          border: Border.all(color: Colors.white),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: curr,
      );
      curr = SizedBox(width: 72, height: 32, child: curr);
      curr = Opacity(opacity: isActive ? 1 : 0.25, child: curr);

      if (!isActive) return curr;

      return GestureDetector(
        onTap: () => ctrl.animateTo(latLon, zoom),
        child: curr,
      );
    }

    Widget curent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            button('London', londonLocation, 4),
            button('Madrid', madridLocation, 5),
            button('Vienna', viennaLocation, 6),
            button('Istanbul', istanbulLocation, 7),
            button('Stockholm', stockholmLocation, 8),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            button('Budapest', budapestLocation, 9),
            button('Lisbon', lisbonLocation, 10),
            button('Paris', parisLocation, 11),
            button('Rome', romeLocation, 12),
            button('Berlin', berlinLocation, 13),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            button('Prishtin', prishtinaLocation, 14),
            button('Shkup', shkupLocation, 15),
            button('Tirana3', tirana3Location, 16),
            button('Tirana2', tirana2Location, 16),
            button('Tirana1', tirana1Location, 16),
          ],
        ),
        SizedBox(height: gap),
      ],
    );

    curent = ColoredBox(color: blueColor.withValues(alpha: 0.5), child: curent);

    final debugIcon = debugMode ? Icons.deblur : Icons.deblur_outlined;
    final clusterIcon = clusterMode
        ? Icons.bubble_chart
        : Icons.bubble_chart_outlined;

    curent = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        iconButton(debugIcon, toggleDebugMode),
        iconButton(clusterIcon, toggleClusterMode),
        iconButton(Icons.location_pin, onTapSwitchMarkers),
        iconButton(Icons.line_axis, onTapSwitchLines),
        iconButton(Icons.location_searching, () => ctrl.animateTo(myGps, 18)),
        // iconButton(
        //   Icons.location_searching,
        //   () => ctrl.animateTo(LatLon(41.5925606, 20.40223467), 8),
        // ),
        curent,
      ],
    );
    curent = SizedBox(width: mQ.size.width, child: curent);

    return Positioned(bottom: 0, child: curent);
  }
}
