# SmartRoute Architecture v2

This document is the architectural source of truth for the SmartRoute project. It defines the structural principles, data-flow boundaries, state management rules, and technical standards.

All developers and AI coding agents MUST understand and follow this architecture.

---

## 1. Project Overview & Architectural Style

SmartRoute is a public transit companion application for the Klang Valley, Malaysia (covering LRT, MRT, Monorail, BRT, and Bus networks).

The project adopts a **Feature-First, Clean-Lite Architecture**.
This architecture provides clear separation of concerns, testability, and module isolation while remaining accessible, lightweight, and understandable for university students without enterprise over-engineering.

### Target Conceptual Directory Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart                  # Top-level MaterialApp initialization
│   ├── app_shell.dart            # Root layout coordinator, bottom navigation & tab switching
│   └── app_dependencies.dart     # Service/Repository dependency wiring
├── core/
│   ├── config/                   # App constants, environment configs
│   ├── errors/                   # Failure and Exception definitions
│   ├── theme/                    # AppColors, AppTypography, AppSpacing, AppTheme
│   └── utils/                    # Shared pure helper utilities
├── features/
│   └── <feature_name>/           # Feature module (e.g. user_management, tracking, planner)
│       ├── presentation/         # UI layer
│       │   ├── screens/          # Full page screens
│       │   └── widgets/          # Feature-private UI components
│       ├── application/          # State management (Controllers / ViewModels / ChangeNotifiers)
│       ├── domain/               # Feature domain models, value objects, repository interfaces
│       └── data/                 # Repository implementations, Supabase data sources, DTOs
└── shared/
    ├── contracts/                # Public cross-module integration contracts
    ├── models/                   # Common domain models used across multiple features
    └── widgets/                  # Reusable generic UI components (buttons, cards, headers)
```

---

## 2. Transitional Architecture & Legacy Code Awareness

The SmartRoute codebase is currently in a **TRANSITIONAL** state between the initial UI prototype and Architecture V2:

| Layer / Area | Legacy Prototype Path (Current) | Target Architecture V2 Path |
| :--- | :--- | :--- |
| **Feature Screens** | `lib/features/<feature>/screens/` | `lib/features/<feature>/presentation/screens/` |
| **Feature UI Widgets** | Private classes inside screen files | `lib/features/<feature>/presentation/widgets/` |
| **State / Logic** | Local `setState` in screen widgets | `lib/features/<feature>/application/<controller>.dart` |
| **Domain Models & Contracts** | `lib/shared/models/app_models.dart` | `lib/features/<feature>/domain/models/` or `lib/shared/models/` |
| **Data & Mock Sources** | `lib/core/constants/mock_data.dart` | `lib/features/<feature>/data/datasources/` |
| **Auth & Profile Modules** | `lib/features/login/`, `lib/features/profile/` | `lib/features/user_management/` |

### Rules for Working in the Transitional Codebase:
1. **Search Both Paths:** Developers and AI agents must search **BOTH** legacy paths and target V2 paths before creating any new file, widget, or model.
2. **Never Ignore Legacy Code:** The presence of target architectural directories does not mean existing legacy implementations should be ignored.
3. **No Duplicate Implementations:** If a widget, model, or helper exists in a legacy path, it must be reused or extended. Never create a parallel duplicate in the target path.
4. **Incremental Migration Only:** Legacy code is migrated incrementally **only** when an active Task Card explicitly targets that feature/path.
5. **No Mass Restructuring:** A regular feature Task Card must **NEVER** mass-move, rename, or restructure unrelated feature files.
6. **Legacy Code Validity:** Current legacy code remains valid and operational until that specific feature is intentionally migrated.
7. **Phase 0 Constraint:** Do NOT physically restructure or move existing Dart code during Phase 0.

---

## 3. Core Architecture Principles

Data flow strictly follows a unidirectional layered pattern:

```text
UI (Screen / Widget)
        │ User actions / Intent
        ▼
Controller / ViewModel (ChangeNotifier)
        │ Domain operations / Business rules
        ▼
Repository Interface (Domain contract)
        │ Abstract data requests
        ▼
Repository Implementation (Data access)
        │ SQL / REST / SDK calls
        ▼
