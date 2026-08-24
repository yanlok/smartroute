# SmartRoute Testing Strategy & Quality Gates

This document outlines the testing standards, test types, test directory structure, and verification quality gates for the SmartRoute project.

---

## 1. Testing Philosophy & Test Pyramid

Testing ensures confidence and regression safety across all team modules.

```text
       ▲
      / \        Integration Tests (Critical end-to-end flows)
     /   \
    /     \      Widget Tests (Component rendering, UI states, user interactions)
   /       \
  /─────────\    Unit Tests (Controllers, view-models, business logic, pure transformers)
```

1. **Unit Tests (Fast, Isolated, High Volume):**
   - Controllers / ViewModels (`ChangeNotifier`) state transitions.
   - Domain business rules and validation logic.
   - DTO to domain model transformations.
   - Repository error handling and fallback mechanisms.

2. **Widget Tests (Component & Screen Level):**
   - Screen rendering across different states (loading, success, empty, error).
   - User interactions (tapping buttons, filling forms, error dialogs).
   - Critical screens: Login, Registration, Profile, Home, Planner, Alerts.
   - Form input validation messages.

3. **Integration Tests (Narrow & Selective):**
   - Key multi-screen user journeys (e.g. login flow -> home dashboard -> journey search).
   - Only implemented when critical cross-module flows require end-to-end assurance.

---

## 2. Test Directory Structure

Test files must mirror the `lib/` directory structure under `test/`:

```text
test/
├── features/
│   ├── user_management/
│   │   ├── application/
│   │   │   ├── auth_controller_test.dart
│   │   │   └── profile_controller_test.dart
│   │   ├── data/
│   │   │   └── user_repository_impl_test.dart
│   │   └── presentation/
│   │       ├── login_screen_test.dart
│   │       └── profile_screen_test.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen_test.dart
│   └── tracking/
│       └── application/
│           └── tracking_controller_test.dart
└── shared/
    └── widgets/
        └── custom_button_test.dart
```

---

## 3. Mocking & Isolation Strategy

1. **Isolate External Dependencies:**
   - **NEVER** make real network or live Supabase database calls in automated unit/widget tests.
   - Test against abstract repository interfaces (`IAuthRepository`, `IUserRepository`, etc.) using simple mock/fake classes or test doubles.
2. **Deterministic Time & Async:**
   - Use `tester.pump()`, `tester.pumpAndSettle()`, or fake async clocks to avoid flaky timing issues.

---

## 4. Required Quality Gates

Before opening a pull request or submitting code:

### Gate 1: Code Formatting
Ensure all Dart code conforms to the standard formatter:
```bash
dart format --output=none --set-exit-if-changed .
```

### Gate 2: Static Analysis
Ensure zero errors and zero warnings:
```bash
flutter analyze
```

### Gate 3: Automated Test Suite
Ensure all unit and widget tests pass:
```bash
flutter test
```

> **Regression Rule:** A feature PR must **NEVER** knowingly break existing demo functionality, smoke tests, or tests written by other teammates.
