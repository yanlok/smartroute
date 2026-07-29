import '../../../core/constants/navigation_types.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/models/app_models.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class RouteResultsScreen extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  final VoidCallback onBack;

  const RouteResultsScreen({
    super.key,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppShadows.header,
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ColoredDot(color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Asia Jaya LRT',
                                  style: AppTypography.bodySmall),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 12, color: AppColors.iconGray),
                              SizedBox(width: 6),
                              _ColoredDot(color: AppColors.secondary),
                              SizedBox(width: 6),
                              Text('KL Sentral',
                                  style: AppTypography.bodySmall),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('Today · Depart now · 3 options found',
                              style: AppTypography.captionMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      color: AppColors.iconDark,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Results ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...routeOptions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final route = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => onNavigate(AppScreen.routeDetail),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: AppShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label row
                            Row(
                              children: [
                                _RouteBadge(
                                  label: route.label,
                                  color: Color(int.parse(
                                      '0xFF${route.labelColor.replaceFirst('#', '')}')),
                                ),
                                if (idx == 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text('Recommended',
                                        style: AppTypography.captionBold.copyWith(color: AppColors.primary)),
                                  ),
                                ],
                                const Spacer(),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 16, color: AppColors.iconGray),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Segment pills
                            SizedBox(
                              height: 28,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                itemCount: route.segments.length,
                                separatorBuilder: (_, __) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    width: 12,
                                    height: 2,
                                    color: AppColors.divider,
                                  ),
                                ),
                                itemBuilder: (context, si) {
                                  final seg = route.segments[si];
                                  return _SegmentPill(segment: seg);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Stats row
                            Container(
                              padding: const EdgeInsets.only(top: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFF9FAFB)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.access_time_rounded,
                                      value: '${route.duration} min',
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.account_balance_wallet_rounded,
                                      value:
                                          'RM ${route.fare.toStringAsFixed(2)}',
                                      mono: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      icon: Icons.sync_rounded,
                                      value:
                                          '${route.transfers} transfer${route.transfers != 1 ? 's' : ''}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x0F1B4FD8),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: const Color(0x261B4FD8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fares shown are estimates for MyRapid card holders. '
                          "Touch 'n Go accepted at all Rapid KL stations.",
                          style: AppTypography.description.copyWith(
                            color: AppColors.secondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColoredDot extends StatelessWidget {
  final Color color;
  const _ColoredDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RouteBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTypography.captionBold.copyWith(color: Colors.white)),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final RouteSegment segment;
  const _SegmentPill({required this.segment});

  @override
  Widget build(BuildContext context) {
    final isWalk = segment.type == RouteSegmentType.walk;
    final color = isWalk
        ? AppColors.iconGray
        : Color(int.parse(
            '0xFF${segment.lineColor?.replaceFirst('#', '') ?? '9CA3AF'}'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isWalk ? const Color(0xFFF9FAFB) : color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWalk)
            Text('🚶 ${segment.duration}m',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.iconGray,
                ))
          else ...[
            Icon(
              segment.type == RouteSegmentType.bus
                  ? Icons.directions_bus_rounded
                  : Icons.train_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text('${segment.stops} stops',
                style: AppTypography.captionBold.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool mono;
  const _StatItem({
    required this.icon,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.iconGray),
        const SizedBox(width: 6),
        Text(value,
            style: (mono
                    ? AppTypography.monoMedium
                    : AppTypography.bodyLarge)
                .copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
