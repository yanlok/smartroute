import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Resolves a [TransitLine.colorToken] string (e.g. `"kjLine"`,
/// `"mkLine"`) to a concrete [Color] from [AppColors].
///
/// This is the single, validated boundary between the domain's
/// token names and the theme palette. Per `docs/design.md` §3,
/// raw hex strings must never be scattered through widgets — they
/// must be converted at a reusable presentation boundary with a
/// validated fallback.
///
/// Add a new case here when introducing a new [TransitLine]
/// `colorToken` value in the domain layer.
class TransitLineColorResolver {
  TransitLineColorResolver._();

  /// Returns the brand colour for the given token, or a sensible
  /// fallback ([AppColors.primary]) for unknown tokens so the UI
  /// never crashes on bad data.
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
