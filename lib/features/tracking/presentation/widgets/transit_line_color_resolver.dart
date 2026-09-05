import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TransitLineColorResolver {
  TransitLineColorResolver._();

  static Color resolve(String colorToken) {
    switch (colorToken) {
      case 'kjLine':
        return AppColors.kjLine;
      case 'spLine':
        return AppColors.spLine;
      case 'mkLine':
        return AppColors.mkLine;
      case 'mpLine':
        return AppColors.mpLine;
      case 'mlLine':
        return AppColors.mlLine;
      case 'brLine':
        return AppColors.brLine;
      case 'busLine':
        return AppColors.busLine;
      default:
        return AppColors.primary;
    }
  }
}
