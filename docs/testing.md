# SmartRoute testing

## Automated gates

Run from the repository root:

```bash
git diff --check
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/validate_official_sources.dart
```

The suite covers Auth/session state, profile/preferences, favourites and recents, graph routing and ranking, normalized GTFS data, map projection, scheduled rail truth, official realtime parsing/mapping/staleness, LIVE-vs-SCHEDULED UI, notice relevance/read state/admin lifecycle, and legacy Ernest domain behavior.

## Required routing cases

`route_planner_service_test.dart` verifies direct rail, one transfer, multimodal travel, unreachable destinations, same origin/destination, mode filtering, transfer penalty, least-transfer weighting, least-walking weighting, stable ordering, and GTFS-shape projection.

`bundled_transit_network_repository_test.dart` parses the actual submitted asset and proves all five modes, thousands of official stops, canonical Kelana Jaya identity, schedule patterns, shapes, and routing beyond the old handcrafted location set.

## Realtime truth tests

- Official protobuf maps vehicle, trip, route, timestamp, and coordinate identity.
- Stale or route-mismatched positions are rejected.
- Rail never calls a vehicle feed.
- Schedule-derived arrivals are never marked live.
- Tracking UI uses SCHEDULED without a realtime-unavailable message unless a genuine live object exists.

## Database QA

Migration replay and RLS checks are run against isolated/transactional contexts, never by resetting the shared project. Test anonymous, passenger A, passenger B, and admin claims. Roll back QA data and confirm no residue.

## Real-source validation

`tool/validate_official_sources.dart` checks the submitted snapshot metadata, downloads all three official static ZIPs, parses official realtime protobuf responses, reports vehicle counts/timestamps, and treats the documented rail 404 as scheduled behavior. A reachable realtime endpoint is not enough to claim LIVE: an actual matching position must also be fresh.

## Manual Android QA

Automated tests cannot prove map tiles, runtime permission dialogs, network behavior, or complete touch paths on a lecturer's device. Follow `FINAL_ANDROID_QA.md` with a restricted Maps key. Record actual pass/fail results; do not infer them from compilation.
