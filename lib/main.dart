import 'package:flutter/material.dart';
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
import 'features/planner/application/planner_controller.dart';
import 'features/planner/data/geolocator_location_repository.dart';
import 'features/planner/domain/route_planner_service.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/profile/screens/profile_screen.dart';
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
import 'features/user_management/data/repositories/supabase_auth_repository.dart';
import 'features/user_management/data/repositories/supabase_profile_repository.dart';
import 'features/user_management/data/repositories/supabase_saved_journey_repository.dart';

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
  final authController = AuthController(
    authRepository: SupabaseAuthRepository(client: client),
  );
  final profileController = ProfileController(
    profileRepository: SupabaseProfileRepository(client: client),
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
  final trackingController = TrackingController(
    trackingRepository: OfficialTrackingRepository(
      networkRepository: networkRepository,
    ),
    directoryRepository: CanonicalLineDirectoryRepository(networkRepository),
  );

  runApp(
    SmartRouteApp(
      authController: authController,
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
  final AuthController authController;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final NoticeController noticeController;
  final PlannerController plannerController;
  final TransitNetworkController transitController;
  final TrackingController trackingController;

  const SmartRouteApp({
    super.key,
    required this.authController,
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
      authController: authController,
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
  final AuthController authController;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final NoticeController noticeController;
  final PlannerController plannerController;
  final TransitNetworkController transitController;
  final TrackingController trackingController;

  const AppShell({
    super.key,
    required this.authController,
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
  String? _trackingRouteId;
  String _favoriteFingerprint = '';

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
    widget.profileController.addListener(_onProfileChanged);
    widget.savedJourneys.addListener(_onSavedJourneysChanged);
    if (!widget.authController.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.authController.initialize();
      });
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    widget.profileController.removeListener(_onProfileChanged);
    widget.savedJourneys.removeListener(_onSavedJourneysChanged);
    widget.trackingController.dispose();
    widget.plannerController.dispose();
    widget.transitController.dispose();
    widget.noticeController.dispose();
    widget.savedJourneys.dispose();
    widget.profileController.dispose();
    widget.authController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final user = widget.authController.currentUser;
    if (user == null) {
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
      _selectedTransitRouteId = null;
      _trackingRouteId = null;
      _favoriteFingerprint = '';
      widget.profileController.reset();
      widget.savedJourneys.reset();
      widget.noticeController.reset();
    } else {
      _loadUserProduct(user.id);
    }
    setState(() {});
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final user = widget.authController.currentUser;
    final preferences = widget.profileController.preferences;
    if (user != null && preferences != null) {
      widget.noticeController.load(
        userId: user.id,
        notificationsEnabled: preferences.notificationsEnabled,
      );
    }
    setState(() {});
  }

  void _onSavedJourneysChanged() {
    _syncFavoriteRoutes();
    if (mounted) setState(() {});
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
    final fingerprint = widget.savedJourneys.favorites
        .map(
          (item) =>
              '${item.id}:${item.originStopId}:${item.destinationStopId}:${item.objective.name}',
        )
        .join('|');
    if (fingerprint == _favoriteFingerprint) return;
    _favoriteFingerprint = fingerprint;
    final routeIds = <String>{};
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
      if (tab == AppTab.transit) _selectedTransitRouteId = null;
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
      _currentScreen == AppScreen.adminDashboard;

  @override
  Widget build(BuildContext context) {
    if (!widget.authController.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.authController.isAuthenticated
            ? _buildAuthenticatedScreen()
            : LoginScreen(authController: widget.authController),
        bottomNavigationBar:
            widget.authController.isAuthenticated && !_hideNavigation
            ? _BottomNavigation(active: _activeTab, onSelected: _switchTab)
            : null,
      ),
    );
  }

  Widget _buildAuthenticatedScreen() {
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
          initialRouteId: _selectedTransitRouteId,
          onOpenProgress: _openProgress,
        );
      case AppScreen.profile:
        return ProfileScreen(
          authUser: user,
          profileController: widget.profileController,
          onBack: _pop,
          onLogout: widget.authController.signOut,
          isAdmin: widget.noticeController.isAdmin,
          onAdmin: widget.noticeController.isAdmin
              ? () => _push(AppScreen.adminDashboard)
              : null,
          transitController: widget.transitController,
        );
      case AppScreen.adminDashboard:
        return AdminDashboardScreen(
          controller: widget.noticeController,
          transitController: widget.transitController,
          onBack: _pop,
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
      _history.add(_currentScreen);
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
  final ValueChanged<AppTab> onSelected;

  const _BottomNavigation({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final tab in AppTab.values)
            Expanded(
              child: Semantics(
                selected: tab == active,
                button: true,
                label: _label(tab),
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icon(tab),
                          size: AppSpacing.navIconSize,
                          color: tab == active
                              ? AppColors.primary
                              : AppColors.tabInactive,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _label(tab),
                          style: AppTypography.captionBold.copyWith(
                            color: tab == active
                                ? AppColors.primary
                                : AppColors.tabInactive,
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
