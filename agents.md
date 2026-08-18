# AI Development Workflow

This repository follows Context Engineering, strict module boundaries, and an incremental transitional architecture.

AI coding agents MUST understand the project context, architectural rules, and ownership boundaries before making any implementation decisions.

Never skip the required reading process.

---

# Required Reading Order

Before making any changes, AI MUST read the following documents in order:

1. `agents.md` (this file)
2. `docs/architecture.md` (Architecture v2 source of truth)
3. `docs/module_ownership.md` (Team module ownership & protected boundaries)
4. `docs/modules.md` (Feature behavioral specifications)
5. `docs/design.md` (Design system tokens & UI standards)
6. `docs/database.md` (Only if data persistence or Supabase is involved)
7. `docs/data_contracts.md` (When cross-module integration is involved)
8. `docs/testing.md` (Testing requirements and quality gates)

Do NOT begin implementation until sufficient context has been gathered.

---

# AI Workflow

Every task follows this sequential workflow:

```text
Requirements & Task Card Analysis
               ↓
            Planning
               ↓
       Context Validation
               ↓
         Implementation
               ↓
          Self Review
               ↓
    Quality Gates & Verification
               ↓
            Completion
```

Never skip any stage.

---

# Stage 1 — Planning

Before writing any code, AI must determine and verify:

- **Task ID & Scope:** What exact task card is being executed?
- **Owning Module:** Which module does the feature belong to (e.g. User Management, Tracking, Planner)?
- **Allowed Files:** Which files are within the developer's assigned scope?
- **Protected Files:** Which files belong to other teammates and must NOT be modified?
- **Existing Contracts:** Does this task consume or expose a shared contract from `docs/data_contracts.md`?
- **Can existing components be reused?** Search both target and legacy paths.
- **Database Impact:** Are database changes required? If yes, verify with `docs/database.md`. (Do not deploy migrations without explicit instruction).
- **Acceptance Criteria & Required Tests:** What unit and widget tests are required by `docs/testing.md`?

If information is missing or ambiguous, ask for clarification instead of making assumptions.
Never start coding immediately.

---

# Stage 2 — Context Validation (Transitional Codebase Awareness)

The repository is currently in a **TRANSITIONAL** state between the initial prototype and Architecture V2:
- **Target Architecture V2 paths:** `lib/features/<feature>/presentation/`, `application/`, `domain/`, `data/`
- **Current / Legacy paths:** `lib/features/<feature>/screens/`, `lib/features/login/`, `lib/features/profile/`, `lib/shared/models/app_models.dart`, `lib/core/constants/mock_data.dart`

Before creating any new file or class, AI **MUST search BOTH**:
1. Current / legacy paths
2. Target Architecture V2 paths

### Transitional Rules:
- **Never ignore legacy code:** Target folders do not imply that existing legacy code can be overlooked or duplicated.
- **No duplicate implementations:** If a widget, model, or helper already exists in a legacy path, reuse or extend it. Do NOT create a duplicate in the target path.
- **Incremental migration only:** Legacy code is migrated incrementally **only** when the active Task Card explicitly targets that feature/path.
- **No mass restructuring:** A normal feature Task Card must **NEVER** mass-move, rename, or restructure unrelated legacy feature files.
- **Legacy code validity:** Existing implementations in legacy paths remain valid until intentionally migrated by the owning developer.

Search checklist:
- Screens in `lib/features/<module>/presentation/screens/` AND `lib/features/<module>/screens/`
- Widgets in `lib/features/<module>/presentation/widgets/`, `lib/features/<module>/screens/`, and `lib/shared/widgets/`
- Models in `lib/shared/models/` and `lib/features/<module>/domain/models/`
- Repositories, controllers, and services in target and legacy paths
- Theme tokens in `lib/core/theme/` and utilities in `lib/core/utils/`

---

# Stage 3 — Implementation

When implementing features:

