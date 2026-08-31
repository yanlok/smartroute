# SmartRoute final integration audit

Audit date: 31 August 2026 (Asia/Kuala_Lumpur)

## Repository protection

The local checkout was on `develop` at `d53048b` and contained one uncommitted change in `analysis_options.yaml`. It added analyzer exclusions for generated/native directories. The change and any untracked files were preserved in `stash@{0}` as `user-local-work-before-final-integration-2026-08-31`. Nothing was discarded. Remote branches were then fetched with pruning.

The final integration branch did not previously exist locally or on `origin`. It was created from the fetched `origin/develop` head `903a4c1` as `feature/final-product-integration`.

## Remote branch inventory

| Branch | Audited head | Relative to `origin/develop` | Finding |
| --- | --- | --- | --- |
| `origin/develop` | `903a4c1` | baseline | Contains JC Auth/Profile/Home work and CQ Transit Information integration. |
| `origin/real-time-transit-tracking-module` | `1f6e519` | 1 ahead, 0 behind | Clean-Lite tracking implementation, generated official rail GTFS snapshot, import tooling, repository/controller layers, and 21 focused test files. Production wiring still used timer simulation. |
| `origin/feature/yl-smart-route` | `5795450` | 3 ahead, 3 behind | Planner/map/results improvements and a transit schema migration. Planner still consumed handcrafted route templates and its map was a custom-painted illustration. No new planner domain/controller tests. |
| `origin/transit_info_notification` | `547c573` | 0 ahead, 33 behind | Already merged into develop through `1814288`; no re-merge required. Transit Information exposed detailed information only for hardcoded bus T250. Alerts were in-memory prototype notifications. |
| `origin/admin-module` | `e201f54` | 1 ahead, 34 behind | Admin visual shell and widget test. It used visible hardcoded credentials, a local-only session, and an unconfigured dashboard. A generated Gradle HTML report was excluded during conflict resolution. |
| `origin/feature/jc-user-management` | `aa389d9` | 0 ahead, 14 behind | Already an ancestor of develop. Supabase Auth, session restoration, profile, preferences, repository/controller tests retained. |
| `origin/feature/jc-home-dashboard` | `81e9993` | 0 ahead, 7 behind | Already an ancestor of develop. Current product visual baseline retained. |
| `origin/feature/jc-architecture-v2` | `ded8b0c` | 0 ahead, 32 behind | Architecture documentation already inherited by develop. |

## Contribution integration

Ernest's branch was merged intact in merge commit `dbae151`. YL's three unique commits were merged intact in `fec596e`. YH's unique commit was merged through conflict-resolution commit `331d029`. CQ and JC histories remain reachable through `origin/develop`. No contributor commits were squashed or re-authored.

The YH conflict resolution retained the latest Supabase passenger Auth flow, retained the admin screens as the visual starting point, regenerated `pubspec.lock`, and excluded the generated `android/build/reports/problems/problems-report.html` artifact.

## Architecture and dependency findings

The inherited app is transitional. JC User Management and Ernest Tracking use application/domain/data layers; Planner, Route Detail, Transit Information, Transit Map, Alerts, Home, and Admin still contain substantial state or fixed data in screens. Cross-feature navigation is coordinated manually in `main.dart` using `AppScreen` and `AppTab`.

The fetched develop manifest contained Flutter, Material/Cupertino, Google Fonts, SVG, Supabase Flutter, flutter_lints, and mocktail. Neither Google Maps nor device location nor GTFS-Realtime protobuf parsing was present.

The merged baseline analysis failed with five compile errors and ten lint/deprecation findings. The compile errors came from Tracking/Admin constructor drift after branch integration. Other findings included unused YL painter code, deprecated form/radio APIs, and legacy library comments. These are integration defects, not accepted final state.

## Official transit data findings

The official data.gov.my Prasarana endpoints were fetched directly on 31 August 2026:

- `rapid-rail-kl`: 8 routes, 186 stops, 47 trips, 1,122 stop times, and 7,280 shape points.
- `rapid-bus-kl`: 137 routes, 4,053 stops, 2,102 trips, 87,935 stop times, and 69,246 shape points.
- `rapid-bus-mrtfeeder`: 92 routes, 2,112 stops, 9,548 trips, 259,508 stop times, and 35,219 shape points.

Counts above exclude CSV header rows. The downloaded ZIP sizes were 80,595 bytes, 1,677,203 bytes, and 2,702,583 bytes respectively.

The official Rapid KL bus and MRT feeder GTFS-Realtime vehicle-position endpoints returned valid non-empty protobuf payloads of 8,920 bytes and 6,332 bytes during the audit. The equivalent rail endpoint returned HTTP 404. Rail must therefore use GTFS schedules and journey progress without a `LIVE` claim. The documented official realtime API exposes vehicle positions; no official Prasarana trip-update/arrival-prediction endpoint was verified.

