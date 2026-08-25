/// Navigation types shared across the app.
///
/// These match the React app's Screen and TabId types.

/// All screens in the application.
enum AppScreen {
  login,
  adminLogin,
  adminDashboard,
  home,
  planner,
  routeResults,
  routeDetail,
  tracking,
  alerts,
  map,
  profile,
}

/// Bottom navigation tab identifiers.
enum AppTab { home, plan, map, alerts, profile }
