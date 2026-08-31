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
}
