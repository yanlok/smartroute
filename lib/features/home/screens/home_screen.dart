import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/network_pulse_card.dart';
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
            : 'Commuter';
        final network = widget.transitController.network;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _HomeHero(
                greeting: getGreeting(),
                userName: displayName,
                unreadAlertsCount: widget.notices.unreadCount,
                onAlerts: widget.onAlerts,
                onPlan: widget.onPlan,
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
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

                      _SectionHeader(
                        title: 'SAVED COMMUTES',
                        actionText: widget.savedJourneys.favorites.isEmpty
                            ? null
                            : 'Plan new',
                        onAction: widget.savedJourneys.favorites.isEmpty
                            ? null
                            : widget.onPlan,
                      ),
                      const SizedBox(height: AppSpacing.gapMd),
                      if (widget.savedJourneys.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.gapLg,
                          ),
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else if (widget.savedJourneys.favorites.isEmpty)
                        const _EmptyStateCard(
                          icon: Icons.favorite_border_rounded,
                          text:
                              'Save a route from Route Detail to keep it here.',
                        )
                      else
                        for (final favorite
                            in widget.savedJourneys.favorites.take(4)) ...[
                          _SavedJourneyCard(
                            favorite: favorite,
                            network: network,
                            onTap: () => widget.onReplan(
                              favorite.originStopId,
                              favorite.destinationStopId,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.gapMd),
                        ],

                      const SizedBox(height: AppSpacing.sectionXl),

                      const _SectionHeader(title: 'RECENT JOURNEYS'),
                      const SizedBox(height: AppSpacing.gapMd),
                      if (widget.savedJourneys.recentSearches.isEmpty)
                        const _EmptyStateCard(
                          icon: Icons.history_rounded,
                          text: 'Successful journey searches appear here.',
                        )
                      else
                        for (final recent
                            in widget.savedJourneys.recentSearches.take(4)) ...[
                          _RecentJourneyRow(
                            recent: recent,
                            network: network,
                            onTap: () => widget.onReplan(
                              recent.originStopId,
                              recent.destinationStopId,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.gapSm),
                        ],

                      const SizedBox(height: AppSpacing.sectionXl),

                      NetworkPulseCard(
                        routeCount: network?.metadata.routeCount,
                        stopCount: network?.metadata.stopCount,
                        onTap: widget.onTransit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  final String greeting;
  final String userName;
  final int unreadAlertsCount;
  final VoidCallback onAlerts;
  final VoidCallback onPlan;

  const _HomeHero({
    required this.greeting,
    required this.userName,
    required this.unreadAlertsCount,
    required this.onAlerts,
    required this.onPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientDarkHero,
        ),
        boxShadow: AppShadows.header,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl2,
            AppSpacing.sectionMd,
            AppSpacing.xxl2,
            AppSpacing.sectionXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.white65,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          tooltip: 'Alerts',
                          onPressed: onAlerts,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(AppSpacing.gapMd),
                          ),
                          icon: const Icon(
                            Icons.notifications_outlined,
                            size: 22,
                          ),
                        ),
                      ),
                      if (unreadAlertsCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.circular,
                              ),
                              border: Border.all(
                                color: AppColors.surfaceDark,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$unreadAlertsCount',
                              style: AppTypography.captionBold.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionXl),

              Text(
                'Where are you going?',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plan your next Klang Valley journey.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white65,
                ),
              ),

              const SizedBox(height: AppSpacing.sectionLg),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPlan,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.white10,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.white15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.statusOnTime,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gapLg),
                            Expanded(
                              child: Text(
                                'Nearby origin or station',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.white65,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: AppColors.white55,
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 3.5),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 1,
                              height: 16,
                              color: AppColors.white25,
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.gapLg),
                            Expanded(
                              child: Text(
                                'Where to? (e.g. Pasar Seni, KLCC)',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sectionMd),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.buttonVerticalMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.alt_route_rounded, size: 18),
                  label: Text(
                    'Plan a journey',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityNotice extends StatelessWidget {
  final ServiceNotice notice;
  final VoidCallback onTap;

  const _PriorityNotice({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.amberBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notice.source == NoticeSource.official
                              ? 'OFFICIAL NOTICE'
                              : 'SMARTROUTE NOTICE',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notice.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.amber,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTypography.captionBlack.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
      ),
      if (actionText != null && onAction != null)
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              actionText!,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
    ],
  );
}

class _SavedJourneyCard extends StatelessWidget {
  final FavoriteJourney favorite;
  final TransitNetwork? network;
  final VoidCallback onTap;

  const _SavedJourneyCard({
    required this.favorite,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final originRaw =
        network?.stopsById[favorite.originStopId]?.name ??
        favorite.originStopId;
    final destinationRaw =
        network?.stopsById[favorite.destinationStopId]?.name ??
        favorite.destinationStopId;

    final originFormatted = TransitPresentation.formatStopName(originRaw);
    final destinationFormatted = TransitPresentation.formatStopName(
      destinationRaw,
    );

    final rawLower = favorite.label.toLowerCase();
    final bool isDefaultStopLabel =
        rawLower.contains('(platform') ||
        rawLower.contains('(opp') ||
        favorite.label == '$originRaw to $destinationRaw' ||
        favorite.label == '$originFormatted to $destinationFormatted' ||
        favorite.label == '$originRaw -> $destinationRaw' ||
        favorite.label == '$originFormatted -> $destinationFormatted';

    final headerTitle = isDefaultStopLabel
        ? 'SAVED COMMUTE'
        : TransitPresentation.formatStopName(favorite.label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.gapSm),
                  Expanded(
                    child: Text(
                      headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isDefaultStopLabel
                          ? AppTypography.captionBlack.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            )
                          : AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gapMd,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Text(
                      favorite.objective.label.toUpperCase(),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gapMd),

              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.statusOnTime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1.5,
                        height: 14,
                        color: AppColors.border,
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          originFormatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destinationFormatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentJourneyRow extends StatelessWidget {
  final RecentJourney recent;
  final TransitNetwork? network;
  final VoidCallback onTap;

  const _RecentJourneyRow({
    required this.recent,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final originRaw = network?.stopsById[recent.originStopId]?.name ?? 'Origin';
    final destinationRaw =
        network?.stopsById[recent.destinationStopId]?.name ?? 'Destination';

    final originFormatted = TransitPresentation.formatStopName(originRaw);
    final destinationFormatted = TransitPresentation.formatStopName(
      destinationRaw,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.gapMd,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$originFormatted → $destinationFormatted',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search again',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyStateCard({required this.icon, required this.text});

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
        Icon(icon, color: AppColors.textTertiary, size: 20),
        const SizedBox(width: AppSpacing.gapXl),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
