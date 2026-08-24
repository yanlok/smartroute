import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class RouteDetailScreen extends StatelessWidget {
  final VoidCallback onBack;
  final bool isFavourite;
  final ValueChanged<bool> onFavouriteChanged;

  const RouteDetailScreen({
    super.key,
    required this.onBack,
    required this.isFavourite,
    required this.onFavouriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RouteHeader(
          isFavourite: isFavourite,
          onBack: onBack,
          onFavourite: () => onFavouriteChanged(!isFavourite),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sectionLg,
                AppSpacing.pageHorizontal,
                AppSpacing.pageBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RouteOverview(),
                  const SizedBox(height: AppSpacing.sectionLg),
                  const _NextStopCard(),
                  const SizedBox(height: AppSpacing.sectionLg),
                  const _SectionTitle('ROUTE STOPS'),
                  const SizedBox(height: AppSpacing.gapMd),
                  const _StopsCard(),
                  const SizedBox(height: AppSpacing.sectionLg),
                  const _SectionTitle('SERVICE INFORMATION'),
                  const SizedBox(height: AppSpacing.gapMd),
                  const _ServiceInformation(),
                  const SizedBox(height: AppSpacing.sectionLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isFavourite ? null : () => onFavouriteChanged(true),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: Text(isFavourite ? 'Added to favourites' : 'Add to favourite'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onBack;
  final VoidCallback onFavourite;

  const _RouteHeader({
    required this.isFavourite,
    required this.onBack,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.header),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: AppSpacing.gapXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route information', style: AppTypography.titleMedium),
                      Text('Static prototype details', style: AppTypography.labelMedium),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isFavourite ? 'Remove favourite route' : 'Save favourite route',
                  onPressed: onFavourite,
                  icon: Icon(isFavourite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                  color: isFavourite ? AppColors.primary : AppColors.iconDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteOverview extends StatelessWidget {
  const _RouteOverview();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gapMd, vertical: AppSpacing.gapXs),
                decoration: BoxDecoration(color: AppColors.busLine, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text('T250', style: AppTypography.captionBold.copyWith(color: AppColors.surface)),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(child: Text('Bus Route', style: AppTypography.headlineSmall)),
              const _StatusBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.gapXs),
          Text('Wangsa Maju → TAR UMT', style: AppTypography.description.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.gapXl),
          const Row(
            children: [
              Expanded(child: _Metric('Frequency', '10–15 min', Icons.schedule_rounded)),
              Expanded(child: _Metric('Fare', 'RM 1.00', Icons.account_balance_wallet_rounded)),
              Expanded(child: _Metric('Stops', '4', Icons.location_on_outlined)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gapMd, vertical: AppSpacing.gapXs),
        decoration: BoxDecoration(color: AppColors.statusOnTimeBg, borderRadius: BorderRadius.circular(AppRadius.circular)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.statusOnTimeText, size: 12),
            const SizedBox(width: AppSpacing.gapXs),
            Text('On time', style: AppTypography.captionBold.copyWith(color: AppColors.statusOnTimeText)),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.iconGray),
          const SizedBox(height: AppSpacing.gapXs),
          Text(value, style: AppTypography.monoSmallBold),
          Text(label, style: AppTypography.captionMedium.copyWith(color: AppColors.textSecondary)),
        ],
      );
}

class _NextStopCard extends StatelessWidget {
  const _NextStopCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_bus_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected stop: Wangsa Maju LRT', style: AppTypography.bodyLarge),
                  const SizedBox(height: AppSpacing.gapXs),
                  Text('T250 operates towards TAR UMT.', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.captionBlack);
}

class _StopsCard extends StatelessWidget {
  const _StopsCard();
  static const _stops = [
    ('Wangsa Maju LRT', 'Stop 1'),
    ('PV128', 'Stop 2'),
    ('Columbia Asia', 'Stop 3'),
    ('TAR UMT', 'Stop 4 · Destination'),
  ];

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        child: Column(
          children: [
            for (var index = 0; index < _stops.length; index++)
              _StopRow(
                _stops[index].$1,
                _stops[index].$2,
                isCurrent: index == 0,
                isLast: index == _stops.length - 1,
              ),
          ],
        ),
      );
}

class _StopRow extends StatelessWidget {
  final String name;
  final String timing;
  final bool isCurrent;
  final bool isLast;
  const _StopRow(this.name, this.timing, {required this.isCurrent, required this.isLast});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast) Positioned(top: 20, child: Container(width: 2, height: 24, color: AppColors.busLine.withValues(alpha: 0.28))),
                  Container(
                    width: isCurrent ? 14 : 10,
                    height: isCurrent ? 14 : 10,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.busLine : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.busLine, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.gapSm),
            Expanded(child: Text(name, style: isCurrent ? AppTypography.bodyLarge : AppTypography.bodyMedium)),
            Text(timing, style: AppTypography.labelMedium.copyWith(color: isCurrent ? AppColors.secondary : AppColors.textSecondary)),
          ],
        ),
      );
}

class _ServiceInformation extends StatelessWidget {
  const _ServiceInformation();

  @override
  Widget build(BuildContext context) => const _SurfaceCard(
        child: Column(
          children: [
            _InfoRow(Icons.calendar_today_outlined, 'Operating hours', '6:00 AM – 11:00 PM'),
            Divider(color: AppColors.borderLight),
            _InfoRow(Icons.schedule_rounded, 'Frequency', 'Every 10–15 minutes'),
            Divider(color: AppColors.borderLight),
            _InfoRow(Icons.payments_outlined, 'Fare', 'RM 1.00'),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapSm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.iconDark),
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.captionMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: child,
      );
}