Supabase Client / External Transit API
```

### Strict Boundary Rules:
1. **UI Layer (`presentation/`):**
   - Must only display data and capture user input.
   - **Must NEVER directly call Supabase, database APIs, HTTP clients, or platform channels.**
   - Must NEVER execute business logic or data transformations inside Widget `build()` methods.
2. **Application Layer (`application/`):**
   - Holds controllers / view-models extending `ChangeNotifier`.
   - Coordinates presentation state (loading, error, success, empty).
   - Calls domain repository interfaces; does not know about Supabase internals.
3. **Domain Layer (`domain/`):**
   - Defines pure Dart business entities and abstract repository contracts (e.g., `abstract class UserRepository`).
   - Completely independent of Flutter UI and third-party database packages.
4. **Data Layer (`data/`):**
   - Implements repository interfaces using Supabase client, local storage, or REST APIs.
   - Maps database tables / DTOs into domain entities.
   - Isolates vendor-specific APIs so external providers can be swapped or mocked in tests.

---

## 4. State Management Standard

SmartRoute enforces **ONE consistent, project-wide state management approach**:

- **Controllers / ViewModels with `ChangeNotifier`:**
  - Used for all feature business logic, session state, asynchronous operations, and multi-widget state.
  - Controllers expose immutable UI state or specific getters and notify listeners on change.
  - UI binds to controllers using `ListenableBuilder` or `AnimatedBuilder`.
- **Local `setState`:**
  - Allowed **ONLY** for small, transient, screen-local presentation state (e.g., toggling password visibility, tab highlight, text editing controller setup).
- **Prohibited Frameworks:**
  - Do **NOT** introduce Riverpod, Bloc, GetX, MobX, or Redux.
  - Mixing multiple state management frameworks causes maintenance confusion and is strictly prohibited.

---

## 5. Navigation & Shell Architecture

- **Current Navigation Mechanism:**
  - SmartRoute uses a manual coordinator pattern in `AppShell` with `AppScreen` and `AppTab` enums.
  - Tab switching, screen pushes (`_push`), and pops (`_pop`) are managed cleanly through constructor callbacks (e.g., `onNavigate`, `onBack`, `onLogout`).
- **Navigation Prohibitions:**
  - Do **NOT** introduce `go_router`, `AutoRoute`, `Beamer`, or complex Navigator 2.0 routers during regular feature tasks.
  - A routing migration affects every module across the team and requires an explicit, team-wide architectural decision.

---

## 6. Cross-Module Boundaries & Integration

To ensure independent team member ownership and prevent merge conflicts:

```text
Feature A (Consumer)
        │
        ▼ (calls public contract)
Shared Contract / Public Capability (lib/shared/contracts/)
        ▲ (implements / exposes capability)
        │
Feature B (Provider)
```

1. **No Private Widget Imports:** Feature A must NEVER import Feature B's private screens, widgets, or internal data classes.
2. **Communication via Contracts:** Cross-module communication uses shared contracts (`lib/shared/contracts/`), shared models (`lib/shared/models/`), or shell callbacks.
3. **No Circular Dependencies:** Dependencies must flow downward towards `shared/` and `core/`.

---

## 7. Supabase Integration Principles

- **Authentication:** Managed strictly by Supabase Auth (`auth.users`).
- **Application Data:** Stored in public relational tables with Row Level Security (RLS) enabled on all tables.
- **Client Security:** The Flutter mobile/web client uses the Supabase publishable key (or legacy anon key where applicable) together with proper RLS. The `service_role` / secret key must never be bundled in the app.
- **Data Encapsulation:** All Supabase operations are encapsulated inside `data/` data sources and repositories.
- Refer to `docs/database.md` for full schema specifications and RLS policies.

---

## 8. Error, Loading, and Empty State Handling

Every asynchronous data-driven view must explicitly handle the 4 fundamental UI states (where applicable):

1. **Loading State:** Display non-blocking progress indicators (shimmer or centered indicator). Prevent duplicate submissions.
2. **Success State:** Display received data using design system tokens.
3. **Empty State:** When query results are empty (e.g., no favorite routes saved, no alerts active), show a friendly illustrative empty state with actionable guidance.
4. **Error State:** Display human-readable, non-technical error messages with a retry button. Never expose raw stack traces or database errors to end users.

---

## 9. Quality Gates and Verification

Before any feature code is merged into `develop`:

```bash
# 1. Code formatting check
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze

# 3. Automated test suite
flutter test
```

All three gates must pass with zero errors and zero warnings.

For detailed testing guidelines, see `docs/testing.md`.
For team module boundaries, see `docs/module_ownership.md`.
For design system specifications, see `docs/design.md`.
