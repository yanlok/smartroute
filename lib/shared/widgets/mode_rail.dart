import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transit_presentation.dart';
import '../models/transit_models.dart';

class ModeRail extends StatelessWidget {
  final Set<TransitMode> selectedModes;
  final ValueChanged<TransitMode> onToggleMode;
  final bool showAllOption;
  final bool isAllSelected;
  final VoidCallback? onSelectAll;

  const ModeRail({
    super.key,
    required this.selectedModes,
    required this.onToggleMode,
    this.showAllOption = false,
    this.isAllSelected = false,
    this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (showAllOption) ...[
            _ModeSegment(
              label: 'All',
              icon: Icons.hub_rounded,
              color: AppColors.textPrimary,
              isSelected: isAllSelected,
              onTap: onSelectAll ?? () {},
            ),
            const SizedBox(width: AppSpacing.gapSm),
          ],
          for (final mode in TransitMode.values) ...[
            _ModeSegment(
              label: mode.label,
              icon: TransitPresentation.modeIcon(mode),
              color: TransitPresentation.modeColor(mode),
              isSelected: selectedModes.contains(mode),
              onTap: () => onToggleMode(mode),
            ),
            if (mode != TransitMode.values.last)
              const SizedBox(width: AppSpacing.gapSm),
          ],
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gapXl,
            vertical: AppSpacing.gapMd,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.gapSm),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
