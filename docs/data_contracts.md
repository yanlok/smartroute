# SmartRoute Cross-Module Integration & Contract Principles

This document establishes the architectural principles and candidate capabilities for cross-module integration in SmartRoute.

---

## 1. Architectural Integration Principles

In SmartRoute, each functional module is owned by a specific team member.

To prevent tight coupling, duplicate logic, and merge conflicts across module boundaries:

```text
[Feature A (Consumer)]
          │
          ▼
[Shared Public Contract (lib/shared/contracts/)]
          ▲
          │
[Feature B (Provider)]
```

### Core Contract Principles:
1. **No Private Imports:** A feature must **NEVER** import another feature's private presentation widgets, internal state controllers, or private data sources.
2. **Promote to Shared with Caution:** Do not prematurely create massive shared model files. A concept belongs in `lib/shared/contracts/` or `lib/shared/models/` **ONLY** when at least two modules genuinely require the exact same stable data shape.
3. **Avoid Leaking Implementation Details:** A public contract must only expose minimal, high-level capabilities required by consumers, never exposing provider-internal network models, database rows, or framework dependencies.
4. **Unidirectional & Acyclic:** Cross-module dependencies must never form a cycle. Dependencies flow towards `shared/` and `core/`.

---

## 2. Cross-Module Contract Readiness Rule

A cross-module contract becomes implementation-ready **ONLY** when all of the following conditions are met:
1. **Provider owner agrees** to supply the capability;
2. **Consumer owner agrees** on the interface requirements;
3. The **minimal shared data shape** is established and verified;
4. The contract avoids leaking provider-internal implementation details.

> **Phase 0 Status:** In Phase 0, integration needs are identified conceptually as **candidate capabilities**. Concrete Dart interfaces will be finalized by module owners during their respective feature phases.

---

## 3. Candidate Integration Capabilities

The following candidate integration capabilities represent areas where features will exchange data:

### 3.1 User Session & Authentication Capability
- **Provider:** JC (User Management)
- **Consumers:** Home Dashboard, Route Planner, Profile
- **Conceptual Need:** Expose whether the user is currently authenticated and provide basic profile summary information (user ID, display name, avatar) without exposing raw tokens or auth implementation details.
- *Note:* JC will design the final JC-owned session capability in a future User Management Task Card.

---

### 3.2 Service Alert Summary Capability
- **Provider:** CQ (Notifications & Alerts)
- **Consumers:** Home Dashboard (Disruption Banner), Route Planner (Line Warnings)
- **Conceptual Need:** Supply high-priority service disruption summaries (title, affected line, severity level) for Home without requiring Home to fetch or interpret raw disruption feeds.
- *Note:* Final method signatures and data structures will be established when CQ implements the Alerts module.

```dart
// Illustrative example only — not an approved implementation contract.
abstract class IAlertSummaryCandidate {
  // Conceptual: provide active alerts affecting transit lines
}
```

---

### 3.3 Live Transit Tracking & Status Capability
- **Provider:** Ernest (Real-Time Transit Tracking)
- **Consumers:** Home Dashboard (Live Station Status Card)
- **Conceptual Need:** Supply quick line status summaries or next-arrival countdowns for Home without instantiating the full live vehicle tracking pipeline or UI visualizer.
- *Note:* Final contract shape will be defined when Ernest implements the Tracking module.

```dart
// Illustrative example only — not an approved implementation contract.
abstract class ITrackingSummaryCandidate {
  // Conceptual: provide quick status summary for prominent stations/lines
}
```

---

### 3.4 Route Planning Navigation Capability
- **Provider:** YL (Smart Route Planning)
- **Consumers:** Home Dashboard (Recent Search / Favorite Route shortcuts)
- **Conceptual Need:** Dispatch user intent to calculate a route between origin and destination stations via navigation callbacks or parameter passing, rather than Home implementing routing algorithms.

---

### 3.5 Shared Transit Station & Route Summaries
- **Shared Entities:** Genuinely shared transit concepts (such as `StationInfo`, `TransportLine`, or basic route summary metadata) will reside in `lib/shared/models/` once their shared definitions are verified across Planner, Map, and Tracking modules.
