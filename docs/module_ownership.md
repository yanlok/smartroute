# SmartRoute Team Module Ownership

This document defines the official ownership boundaries, protected codebase paths, and cross-team integration rules for the SmartRoute project.

Every team member has distinct ownership over specific functional modules to enable parallel development without conflicts.

---

## 1. Module Ownership Matrix

| Developer | Module / Domain | Scope & Core Concepts | Codebase Paths |
| :--- | :--- | :--- | :--- |
| **Ernest** | **Real-Time Transit Tracking** | Live arrival countdowns, train/bus tracking, vehicle location pipeline, platform & stop live telemetry. | `lib/features/tracking/**` |
| **YL** | **Smart Route Planning** | Journey planner, origin/destination selection, multimodal routing, route comparisons, ETA estimation, fare calculations, route results & detail logic. | `lib/features/planner/**`<br>`lib/features/route_results/**`<br>`lib/features/route_detail/**` |
| **JC** | **User Management**<br>& **Home Dashboard** | Authentication UI integration (login, register, logout), user session lifecycle, profile management, persistent user preferences, favorite routes, recent searches, and Home Dashboard composition/aggregation. | `lib/features/user_management/**`<br>`lib/features/home/**`<br>*(and existing login/profile during migration)* |
| **CQ** | **Transit Information**<br>& **Notifications & Alerts** | Station details, line metadata, operating hours, facilities, accessibility info, interactive transit maps, service disruption alerts, delay notifications, announcements. | `lib/features/alerts/**`<br>`lib/features/transit_map/**` |
| **YH** | **Admin Module** | Transit information administration, user account management/moderation, feedback administration, alert and announcement broadcasting administration. | `lib/features/admin/**` *(future)* |

---

## 2. Protected Codebase Rules

1. **Strict Ownership Boundaries:**
   - Developers must work inside their assigned module directories.
   - A developer MUST NOT edit another owner's feature implementation unless:
     1. Cross-module integration explicitly requires it;
     2. The module owner has given explicit consent; or
     3. The change modifies a shared contract in `lib/shared/contracts/` approved by the team.

2. **No Direct Private Widget/Repository Imports:**
   - Never import another feature's private widgets or internal data layer classes (e.g. `import '../tracking/widgets/_live_map.dart'`).
   - All cross-module data exchange must occur through public contracts in `lib/shared/contracts/` or shared models in `lib/shared/models/`.

3. **Branch Isolation:**
   - Feature branches must reflect the owner and feature (e.g. `feature/jc-user-management`, `feature/ernest-live-tracking`).
   - Merge requests must be reviewed by affected module owners before merging into `develop`.

---

## 3. The Home Dashboard Aggregation Rule

The **Home Dashboard (`lib/features/home/`)** owned by **JC** is an **AGGREGATOR**, not the owner of every feature's underlying business logic.

```text
                                  ┌────────────────────────┐
                                  │     Home Dashboard     │
                                  │      (Aggregator)      │
                                  └───────────┬────────────┘
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      ▼                       ▼                       ▼
           ┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
           │   Alert Contract    │ │  Tracking Contract  │ │ Navigation Callback │
           │   (Owned by CQ)     │ │ (Owned by Ernest)   │ │   (To YL Planner)   │
           └─────────────────────┘ └─────────────────────┘ └─────────────────────┘
```

### Specific Integration Examples:
- **Service Alerts Widget on Home:**
  - Home may **DISPLAY** a high-priority alert summary provided by CQ's alerts module.
  - Home must **NOT** duplicate CQ's alert-fetching, filtering, or severity-interpretation logic.
- **Route Planning Entry on Home:**
  - Home provides search bars and shortcut buttons that **NAVIGATE** to YL's planner module via navigation callbacks.
  - Home must **NOT** implement YL's route-planning algorithm or fare calculations.
- **Live Transit Status on Home:**
  - Home may **DISPLAY** quick station/line status supplied through a public contract provided by Ernest.
  - Home must **NOT** duplicate Ernest's live vehicle tracking pipeline or WebSocket/polling logic.

---

## 4. Conflict Resolution Workflow

If a feature requirement spans multiple domains:
1. Discuss and agree upon a shared contract interface in `lib/shared/contracts/` (see `docs/data_contracts.md`).
2. The owning developer implements the contract provider in their respective module.
3. The consumer developer integrates the contract via dependency injection or callbacks.
4. Open a Pull Request with all affected module owners tagged as reviewers.
