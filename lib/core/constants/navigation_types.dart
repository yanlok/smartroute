/// Navigation types shared across the app.
///
/// These match the React app's Screen and TabId types.

/// All screens in the application.
enum AppScreen {
  login,
  home,
  planner,
  plannerMap,
  routeResults,
  routeDetail,
  tracking,
  alerts,
  map,
  transitInformation,
  profile,
}

/// Bottom navigation tab identifiers.
enum AppTab { home, plan, map, alerts, transitInformation, profile }
