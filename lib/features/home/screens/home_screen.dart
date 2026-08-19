import 'package:flutter/material.dart';

import '../../../core/constants/navigation_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/kl_skyline.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/domain/models/app_user.dart';

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
        // ── Header Hero ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientHeader,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
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
                            'Welcome back,',
                            style: AppTypography.headerLabel.copyWith(
                              color: AppColors.white65,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_displayName 👋',
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to plan your next trip?',
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
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const KLSkyline(height: 148),
            ],
          ),
        ),

        // ── Scrollable Body ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Main Planner CTA Card
                    _PrimaryJourneyCard(
                      onTap: () => widget.onNavigate(AppScreen.planner),
                    ),

                    const SizedBox(height: 18),

                    // Your Travel Setup (Real preferences summary)
                    _TravelSetupSection(
                      profileController: widget.profileController,
                      userId: widget.authUser.id,
                    ),

                    const SizedBox(height: 20),

                    // Explore SmartRoute (Polished feature cards)
                    _ExploreSection(onNavigate: widget.onNavigate),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Main Planner CTA Card ──────────────────────────────────────────────────

class _PrimaryJourneyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryJourneyCard({required this.onTap});

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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAN YOUR JOURNEY',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a destination and compare route options.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.mutedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Your Travel Setup Section ──────────────────────────────────────────────

class _TravelSetupSection extends StatelessWidget {
  final ProfileController profileController;
  final String userId;

  const _TravelSetupSection({
    required this.profileController,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isLoaded = profileController.isLoadedFor(userId);
    final prefs = isLoaded ? profileController.preferences : null;

    final notifText = prefs != null
        ? (prefs.notificationsEnabled ? 'On' : 'Off')
        : '—';
    final locationText = prefs != null
        ? (prefs.locationEnabled ? 'On' : 'Off')
        : '—';
    final languageText = prefs != null
        ? (prefs.language == 'ms' ? 'Bahasa Melayu' : 'English (Malaysia)')
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR TRAVEL SETUP', style: AppTypography.captionBlack),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SetupChip(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: notifText,
                active: prefs?.notificationsEnabled ?? false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SetupChip(
                icon: Icons.near_me_outlined,
                label: 'Location',
                value: locationText,
                active: prefs?.locationEnabled ?? false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SetupChip(
                icon: Icons.language_rounded,
                label: 'Language',
                value: languageText,
                active: true,
                isLanguage: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SetupChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;
  final bool isLanguage;

  const _SetupChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    this.isLanguage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: value == '—'
                    ? AppColors.textTertiary
                    : (active ? AppColors.secondary : AppColors.textTertiary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: value == '—'
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
              fontSize: isLanguage ? 11 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Explore SmartRoute Section ─────────────────────────────────────────────

class _ExploreSection extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  const _ExploreSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXPLORE SMARTROUTE', style: AppTypography.captionBlack),
        const SizedBox(height: 10),
        _FeatureCard(
          key: const Key('home_transit_map_card'),
          icon: Icons.map_outlined,
          iconColor: AppColors.secondary,
          iconBg: AppColors.secondaryLight,
          title: 'Transit Map',
          subtitle: 'Explore transit lines and stations',
          onTap: () => onNavigate(AppScreen.map),
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          key: const Key('home_service_alerts_card'),
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.amber,
          iconBg: AppColors.amberBg,
          title: 'Service Alerts',
          subtitle: 'View service notices and disruptions',
          onTap: () => onNavigate(AppScreen.alerts),
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          key: const Key('home_profile_card'),
          icon: Icons.manage_accounts_outlined,
          iconColor: AppColors.success,
          iconBg: AppColors.successBg,
          title: 'Profile & Preferences',
          subtitle: 'Manage your SmartRoute settings',
          onTap: () => onNavigate(AppScreen.profile),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.iconGray,
            ),
          ],
        ),
      ),
    );
  }
}