1. **Follow the Architecture:** Strictly adhere to the Feature-First, Clean-Lite architecture (`presentation/`, `application/`, `domain/`, `data/`).
2. **Respect Module Ownership:** Stay within assigned directories defined in `docs/module_ownership.md`.
3. **Follow Design Standards:** Use `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, and `AppShadows` from `docs/design.md`. Never hardcode colors or raw text styles when tokens exist.
4. **State Management Constraint:** Use `ChangeNotifier` / controller / view-model for business state. Use `setState` only for trivial screen-local UI state. Do NOT introduce Riverpod, Bloc, GetX, or other libraries.
5. **Navigation Constraint:** Respect manual shell navigation (`AppShell`). Do NOT introduce `go_router`, `AutoRoute`, or Navigator 2.0.
6. **Keep Changes Small:** Modify the minimum number of files necessary. No speculative abstractions.

---

# Stage 4 — Self Review & Quality Gates

Before concluding any implementation turn, AI must self-review against this checklist:

### Self-Review Checklist
- [ ] Existing components and theme tokens reused (checked both legacy and target paths)
- [ ] No duplicated logic, models, or widgets
- [ ] Module boundaries respected (no unauthorized edits to other owners' files)
- [ ] Business/data logic separated from UI (no Supabase/API calls inside widgets or `build()` methods)
- [ ] Controller/view-model properly handles state lifecycle and resource disposal
- [ ] Loading state handled (non-blocking, progress indicators where applicable)
- [ ] Error state handled (user-friendly messages, retry capability where applicable)
- [ ] Empty state handled (meaningful empty views where applicable)
- [ ] Null safety respected
- [ ] No hardcoded design values when a design token exists (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`)
- [ ] User-visible reusable strings centralized when reuse/localization requires it (simple feature-specific labels do not require premature abstraction)
- [ ] No dead code or unused imports

### Verification Commands
AI must run:
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
Confirm all tests pass and analyze reports zero warnings/errors before finishing.

---

# What AI Coding Agents Must NEVER Do

AI must NOT:

- **Redesign Architecture:** Do not redesign, rewrite, or replace the established Clean-Lite architecture based on personal preference.
- **Cross Module Boundaries:** Do not modify another teammate's module without explicit permission or a team-approved contract change.
- **Introduce New State Management:** Do not install or introduce Riverpod, Bloc, GetX, MobX, etc.
- **Introduce Routing Packages:** Do not install or introduce `go_router`, AutoRoute, or custom router packages.
- **Edit `main` or `develop` Directly:** All work must happen on dedicated `feature/*` branches.
- **Deploy Database Migrations:** Do not apply database changes to live Supabase instances unless explicitly instructed.
- **Expose Secrets:** Never commit service-role keys, raw API tokens, or hardcoded credentials.
- **Duplicate Existing Functionality:** Always search and reuse existing widgets and models across both legacy and target paths.
- **Perform Unrelated Refactoring:** Do not reformat, refactor, or rename code outside the active task scope.
- **Guess Requirements:** Ask for clarification if specifications in `docs/` are incomplete.

---

# Task Card Execution

AI should implement narrow, well-defined Task Cards structured as follows:

```markdown
### Task Card: [TASK-ID] [Title]
- **Module:** [e.g. User Management]
- **Owner:** [e.g. JC]
- **Target Files:** [List of files to create/modify]
- **Contract Dependencies:** [Shared contracts consumed/exposed]
- **Database Tables:** [Profiles, user_preferences, etc.]
- **Acceptance Criteria:** [Specific testable requirements]
- **Required Tests:** [Unit / Widget test files]
```

---

# Quality Gate Summary

```text
✓ Read all required docs in order
        ↓
✓ Validated existing context (searched legacy & target paths)
        ↓
✓ Strictly adhered to Clean-Lite architecture
        ↓
✓ Followed design tokens (docs/design.md)
        ↓
✓ Respected module ownership boundaries
        ↓
✓ Self-reviewed implementation
        ↓
✓ Verified via format, analyze, and tests
        ↓
✓ Ready for production PR
```