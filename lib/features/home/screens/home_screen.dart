import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/kl_skyline.dart';
import '../../../core/constants/navigation_types.dart';

class HomeScreen extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  final bool showT250Favourite;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.showT250Favourite = false,
  });

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
              // System status bar spacer with gradient background
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
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
                            'Good Morning,',
                            style: AppTypography.headerLabel,
                          ),
                          Text(
                            'Yih Loong 👋',
                            style: AppTypography.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onNavigate(AppScreen.alerts),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white20,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_rounded,
                                color: Colors.white, size: 16),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.yellowBadge,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFB91C1C), width: 1),
                                ),
                              ),
                            ),
                          ],
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
            child: Column(
              children: [
                // Service alert banner
                _ServiceAlertBanner(onTap: () => onNavigate(AppScreen.alerts)),

                // Quick planner
                _QuickPlanner(onTap: () => onNavigate(AppScreen.planner)),

                // Quick actions grid
                _QuickActions(onNavigate: onNavigate),

                // Favourite routes
                _FavouriteRoutes(
                  showT250Favourite: showT250Favourite,
                  onTap: () => onNavigate(AppScreen.routeResults),
                ),

                // Nearby stations
                _NearbyStations(onMapTap: () => onNavigate(AppScreen.map)),

                // Fare savings card
                const _FareSavingsCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ],
    );
  }
}

// ─── Service Alert Banner ─────────────────────────────────────────────────

class _ServiceAlertBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ServiceAlertBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.amber100),
            boxShadow: AppShadows.cardMd,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.amber600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2 Service Alerts Active',
                        style: AppTypography.bodySmall),
                    SizedBox(height: 2),
                    Text('MRT Kajang Line · 5–8 min delay',
                        style: AppTypography.labelMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.iconGray),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Planner ────────────────────────────────────────────────────────

class _QuickPlanner extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickPlanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
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
                    Text('WHERE TO?',
                        style: AppTypography.labelLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const _Dot(color: AppColors.primary, size: 10),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Asia Jaya LRT',
                              style: AppTypography.bodyLarge,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 12, color: AppColors.iconGray),
                        const SizedBox(width: 8),
                        const _Dot(color: AppColors.secondary, size: 10),
                        const SizedBox(width: 8),
                        Text('Select destination',
                            style: AppTypography.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.navigation_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions (2×2 Grid) ─────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK ACTIONS',
              style: AppTypography.captionBlack),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.alt_route_rounded,
                  label: 'Plan Trip',
                  gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary),
                  onTap: () => onNavigate(AppScreen.planner),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionCard(
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
                  icon: Icons.credit_card_rounded,
                  label: 'My Card',
                  color: AppColors.success,
                  bgColor: AppColors.successBg,
                  onTap: () => onNavigate(AppScreen.profile),
                ),
              ),
            ],
          ),
        ],
      ),
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
          color: bgColor,
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
              child: Center(
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: AppTypography.captionBold.copyWith(
                  color: gradient != null
                      ? AppColors.textPrimary
                      : (color ?? AppColors.textPrimary),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Transport Service Status ─────────────────────────────────────────────

// ─── Favourite Routes ─────────────────────────────────────────────────────

class _FavouriteRoutes extends StatelessWidget {
  final VoidCallback onTap;
  final bool showT250Favourite;

  const _FavouriteRoutes({
    required this.onTap,
    required this.showT250Favourite,
  });

  @override
  Widget build(BuildContext context) {
    final routes = [
      ...favouriteRoutes,
      if (showT250Favourite)
        const {
          'from': 'Wangsa Maju LRT',
          'to': 'TAR UMT',
          'duration': '10–15 min',
          'fare': 'RM 1.00',
          'via': 'T250 Bus',
        },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAVOURITE ROUTES',
              style: AppTypography.captionBlack),
          const SizedBox(height: 10),
          ...routes.map((route) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
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
                            color: AppColors.amberBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _Dot(
                                      color: AppColors.primary, size: 8),
                                  const SizedBox(width: 6),
                                  Text(route['from']!,
                                      style: AppTypography.bodyLarge),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: AppColors.iconGray),
                                  const SizedBox(width: 6),
                                  _Dot(
                                      color: AppColors.secondary,
                                      size: 8),
                                  const SizedBox(width: 6),
                                  Text(route['to']!,
                                      style: AppTypography.bodyLarge),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${route['via']} · ${route['duration']} · ${route['fare']}',
                                style: AppTypography.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.iconGray),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Nearby Stations ──────────────────────────────────────────────────────

class _NearbyStations extends StatelessWidget {
  final VoidCallback onMapTap;
  const _NearbyStations({required this.onMapTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEARBY STATIONS',
              style: AppTypography.captionBlack),
          const SizedBox(height: 10),
          ...nearbyStations.map((station) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          color: AppColors.mutedBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.pin_drop_rounded,
                            size: 16, color: AppColors.iconDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(station.name,
                                    style: AppTypography.bodyLarge),
                                const SizedBox(width: 8),
                                ...station.lines.map((l) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(
                                                  '0xFF${station.lineColors[station.lines.indexOf(l)].replaceFirst('#', '')}'))
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(l,
                                            style: AppTypography
                                                .captionBold
                                                .copyWith(
                                              color: Color(int.parse(
                                                  '0xFF${station.lineColors[station.lines.indexOf(l)].replaceFirst('#', '')}')),
                                            )),
                                      ),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${station.distance} · ${station.walkTime} min walk',
                              style: AppTypography.labelMedium,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onMapTap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mutedBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.navigation_rounded,
                              size: 14, color: AppColors.iconDark),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Fare Savings Card ────────────────────────────────────────────────────

class _FareSavingsCard extends StatelessWidget {
  const _FareSavingsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.gradientBlue),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white20,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.trending_down_rounded,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FARE SAVINGS THIS MONTH',
                          style: AppTypography.labelSmallBold),
                      Text('Using SmartRoute instead of driving',
                          style: AppTypography.labelMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.white65),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SavingsStat(
                  label: 'Saved',
                  value: 'RM 18.40',
                  isHighlight: true,
                ),
                const SizedBox(width: 16),
                _SavingsStat(
                  label: 'Trips',
                  value: '47',
                  isHighlight: false,
                ),
                const SizedBox(width: 16),
                _SavingsStat(
                  label: 'Spent',
                  value: 'RM 82.50',
                  isHighlight: false,
                ),
                const SizedBox(width: 16),
                _SavingsStat(
                  label: 'Balance',
                  value: 'RM 23.10',
                  isHighlight: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SavingsStat({
    required this.label,
    required this.value,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.captionMedium
                  .copyWith(color: AppColors.white65)),
          const SizedBox(height: 2),
          Text(
            value,
            style: isHighlight
                ? AppTypography.displayLarge.copyWith(color: Colors.white)
                : AppTypography.monoMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Sub-widgets ───────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
