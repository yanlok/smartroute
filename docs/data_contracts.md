# SmartRoute Cross-Module Data Contracts

This document establishes the guidelines and interface patterns for cross-module communication in SmartRoute.

---

## 1. Architectural Integration Principle

In SmartRoute, each feature module operates as an independent domain owned by a specific team member.

To prevent tight coupling, spaghetti dependencies, and merge conflicts:

```text
[Feature A (Consumer)]
          │
          ▼
[Shared Public Contract (lib/shared/contracts/)]
          ▲
          │
[Feature B (Provider)]
```

### Core Rules:
1. **No Private Imports:** A feature must **NEVER** import another feature's private presentation widgets, internal state controllers, or private data sources.
2. **Promote to Shared with Caution:** Do not prematurely create massive shared model files. A concept is placed in `lib/shared/contracts/` or `lib/shared/models/` **ONLY** when at least two modules genuinely require the exact same stable data shape.
3. **Unidirectional & Acyclic:** Cross-module dependencies must never form a cycle (e.g., Feature A depends on B, and B depends on A). All dependencies point towards `shared/` or `core/`.

---

## 2. Standard Public Contract Interfaces

When modules need to communicate, they interact via abstract Dart contracts located under `lib/shared/contracts/`.

### 2.1 User Session Contract (`IUserSessionContract`)
*Provided by: JC (User Management)*
*Consumed by: Home Dashboard, Planner, Profile*

Exposes current user session status without exposing private Supabase auth tokens or internal controller logic:

```dart
abstract class IUserSessionContract {
  bool get isAuthenticated;
  String? get currentUserId;
  String? get userDisplayName;
  String? get userAvatarUrl;
  Stream<bool> get authStateChanges;
}
```

---

### 2.2 Alert Summary Contract (`IAlertSummaryContract`)
*Provided by: CQ (Notifications & Alerts)*
*Consumed by: Home Dashboard, Planner (Route Warning)*

Allows Home to display high-priority disruption banners without duplicating alert parsing logic:

```dart
class AlertSummary {
  final String id;
  final String title;
  final String lineId;
  final String severity; // 'info', 'warning', 'severe'
  final DateTime publishedAt;

  const AlertSummary({
    required this.id,
    required this.title,
    required this.lineId,
    required this.severity,
    required this.publishedAt,
  });
}

abstract class IAlertSummaryContract {
  Future<List<AlertSummary>> getActiveAlerts();
  Future<List<AlertSummary>> getAlertsForLine(String lineId);
}
```

---

### 2.3 Live Tracking Contract (`ITrackingSummaryContract`)
*Provided by: Ernest (Real-Time Tracking)*
*Consumed by: Home Dashboard, Station Board*

Allows Home to display a quick station countdown card without instantiating the entire live tracking visualizer:

```dart
class LineStatusSummary {
  final String lineCode;
  final String lineName;
  final String status; // 'Normal', 'Delayed', 'Disrupted'
  final int nextTrainEtaMinutes;

  const LineStatusSummary({
    required this.lineCode,
    required this.lineName,
    required this.status,
    required this.nextTrainEtaMinutes,
  });
}

abstract class ITrackingSummaryContract {
  Future<List<LineStatusSummary>> getQuickLineStatuses();
}
```

---

### 2.4 Route Planning Navigation Contract
*Provided by: YL (Smart Route Planning)*
*Consumed by: Home Dashboard (Quick Search)*

When Home initiates a journey search from recent searches or favorite routes, it dispatches user intent via navigation callbacks rather than instantiating the planner repository directly:

```dart
typedef OnPlanRouteRequest = void Function({
  required String originStationId,
  required String destinationStationId,
});
```

---

## 3. Contract Evolution Rules

1. **Backwards Compatibility:** Changes to shared contracts must not break other team members' modules.
2. **Team Consensus:** Any modification to `lib/shared/contracts/` must be agreed upon by both the producing and consuming developers before implementation.
3. **Mock Implementations for Testing:** Every shared contract must have a simple mock or fake implementation in tests to allow unit testing without spinning up dependent modules.
