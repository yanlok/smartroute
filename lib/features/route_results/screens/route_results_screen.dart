import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../planner/application/planner_controller.dart';

class RouteResultsScreen extends StatelessWidget {
  final PlannerController controller;
  final VoidCallback onBack;
  final ValueChanged<JourneyOption> onOpenRoute;

  const RouteResultsScreen({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onOpenRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final origin = controller.origin;
        final destination = controller.destination;
        final originName = origin != null
            ? TransitPresentation.formatStopName(origin.name)
            : null;
        final destName = destination != null
            ? TransitPresentation.formatStopName(destination.name)
            : null;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppPageHeader(
                title: 'Compare routes',
                subtitle: originName == null || destName == null
                    ? null
                    : '$originName → $destName',
                onBack: onBack,
              ),
              Expanded(
                child: controller.routes.isEmpty
                    ? _EmptyResults(onBack: onBack)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal,
                          AppSpacing.sectionLg,
                          AppSpacing.pageHorizontal,
                          AppSpacing.pageBottom,
                        ),
                        itemCount: controller.routes.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sectionLg),
                        itemBuilder: (context, index) {
                          final route = controller.routes[index];
                          return _RouteCard(
                            journey: route,
                            network: controller.network!,
                            recommended: index == 0,
                            onTap: () {
                              controller.selectRoute(route);
                              onOpenRoute(route);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final JourneyOption journey;
  final TransitNetwork network;
  final bool recommended;
  final VoidCallback onTap;

  const _RouteCard({
    required this.journey,
    required this.network,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transitSegments = journey.segments.where((item) => !item.isWalking);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: recommended ? AppColors.primary : AppColors.borderLight,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gapMd,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: recommended
                        ? AppColors.primaryLight
                        : AppColors.mutedBg,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    journey.objective.label.toUpperCase(),
                    style: AppTypography.captionBold.copyWith(
                      color: recommended
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${journey.durationMinutes} min',
                  style: AppTypography.monoLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            Wrap(
              spacing: AppSpacing.gapSm,
              runSpacing: AppSpacing.gapSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final segment in transitSegments) ...[
                  if (network.routesById[segment.routeId] case final route?)
                    _LineChip(route: route),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            Row(
              children: [
                _Metric(
                  icon: Icons.sync_alt_rounded,
                  label:
                      '${journey.transferCount} transfer${journey.transferCount == 1 ? '' : 's'}',
                ),
                const SizedBox(width: AppSpacing.sectionLg),
                _Metric(
                  icon: Icons.directions_walk_rounded,
                  label: '${journey.walkingMetres} m walk',
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChip extends StatelessWidget {
  final TransitRoute route;

  const _LineChip({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gapMd,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TransitPresentation.routeColor(route),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        route.shortName.isEmpty ? route.mode.label : route.shortName,
        style: AppTypography.captionBold.copyWith(color: AppColors.surface),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}

class _EmptyResults extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyResults({required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.route_outlined,
            size: 42,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Text('No route options to show', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.gapMd),
          const Text('Return to the planner and choose two official stops.'),
          const SizedBox(height: AppSpacing.sectionLg),
          OutlinedButton(
            onPressed: onBack,
            child: const Text('Back to planner'),
          ),
        ],
      ),
    ),
  );
}
