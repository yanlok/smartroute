import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/navigation_types.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/alerts/application/notice_controller.dart';
import 'features/alerts/data/supabase_notice_repository.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/login/screens/login_screen.dart';
import 'features/login/screens/set_new_password_screen.dart';
import 'features/planner/application/planner_controller.dart';
import 'features/planner/data/geolocator_location_repository.dart';
import 'features/planner/domain/route_planner_service.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/saved_journeys_screen.dart';
import 'features/route_detail/screens/route_detail_screen.dart';
import 'features/route_results/screens/route_results_screen.dart';
import 'features/tracking/application/tracking_controller.dart';
import 'features/tracking/data/repositories/canonical_line_directory_repository.dart';
import 'features/tracking/data/repositories/official_tracking_repository.dart';
import 'features/tracking/presentation/screens/tracking_screen.dart';
import 'features/transit_information/screens/transit_information_screen.dart';
import 'features/transit_network/application/transit_network_controller.dart';
import 'features/transit_network/data/bundled_transit_network_repository.dart';
import 'features/user_management/application/auth_controller.dart';
import 'features/user_management/application/profile_controller.dart';
import 'features/user_management/application/saved_journey_controller.dart';
import 'features/user_management/application/user_role_controller.dart';
import 'features/user_management/data/repositories/supabase_auth_repository.dart';
import 'features/user_management/data/repositories/supabase_avatar_storage_repository.dart';
import 'features/user_management/data/repositories/supabase_profile_repository.dart';
import 'features/user_management/data/repositories/supabase_saved_journey_repository.dart';
import 'features/user_management/data/repositories/supabase_user_role_repository.dart';
import 'features/user_management/domain/models/user_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const config = AppConfig.fromEnvironment();
  config.validateSupabase();
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );

  final client = Supabase.instance.client;
  final networkRepository = BundledTransitNetworkRepository();
  final authRepository = SupabaseAuthRepository(
    client: client,
    googleWebClientId: config.googleWebClientId,
  );
  final authController = AuthController(authRepository: authRepository);
  await authController.checkInitialRecoveryLink();

  final userRoleRepository = SupabaseUserRoleRepository(client: client);
  final userRoleController = UserRoleController(repository: userRoleRepository);

  final profileController = ProfileController(
    profileRepository: SupabaseProfileRepository(client: client),
    avatarStorageRepository: SupabaseAvatarStorageRepository(client: client),
  );
  final savedJourneys = SavedJourneyController(
    repository: SupabaseSavedJourneyRepository(client: client),
  );
  final noticeController = NoticeController(
    repository: SupabaseNoticeRepository(client: client),
  );
  final plannerController = PlannerController(
    networkRepository: networkRepository,
    locationRepository: GeolocatorLocationRepository(),
  );
  final transitController = TransitNetworkController(
    repository: networkRepository,
  );
  final trackingRepository = OfficialTrackingRepository(
    networkRepository: networkRepository,
  );
  final trackingController = TrackingController(
    trackingRepository: trackingRepository,
    directoryRepository: CanonicalLineDirectoryRepository(networkRepository),
  );

  runApp(
    SmartRouteApp(
      client: client,
      authController: authController,
      userRoleController: userRoleController,
      profileController: profileController,
      savedJourneys: savedJourneys,
      noticeController: noticeController,
      plannerController: plannerController,
      transitController: transitController,
      trackingController: trackingController,
    ),
  );
}

class SmartRouteApp extends StatelessWidget {
  final SupabaseClient? client;
  final AuthController authController;
  final UserRoleController userRoleController;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final NoticeController noticeController;
  final PlannerController plannerController;
  final TransitNetworkController transitController;
  final TrackingController trackingController;

  const SmartRouteApp({
    super.key,
    this.client,
    required this.authController,
    required this.userRoleController,
    required this.profileController,
    required this.savedJourneys,
    required this.noticeController,
    required this.plannerController,
    required this.transitController,
    required this.trackingController,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SmartRoute',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: AppShell(
      client: client,
      authController: authController,
      userRoleController: userRoleController,
      profileController: profileController,
      savedJourneys: savedJourneys,
      noticeController: noticeController,
      plannerController: plannerController,
      transitController: transitController,
      trackingController: trackingController,
    ),
  );
}

