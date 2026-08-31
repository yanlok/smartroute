import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/constants/navigation_types.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_login_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/login/screens/login_screen.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/planner/screens/planner_map_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/route_detail/screens/route_detail_screen.dart';
import 'features/route_results/screens/route_results_screen.dart';
import 'features/tracking/presentation/screens/tracking_screen.dart';
import 'features/transit_map/screens/transit_map_screen.dart';
import 'features/transit_information/screens/transit_information_screen.dart';
import 'features/user_management/application/auth_controller.dart';
import 'features/user_management/application/profile_controller.dart';
import 'features/user_management/data/repositories/supabase_auth_repository.dart';
import 'features/user_management/data/repositories/supabase_profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const config = AppConfig.fromEnvironment();
  config.validateSupabase();

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );

  final authRepository = SupabaseAuthRepository(
    client: Supabase.instance.client,
  );
  final authController = AuthController(authRepository: authRepository);

  final profileRepository = SupabaseProfileRepository(
    client: Supabase.instance.client,
  );
  final profileController = ProfileController(
    profileRepository: profileRepository,
  );

  runApp(
    SmartRouteApp(
      authController: authController,
      profileController: profileController,
    ),
  );
}

class SmartRouteApp extends StatelessWidget {
  final AuthController authController;
  final ProfileController profileController;

  const SmartRouteApp({
    super.key,
    required this.authController,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartRoute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppShell(
        authController: authController,
        profileController: profileController,
      ),
    );
  }
}

/// Root shell that manages authentication state and screen navigation.
class AppShell extends StatefulWidget {
  final AuthController authController;
  final ProfileController profileController;

  const AppShell({
    super.key,
    required this.authController,
    required this.profileController,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showAdminPortal = false;
  bool _adminLoggedIn = false;
  AppTab _activeTab = AppTab.home;
  AppScreen _currentScreen = AppScreen.home;
  String _plannerFrom = 'Asia Jaya';
  String _plannerTo = 'KL Sentral';
  final List<AppScreen> _history = [];
  bool _isT250Favourite = false;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
    if (!widget.authController.isInitialized &&
        !widget.authController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.authController.isInitialized) {
          widget.authController.initialize();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_onAuthChanged);
      widget.authController.addListener(_onAuthChanged);
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (!widget.authController.isAuthenticated) {
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
      _isT250Favourite = false;
      widget.profileController.reset();
    }
    setState(() {});
  }

  void _push(AppScreen screen) {
    setState(() {
      _history.add(_currentScreen);
      _currentScreen = screen;
    });
  }

  void _pop() {
    if (_history.isNotEmpty) {
      setState(() {
        _currentScreen = _history.removeLast();
      });
    }
  }

  void _switchTab(AppTab tab) {
    setState(() {
      _activeTab = tab;
      _history.clear();
      _currentScreen = _tabToScreen(tab);
    });
  }

  AppScreen _tabToScreen(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return AppScreen.home;
      case AppTab.plan:
        return AppScreen.planner;
      case AppTab.map:
        return AppScreen.map;
      case AppTab.alerts:
        return AppScreen.alerts;
      case AppTab.transitInformation:
        return AppScreen.transitInformation;
      case AppTab.profile:
        return AppScreen.profile;
    }
  }

  void _logout() async {
    await widget.authController.signOut();
  }

  void _openAdminPortal() {
    setState(() {
      _showAdminPortal = true;
      _adminLoggedIn = false;
      _currentScreen = AppScreen.adminLogin;
      _activeTab = AppTab.home;
      _history.clear();
    });
  }

  void _closeAdminPortal() {
    setState(() {
      _showAdminPortal = false;
      _adminLoggedIn = false;
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
    });
  }

  void _adminLogin() {
    setState(() {
      _showAdminPortal = true;
      _adminLoggedIn = true;
      _currentScreen = AppScreen.adminDashboard;
      _activeTab = AppTab.home;
      _history.clear();
    });
  }

  void _adminLogout() {
    setState(() {
      _showAdminPortal = false;
      _adminLoggedIn = false;
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
    });
  }

  bool get _hideBottomNav =>
      _currentScreen == AppScreen.plannerMap ||
      _currentScreen == AppScreen.routeResults ||
      _currentScreen == AppScreen.routeDetail ||
      _currentScreen == AppScreen.tracking;

