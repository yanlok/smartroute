import 'package:flutter/material.dart';

import '../../shared/models/transit_models.dart';
import '../theme/app_colors.dart';

class TransitPresentation {
  const TransitPresentation._();

  static Color routeColor(TransitRoute route) {
    final value = route.colorHex.replaceFirst('#', '');
    final parsed = int.tryParse(value, radix: 16);
    if (parsed != null && value.length == 6) return Color(0xFF000000 | parsed);
    return modeColor(route.mode);
  }

  static Color modeColor(TransitMode mode) => switch (mode) {
    TransitMode.lrt => AppColors.kjLine,
    TransitMode.mrt => AppColors.mkLine,
    TransitMode.monorail => AppColors.mlLine,
    TransitMode.brt => AppColors.brLine,
    TransitMode.bus => AppColors.busLine,
  };

  static IconData modeIcon(TransitMode mode) => switch (mode) {
    TransitMode.bus || TransitMode.brt => Icons.directions_bus_rounded,
    TransitMode.monorail => Icons.tram_rounded,
    TransitMode.lrt || TransitMode.mrt => Icons.train_rounded,
  };

  static String formatStopName(String rawName) {
    var name = rawName.trim();
    if (name.isEmpty) return name;

    final prefixRegex = RegExp(
      r'^(?:\([A-Za-z0-9]+\)\s*)?(?:[A-Za-z]{2,4}\d{1,5}\s+)',
      caseSensitive: false,
    );
    final match = prefixRegex.firstMatch(name);
    if (match != null) {
      final stripped = name.substring(match.end).trim();
      if (stripped.isNotEmpty) {
        name = stripped;
      }
    } else {
      final mPrefix = RegExp(r'^\([mM]\d*\)\s*');
      final mMatch = mPrefix.firstMatch(name);
      if (mMatch != null) {
        final stripped = name.substring(mMatch.end).trim();
        if (stripped.isNotEmpty) {
          name = stripped;
        }
      }
    }

    final trailingNoiseRegex = RegExp(
      r'\s*\((?:opp\.?|opposite|platform\s+[A-Za-z0-9\s\-]+|pintu\s+[A-Za-z0-9\s\-]+)\)$',
      caseSensitive: false,
    );
    name = name.replaceAll(trailingNoiseRegex, '').trim();

    return name.isNotEmpty ? name : rawName;
  }
}
