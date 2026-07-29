# SmartRoute — Klang Valley Transit Companion

> **Full project analysis and documentation for developers**
>
> _Generated: 2026-07-25 | Flutter 3.41.4 | Dart ^3.11.1_

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technical Stack](#2-technical-stack)
3. [Project Structure](#3-project-structure)
4. [Architecture & Design](#4-architecture--design)
5. [Navigation & Routing](#5-navigation--routing)
6. [Theme System](#6-theme-system)
7. [Data Models](#7-data-models)
8. [Mock Data](#8-mock-data)
9. [Screen by Screen Breakdown](#9-screen-by-screen-breakdown)
   - 9.1 [Login Screen](#91-login-screen)
   - 9.2 [Home Screen](#92-home-screen)
   - 9.3 [Planner Screen](#93-planner-screen)
   - 9.4 [Route Results Screen](#94-route-results-screen)
   - 9.5 [Route Detail Screen](#95-route-detail-screen)
   - 9.6 [Tracking Screen](#96-tracking-screen)
   - 9.7 [Alerts Screen](#97-alerts-screen)
   - 9.8 [Transit Map Screen](#98-transit-map-screen)
   - 9.9 [Profile Screen](#99-profile-screen)
10. [Shared Widgets](#10-shared-widgets)
11. [Animations](#11-animations)
12. [React Source (Design Prototype)](#12-react-source-design-prototype)
13. [Testing](#13-testing)
14. [Current State & Limitations](#14-current-state--limitations)
15. [Future Roadmap Suggestions](#15-future-roadmap-suggestions)

---

## 1. Project Overview

**SmartRoute** is a mobile transit companion application for the **Klang Valley, Malaysia** public transport network. It helps commuters:

- **Plan journeys** across LRT, MRT, Bus, BRT, and Monorail networks
- **View real-time transit maps** with line filtering and station info
- **Track live train positions** with animated progress
- **Read service alerts** (delays, suspensions, maintenance)
- **View profile** with travel stats, payment methods, and settings

The app currently uses **hardcoded mock data** throughout — there is no backend, API, or state management library. It is a **prototype/MVP** built to demonstrate the full UX flow and visual design, ported from a Figma export.

---

## 2. Technical Stack

### Flutter App (`/lib`)

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.41.4 (stable) |
| **Language** | Dart ^3.11.1 |
| **UI System** | Material 3 (`useMaterial3: true`) |
| **Fonts** | Google Fonts — Plus Jakarta Sans (primary), DM Mono (monospace numbers) |
| **SVG Support** | `flutter_svg: ^2.0.17` |
| **Icons** | `cupertino_icons: ^1.0.8`, Material Icons |
| **Linting** | `flutter_lints: ^6.0.0` |
| **State Management** | Local `setState()` only (no Provider/Riverpod/Bloc) |
| **Navigation** | Manual `_history` stack (no GoRouter) |
| **Platforms** | Android, iOS, Web |

### React Design Prototype (`/react-source`)

| Layer | Technology |
|-------|-----------|
| **Framework** | React 18 + TypeScript |
| **Bundler** | Vite |
| **Styling** | Tailwind CSS 4 |
| **UI Library** | shadcn/ui (47 components) |
| **Icons** | lucide-react |
| **Package Manager** | pnpm |

---

## 3. Project Structure

```
smartroute/
│
├── lib/                              # ★ Main Dart source code
│   ├── main.dart                     # App entry point, root shell widget
│   ├── core/
│   │   ├── constants/
│   │   │   ├── mock_data.dart        # All hardcoded prototype data
│   │   │   └── navigation_types.dart # AppScreen & AppTab enums
│   │   ├── extensions/               # (empty — placeholder)
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # Color palette & gradients
│   │   │   ├── app_radius.dart       # Border radius tokens
│   │   │   ├── app_shadows.dart      # Shadow/elevation tokens
│   │   │   ├── app_spacing.dart      # 4px-grid spacing scale
│   │   │   ├── app_theme.dart        # Material 3 ThemeData
│   │   │   └── app_typography.dart   # Typography tokens
│   │   └── utils/                    # (empty — placeholder)
│   ├── features/                     # Feature modules (one per screen)
│   │   ├── login/screens/login_screen.dart
│   │   ├── home/screens/home_screen.dart
│   │   ├── planner/screens/planner_screen.dart
│   │   ├── route_results/screens/route_results_screen.dart
│   │   ├── route_detail/screens/route_detail_screen.dart
│   │   ├── tracking/screens/tracking_screen.dart
│   │   ├── alerts/screens/alerts_screen.dart
│   │   ├── transit_map/screens/transit_map_screen.dart
│   │   └── profile/screens/profile_screen.dart
│   └── shared/
│       ├── layouts/                  # (empty — placeholder)
│       ├── models/
│       │   └── app_models.dart       # All data model classes
│       └── widgets/
│           ├── kl_skyline.dart       # Animated KL skyline CustomPaint
│           └── status_bar.dart       # System status bar padding widget
│
├── android/                          # Android native project
│   ├── app/src/main/kotlin/.../MainActivity.kt
│   ├── app/build.gradle.kts          # compileSdk, minSdk, namespace config
│   ├── build.gradle.kts              # Root Gradle (AGP 8.11.1)
│   └── settings.gradle.kts           # Gradle settings (Kotlin 2.2.20)
│
├── ios/                              # iOS native project
│   ├── Runner/                       # AppDelegate, SceneDelegate, storyboards
│   └── RunnerTests/RunnerTests.swift
│
├── web/                              # Web platform
│   ├── index.html, manifest.json
│   └── icons/                        # PWA icons
│
├── assets/                           # Flutter assets (both directories empty)
│   ├── images/
│   └── icons/
│
├── test/
│   └── widget_test.dart              # Simple smoke test
│
├── react-source/                     # Figma → React design prototype
│   └── smartroute-mobile-asm/
│       └── src/app/App.tsx           # Entire app in one ~1982-line file
│
├── pubspec.yaml                      # Flutter dependencies & metadata
├── analysis_options.yaml             # Dart linter config
└── README.md                         # Standard Flutter auto-generated README
```

---

## 4. Architecture & Design

### Overall Pattern

The app follows a **feature-first** folder structure (not layer-first):

```
lib/
├── core/         # Cross-cutting concerns: theme, constants, enums
├── features/     # Each screen is its own feature module
└── shared/       # Models and reusable widgets
```

Each feature contains exactly one file — its screen widget. There are no feature-specific models, services, or state classes. All data is shared from the `core/constants/mock_data.dart` file.

### Shell Architecture

The app uses a **root shell pattern** in `main.dart`:

```
SmartRouteApp (StatelessWidget)
  └── AppShell (StatefulWidget) — manages:
       ├── Auth state (_loggedIn flag)
       ├── Screen navigation (_history stack + _currentScreen)
       ├── Tab navigation (_activeTab)
       ├── System UI overlay styling
       └── Bottom navigation bar
```

The `AppShell` is the single stateful root that:
- Determines whether to show `LoginScreen` or main app
- Handles all `_push()` / `_pop()` navigation
- Shows/hides the bottom nav based on current screen
- Passes callbacks (`onNavigate`, `onBack`, `onLogin`, `onLogout`) to child screens

### Data Flow

Simple unidirectional flow through callbacks:

```
AppShell (source of truth)
  │
  ├── Passes callbacks to screens
  │     └── onNavigate: AppScreen → void  (_push)
  │     └── onBack: void                 (_pop)
  │     └── onLogin: void                (sets _loggedIn = true)
  │     └── onLogout: void               (resets to login)
  │
  └── Screens use mock data directly (imports from mock_data.dart)
        └── Local UI state via setState() for toggles, filters, etc.
```

---

## 5. Navigation & Routing

### Navigation Types (`lib/core/constants/navigation_types.dart`)

```dart
enum AppScreen {
  login, home, planner, routeResults,
  routeDetail, tracking, alerts, map, profile,
}

enum AppTab { home, plan, map, alerts, profile }
```

### How Navigation Works

- **No routing package** — the app uses a manual `List<AppScreen> _history` stack
- `_push(AppScreen)` adds current screen to history and sets the new screen
- `_pop()` restores the previous screen from history
- `_switchTab(AppTab)` clears history and sets the corresponding screen
- The bottom nav bar is **hidden** on `routeResults`, `routeDetail`, and `tracking` screens

### Navigation Map

```
LoginScreen ──(login)──► AppShell
                            │
                    ┌───────┴────────┐
                    │  Tab Bar       │
                    │ [Home|Plan|Map │
                    │  |Alerts|Profile]
                    └───────┬────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
   HomeScreen         PlannerScreen      TransitMapScreen
         │                  │                  │
         ├──► AlertsScreen  ├──► RouteResultsScreen
         │                  │        │
         │                  │        └──► RouteDetailScreen
         │                  │              │
         │                  │              └──► TrackingScreen
         │                  │
         └──► ProfileScreen
```

---

## 6. Theme System

The theme is fully centralized and follows a token-based design system matching the React prototype's Tailwind configuration.

### AppColors (`lib/core/theme/app_colors.dart`)

| Category | Examples |
|----------|---------|
| **Brand** | `primary` (#E31837), `primaryDark` (#C41030), `secondary` (#1B4FD8) |
| **Transport Lines** | `kjLine` (#009FE3), `spLine` (#00A550), `mkLine` (#003087), `mpLine` (#8B0000), `mlLine` (#7C3AED), `brLine` (#F59E0B) |
| **Status** | `statusOnTime` (#22C55E), `statusMinorDelay` (#F59E0B), `statusMajorDelay` (#EF4444), `statusSuspended` (#B91C1C) |
| **Severity** | Info (blue), Warning (amber), Critical (red) — each with bg/text variants |
| **UI** | `background` (#F5F7FA), `surface` (#FFFFFF), `textPrimary`, `textSecondary`, `textTertiary`, `border`, `inputBg`, etc. |
| **Gradients** | 4 gradient lists: `gradientPrimary`, `gradientHeader` (3-stop), `gradientBlue`, `gradientProfile` |

### AppTypography (`lib/core/theme/app_typography.dart`)

Two font families:
- **Plus Jakarta Sans** — primary UI text (via `google_fonts`)
- **DM Mono** — monospaced numbers for fares, durations, stats

Scale includes: `displayLarge` (30px), `headlineLarge` (24px), `headlineMedium` (20px), `headlineSmall` (18px), `titleLarge` (15px), `bodyLarge` (14px), `labelLarge` (11px), `captionBlack` (10px uppercase), `overline` (8px), plus mono variants and special styles (logo, description).

### AppSpacing (`lib/core/theme/app_spacing.dart`)

Based on a **4px grid system**, mapping to Tailwind's spacing scale:
- `xs=4`, `sm=6`, `md=8`, `lg=10`, `xl=12`, `xxl=16`, `xxl2=20`, `xxl3=24`, `xxl4=32`
- Named spacings for: page padding, card padding, input padding, buttons, gaps, section spacing
- Specific element sizes: `avatarSize=56`, `quickActionSize=72`, `lineCardWidth=144`, `phoneWidth=390`, `phoneHeight=844`

### AppRadius (`lib/core/theme/app_radius.dart`)

- `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=20`, `xxl=32`, `circular=9999`

### AppShadows (`lib/core/theme/app_shadows.dart`)

| Token | Usage |
|-------|-------|
| `card` | Cards — subtle (0,1) 4px black@4% |
| `cardMd` | Medium card elevation |
| `cardLg` | Elevated card |
| `primaryButton` | Red CTA buttons — red@42% 24px blur |
| `ctaButton` | "Find Best Routes" button |
| `trackButton` | "Track Live" button |
| `loginCard` | Login card — (0,0) 25px black@25% |
| `header` | Page headers |
| `panel` | Station info panel with negative Y offset |
| `phoneShell` | Desktop phone mockup shell |

### AppTheme (`lib/core/theme/app_theme.dart`)

Material 3 `ThemeData.light` with:
- `ColorScheme.fromSeed` seeded with `AppColors.primary`
- Google Fonts text theme integration
- Custom `AppBarTheme` (white bg, no elevation, no surface tint)
- Custom `CardThemeData` (white bg, 16px radius, subtle border)
- Custom `InputDecorationTheme` (filled grey bg, 12px radius, red focus border)
- Custom `BottomNavigationBarThemeData` (fixed type, red/grey colors, 10px black weight labels)
- Custom `ElevatedButtonThemeData` (red bg, white text, 16px radius, 900 weight)

---

## 7. Data Models

All models are defined in `lib/shared/models/app_models.dart` as plain Dart classes with `const` constructors.

### TransportLine

```dart
class TransportLine {
  final String id;           // e.g. 'kjl', 'spl'
  final String name;         // e.g. 'Kelana Jaya Line'
  final String shortName;    // e.g. 'KJ', 'SP'
  final String color;        // hex string e.g. '#009FE3'
  final TransportStatus status;
  final int? delay;          // delay in minutes (null if on time)
}
```

### TransportStatus (enum)

`onTime` | `minorDelay` | `majorDelay` | `suspended`

Each has a `label` getter returning human-readable text.

### StationInfo

```dart
class StationInfo {
  final String id;           // e.g. 'asv', 'taman'
  final String name;         // e.g. 'Asia Jaya'
  final List<String> lines;  // lines serving this station
  final List<String> lineColors;
  final String distance;     // e.g. '320m'
  final int walkTime;        // minutes
}
```

### RouteSegment

```dart
class RouteSegment {
  final RouteSegmentType type; // walk, lrt, mrt, bus, monorail
  final String from;
  final String to;
  final String? line;          // e.g. 'Kelana Jaya Line'
  final String? lineColor;
  final int duration;          // minutes
  final int? stops;            // number of intermediate stops
}
```

### RouteSegmentType (enum)

`walk` | `lrt` | `mrt` | `bus` | `monorail`

Each has an `icon` getter (emoji: 🚶🚆🚌) and a `label` getter.

### RouteOption

```dart
class RouteOption {
  final String id;               // 'fastest', 'cheapest', 'direct'
  final String label;            // 'Fastest', 'Cheapest', 'Direct'
  final String labelColor;       // hex label badge color
  final int duration;            // total minutes
  final double fare;             // RM
  final int transfers;
  final List<RouteSegment> segments;
}
```

### AlertItem

```dart
class AlertItem {
  final String id;
  final String line;             // e.g. 'MRT Kajang Line'
  final String lineColor;
  final AlertSeverity severity;  // info, warning, critical
  final String title;
  final String description;
  final String time;             // e.g. '10 min ago'
  final bool read;
  AlertItem copyWith({bool? read}); // mark as read
}
```

### AlertSeverity (enum)

`info` | `warning` | `critical` — each has a `label` getter.

---

## 8. Mock Data

Located in `lib/core/constants/mock_data.dart`. All data is `const` and matches the React prototype exactly.

| Constant | Type | Count | Details |
|----------|------|-------|---------|
| `transportLines` | `List<TransportLine>` | 6 | KJ, SP, MK, MP, Monorail, BRT — includes statuses with delays |
| `nearbyStations` | `List<StationInfo>` | 3 | Asia Jaya, Taman Jaya, Subang Jaya |
| `routeOptions` | `List<RouteOption>` | 3 | Fastest (28min, RM2.50, 1 transfer), Cheapest (38min, RM1.80, 2 transfers), Direct (42min, RM3.20, 0 transfers) |
| `alertsData` | `List<AlertItem>` | 4 | 1 warning, 2 info, 1 critical — 2 marked as read |
| `kjLineStops` | `List<String>` | 6 | Asia Jaya → Taman Paramount → Taman Jaya → Universiti → Bangsar → KL Sentral |
| `recentSearches` | `List<Map>` | 3 | "Asia Jaya→KL Sentral", "Subang Jaya→KLCC", "Kelana Jaya→Bukit Bintang" |
| `popularDestinations` | `List<Map>` | 4 | KLCC 🏙️, Bukit Bintang 🛍️, KL Sentral 🚉, Petaling Jaya 🏢 |
| `favouriteRoutes` | `List<Map>` | 2 | "Asia Jaya→KL Sentral" (28min, RM2.50), "Subang Jaya→KLCC" (35min, RM2.90) |

---

## 9. Screen by Screen Breakdown

### 9.1 Login Screen

**File:** `lib/features/login/screens/login_screen.dart` (~434 lines)

**Route:** Default screen when `_loggedIn == false`

**Structure:**
1. **Gradient hero header** — logo ("SmartRoute" + "Klang Valley Transit Companion"), animated KL skyline, centered layout
2. **White card** overlapping the hero with rounded top corners (32px)
3. **Tab toggle** — "Sign In" / "Register" with `AnimatedContainer` transition
4. **Register form** (additional field: full name)
5. **Sign In form** — email + password with visibility toggle
6. **Forgot password?** link
7. **Primary CTA button** — "Sign In" / "Create Account" with gradient + shadow
8. **Social buttons** — "Continue with Google" (G icon), "Continue with Apple" (Apple icon)
9. **Terms & Privacy** links

**User flow:** Tapping Sign In → calls `onLogin` → `_loggedIn = true` → shows main app

**Key widgets:**
- `_GradientText` — text with shader gradient effect
- Custom `AnimatedContainer` for tab switching (250ms ease)
- Social buttons with outlined style (16px radius, 1px border)

---

### 9.2 Home Screen

**File:** `lib/features/home/screens/home_screen.dart` (~820 lines)

**Route:** Default tab screen (AppTab.home)

**Structure:**
1. **StatusBar** with red/dark background
2. **Gradient header** (`gradientHeader`):
   - Row: "Good Morning, Yih Loong" greeting + notification bell with badge count
   - KL Skyline widget
3. **Service Alert Banner** — amber warning card ("Service Alert:... KL Monorail"), tappable → navigates to alerts
4. **Quick Planner** — "From: Asia Jaya LRT" → "To: Destination" with swap icon
5. **Quick Actions** — 2×2 grid:
   - Plan Trip 🚆 | Live Map 🗺️
   - Alerts 🔔 | My Card 💳
6. **Service Status** — horizontal scroll list (6 transport lines):
   - Each card: line color dot, short name, line name, status badge
   - Status badge colors: green (On Time), amber (Minor Delay), red (Major/Suspended)
7. **Favourite Routes** — list cards with star icon, from/to, duration, fare, via line
8. **Nearby Stations** — list with distance, walk time, line badges
9. **Fare Savings Card** — blue gradient card with savings stats (saved, trips, spent, balance)

**Sub-widgets (all private):**
- `_ServiceAlertBanner` — amber alert chip with forward arrow
- `_QuickPlanner` — from/to inputs with swap icon
- `_QuickActions` — 2×2 grid of `_ActionCard` widgets
- `_ActionCard` — icon + label with colored background
- `_TransportStatus` — horizontal `ListView` of `_LineCard` widgets
- `_LineCard` — station-line style card showing transport status
- `_StatusBadge` — colored pill based on status enum
- `_FavouriteRoutes` — list of saved routes
- `_NearbyStations` — station cards with distance & walk time
- `_FareSavingsCard` — `Container` with `LinearGradient` and stats grid
- `_SavingsStat` — individual stat display (value + label)
- `_Dot` — small colored circle

---

### 9.3 Planner Screen

**File:** `lib/features/planner/screens/planner_screen.dart` (~525 lines)

**Route:** AppTab.plan

**Structure:**
1. **Header** — back arrow + "Plan Journey" title
2. **From/To inputs**:
   - "From" input (pre-filled: "Asia Jaya")
   - Dashed connector line (CustomPaint: `_DashedLinePainter`)
   - Swap button (arrows up/down icon)
   - "To" input (placeholder: "Enter destination")
3. **Date & Time selectors**:
   - "Today" chip (active state)
   - "Depart Now" toggle
4. **Transport modes** — toggle chips with animated active state:
   - LRT 🚆 | MRT 🚆 | Bus 🚌 | Monorail 🚆 | BRT 🚌
   - Active chip: red background, white text, bounce-scale animation
5. **Recent Searches** — list of 3 recent routes (tappable → navigates to routeResults)
6. **Popular Destinations** — 2-column grid of 4 destinations with emoji icons
7. **Bottom CTA** — "Find Best Routes" with gradient + shadow

**User flow:** Enter destinations → tap "Find Best Routes" → navigates to `routeResults`

---

### 9.4 Route Results Screen

**File:** `lib/features/route_results/screens/route_results_screen.dart` (~353 lines)

**Route:** AppScreen.routeResults (pushed from planner)

**Structure:**
1. **Header** — back arrow + "Asia Jaya → KL Sentral" subtitle + filter icon
2. **3 route option cards** (Fastest, Cheapest, Direct):
   - Colored label badge (green/blue/purple) — "Recommended" badge on first option
   - **Segment pills** — visual timeline of journey segments:
     - Walk 🚶 4min (gray pill)
     - LRT 🚆 18min, 6 stops (blue pill with line name)
     - Walk 🚶 6min (gray pill)
   - **Stats row** — duration, fare, transfers
3. **Info banner** — "Fares are estimates. Actual fares may vary."
4. **Tap any card** → navigates to `routeDetail`

**Sub-widgets:**
- `_ColoredDot` — small colored circle
- `_RouteBadge` — label badge with "Recommended" variant
- `_SegmentPill` — colored pill showing segment type, duration, stops
- `_StatItem` — stat label + value

---

### 9.5 Route Detail Screen

**File:** `lib/features/route_detail/screens/route_detail_screen.dart` (~473 lines)

**Route:** AppScreen.routeDetail (pushed from routeResults)

**Structure:**
1. **Header** — back arrow + "Route Details" + bookmark icon
2. **Summary banner** — row of 4 `_SummaryItem` widgets:
   - ⏱ 28 min | 💰 RM 2.50 | 🔄 1 transfer | 🕐 2:30 PM / 2:58 PM
3. **Timeline steps**:
   - **Step 1: Walk** 🚶 → "Walk to Asia Jaya LRT" (4 min)
   - **Step 2: Board train** 🚆 → "Board Kelana Jaya Line towards Gombak"
     - Expandable stop list: 6 stations (Asia Jaya → ... → KL Sentral)
     - Duration: 18 min
   - **Step 3: Walk** 🚶 → "Arrive at your destination" (6 min)
4. **Action buttons**:
   - "Track Live" (red, with shadow) → navigates to `tracking`
   - "Bookmark" (outlined)
   - "Share" (outlined)

**Sub-widgets:**
- `_SummaryItem` — icon + value + label in a column
- `_BoardTrainStep` — train boarding step with expandable stops
- `_StopRow` — single stop in the list with dot indicator
- `_TimelineStep` — generic timeline step widget
- `_TrainIcon` — small train SVG approximation

---

### 9.6 Tracking Screen

**File:** `lib/features/tracking/screens/tracking_screen.dart` (~545 lines)

**Route:** AppScreen.tracking (pushed from routeDetail)

**Structure:**
1. **Header** — back arrow + "Kelana Jaya Line" + **LIVE badge** (animated pulsing dot + "LIVE")
2. **Map area** — CustomPaint (`_TrackingMapPainter`):
   - Grid background
   - Roads (gray horizontal lines)
   - LRT track (curved blue line)
   - Station positions along the track (small dots with labels)
   - **Ping animation** at current station (expanding ring)
   - **Animated train icon** moving along the track based on progress
   - Destination marker at KL Sentral
3. **Vehicle info card** — train ID, platform, ETA, progress bar
4. **Upcoming stops** — list of next 4 stops from current position

**Animation:** `Timer.periodic` (3-second interval) simulates train movement:
- Progress increments from 28% → 96%, then resets to 18%
- Train position and current station label update in real time

**Sub-widgets:**
- `_KJBadge` — Kelana Jaya Line color badge
- `_TrackingMapPainter` — full map CustomPainter with coordinates for track, stations, train

---

### 9.7 Alerts Screen

**File:** `lib/features/alerts/screens/alerts_screen.dart` (~313 lines)

**Route:** AppScreen.alerts (from tab or home banner)

**Structure:**
1. **Header** — "Notifications" + count badge ("4")
2. **Filter chips** — All (4) | Unread (2) | Delays (1) | Info (2)
   - Active filter has red background
3. **Alert list** — cards with:
   - Severity indicator icon + background color (info=blue🔵, warning=amber🟡, critical=red🔴)
   - Line name + time
   - Title (bold)
   - Description (body text)
   - **Unread indicator** — red dot + left red border (4px left side)
   - **Tap** → marks as read (removes red dot/border)
4. **Empty state** — celebration animation (🎉) when all alerts are read

**Sub-widgets:**
- `_SeverityConfig` — maps severity to icon, icon color, bg color, border color
- `_EmptyState` — celebratory message when no unread alerts

---

### 9.8 Transit Map Screen

**File:** `lib/features/transit_map/screens/transit_map_screen.dart` (~548 lines)

**Route:** AppScreen.map (from tab)

**Structure:**
1. **Header** — "Transit Map" + filter chips row:
   - All | KJ (blue) | SP (green) | MK (dark blue) | MP (dark red) | ML (purple)
   - Active chip: full color + white text
   - Inactive: grey bg
2. **InteractiveViewer** — zoomable (0.5×–3.0×), panable map canvas
3. **Transit network diagram** (CustomPaint: `_TransitMapPainter`):
   - 6 transit lines drawn as polylines:
     - Kelana Jaya Line (KJ) — blue, top
     - Sri Petaling Line (SP) — green, middle
     - MRT Kajang Line (MK) — dark blue, below
     - MRT Putrajaya (MP) — dark red
     - KL Monorail (ML) — purple, dashed stroke
     - BRT Sunway (BR) — amber
   - **Station dots** per line (small circles at coordinates)
   - **Interchange stations** — red double-ring markers at:
     - KL Sentral (KJ ↔ MK ↔ MP)
     - Pasar Seni (KJ ↔ MK)
     - Merdeka (SP ↔ MK)
     - Bukit Bintang (MK ↔ ML)
     - Titiwangsa (SP ↔ ML)
   - **Station labels** — text next to dots
   - **Legend** — bottom right showing all 6 line colors
4. **Station info panel** — slides up from bottom on tap:
   - Station name
   - Lines serving it
   - "Get Directions" button → navigates to planner
   - "Station Info" button

**Sub-widgets:**
- `_TransitMapPainter` — full transit network CustomPainter with coordinate mapping
- `_Station` — data class for station coordinates (x, y, name, line, isInterchange)
- `_Interchange` — data class for interchange stations

---

### 9.9 Profile Screen

**File:** `lib/features/profile/screens/profile_screen.dart` (~493 lines)

**Route:** AppScreen.profile (from tab)

**Structure:**
1. **Header** — back button (hidden in tab context) + "Profile"
2. **Profile card** — gradient (`gradientProfile`):
   - Avatar circle with initials "YL" (56px)
   - Name: "Yih Loong"
   - Email: "yihloong@smartroute.my"
   - Premium badge (yellow star + "Premium")
3. **Travel stats** — 3 `_StatCard` widgets:
   - 247 trips | 1,240 km | 89 kg CO₂ saved
4. **Payment methods**:
   - MyRapid Card — "**** 4821" (balance: RM 24.50) + "Top Up" button
   - Touch 'n Go eWallet — linked
5. **Settings**:
   - Push Notifications — toggle switch
   - Location Services — toggle switch
   - Language → "English" (forward arrow)
   - Help & Support (forward arrow)
   - About — v2.4.1
6. **Sign Out button** — red outlined, calls `onLogout` → returns to login

**Sub-widgets:**
- `_StatCard` — icon + value + label
- `_PaymentRow` — payment method card with icon, name, action button
- `_SettingsToggle` — title + Switch widget
- `_SettingsRow` — title + subtitle/value + chevron
- `_SettingsDivider` — styled divider between sections

---

## 10. Shared Widgets

### KLSkyline (`lib/shared/widgets/kl_skyline.dart`)

An animated KL city skyline rendered entirely with `CustomPaint`.

**Elements:**
- Stars (7 dots with varying opacity)
- Background buildings (12 rectangles at various positions)
- **KL Tower** — line + oval + rectangle
- **Petronas Twin Towers** — triangular spires, rectangular bodies, sky bridge, horizontal detail lines
- **Elevated LRT track** — horizontal bar with 7 pillars
- **Animated LRT train** — red train with 5 windows, yellow headlight, moving left→right (9-second loop)
- **Animated bus** — blue bus with 4 windows, blue headlight, moving right→left (13-second loop derived from train progress)

**Animation:** Uses `AnimationController` with 9-second duration, repeated. Bus progress derived as `(trainProgress * 9/13) % 1.0`.

### StatusBar (`lib/shared/widgets/status_bar.dart`)

A simple widget providing system status bar padding with a configurable background color. It reads `MediaQuery.of(context).padding.top` and renders a colored spacer of that height. Used on screens with gradient/tinted backgrounds where the status bar area should have matching color.

---

## 11. Animations

| Screen/Widget | Animation | Technique |
|--------------|-----------|-----------|
| KLSkyline | Train moving left→right (9s loop), Bus moving right→left | `AnimationController` + `CustomPaint` |
| Login Screen | Tab transition (Sign In ↔ Register) | `AnimatedContainer` (250ms ease) |
| Tracking Screen | Pulsing LIVE dot | `AnimationController` + scaling/opacity |
| Tracking Screen | Ping ring at current station | `AnimationController` + expanding circle |
| Tracking Screen | Train icon movement along track | `Timer.periodic` progress update |
| Planner Screen | Active transport mode chip | `AnimatedScale` + `AnimatedContainer` |
| Transit Map | InteractiveViewer zoom/pan | Built-in `InteractiveViewer` gesture handling |

---

## 12. React Source (Design Prototype)

Located in `/react-source/smartroute-mobile-asm/`, this is a **Figma export** converted to a React + TypeScript app.

### Key File

**`src/app/App.tsx`** (~1,982 lines) — a single-file React app containing:
- All 9 screens (exact same screens as the Flutter app)
- Same hardcoded data in TypeScript
- CSS keyframe animations (`@keyframes trainRun`, `busRun`, `pulseDot`, `pingRing`)
- Phone shell wrapper (390×844px) with dynamic island notch
- Desktop background gradient
- Uses `lucide-react` for icons and Tailwind CSS utility classes

### Component Library

**`src/app/components/ui/`** — 47 shadcn/ui component files:
Accordion, Alert, AlertDialog, AspectRatio, Badge, Breadcrumb, Button, Calendar, Card, Carousel, Chart, Checkbox, Collapsible, Combobox, Command, ContextMenu, DataTable, DatePicker, Dialog, Drawer, DropdownMenu, Form, HoverCard, Input, Label, Menubar, NavigationMenu, Pagination, Popover, Progress, RadioGroup, Resizable, ScrollArea, Select, Separator, Sheet, Skeleton, Slider, Switch, Table, Tabs, Textarea, Toast, Toggle, ToggleGroup, Tooltip

### Guidelines

**`guidelines/Guidelines.md`** — design guidelines for the prototype (likely from Figma).

---

## 13. Testing

### Flutter Tests (`test/widget_test.dart`)

```dart
void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRouteApp());
    expect(find.byType(SmartRouteApp), findsOneWidget);
  });
}
```

A single smoke test that verifies the app builds and renders without throwing an error. There are **no unit tests** for models, **no widget tests** for individual screens, and **no integration tests**.

### iOS Tests (`ios/RunnerTests/RunnerTests.swift`)

Empty test class template from Flutter project creation.

---

## 14. Current State & Limitations

### What Works (Prototype Quality)

- ✅ All 9 screens render correctly with mock data
- ✅ Navigation between all screens works (push/pop, tabs, hiding nav)
- ✅ Theme system is fully implemented and centralized
- ✅ Animations (skyline, tracking, pulsing dots)
- ✅ Login/Register UI flow (no actual authentication)
- ✅ Planner UI with mode selection
- ✅ Route results with 3 options
- ✅ Step-by-step route detail with expandable stops
- ✅ Live tracking simulation with timer-based progress
- ✅ Alert list with read/unread state and filtering
- ✅ Interactive transit map with zoom/pan
- ✅ Profile with stats, payment methods, settings toggles

### What's Missing / Limitations

| Issue | Details |
|-------|---------|
| **No backend** | All data is hardcoded; no API integration |
| **No state management** | Uses local `setState()` — no Provider, Riverpod, Bloc |
| **No routing** | Manual `_history` stack — no GoRouter, Navigator 2.0 |
| **No real-time data** | Tracking uses `Timer.periodic` simulation |
| **No authentication** | Login is a flag toggle; no Firebase, Supabase, etc. |
| **No actual GPS** | Location-based features are UI-only |
| **No payment integration** | "Top Up" button is decorative |
| **Asset directories empty** | `assets/images/` and `assets/icons/` are declared but contain no files |
| **Empty placeholder dirs** | `extensions/`, `utils/`, `layouts/` are empty |
| **No error handling** | No try/catch, no loading states, no error screens |
| **No i18n** | All text is hardcoded in English |
| **No accessibility** | No semantic labels, no screen reader support |
| **Limited test coverage** | Single smoke test only |
| **No CI/CD** | No GitHub Actions, Fastlane, or build scripts |
| **Small code issue** | `AnimatedBuilder` in `kl_skyline.dart` line 39 — should be `AnimatedBuilder` (it is actually correct, no typo) |

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.17

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^6.0.0
```

---

## 15. Future Roadmap Suggestions

### Phase 1: Foundation (Make It Real)

- [ ] Integrate a state management solution (Riverpod or Bloc)
- [ ] Add GoRouter for proper URL-based navigation
- [ ] Connect to real transit APIs (Prasarana, RapidKL, Moovit, Google Transit)
- [ ] Implement Firebase Auth or Supabase for authentication
- [ ] Add loading, error, and empty states to all screens

### Phase 2: Features

- [ ] Real-time GPS tracking and location-based nearby stations
- [ ] Actual live train tracking (WebSocket or polling from transit APIs)
- [ ] Push notifications for service alerts
- [ ] Favourite routes persistence (local storage or cloud)
- [ ] Fare calculator with real pricing
- [ ] Trip history and analytics

### Phase 3: Polish

- [ ] Add dark mode support
- [ ] i18n (Bahasa Malaysia, Chinese, Tamil)
- [ ] Accessibility (screen readers, large text, high contrast)
- [ ] Performance optimization (lazy loading, caching)
- [ ] CI/CD pipeline with automated testing
- [ ] App store deployment (Play Store, App Store)

### Technical Debt

- [ ] Move mock data to a proper repository/service layer
- [ ] Split large screen files (>400 lines) into smaller components
- [ ] Add proper model serialization (toJson/fromJson) for API readiness
- [ ] Write unit tests for all models and utility functions
- [ ] Write widget tests for all screens
- [ ] Add integration tests for critical user flows
- [ ] Populate `assets/images/` and `assets/icons/` with real assets
- [ ] Standardize error handling patterns
- [ ] Add logging framework

---

## Appendix A: File Index

| File | Lines | Purpose |
|------|-------|---------|
| `lib/main.dart` | 253 | App entry, AppShell root widget |
| `lib/core/constants/navigation_types.dart` | 22 | AppScreen & AppTab enums |
| `lib/core/constants/mock_data.dart` | 271 | All hardcoded prototype data |
| `lib/core/theme/app_colors.dart` | 143 | Color palette & gradients |
| `lib/core/theme/app_radius.dart` | 26 | Border radius tokens |
| `lib/core/theme/app_shadows.dart` | 109 | Shadow/elevation tokens |
| `lib/core/theme/app_spacing.dart` | 159 | 4px-grid spacing scale |
| `lib/core/theme/app_theme.dart` | 187 | Material 3 ThemeData |
| `lib/core/theme/app_typography.dart` | 201 | Typography tokens |
| `lib/shared/models/app_models.dart` | 191 | All data models |
| `lib/shared/widgets/kl_skyline.dart` | 312 | Animated KL skyline |
| `lib/shared/widgets/status_bar.dart` | 36 | Status bar padding |
| `lib/features/login/screens/login_screen.dart` | 434 | Login/Register screen |
| `lib/features/home/screens/home_screen.dart` | 820 | Main dashboard |
| `lib/features/planner/screens/planner_screen.dart` | 525 | Journey planner |
| `lib/features/route_results/screens/route_results_screen.dart` | 353 | Route options |
| `lib/features/route_detail/screens/route_detail_screen.dart` | 473 | Step-by-step route |
| `lib/features/tracking/screens/tracking_screen.dart` | 545 | Live tracking |
| `lib/features/alerts/screens/alerts_screen.dart` | 313 | Service alerts |
| `lib/features/transit_map/screens/transit_map_screen.dart` | 548 | Interactive transit map |
| `lib/features/profile/screens/profile_screen.dart` | 493 | User profile |
| `test/widget_test.dart` | 12 | Smoke test |
| **Total Dart** | **~5,618** | |

## Appendix B: Transport Lines Reference

| ID | Short Name | Full Name | Color | Hex |
|----|-----------|-----------|-------|-----|
| `kjl` | KJ | Kelana Jaya Line | Blue | `#009FE3` |
| `spl` | SP | Sri Petaling Line | Green | `#00A550` |
| `mrt-k` | MK | MRT Kajang Line | Dark Blue | `#003087` |
| `mrt-p` | MP | MRT Putrajaya | Dark Red | `#8B0000` |
| `mono` | ML | KL Monorail | Purple | `#7C3AED` |
| `brt` | BR | BRT Sunway | Amber | `#F59E0B` |

## Appendix C: Screen Navigation Map

```
                    ┌─────────────┐
                    │  AppShell   │
                    │  (root)     │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │    _loggedIn?           │
              │  false ───► LoginScreen │
              │  true  ───► Main App    │
              └─────────────────────────┘
                           
         ┌──────────────────────────────────┐
         │          Main App                │
         │  Tab Bar + Screen Area           │
         └──────────────────────────────────┘
              │       │       │       │
    ┌─────────┘  ┌────┘       └────┐  └─────────┐
    ▼            ▼                  ▼            ▼
 HomeScreen   PlannerScreen    TransitMap    AlertsScreen
    │            │               Screen         │
    │            │                               │
    │            ▼                               │
    │      RouteResultsScreen                    │
    │            │                               │
    │            ▼                               │
    │      RouteDetailScreen                     │
    │            │                               │
    │            ▼                               │
    │      TrackingScreen                        │
    │                                            │
    └──────────────────► ProfileScreen ◄─────────┘
                              │
                              ▼
                          (onLogout)
                              │
                              ▼
                         LoginScreen
```

---

*This documentation was generated by analyzing the full source code of the SmartRoute Flutter project. It covers all files, models, screens, theme tokens, navigation, and current limitations as of July 2026.*
