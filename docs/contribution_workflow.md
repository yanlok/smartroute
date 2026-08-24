# SmartRoute Contribution & Git Branching Workflow

This document defines the team Git branching model, Pull Request process, release policies, and developer workflows for SmartRoute.

---

## 1. Branching Strategy

SmartRoute follows a 3-tier branch model:

```text
feature/* (Feature Branches)
       │
       ▼ (Pull Request & Code Review)
   develop (Team Integration Branch)
       │
       ▼ (Release Smoke Testing & Verification)
    main (Stable Production / Demoable Release Branch)
```

### Core Branching Rules:
- **`main`:**
  - **Always stable and demoable.**
  - Never commit or develop directly on `main`.
  - Receives merges **ONLY** from `develop` following comprehensive release verification.
- **`develop`:**
  - Active team integration branch.
  - Never develop directly on `develop`.
  - Feature branches are merged here via Pull Requests.
- **`feature/*`:**
  - Work branches for individual tasks and modules (e.g. `feature/jc-user-management`, `feature/ernest-tracking`).
  - Branch off from latest `develop`.

---

## 2. Feature Development Lifecycle

### Step 1: Start a New Task
```bash
# Switch to develop and get latest changes
git checkout develop
git pull origin develop

# Create your dedicated feature branch
git checkout -b feature/<developer-initials>-<feature-name>
```

### Step 2: Implementation & Context Discipline
- Adhere strictly to your assigned module (`docs/module_ownership.md`).
- Follow the design system tokens (`docs/design.md`).
- Keep changes minimal, clean, and well-tested.

### Step 3: Local Quality Gate Verification
Before committing or creating a PR:
```bash
# 1. Format
dart format --output=none --set-exit-if-changed .

# 2. Analyze
flutter analyze

# 3. Test
flutter test
```

### Step 4: Open a Pull Request
- Target **`develop`** (NEVER target `main`).
- Fill out the PR description using `.github/pull_request_template.md`.
- Request reviews from affected module owners.

---

## 3. Release Policy (`develop` -> `main`)

`main` must remain ready for presentation, grading, and demonstration at all times.

Before merging `develop` into `main`, the team must verify:
- [ ] Application compiles and launches cleanly across target platforms (Android/iOS/Web).
- [ ] Authentication / demo entry paths work reliably.
- [ ] Core navigation between all 5 tabs and detail screens is functioning without crashes.
- [ ] No unhandled fatal exceptions or red error screens.
- [ ] `flutter analyze` reports zero errors.
- [ ] `flutter test` suite passes completely.
- [ ] End-to-end user smoke test performed on device/simulator.

> **Zero Tolerance:** Never use `main` as an experimental or broken staging ground.
