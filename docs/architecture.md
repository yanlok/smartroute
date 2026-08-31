# SmartRoute final architecture

SmartRoute is an Android-first Klang Valley public-transport companion built around one product journey: plan, compare, understand, follow, and save a commute. It uses a feature-first Clean-Lite architecture with `ChangeNotifier` controllers and the existing manual `AppShell` coordinator.

## Runtime data flow

```text
Malaysia government GTFS ZIP feeds
        -> deterministic import and normalization
        -> bundled canonical transit_network.json
        -> TransitNetworkRepository
        -> Planner / Transit / Tracking / Alerts / Home / Admin selectors

Official Prasarana GTFS-Realtime vehicle positions
        -> OfficialGtfsRealtimeDataSource
        -> OfficialTrackingRepository
        -> fresh bus/BRT vehicle positions only

Supabase Auth and RLS-protected tables
        -> feature repositories
        -> Auth, Profile, SavedJourney, and Notice controllers
        -> passenger and authorized admin screens

SmartRoute-computed journeys + canonical coordinates and GTFS shapes
        -> google_maps_flutter
        -> geographic presentation on Android
```

Google Maps is the geographic canvas. It does not compute public-transport routes. `RoutePlannerService` computes journeys from the normalized government GTFS network.

## Layers

- Presentation renders immutable controller state and forwards user intent. It contains no HTTP, GTFS parsing, Supabase queries, or graph search.
- Application controllers own loading, success, empty, retry, and safe error state.
- Domain and shared contracts define routing, transit identity, tracking, notices, location, user, and saved-journey behavior.
- Data implementations load the bundled network, device location, official realtime protobuf, and Supabase rows.

Cross-feature code depends on `lib/shared/contracts` and `lib/shared/models`. The canonical shared objects are `TransitNetwork`, `TransitRoute`, `TransitStop`, `TransitPattern`, `JourneyOption`, `ServiceNotice`, and saved journey models.

## Canonical transit network

`assets/data/transit_network.json` is a generated snapshot of these official Prasarana feeds:

- `rapid-rail-kl`
- `rapid-bus-kl`
- `rapid-bus-mrtfeeder`

The snapshot contains routes, stops, travel edges, transfer edges, representative schedule patterns, and route shapes. Runtime code parses it once through `BundledTransitNetworkRepository`, which caches the parsed result. It is the single static transit truth for the final mobile app.

Canonical identifiers are namespaced as `<source>:<official_gtfs_id>`, for example `rapid-rail-kl:KJ` and `rapid-rail-kl:KJ21`. Raw GTFS maps never reach widgets.

The older seeded Supabase transit tables remain migration-compatible historical work, but final runtime routing does not mix them with the bundled network. The old timer-driven tracking source and generated rail directory remain isolated test/demo infrastructure; production dependency wiring uses the canonical directory and official realtime repository.

## Routing

`RoutePlannerService` is a pure Dart weighted Dijkstra implementation. The graph includes directed transit edges and nearby interchange/walking connections. Different weights produce Fastest, Fewer transfers, and Least walking alternatives. Duplicate signatures are removed and ordering is stable. Fare values are not fabricated.

## Realtime truth

The official Prasarana realtime integration polls no faster than every 30 seconds. It accepts only bus/BRT positions whose `route_id` matches the same canonical static route and whose timestamp is within two minutes of the device clock. Only those objects have `isLive=true` and can produce a LIVE badge.

Rail never calls a vehicle-position endpoint. Rail and any stale/unavailable bus feed use GTFS scheduled journey progress. The current official feed does not provide arrival predictions, so SmartRoute does not label schedule-derived times as live ETAs.

## Persistence and authorization

Supabase Auth is the only login/session authority. Passenger-owned profile, preferences, favourites, recent searches, subscriptions, and read state are protected by owner-scoped RLS. Admin capability comes from `user_roles`; the client cannot grant roles. `private.is_admin()` is security-definer code with a fixed search path and narrowly granted execution.

Admins manage SmartRoute-owned notices and inspect source metadata. They cannot edit official GTFS truth or create notices presented as official.

## Navigation and lifecycle

The authenticated shell has five tabs: Home, Plan, Transit, Alerts, and Profile. Results, route detail, transit detail, journey progress, and admin are drill-down screens. Controllers and repositories are constructed once in `main.dart`, shared by the shell, and disposed with it.

## Configuration

- Supabase uses the publishable client configuration in `AppConfig`; no service-role secret is present in Flutter.
- Android Google Maps reads `MAPS_API_KEY` from ignored `android/local.properties` into a manifest placeholder.
- Android application ID and Maps restriction package: `com.smartroute.app`.
- Location requires both the stored user preference and Android runtime permission; manual stop selection always remains available.