  @override
  Widget build(BuildContext context) {
    if (!widget.authController.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final useLightStatusIcons =
        _currentScreen == AppScreen.login ||
        _currentScreen == AppScreen.home ||
        _currentScreen == AppScreen.adminLogin ||
        _currentScreen == AppScreen.adminDashboard;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: useLightStatusIcons
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: Material(
        color: Colors.transparent,
        child: _adminLoggedIn
            ? _buildScreen()
            : _showAdminPortal
            ? _buildAuthentication()
            : widget.authController.isAuthenticated
            ? _buildMainApp()
            : _buildLogin(),
      ),
    );
  }

  Widget _buildLogin() {
    return LoginScreen(
      authController: widget.authController,
      onAdminPortal: _openAdminPortal,
    );
  }

  Widget _buildAuthentication() {
    if (_currentScreen == AppScreen.adminLogin) {
      return AdminLoginScreen(onLogin: _adminLogin, onBack: _closeAdminPortal);
    }

    return _buildLogin();
  }

  Widget _buildMainApp() {
    return Column(
      children: [
        Expanded(child: _buildScreen()),
        if (!_hideBottomNav) _buildBottomNav(),
      ],
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.adminLogin:
        return AdminLoginScreen(
          onLogin: _adminLogin,
          onBack: _closeAdminPortal,
        );
      case AppScreen.adminDashboard:
        return AdminDashboardScreen(onLogout: _adminLogout);
      case AppScreen.home:
        final user = widget.authController.currentUser;
        if (user == null) {
          return const SizedBox.shrink();
        }
        return HomeScreen(
          authUser: user,
          profileController: widget.profileController,
          onNavigate: _push,
          showT250Favourite: _isT250Favourite,
        );
      case AppScreen.planner:
        return PlannerScreen(
          onNavigate: _push,
          onSearch: (from, to) {
            setState(() {
              _plannerFrom = from;
              _plannerTo = to;
              _history.add(_currentScreen);
              _currentScreen = AppScreen.plannerMap;
            });
          },
          onBack: _pop,
        );
      case AppScreen.plannerMap:
        return PlannerMapScreen(
          from: _plannerFrom,
          to: _plannerTo,
          onBack: _pop,
          onChangeJourney: (from, to) {
            setState(() {
              _plannerFrom = from;
              _plannerTo = to;
            });
          },
          onFindRoutes: () => _push(AppScreen.routeResults),
        );
      case AppScreen.routeResults:
        return RouteResultsScreen(
          from: _plannerFrom,
          to: _plannerTo,
          onNavigate: _push,
          onBack: _pop,
        );
      case AppScreen.routeDetail:
        return RouteDetailScreen(
          isFavourite: _isT250Favourite,
          onFavouriteChanged: (isFavourite) {
            setState(() => _isT250Favourite = isFavourite);
          },
          onBack: _pop,
        );
      case AppScreen.tracking:
        return TrackingScreen(onBack: _pop);
      case AppScreen.alerts:
        return AlertsScreen(onBack: _pop);
      case AppScreen.map:
        return TransitMapScreen(onBack: _pop);
      case AppScreen.transitInformation:
        return TransitInformationScreen(onNavigate: _push);
      case AppScreen.profile:
        final user = widget.authController.currentUser;
        if (user == null) {
          return const SizedBox.shrink();
        }
        return ProfileScreen(
          authUser: user,
          profileController: widget.profileController,
          onBack: _pop,
          onLogout: _logout,
        );
      case AppScreen.login:
        return LoginScreen(
          authController: widget.authController,
          onAdminPortal: _openAdminPortal,
        );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppTab.values.map((tab) {
            final active = _activeTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchTab(tab),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0x1AE31837)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _tabIcon(tab),
                        size: 20,
                        color: active
                            ? const Color(0xFFE31837)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tabLabel(tab),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? const Color(0xFFE31837)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _tabIcon(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return Icons.home_rounded;
      case AppTab.plan:
        return Icons.alt_route_rounded;
      case AppTab.map:
        return Icons.map_rounded;
      case AppTab.alerts:
        return Icons.notifications_rounded;
      case AppTab.transitInformation:
        return Icons.info_outline_rounded;
      case AppTab.profile:
        return Icons.person_rounded;
    }
  }

  String _tabLabel(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return 'Home';
      case AppTab.plan:
        return 'Plan';
      case AppTab.map:
        return 'Map';
      case AppTab.alerts:
        return 'Alerts';
      case AppTab.transitInformation:
        return 'Info';
      case AppTab.profile:
        return 'Profile';
    }
  }
}
