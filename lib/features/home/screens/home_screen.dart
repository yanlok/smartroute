import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../alerts/application/notice_controller.dart';
import '../../transit_network/application/transit_network_controller.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../../user_management/domain/models/app_user.dart';
import '../../user_management/domain/models/saved_journey.dart';

@visibleForTesting
String getGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17) return 'Good evening';
  return 'Hello';
}

class HomeScreen extends StatefulWidget {
  final AppUser authUser;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final NoticeController notices;
  final TransitNetworkController transitController;
  final VoidCallback onPlan;
  final VoidCallback onAlerts;
  final VoidCallback onTransit;
  final Future<void> Function(String originStopId, String destinationStopId)
  onReplan;

  const HomeScreen({
    super.key,
    required this.authUser,
    required this.profileController,
    required this.savedJourneys,
    required this.notices,
    required this.transitController,
    required this.onPlan,
    required this.onAlerts,
    required this.onTransit,
    required this.onReplan,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.profileController.isLoadedFor(widget.authUser.id)) {
      await widget.profileController.load(userId: widget.authUser.id);
    }
    await Future.wait([
      widget.savedJourneys.load(widget.authUser.id),
      widget.transitController.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.profileController,
        widget.savedJourneys,
        widget.notices,
        widget.transitController,
      ]),
      builder: (context, _) {
        final name = widget.profileController.profile?.fullName.trim();
        final displayName = name?.isNotEmpty == true
            ? name!
            : widget.authUser.fullName.trim().isNotEmpty
            ? widget.authUser.fullName.trim()
            : 'SmartRoute user';
        final network = widget.transitController.network;
        return Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.gradientBlue),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl2,
                    AppSpacing.sectionLg,
                    AppSpacing.xxl2,
                    AppSpacing.sectionXxl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getGreeting(),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.white65,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'One commute, from planning to arrival.',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.white65,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Alerts',
                            onPressed: widget.onAlerts,
                            icon: const Icon(Icons.notifications_rounded),
                          ),
                          if (widget.notices.unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: CircleAvatar(
                                radius: 9,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  '${widget.notices.unreadCount}',
                                  style: AppTypography.captionBold.copyWith(
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sectionLg,
                    AppSpacing.pageHorizontal,
                    AppSpacing.pageBottom,
                  ),
                  children: [
                    if (widget.notices.relevantNotices.firstOrNull
                        case final notice?) ...[
                      _PriorityNotice(notice: notice, onTap: widget.onAlerts),
                      const SizedBox(height: AppSpacing.sectionLg),
                    ],
                    _PlanCard(onTap: widget.onPlan),
                    const SizedBox(height: AppSpacing.sectionXl),
                    _SectionHeader(
                      title: 'FAVOURITE JOURNEYS',
                      action: widget.savedJourneys.favorites.isEmpty
                          ? null
                          : widget.onPlan,
                    ),
                    const SizedBox(height: AppSpacing.gapMd),
                    if (widget.savedJourneys.isLoading)
                      const LinearProgressIndicator(color: AppColors.primary)
                    else if (widget.savedJourneys.favorites.isEmpty)
                      const _EmptyCard(
                        icon: Icons.favorite_border_rounded,
                        text: 'Save a route from Route Detail to keep it here.',
                      )
                    else
                      for (final favorite
                          in widget.savedJourneys.favorites.take(4))
                        _JourneyTile(
                          label: favorite.label,
                          subtitle: favorite.objective.label,
                          onTap: () => widget.onReplan(
                            favorite.originStopId,
                            favorite.destinationStopId,
                          ),
                        ),
                    const SizedBox(height: AppSpacing.sectionXl),
                    const _SectionHeader(title: 'RECENT JOURNEYS'),
                    const SizedBox(height: AppSpacing.gapMd),
                    if (widget.savedJourneys.recentSearches.isEmpty)
                      const _EmptyCard(
                        icon: Icons.history_rounded,
                        text: 'Successful journey searches appear here.',
                      )
                    else
                      for (final recent
                          in widget.savedJourneys.recentSearches.take(4))
                        _RecentTile(
                          recent: recent,
                          network: network,
                          onTap: () => widget.onReplan(
                            recent.originStopId,
                            recent.destinationStopId,
                          ),
                        ),
                    const SizedBox(height: AppSpacing.sectionXl),
                    _NetworkCard(
                      routeCount: network?.metadata.routeCount,
                      stopCount: network?.metadata.stopCount,
                      onTap: widget.onTransit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PriorityNotice extends StatelessWidget {
  final ServiceNotice notice;
  final VoidCallback onTap;

  const _PriorityNotice({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: AppColors.amber),
          const SizedBox(width: AppSpacing.gapXl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.source == NoticeSource.official
                      ? 'OFFICIAL NOTICE'
                      : 'SMARTROUTE NOTICE',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.amber,
                  ),
                ),
                Text(notice.title, style: AppTypography.bodyLarge),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xxl2),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.gradientPrimary),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.cardLg,
    ),
    child: Row(
      children: [
        const Icon(Icons.alt_route_rounded, color: AppColors.surface, size: 32),
        const SizedBox(width: AppSpacing.sectionLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan a journey',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              Text(
                'Compare multimodal routes using official transit data.',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white65,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Open planner',
          onPressed: onTap,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: AppTypography.captionBlack)),
      if (action != null)
        TextButton(onPressed: action, child: const Text('Plan another')),
    ],
  );
}

class _JourneyTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _JourneyTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.favorite_rounded, color: AppColors.primary),
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _RecentTile extends StatelessWidget {
  final RecentJourney recent;
  final TransitNetwork? network;
  final VoidCallback onTap;

  const _RecentTile({
    required this.recent,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final origin = network?.stopsById[recent.originStopId]?.name ?? 'Origin';
    final destination =
        network?.stopsById[recent.destinationStopId]?.name ?? 'Destination';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.history_rounded),
        title: Text('$origin → $destination'),
        subtitle: Text('Search again'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.gapXl),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _NetworkCard extends StatelessWidget {
  final int? routeCount;
  final int? stopCount;
  final VoidCallback onTap;

  const _NetworkCard({
    required this.routeCount,
    required this.stopCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.hub_rounded, color: AppColors.secondary),
      title: const Text('Explore the official network'),
      subtitle: Text(
        routeCount == null
            ? 'Loading transit catalogue…'
            : '$routeCount routes · $stopCount stops and stations',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
