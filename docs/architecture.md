# SmartRoute Architecture

This document is the architectural source of truth for SmartRoute. It is written for both developers and AI coding agents. Read it before changing application code and keep it synchronized with intentional architectural changes.

## 1. Project Context

SmartRoute is a Flutter transit companion for the Klang Valley. The current repository is a front-end prototype/MVP for Android, iOS, and web.

Current technical facts:

- Flutter with Dart `^3.11.1`.
- Material 3 using a centralized light theme.
- Feature-first source organization.
- Local widget state with `setState`.
- Root-owned authentication and navigation state in `AppShell`.
- Manual enum-based navigation; no routing package is installed.
- Immutable plain Dart models with `const` constructors.
- Static data in `core/constants/mock_data.dart`.
- No backend, database, persistence, authentication provider, location service, or production transit API.
- No dependency injection, repository layer, service layer, or third-party state-management package.

Do not describe simulated or static behavior as production functionality. Login, live tracking, alerts, journey results, profile data, and payment information are presently UI demonstrations backed by in-memory or mock data.

## 2. Architectural Style

The application uses a small, feature-first architecture:

```text
lib/
├── main.dart
├── core/
│   ├── constants/
│   └── theme/
├── features/
│   └── <feature>/
│       └── screens/
└── shared/
    ├── models/
    └── widgets/
```

Responsibilities are divided as follows:

| Area | Responsibility | Must not contain |
| --- | --- | --- |
| `main.dart` | App bootstrap, `MaterialApp`, root shell, authentication gate, app-wide navigation | Feature-specific rendering or data-access logic |
| `core/constants` | App-wide enums and temporary static prototype data | Stateful widgets or feature UI |
| `core/theme` | Design tokens and `ThemeData` | Feature-specific styling decisions |
| `features/<feature>` | A cohesive user-facing capability and its private presentation components | Unrelated features or app-wide utilities |
| `shared/models` | Models genuinely used across features | Widget state or data fetching |
| `shared/widgets` | Reusable, application-wide visual components | Feature business rules |

The existing feature modules are `login`, `home`, `planner`, `route_results`, `route_detail`, `tracking`, `alerts`, `transit_map`, and `profile`.

## 3. Dependency Direction

Dependencies must point toward stable, reusable code:

```text
main.dart
  ├── features/*
  ├── core/*
  └── shared/*

features/*
  ├── core/*
  └── shared/*

shared/widgets
  ├── shared/models (when required)
  └── core/theme

core/constants
  └── shared/models (temporary mock-data composition only)
```

Rules:

1. A feature must not import another feature's private screen widgets to reuse implementation details.
2. Promote a component to `shared/widgets` only when it is genuinely reused across features and has no feature-specific behavior.
3. Keep a widget private in its feature file when it supports only that screen. Existing code uses private classes such as `_StatCard`, `_StatusBadge`, and `_TimelineStep` for this purpose.
4. `core` must remain independent of feature presentation code.
5. Avoid circular dependencies and catch-all utility files.
6. Prefer relative imports consistently with the existing source tree. Package imports are used for external packages.

## 4. Application Bootstrap and Shell

`main()` initializes Flutter, locks the app to portrait orientation, and runs `SmartRouteApp`.

`SmartRouteApp` is a `StatelessWidget` that configures:

- application title;
- the centralized `AppTheme.light` theme;
- hidden debug banner; and
- `AppShell` as the home widget.

`AppShell` is the current application coordinator and the single source of truth for:

- the prototype login flag;
- the selected bottom-navigation tab;
- the current screen;
- the manual back-history stack;
- the mapping from `AppTab` to `AppScreen`;
- bottom-navigation visibility; and
- logout reset behavior.

Do not duplicate shell state inside screens. A screen requests a transition through the callback supplied by the shell.

## 5. Navigation Contract

Navigation is intentionally implemented without `Navigator` routes or a routing dependency.

- `AppScreen` lists every displayable screen.
- `AppTab` lists the five root tabs.
- `_push` records the current screen and opens a child screen.
- `_pop` restores the latest screen from the local history stack.
- `_switchTab` clears child history and opens the selected tab root.
- `routeResults`, `routeDetail`, and `tracking` hide the bottom navigation.
- Login and logout are controlled by `AppShell`.

Screen constructors use narrow callback contracts such as:

```dart
final ValueChanged<AppScreen> onNavigate;
final VoidCallback onBack;
final VoidCallback onLogout;
```

When adding a screen under the current architecture:

1. Add the value to `AppScreen`.
2. Add its feature screen under `features/<feature>/screens/`.
3. Add exactly one mapping in `AppShell._buildScreen()`.
4. Pass navigation callbacks rather than importing or mutating shell state.
5. Decide explicitly whether the bottom navigation is visible.
6. Update the tab mapping only if the screen is a root tab.

Do not introduce `go_router`, Navigator 2.0, deep-link routing, or another navigation approach as part of an unrelated feature. Navigation migration is an app-wide architectural change and requires an explicit requirement, a migration plan, and updated tests and documentation.

## 6. State Ownership and Data Flow

The current data flow is unidirectional:

```text
AppShell state
    │ callbacks and constructor values
    ▼
Feature screen
    │ local interaction
    ▼
setState for screen-local presentation state
```

State belongs at the narrowest level that needs it:

- Use immutable constructor inputs for values owned by a parent.
- Use callbacks to report user intent upward.
- Use `setState` only for short-lived state local to one widget or screen, such as a selected filter, password visibility, an expanded section, or a toggle.
- Keep derived values out of state when they can be computed from existing state.
- Never mutate state during `build`.
- Check `mounted` before calling `setState` after an asynchronous gap.
- Dispose every `AnimationController`, `TextEditingController`, `Timer`, stream subscription, focus node, and similar resource owned by a `State` object.

