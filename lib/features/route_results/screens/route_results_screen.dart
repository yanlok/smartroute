import '../../../core/constants/navigation_types.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/models/app_models.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class RouteResultsScreen extends StatefulWidget {
  final String from;
  final String to;
  final void Function(AppScreen) onNavigate;
  final VoidCallback onBack;

  const RouteResultsScreen({
    super.key,
    this.from = 'Asia Jaya',
    this.to = 'KL Sentral',
    required this.onNavigate,
    required this.onBack,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  String _sort = 'Recommended';
  final Set<String> _expandedRoutes = {};

  List<RouteOption> _sortedRoutes() {
    final routes = [...routeOptionsForJourney(widget.from, widget.to)];
    switch (_sort) {
      case 'Fastest':
        routes.sort((a, b) => a.duration.compareTo(b.duration));
      case 'Fewest transfers':
        routes.sort((a, b) => a.transfers.compareTo(b.transfers));
      case 'Least walking':
        routes.sort((a, b) => _walkingMinutes(a).compareTo(_walkingMinutes(b)));
    }
    return routes;
  }

  int _walkingMinutes(RouteOption route) => route.segments
      .where((segment) => segment.type == RouteSegmentType.walk)
      .fold(0, (total, segment) => total + segment.duration);

  @override
  Widget build(BuildContext context) {
    final journeyRoutes = _sortedRoutes();
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
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
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
                              Text(widget.from, style: AppTypography.bodySmall),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: AppColors.iconGray,
                              ),
                              SizedBox(width: 6),
                              _ColoredDot(color: AppColors.secondary),
                              SizedBox(width: 6),
                              Text(widget.to, style: AppTypography.bodySmall),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${journeyRoutes.length} route option${journeyRoutes.length == 1 ? '' : 's'} found',
                            style: AppTypography.captionMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSortOptions(context),
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
                ...journeyRoutes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final route = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => widget.onNavigate(AppScreen.routeDetail),
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
                                  color: Color(
                                    int.parse(
                                      '0xFF${route.labelColor.replaceFirst('#', '')}',
                                    ),
                                  ),
                                ),
                                if (idx == 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Recommended',
                                      style: AppTypography.captionBold.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.iconGray,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
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

                            InkWell(
                              onTap: () => setState(() {
                                if (_expandedRoutes.contains(route.id)) {
                                  _expandedRoutes.remove(route.id);
                                } else {
                                  _expandedRoutes.add(route.id);
                                }
                              }),
                              child: Row(
                                children: [
                                  Icon(
                                    _expandedRoutes.contains(route.id)
                                        ? Icons.expand_less_rounded
                                        : Icons.format_list_numbered_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _expandedRoutes.contains(route.id)
                                        ? 'Hide steps'
                                        : 'View steps',
                                    style: AppTypography.captionBold.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_expandedRoutes.contains(route.id))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: route.segments.asMap().entries.map((
                                    step,
                                  ) {
                                    final segment = step.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${step.key + 1}.',
                                            style: AppTypography.captionBold,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${segment.from} to ${segment.to} · ${segment.duration} min',
                                              style:
                                                  AppTypography.captionMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

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
                                      icon:
                                          Icons.account_balance_wallet_rounded,
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
                    border: Border.all(color: const Color(0x261B4FD8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
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

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort routes by', style: AppTypography.titleLarge),
              ),
            ),
            ...[
              'Recommended',
              'Fastest',
              'Fewest transfers',
              'Least walking',
            ].map(
              (option) => RadioListTile<String>(
                value: option,
                groupValue: _sort,
                title: Text(option),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sort = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
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
      child: Text(
        label,
        style: AppTypography.captionBold.copyWith(color: Colors.white),
      ),
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
        : Color(
            int.parse(
              '0xFF${segment.lineColor?.replaceFirst('#', '') ?? '9CA3AF'}',
            ),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isWalk ? const Color(0xFFF9FAFB) : color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWalk)
            Text(
              '🚶 ${segment.duration}m',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.iconGray,
              ),
            )
          else ...[
            Icon(
              segment.type == RouteSegmentType.bus
                  ? Icons.directions_bus_rounded
                  : Icons.train_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${segment.stops} stops',
              style: AppTypography.captionBold.copyWith(color: color),
            ),
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
  const _StatItem({required this.icon, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.iconGray),
        const SizedBox(width: 6),
        Text(
          value,
          style: (mono ? AppTypography.monoMedium : AppTypography.bodyLarge)
              .copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
