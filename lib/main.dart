import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/navigation_types.dart';
import 'features/login/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/route_results/screens/route_results_screen.dart';
import 'features/route_detail/screens/route_detail_screen.dart';
import 'features/tracking/screens/tracking_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/transit_map/screens/transit_map_screen.dart';
import 'features/transit_information/screens/transit_information_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SmartRouteApp());
}

class SmartRouteApp extends StatelessWidget {
  const SmartRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartRoute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}

/// Root shell that manages authentication state and screen navigation.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _loggedIn = false;
  AppTab _activeTab = AppTab.home;
  AppScreen _currentScreen = AppScreen.home;
  final List<AppScreen> _history = [];
  bool _isT250Favourite = false;

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

  void _login() => setState(() => _loggedIn = true);

  void _logout() {
    setState(() {
      _loggedIn = false;
      _currentScreen = AppScreen.home;
      _activeTab = AppTab.home;
      _history.clear();
      _isT250Favourite = false;
    });
  }

  bool get _hideBottomNav =>
      _currentScreen == AppScreen.routeResults ||
      _currentScreen == AppScreen.routeDetail ||
      _currentScreen == AppScreen.tracking;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentScreen == AppScreen.login ||
              _currentScreen == AppScreen.home
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
        child: _loggedIn ? _buildMainApp() : _buildLogin(),
      ),
    );
  }

  Widget _buildLogin() {
    return LoginScreen(onLogin: _login);
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
      case AppScreen.home:
        return HomeScreen(
          onNavigate: _push,
          showT250Favourite: _isT250Favourite,
        );
      case AppScreen.planner:
        return PlannerScreen(onNavigate: _push, onBack: _pop);
      case AppScreen.routeResults:
        return RouteResultsScreen(onNavigate: _push, onBack: _pop);
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
        return ProfileScreen(onBack: _pop, onLogout: _logout);
      case AppScreen.login:
        return LoginScreen(onLogin: _login);
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
