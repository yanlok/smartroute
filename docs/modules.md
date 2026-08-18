# SmartRoute Feature Modules Specification

This document provides functional and architectural specifications for every module in SmartRoute. Developers and AI coding agents must align their implementation with the module boundaries and contracts defined here.

---

## Module Index

1. [User Management & Authentication (JC)](#1-user-management--authentication-jc)
2. [Home Dashboard (JC)](#2-home-dashboard-jc)
3. [Smart Route Planning (YL)](#3-smart-route-planning-yl)
4. [Real-Time Transit Tracking (Ernest)](#4-real-time-transit-tracking-ernest)
5. [Transit Information & Interactive Map (CQ)](#5-transit-information--interactive-map-cq)
6. [Notifications & Service Alerts (CQ)](#6-notifications--service-alerts-cq)
7. [Admin Module (YH)](#7-admin-module-yh)

---

## 1. User Management & Authentication (JC)

- **Owner:** JC
- **Current / Target Path:** `lib/features/user_management/` (incorporating existing `lib/features/login/` and `lib/features/profile/`)

### Current Required Scope:
- **Authentication Lifecycle:** Registration (sign-up with full name, email, password), Login, Logout, Session restoration and validation via Supabase Auth.
- **User Profile:** Manage user profile metadata (`full_name`, `photo_url`, account timestamps).
- **User Preferences:** Persist user settings (`notifications_enabled`, `location_enabled`, `language`).
- **Saved Entities:** Manage user-specific favorite routes and recent search history.
- **Home Dashboard Integration:** Expose user profile and saved routes to the Home Dashboard.

### Optional / Future Enhancements:
- Password recovery / reset flow.
- Transit mode weighting (`preferred_transport_modes`).

### Layered Architecture (Target)
```text
lib/features/user_management/
├── presentation/
│   ├── screens/         # LoginScreen, RegisterScreen, ProfileScreen, SettingsScreen
│   └── widgets/         # AuthCard, PreferenceToggleTile, ProfileHeader
├── application/
│   ├── auth_controller.dart          # Handles auth state & session lifecycle
│   └── profile_controller.dart       # Handles profile updates & preferences
├── domain/
│   ├── models/          # UserProfile, UserPreferences, FavoriteRoute, RecentSearch
│   └── repositories/    # IAuthRepository, IUserRepository
└── data/
    ├── datasources/     # SupabaseAuthDataSource, SupabaseUserDataSource
    └── repositories/    # AuthRepositoryImpl, UserRepositoryImpl
```

---

## 2. Home Dashboard (JC)

- **Owner:** JC
- **Current / Target Path:** `lib/features/home/`

### Responsibilities
- **Hub & Aggregator:** Acts as the primary landing surface after login.
- **Greeting & Personalization:** Shows user profile summary and quick greeting.
- **Recent Searches & Shortcuts:** Quick access to recent journey searches and favorite routes.
- **Cross-Module Aggregation:**
  - Displays high-priority service disruption summaries provided by **CQ's Alert capability**.
  - Displays live transit status summaries provided by **Ernest's Tracking capability**.
  - Provides quick action buttons that navigate to **YL's Planner** or **CQ's Transit Map**.

> **Boundary Rule:** Home coordinates presentation. It must NEVER contain business logic for calculating routes, fetching raw GTFS tracking data, or parsing raw disruption feeds.

---

## 3. Smart Route Planning (YL)

- **Owner:** YL
- **Current / Target Path:** `lib/features/planner/`, `lib/features/route_results/`, `lib/features/route_detail/`

### Responsibilities
- **Journey Planning:** Origin and destination station selection with search autocompletion.
- **Multimodal Routing:** Calculate optimized routes across LRT, MRT, Monorail, BRT, and Bus lines.
- **Route Comparison:** Compare options based on fastest time, fewest transfers, lowest fare, or least walking.
- **Route Details:** Step-by-step navigation instructions, interchange transfer guides, platform information, and fare breakdown.

*(Note: Detailed internal architecture and data sources evolve under YL's module ownership).*

---

## 4. Real-Time Transit Tracking (Ernest)

- **Owner:** Ernest
- **Current / Target Path:** `lib/features/tracking/`

### Responsibilities
- **Live Vehicle Telemetry:** Ingest and process real-time train and bus positions.
- **Arrival Countdown:** Calculate and display real-time arrival estimates (ETAs) per station and platform.
- **Interactive Visual Tracking:** Render train locations along line diagrams and maps with animated motion.
- **Status Exposer:** Expose lightweight live status summaries for the Home Dashboard.

*(Note: Detailed internal architecture and live pipeline evolve under Ernest's module ownership).*

---

## 5. Transit Information & Interactive Map (CQ)

- **Owner:** CQ
- **Current / Target Path:** `lib/features/transit_map/`

### Responsibilities
- **Interactive Network Map:** Render Klang Valley transit lines (LRT Kelana Jaya, MRT Kajang, Putrajaya, Monorail, etc.) with zoom/pan capabilities.
- **Station Information:** Display station facilities (parking, accessibility/elevators, feeder bus connections, operating hours).
- **Line Filtering:** Filter map layers by transit mode or line.

*(Note: Detailed internal architecture evolves under CQ's module ownership).*

---

## 6. Notifications & Service Alerts (CQ)

- **Owner:** CQ
- **Current / Target Path:** `lib/features/alerts/`

### Responsibilities
- **Disruption Feeds:** Ingest and display real-time service delays, track maintenance, and emergency announcements.
- **Severity Categorization:** Tag alerts as `info`, `warning`, or `severe`.
- **Alert Summary Capability:** Provide high-priority alert summaries for the Home Dashboard.

*(Note: Detailed internal architecture evolves under CQ's module ownership).*

---

## 7. Admin Module (YH)

- **Owner:** YH
- **Current / Target Path:** `lib/features/admin/` (Future development)

### Responsibilities
- **Transit Data Administration:** Manage static station schedules, operating hours, and fare matrices.
- **Alert Broadcasting:** Author and publish emergency broadcast alerts and maintenance announcements.
- **User Moderation & Feedback:** Review user feedback and manage reported account issues.

*(Note: Detailed internal architecture evolves under YH's module ownership).*
