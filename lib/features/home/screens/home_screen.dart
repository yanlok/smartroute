import 'package:flutter/material.dart';

import '../../../core/constants/navigation_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/kl_skyline.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/domain/models/app_user.dart';

/// Pure time-of-day greeting helper based on local hour.
///
/// 05:00–11:59 → Good morning
/// 12:00–16:59 → Good afternoon
/// otherwise   → Good evening
@visibleForTesting
String getGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) {
    return 'Good morning';
  } else if (hour >= 12 && hour < 17) {
    return 'Good afternoon';
  } else {
    return 'Good evening';
  }
}

class HomeScreen extends StatefulWidget {
  final AppUser authUser;
  final ProfileController profileController;
  final void Function(AppScreen) onNavigate;

  const HomeScreen({
    super.key,
    required this.authUser,
    required this.profileController,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.profileController.addListener(_onProfileChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileController != widget.profileController) {
      oldWidget.profileController.removeListener(_onProfileChanged);
      widget.profileController.addListener(_onProfileChanged);
    }
    if (oldWidget.authUser.id != widget.authUser.id ||
        oldWidget.profileController != widget.profileController) {
      _ensureProfileLoaded();
    }
  }

  @override
  void dispose() {
    widget.profileController.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _ensureProfileLoaded() {
    if (!mounted) return;
    if (widget.authUser.id.isEmpty) return;

    if (!widget.profileController.isLoadedFor(widget.authUser.id) &&
        !widget.profileController.isLoading) {
      widget.profileController.load(userId: widget.authUser.id);
    }
  }

  String get _displayName {
    if (widget.profileController.isLoadedFor(widget.authUser.id)) {
      final name = widget.profileController.profile?.fullName.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    final authName = widget.authUser.fullName.trim();
    if (authName.isNotEmpty) {
      return authName;
    }

    return 'SmartRoute User';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Compact Hero Header ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientBlue,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getGreeting(),
                            style: AppTypography.headerLabel.copyWith(
                              color: AppColors.white65,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_displayName 👋',
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Where would you like to go today?',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.white55,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const Key('home_notification_action'),
                      onTap: () => widget.onNavigate(AppScreen.alerts),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white20,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white25,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const KLSkyline(height: 88),
            ],
          ),
        ),

        // ── Scrollable Body with Max-Width Constraint ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        // Main Journey Card (Primary Home Feature)
                        _JourneyStarterCard(
                          onTap: () => widget.onNavigate(AppScreen.planner),
                        ),

                        const SizedBox(height: 18),

                        // SmartRoute Information Section (Non-interactive)
                        const _SmartRouteInfoSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Main Journey Starter Card ──────────────────────────────────────────────

class _JourneyStarterCard extends StatelessWidget {
  final VoidCallback onTap;
  const _JourneyStarterCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('home_planner_card'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Supporting text
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where do you want to go?',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Plan your journey across Klang Valley.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Visual route fields prompt
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  // Transit dots & connector line
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 26, color: AppColors.divider),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Route fields prompts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Start prompt
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start',
                              style: AppTypography.captionMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Choose starting point',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPlaceholder,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 10),

                        // Destination prompt
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination',
                              style: AppTypography.captionMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Search destination',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPlaceholder,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Plan Journey CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('home_plan_journey_button'),
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Plan Journey',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SmartRoute Non-Interactive Informational Section ───────────────────────

class _SmartRouteInfoSection extends StatelessWidget {
  const _SmartRouteInfoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Travel smarter with SmartRoute',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Plan public transport journeys across Klang Valley from one simple starting point.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _InfoPill(
                  icon: Icons.directions_transit_rounded,
                  label: 'Route planning',
                  color: AppColors.secondary,
                  bgColor: AppColors.secondaryLight,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  icon: Icons.map_outlined,
                  label: 'Transit information',
                  color: AppColors.amber,
                  bgColor: AppColors.amberBg,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  icon: Icons.notifications_none_rounded,
                  label: 'Service awareness',
                  color: AppColors.success,
                  bgColor: AppColors.successBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