Do not add Provider, Riverpod, Bloc, GetX, or another state-management system for a local interaction. If real authentication, persisted preferences, live service alerts, journey planning, or shared session state is introduced, first define ownership and lifecycle, then adopt one project-wide approach through an explicit architectural decision. Do not mix competing state-management systems.

## 7. Models and Data

Shared domain-shaped values currently live in `shared/models/app_models.dart`:

- `TransportLine` and `TransportStatus`;
- `StationInfo`;
- `RouteSegment` and `RouteSegmentType`;
- `RouteOption`; and
- `AlertItem` and `AlertSeverity`.

Model rules:

- Models are plain, null-safe Dart types.
- Prefer immutable `final` fields and `const` constructors.
- Use enums for closed sets of states or types.
- Put presentation labels on enums only while they are simple and not localized.
- Provide focused `copyWith` methods when immutable updates are needed.
- Do not store `BuildContext`, widgets, controllers, or mutable UI state in models.
- Do not add serialization until a real persistence or API contract requires it.
- Keep a model feature-local if only one feature owns it; move it to `shared/models` only after cross-feature reuse is established.

`core/constants/mock_data.dart` is the temporary source for prototype fixtures. New mock fixtures may extend it only when they are app-wide. Feature-only fixtures should stay private to that feature. Mock data must not leak into a future production data source.

There is currently no database. Any task involving persistence must also read and update `docs/database.md` before implementation.

## 8. Future Data and Service Boundaries

Do not create speculative repositories, services, DTOs, or providers. Add a boundary only when a real external concern exists.

When an API, database, device capability, or persistence mechanism is explicitly required, use this separation:

```text
Screen/widgets
    ▼ user intent and rendered state
Feature state/controller
    ▼ domain operation
Repository interface
    ▼ data operation
API, database, or device service
```

Required behavior for such a change:

- UI must not call HTTP clients, databases, platform channels, or storage APIs directly.
- External payloads must be converted at the data boundary rather than spread through widgets.
- Repository interfaces describe feature needs, not vendor APIs.
- Loading, success, empty, and failure states must be explicit.
- Errors shown to users must be actionable and must not expose stack traces or credentials.
- Secrets and environment-specific endpoints must never be committed as Dart constants.
- Dependencies must be justified, narrowly scoped, and compatible with all supported platforms.
- Update this document and `docs/database.md` when the resulting architecture changes.

## 9. Presentation Boundaries

Screens compose presentation and translate user interaction into callbacks. They may contain private, focused widgets. Business rules, data access, authentication, persistence, and network calls do not belong in widget `build` methods.

Split code when doing so creates a meaningful boundary, for example:

- the component is reused;
- it owns an independent lifecycle;
- it has a clear input/output contract; or
- the screen is no longer understandable as a composition of sections.

Do not split every small widget into a file. Reuse, extend, then create. Search the current feature and `shared/widgets` before introducing a component.

Custom drawing is already used for the KL skyline, transit map, and tracking map. Keep painter inputs immutable, keep interaction/state outside `CustomPainter`, and implement `shouldRepaint` according to the values that actually affect output.

## 10. Error, Loading, and Empty States

The current mock-only screens render synchronously, so most do not yet need loading or error states. Once work becomes asynchronous:

- preserve the previous useful UI when appropriate;
- prevent duplicate submissions;
- show a deliberate progress state;
- distinguish an empty result from a failed request;
- offer retry or recovery when possible;
- handle cancellation and widget disposal safely; and
- test success, empty, error, and retry paths.

Do not add fake loading delays or catch errors silently.

## 11. Testing and Quality Gates

The repository currently has one application smoke test. Every behavioral change must add or update tests proportional to its risk:

- unit tests for pure transformations and business rules;
- widget tests for rendering, interaction, validation, callbacks, and states;
- integration tests only for critical multi-screen or platform flows.

Before completion, run at minimum:

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

If a command cannot run, report exactly which check was not completed and why. Do not weaken lints or suppress warnings merely to make a check pass.

## 12. Architectural Change Rules

The following require explicit user requirements and documentation updates:

- adding or replacing state management;
- replacing manual navigation;
- introducing an API, database, authentication provider, persistence, or dependency injection;
- changing the feature-first folder structure;
- adding a new shared abstraction used across the application; or
- adding a dependency that establishes a new architectural pattern.

For any such change:

1. State the problem and constraints.
2. Search for an existing solution in the repository.
3. Compare the smallest viable options.
4. Define ownership, dependencies, lifecycle, failure behavior, and migration scope.
5. Implement the smallest coherent change.
6. Add tests.
7. Update relevant documentation in the same change.

## 13. AI Implementation Checklist

Before editing:

- Read `docs/architecture.md`, `docs/modules.md`, and `docs/design.md` in order.
- Read `docs/database.md` when data persistence or relationships are involved.
- Identify the owning feature and current state owner.
- Search for existing screens, widgets, models, constants, and patterns.
- Confirm whether the request already exists and whether an API or database change is truly required.

During implementation:

- Preserve dependency direction.
- Keep state at the narrowest valid owner.
- Reuse existing components and design tokens.
- Avoid unrelated refactors and speculative abstractions.
- Keep UI separate from business and data-access logic.
- Handle lifecycle, null safety, asynchronous errors, and all relevant UI states.

Before completion:

- Review the diff for duplicated code, dead code, hardcoded design values, and unrelated changes.
- Verify responsive behavior and accessibility.
- Format, analyze, and test.
- Update documentation if the architecture changed.
