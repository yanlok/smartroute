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
                            'Welcome back,',
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
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
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

                    // Your Travel Setup (Mobile-first 2-row layout)
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
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
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
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Your Travel Setup Section (Mobile-First 2-Row Layout) ──────────────────

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

    final notifActive = prefs?.notificationsEnabled ?? false;
    final locationActive = prefs?.locationEnabled ?? false;

    final notifText = prefs != null ? (notifActive ? 'On' : 'Off') : '—';
    final locationText = prefs != null ? (locationActive ? 'On' : 'Off') : '—';
    final languageText = prefs != null
        ? (prefs.language == 'ms' ? 'Bahasa Melayu' : 'English (Malaysia)')
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR TRAVEL SETUP', style: AppTypography.captionBlack),
        const SizedBox(height: 10),

        // Row 1: Notifications + Location (2 equal cards)
        Row(
          children: [
            Expanded(
              child: _SetupCompactCard(
                icon: Icons.notifications_none_rounded,
                iconColor: notifText == '—'
                    ? AppColors.textTertiary
                    : (notifActive
                          ? AppColors.secondary
                          : AppColors.textTertiary),
                iconBg: notifText == '—'
                    ? AppColors.mutedBg
                    : (notifActive
                          ? AppColors.secondaryLight
                          : AppColors.mutedBg),
                label: 'Notifications',
                value: notifText,
                badgeColor: notifText == '—'
                    ? AppColors.textTertiary
                    : (notifActive
                          ? AppColors.success
                          : AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SetupCompactCard(
                icon: Icons.near_me_outlined,
                iconColor: locationText == '—'
                    ? AppColors.textTertiary
                    : (locationActive
                          ? AppColors.secondary
                          : AppColors.textTertiary),
                iconBg: locationText == '—'
                    ? AppColors.mutedBg
                    : (locationActive
                          ? AppColors.secondaryLight
                          : AppColors.mutedBg),
                label: 'Location',
                value: locationText,
                badgeColor: locationText == '—'
                    ? AppColors.textTertiary
                    : (locationActive
                          ? AppColors.success
                          : AppColors.textTertiary),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Language (Full-width card)
        _SetupLanguageCard(languageText: languageText, isLoaded: prefs != null),
      ],
    );
  }
}

class _SetupCompactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color badgeColor;

  const _SetupCompactCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Spacer(),
              if (value != '—')
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: value == '—'
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupLanguageCard extends StatelessWidget {
  final String languageText;
  final bool isLoaded;

  const _SetupLanguageCard({
    required this.languageText,
    required this.isLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLoaded ? AppColors.secondaryLight : AppColors.mutedBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.language_rounded,
              size: 18,
              color: isLoaded ? AppColors.secondary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  languageText,
                  style: AppTypography.bodyLarge.copyWith(
                    color: languageText == '—'
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isLoaded && languageText != '—')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                languageText.contains('Bahasa') ? 'MS' : 'EN',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.secondary,
                  fontSize: 10,
                ),
              ),
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
          icon: Icons.map_rounded,
          iconColor: AppColors.secondary,
          iconBg: AppColors.secondaryLight,
          title: 'Transit Map',
          subtitle: 'Explore transit lines and stations',
          onTap: () => onNavigate(AppScreen.map),
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          key: const Key('home_service_alerts_card'),
          icon: Icons.notifications_active_rounded,
          iconColor: AppColors.amber,
          iconBg: AppColors.amberBg,
          title: 'Service Alerts',
          subtitle: 'View service notices and disruptions',
          onTap: () => onNavigate(AppScreen.alerts),
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          key: const Key('home_profile_card'),
          icon: Icons.manage_accounts_rounded,
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.mutedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
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