class AppShell extends StatefulWidget {
  final SupabaseClient? client;
  final AuthController authController;
  final UserRoleController userRoleController;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final NoticeController noticeController;
  final PlannerController plannerController;
  final TransitNetworkController transitController;
  final TrackingController trackingController;

  const AppShell({
    super.key,
    this.client,
    required this.authController,
    required this.userRoleController,
    required this.profileController,
    required this.savedJourneys,
    required this.noticeController,
    required this.plannerController,
    required this.transitController,
    required this.trackingController,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _activeTab = AppTab.home;
  AppScreen _currentScreen = AppScreen.home;
  final List<AppScreen> _history = [];
  String? _selectedTransitRouteId;
  String? _selectedTransitStopId;
  String? _trackingRouteId;
  String _favoriteFingerprint = '';
  bool _rebuildScheduled = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
    widget.userRoleController.addListener(_onRoleChanged);
    widget.profileController.addListener(_onProfileChanged);
    widget.savedJourneys.addListener(_onSavedJourneysChanged);
    widget.noticeController.addListener(_onNoticesChanged);

    final client = widget.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        widget.authController.handleAuthChangeEvent(data.event);
      }, onError: (_) {});
    }

    if (!widget.authController.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.authController.initialize();
        if (mounted &&
            widget.authController.isAuthenticated &&
            !widget.authController.isPasswordRecovery) {
          _resolveAndLoad(widget.authController.currentUser!.id);
        }
      });
    } else if (widget.authController.isAuthenticated &&
        !widget.authController.isPasswordRecovery &&
        !widget.userRoleController.isResolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveAndLoad(widget.authController.currentUser!.id);
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    widget.authController.removeListener(_onAuthChanged);
    widget.userRoleController.removeListener(_onRoleChanged);
    widget.profileController.removeListener(_onProfileChanged);
    widget.savedJourneys.removeListener(_onSavedJourneysChanged);
    widget.noticeController.removeListener(_onNoticesChanged);
    widget.trackingController.dispose();
    widget.plannerController.dispose();
    widget.transitController.dispose();
    widget.noticeController.dispose();
    widget.savedJourneys.dispose();
    widget.profileController.dispose();
    widget.userRoleController.dispose();
    widget.authController.dispose();
    super.dispose();
  }

  void _onRoleChanged() {
    _requestRebuild();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (widget.authController.isPasswordRecovery) {
      _requestRebuild();
      return;
    }
    final user = widget.authController.currentUser;
    if (user == null) {
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
      _selectedTransitRouteId = null;
      _selectedTransitStopId = null;
      _trackingRouteId = null;
      _favoriteFingerprint = '';
      widget.profileController.reset();
      widget.savedJourneys.reset();
      widget.noticeController.reset();
      widget.userRoleController.reset();
    } else {
      _resolveAndLoad(user.id);
    }
    _requestRebuild();
  }

  Future<void> _resolveAndLoad(String userId) async {
    final role = await widget.userRoleController.resolveRole(userId);
    if (!mounted) return;

    if (role == null) {
      if (mounted) setState(() {});
      return;
    }

    if (role == UserRole.admin) {
      await Future.wait([
        widget.transitController.load(),
        widget.noticeController.load(
          userId: userId,
          notificationsEnabled: true,
        ),
      ]);
    } else {
      await _loadUserProduct(userId);
    }
    if (mounted) setState(() {});
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final user = widget.authController.currentUser;
    final preferences = widget.profileController.preferences;
    if (user != null &&
        preferences != null &&
        !widget.userRoleController.isAdmin) {
      widget.noticeController.load(
        userId: user.id,
        notificationsEnabled: preferences.notificationsEnabled,
      );
    }
    _requestRebuild();
  }

  void _onSavedJourneysChanged() {
    _syncFavoriteRoutes();
    _requestRebuild();
  }

  void _onNoticesChanged() {
    _requestRebuild();
  }

  void _requestRebuild() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  Future<void> _loadUserProduct(String userId) async {
    await Future.wait([
      widget.profileController.load(userId: userId),
      widget.savedJourneys.load(userId),
      widget.plannerController.load(),
      widget.transitController.load(),
    ]);
    final preferences = widget.profileController.preferences;
    await widget.noticeController.load(
      userId: userId,
      notificationsEnabled: preferences?.notificationsEnabled ?? true,
    );
    await _syncFavoriteRoutes();
  }

  Future<void> _syncFavoriteRoutes() async {
    final network = widget.transitController.network;
    if (network == null) return;
    final journeyFingerprint = widget.savedJourneys.favorites
        .map(
          (item) =>
              '${item.id}:${item.originStopId}:${item.destinationStopId}:${item.objective.name}',
        )
        .join('|');
    final stationFingerprint = widget.savedJourneys.favoriteStations
        .map((item) => '${item.id}:${item.stationId}:${item.routeId}')
        .join('|');
    final fingerprint = '$journeyFingerprint#$stationFingerprint';
    if (fingerprint == _favoriteFingerprint) return;
    _favoriteFingerprint = fingerprint;
    final stationRouteIds = <String>{};
    for (final favorite in widget.savedJourneys.favoriteStations) {
      final station = network.stopsById[favorite.stationId];
      if (station == null) {
        stationRouteIds.add(favorite.routeId);
      } else {
        stationRouteIds.addAll(station.routeIds);
      }
    }
    widget.noticeController.setFavoriteStationRouteIds(stationRouteIds);
    final routeIds = <String>{...stationRouteIds};
    final service = RoutePlannerService(network);
    for (final favorite in widget.savedJourneys.favorites) {
      final journey = service.planForObjective(
        originStopId: favorite.originStopId,
        destinationStopId: favorite.destinationStopId,
        objective: favorite.objective,
      );
      for (final segment in journey?.segments ?? const []) {
        if (segment.routeId != null) routeIds.add(segment.routeId!);
      }
    }
    widget.noticeController.setFavoriteRouteIds(routeIds);
  }

  void _push(AppScreen screen) {
    setState(() {
      _history.add(_currentScreen);
      _currentScreen = screen;
    });
  }

  void _pop() {
    setState(() {
      if (_history.isNotEmpty) {
        _currentScreen = _history.removeLast();
      } else {
        _currentScreen = _tabScreen(_activeTab);
      }
    });
  }

  void _switchTab(AppTab tab) {
    setState(() {
      _activeTab = tab;
      _history.clear();
      _currentScreen = _tabScreen(tab);
      if (tab == AppTab.transit) {
        _selectedTransitRouteId = null;
        _selectedTransitStopId = null;
      }
    });
  }

  AppScreen _tabScreen(AppTab tab) => switch (tab) {
    AppTab.home => AppScreen.home,
    AppTab.plan => AppScreen.planner,
    AppTab.transit => AppScreen.transitInformation,
    AppTab.alerts => AppScreen.alerts,
    AppTab.profile => AppScreen.profile,
  };

  bool get _hideNavigation =>
      _currentScreen == AppScreen.routeResults ||
      _currentScreen == AppScreen.routeDetail ||
      _currentScreen == AppScreen.tracking ||
      _currentScreen == AppScreen.savedJourneys ||
      _currentScreen == AppScreen.adminDashboard;

  @override
  Widget build(BuildContext context) {
    if (widget.authController.isPasswordRecovery) {
      return SetNewPasswordScreen(
        authController: widget.authController,
        onSuccess: () {
          widget.userRoleController.reset();
          _onAuthChanged();
        },
        onCancel: () async {
          widget.userRoleController.reset();
          await widget.authController.cancelPasswordRecovery();
          _onAuthChanged();
        },
      );
    }

    if (!widget.authController.isAuthenticated) {
      return LoginScreen(authController: widget.authController);
    }

    if (widget.userRoleController.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.gapLg),
                    decoration: const BoxDecoration(
                      color: AppColors.severityCriticalBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 48,
                      color: AppColors.severityCriticalColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionMd),
                  Text(
                    'Access Verification Failed',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.gapSm),
                  Text(
                    widget.userRoleController.errorMessage ??
                        'Unable to verify account access. Please try again.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sectionLg),
                  FilledButton(
                    onPressed: () {
                      final user = widget.authController.currentUser;
                      if (user != null) {
                        _resolveAndLoad(user.id);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  TextButton(
                    onPressed: () async {
                      await widget.authController.signOut();
                      widget.userRoleController.reset();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!widget.authController.isInitialized ||
        !widget.userRoleController.isResolved ||
        widget.userRoleController.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (widget.userRoleController.isAdmin) {
      return AdminDashboardScreen(
        controller: widget.noticeController,
        transitController: widget.transitController,
        onSignOut: () async {
          await widget.authController.signOut();
          widget.userRoleController.reset();
        },
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _buildAuthenticatedPassengerScreen(),
        bottomNavigationBar: !_hideNavigation
            ? _BottomNavigation(
                active: _activeTab,
                unreadCount: widget.noticeController.unreadCount,
                onSelected: _switchTab,
              )
            : null,
      ),
    );
  }

  Widget _buildAuthenticatedPassengerScreen() {
    final user = widget.authController.currentUser!;
    final preferences = widget.profileController.preferences;
    switch (_currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          authUser: user,
          profileController: widget.profileController,
          savedJourneys: widget.savedJourneys,
          notices: widget.noticeController,
          transitController: widget.transitController,
          onPlan: () => _switchTab(AppTab.plan),
          onAlerts: () => _switchTab(AppTab.alerts),
          onTransit: () => _switchTab(AppTab.transit),
          onReplan: (origin, destination) =>
              _replan(origin, destination, user.id),
          onOpenFavoriteStation: _openTransitStation,
        );
      case AppScreen.planner:
        return PlannerScreen(
          controller: widget.plannerController,
          savedJourneys: widget.savedJourneys,
          userId: user.id,
          locationEnabled: preferences?.locationEnabled ?? false,
          onRoutesReady: () => _push(AppScreen.routeResults),
        );
      case AppScreen.routeResults:
        return RouteResultsScreen(
          controller: widget.plannerController,
          onBack: _pop,
          onOpenRoute: (_) => _push(AppScreen.routeDetail),
        );
      case AppScreen.routeDetail:
        return RouteDetailScreen(
          planner: widget.plannerController,
          savedJourneys: widget.savedJourneys,
          notices: widget.noticeController,
          userId: user.id,
          showCurrentLocation: preferences?.locationEnabled ?? false,
          onBack: _pop,
          onOpenTransit: _openTransitRoute,
          onOpenProgress: _openProgress,
        );
      case AppScreen.tracking:
        final network = widget.transitController.network;
        final routeId = _trackingRouteId;
        if (network == null || routeId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return TrackingScreen(
          lineId: routeId,
          controller: widget.trackingController,
          network: network,
          journey: widget.plannerController.selectedRoute,
          onBack: _pop,
        );
      case AppScreen.alerts:
        return AlertsScreen(
          controller: widget.noticeController,
          transitController: widget.transitController,
          notificationsEnabled: preferences?.notificationsEnabled ?? true,
          onOpenRoute: _openTransitRoute,
        );
      case AppScreen.transitInformation:
        return TransitInformationScreen(
          controller: widget.transitController,
          notices: widget.noticeController,
          userId: user.id,
          savedJourneys: widget.savedJourneys,
          initialRouteId: _selectedTransitRouteId,
          initialStopId: _selectedTransitStopId,
          onOpenProgress: _openProgress,
          onOpenAlerts: () => _switchTab(AppTab.alerts),
          onViewFavoriteStations: () => _switchTab(AppTab.home),
        );
      case AppScreen.profile:
        return ProfileScreen(
          authUser: user,
          authController: widget.authController,
          profileController: widget.profileController,
          savedJourneys: widget.savedJourneys,
          onBack: _pop,
          onLogout: () async {
            await widget.authController.signOut();
            widget.userRoleController.reset();
          },
          onSavedJourneys: () => _push(AppScreen.savedJourneys),
          isAdmin: false,
          onAdmin: null,
          transitController: widget.transitController,
        );
      case AppScreen.savedJourneys:
        return SavedJourneysScreen(
          userId: user.id,
          controller: widget.savedJourneys,
          network: widget.transitController.network,
          onBack: _pop,
          onReplan: (origin, destination) =>
              _replan(origin, destination, user.id),
        );
      case AppScreen.adminDashboard:
        return HomeScreen(
          authUser: user,
          profileController: widget.profileController,
          savedJourneys: widget.savedJourneys,
          notices: widget.noticeController,
          transitController: widget.transitController,
          onPlan: () => _switchTab(AppTab.plan),
          onAlerts: () => _switchTab(AppTab.alerts),
          onTransit: () => _switchTab(AppTab.transit),
          onReplan: (origin, destination) =>
              _replan(origin, destination, user.id),
          onOpenFavoriteStation: _openTransitStation,
        );
      case AppScreen.login:
        return LoginScreen(authController: widget.authController);
    }
  }

  Future<void> _replan(
    String originStopId,
    String destinationStopId,
    String userId,
  ) async {
    final success = await widget.plannerController.replan(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      userId: userId,
      savedJourneys: widget.savedJourneys,
    );
    if (!mounted || !success) return;
    _activeTab = AppTab.plan;
    _history.clear();
    _currentScreen = AppScreen.routeResults;
    setState(() {});
  }

  void _openTransitRoute(String routeId) {
    setState(() {
      _selectedTransitRouteId = routeId;
      _selectedTransitStopId = null;
      _history.add(_currentScreen);
      _currentScreen = AppScreen.transitInformation;
    });
  }

  void _openTransitStation(String stationId, String routeId) {
    setState(() {
      _selectedTransitRouteId = routeId;
      _selectedTransitStopId = stationId;
      _activeTab = AppTab.transit;
      _history.clear();
      _history.add(AppScreen.home);
      _currentScreen = AppScreen.transitInformation;
    });
  }

  void _openProgress(String routeId) {
    setState(() {
      _trackingRouteId = routeId;
      _history.add(_currentScreen);
      _currentScreen = AppScreen.tracking;
    });
  }
}

class _BottomNavigation extends StatelessWidget {
  final AppTab active;
  final int unreadCount;
  final ValueChanged<AppTab> onSelected;

  const _BottomNavigation({
    required this.active,
    required this.unreadCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final tab in AppTab.values)
            Expanded(
              child: Semantics(
                selected: tab == active,
                button: true,
                label: tab == AppTab.alerts && unreadCount > 0
                    ? 'Alerts, $unreadCount unread'
                    : _label(tab),
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: tab == active
                          ? AppColors.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _icon(tab),
                              size: AppSpacing.navIconSize,
                              color: tab == active
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            if (tab == AppTab.alerts && unreadCount > 0)
                              Positioned(
                                right: -10,
                                top: -7,
                                child: _NavigationBadge(count: unreadCount),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _label(tab),
                          style: AppTypography.captionBold.copyWith(
                            color: tab == active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: tab == active
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  static IconData _icon(AppTab tab) => switch (tab) {
    AppTab.home => Icons.home_rounded,
    AppTab.plan => Icons.alt_route_rounded,
    AppTab.transit => Icons.train_rounded,
    AppTab.alerts => Icons.notifications_rounded,
    AppTab.profile => Icons.person_rounded,
  };

  static String _label(AppTab tab) => switch (tab) {
    AppTab.home => 'Home',
    AppTab.plan => 'Plan',
    AppTab.transit => 'Transit',
    AppTab.alerts => 'Alerts',
    AppTab.profile => 'Profile',
  };
}

class _NavigationBadge extends StatelessWidget {
  final int count;

  const _NavigationBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.circular),
      border: Border.all(color: AppColors.surface, width: 1.5),
    ),
    alignment: Alignment.center,
    child: Text(
      count > 99 ? '99+' : '$count',
      style: AppTypography.captionBold.copyWith(
        color: AppColors.surface,
        fontSize: 9,
      ),
    ),
  );
}
