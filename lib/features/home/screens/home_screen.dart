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
        // ── Header ──
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
                          Text('Welcome,', style: AppTypography.headerLabel),
                          const SizedBox(height: 2),
                          Text(
                            '$_displayName 👋',
                            style: AppTypography.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

                    // Primary Journey Card (Plan Your Journey)
                    _PrimaryJourneyCard(
                      onTap: () => widget.onNavigate(AppScreen.planner),
                    ),

                    const SizedBox(height: 16),

                    // Quick Actions (Plan Trip, Live Map, Alerts, Profile)
                    _QuickActions(onNavigate: widget.onNavigate),

                    const SizedBox(height: 20),

                    // Truthful Travel Tools Section
                    _TravelToolsSection(onNavigate: widget.onNavigate),

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

// ─── Primary Journey Card ───────────────────────────────────────────────────

class _PrimaryJourneyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryJourneyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLAN YOUR JOURNEY', style: AppTypography.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a destination and compare route options.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions (4 Actions) ──────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS', style: AppTypography.captionBlack),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                key: const Key('home_plan_trip_action'),
                icon: Icons.alt_route_rounded,
                label: 'Plan Trip',
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                ),
                onTap: () => onNavigate(AppScreen.planner),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                key: const Key('home_live_map_action'),
                icon: Icons.map_rounded,
                label: 'Live Map',
                color: AppColors.secondary,
                bgColor: AppColors.secondaryLight,
                onTap: () => onNavigate(AppScreen.map),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                key: const Key('home_alerts_action'),
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                color: AppColors.amber,
                bgColor: AppColors.amberBg,
                onTap: () => onNavigate(AppScreen.alerts),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                key: const Key('home_profile_action'),
                icon: Icons.person_rounded,
                label: 'Profile',
                color: AppColors.success,
                bgColor: AppColors.successBg,
                onTap: () => onNavigate(AppScreen.profile),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient? gradient;
  final Color? color;
  final Color? bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.gradient,
    this.color,
    this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: bgColor ?? Colors.white,
          border: color != null
              ? null
              : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                gradient: gradient,
                color: gradient == null ? (color ?? AppColors.primary) : null,
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 18)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.captionBold.copyWith(
                color: gradient != null
                    ? AppColors.textPrimary
                    : (color ?? AppColors.textPrimary),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Truthful Travel Tools Section ──────────────────────────────────────────

class _TravelToolsSection extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  const _TravelToolsSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRAVEL TOOLS', style: AppTypography.captionBlack),
        const SizedBox(height: 10),
        _ToolTile(
          icon: Icons.notifications_active_outlined,
          title: 'Service Alerts',
          subtitle: 'View live service notices and disruptions',
          onTap: () => onNavigate(AppScreen.alerts),
        ),
        const SizedBox(height: 8),
        _ToolTile(
          icon: Icons.map_outlined,
          title: 'Transit Map',
          subtitle: 'Explore rail networks, bus lines, and stations',
          onTap: () => onNavigate(AppScreen.map),
        ),
        const SizedBox(height: 8),
        _ToolTile(
          icon: Icons.manage_accounts_outlined,
          title: 'Profile & Preferences',
          subtitle: 'Manage your account details and app settings',
          onTap: () => onNavigate(AppScreen.profile),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
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