Ernest's generated snapshot is valuable and truthful but rail-only. It contains eight lines and real station coordinates/shapes. Its importer mentions bus feeds but reads only `data/gtfs/rapid-rail-kl`, and production repositories instantiate `MockTrackingDataSource`. The simulated objects correctly set `isLive` to false, but the prototype still presents a tracking surface driven by timers.

YL's transit migration contains seven lines, twenty stations, fourteen links, and five handcrafted route templates. The Flutter planner independently contains handcrafted options and precise fare values. These are insufficient as the final network/routing truth.

## Supabase findings

The shared project `lomjlfmikzzdmctyngjv` is active and healthy in `ap-southeast-1` on Postgres 17.6. Remote migration history records only:

- `20260818162514_create_user_management`
- `20260819052050_tighten_user_management_service_role_grants`

Remote tables also include YL's `transit_lines`, `transit_stations`, `station_lines`, `transit_links`, `route_templates`, and `route_template_segments`, all with RLS enabled and the expected seed counts. This confirms migration-history drift. Exact constraints, privileges, policies, and seed equivalence must be verified before history repair. Existing Auth users and the three profile/preference rows must not be modified destructively.

The remote project does not yet contain favourites, recent searches, notification subscriptions/read state, SmartRoute service notices, source metadata, or a safe admin-role table.

## Product gaps to close

- Six permanent tabs expose module boundaries and need consolidation to Home, Plan, Transit, Alerts, Profile.
- Planner and Results use fixed locations/options instead of a network graph.
- Planner map is an illustrative Malaysia painter, not Google Maps.
- Route Detail is tied to T250/fixed data and exposes a generic `Track Live` action.
- Tracking production wiring uses timer simulation and a custom painter.
- Transit Information is complete only for T250; other mode controls are disabled.
- Transit Map uses independent mock data and custom coordinates.
- Alerts/read state/preferences are in-memory.
- Home shows fixed favourite/status content rather than repository aggregation.
- Favourite and recent-search persistence tables and closed loops are absent.
- Admin uses hardcoded credentials and no database authorization or tools.
- Forgot-password, social login, terms/privacy text, and other visible actions require implementation or removal.
- No Google Maps key flow, location permission integration, About/Data Sources surface, final release checklist, or Android QA document exists.

This audit is the implementation baseline. Final documentation must report only capabilities verified after the integration and quality gates.

## Final integration outcome

The implementation now uses a single generated official network at runtime: 237 routes, 6,352 stops, 11,872 edges, 279 representative schedule patterns, and 236 route shapes. IDs are source-namespaced official GTFS IDs. A pure weighted Dijkstra service supplies Fastest, Fewer transfers, and Least walking objectives across LRT, MRT, Monorail, BRT, and bus. Google Maps displays SmartRoute's stops, shapes, and computed journeys but does not provide transit directions.

Production tracking keeps Ernest's controller/repository contracts and uses `OfficialTrackingRepository` plus the canonical line adapter. Official vehicle positions are accepted only for bus/BRT when route identity matches and timestamps are fresh. Rail never queries the unstable endpoint and presents GTFS scheduled progress. The timer-driven repository remains reachable only as test/demo infrastructure and is not constructed by `main.dart`.

Passenger navigation is now Home, Plan, Transit, Alerts, and Profile. Results, Route Detail, Transit detail, Journey Progress, and Admin are contextual drill-downs. The hardcoded admin portal, illustrative fake maps, fake Home statistics, unsupported social/forgot-password actions, and fake language setting were removed from the visible final app.

Supabase migration drift was resolved only after exact structural, privilege, policy, index, and seed equivalence checks. The missing YL migration-history record was repaired without replaying it over existing tables. Three forward final-product migrations were applied. A full isolated transactional replay and anonymous/passenger-A/passenger-B/admin RLS test passed without deleting or resetting Auth users. One existing generic coursework account received the database admin role; no password was read, changed, printed, or committed.

The final source validation on 1 September 2026 again returned HTTP 200 for all three static feeds with the same payload sizes. At the overnight validation time, Rapid KL bus returned no vehicle positions and MRT feeder returned a position with an invalid future timestamp; SmartRoute rejected both as not fresh and would show scheduled times. This proves fallback behavior, not the bus LIVE closed loop. That live-device scenario remains conditional on a valid fresh provider position during operating hours.

The Android Maps implementation is complete, but `MAPS_API_KEY` is absent from ignored `android/local.properties`. Live tiles cannot be marked verified until the team configures a key restricted to `com.smartroute.app` and the signing certificate, then completes `FINAL_ANDROID_QA.md`.
