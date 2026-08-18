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

> **IMPORTANT: Phase Distinction**
> - **Current State:** The repository currently has prototype screens in `lib/features/<feature>/screens/` with prototype static mock fixtures.
> - **Target State:** Features will progressively migrate into the Clean-Lite 4-layer structure (`presentation`, `application`, `domain`, `data`) during feature phases.
> - **Phase 0 Constraint:** Do NOT physically restructure or move existing Dart code during Phase 0.

---

## 2. Core Architecture Principles

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

## 3. State Management Standard

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

## 4. Navigation & Shell Architecture

- **Current Navigation Mechanism:**
  - SmartRoute uses a manual coordinator pattern in `AppShell` with `AppScreen` and `AppTab` enums.
  - Tab switching, screen pushes (`_push`), and pops (`_pop`) are managed cleanly through constructor callbacks (e.g., `onNavigate`, `onBack`, `onLogout`).
- **Navigation Prohibitions:**
  - Do **NOT** introduce `go_router`, `AutoRoute`, `Beamer`, or complex Navigator 2.0 routers during regular feature tasks.
  - A routing migration affects every module across the team and requires an explicit, team-wide architectural decision.

---

## 5. Cross-Module Boundaries & Contracts

To ensure independent team member ownership and prevent merge conflicts:

```text
Feature A (e.g. Home)
        │
        ▼ (calls public contract)
Shared Contract / Public Interface (lib/shared/contracts/)
        ▲ (implements / exposes capability)
        │
Feature B (e.g. Alerts or Planner)
```

1. **No Private Widget Imports:** Feature A must NEVER import Feature B's private screens, widgets, or internal data classes.
2. **Communication via Contracts:** When Feature A needs information or an action from Feature B, it must communicate via:
   - A public contract in `lib/shared/contracts/`
   - Navigation callbacks passed via `AppShell`
   - Shared domain models in `lib/shared/models/`
3. **No Circular Dependencies:** Dependencies must flow downward towards `shared/` and `core/`.

---

## 6. Supabase Integration Principles

- **Authentication:** Managed strictly by Supabase Auth (`auth.users`).
- **Application Data:** Stored in public relational tables with Row Level Security (RLS) enabled on all tables.
- **Client Security:** The Flutter client uses only the public publishable anon key. Never embed service-role keys or database passwords in the app.
- **Data Encapsulation:** All Supabase operations are encapsulated inside `data/` data sources and repositories.
- Refer to `docs/database.md` for full schema specifications and RLS policies.

---

## 7. Error, Loading, and Empty State Handling

Every asynchronous data-driven view must explicitly handle the 4 fundamental UI states:

1. **Loading State:** Display non-blocking progress indicators (shimmer or centered indicator). Prevent duplicate submissions.
2. **Success State:** Display received data using design system tokens.
3. **Empty State:** When query results are empty (e.g., no favorite routes saved, no alerts active), show a friendly illustrative empty state with actionable guidance.
4. **Error State:** Display human-readable, non-technical error messages with a retry button. Never expose raw stack traces or database errors to end users.

---

## 8. Quality Gates and Verification

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
