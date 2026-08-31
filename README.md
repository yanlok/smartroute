# SmartRoute

SmartRoute is an Android-first Klang Valley transit companion for BMIT2073 Mobile Application Development. Its product thesis is **one commute, from planning to arrival**. It transforms official Malaysian government GTFS data into route planning, route comparison, transit information, truthful live/scheduled progress, relevant notices, persisted journeys, and a small authorized admin workflow in support of SDG 9.

## Product scope

- Home: authenticated commute summary, relevant notices, favourites, recents, and network metadata.
- Plan: stop/station or current-location origin, multimodal graph routing, real alternatives, results, and detail.
- Transit: LRT, MRT, Monorail, BRT, and bus catalogue, stops, schedules, shapes, and Google Map context.
- Journey progress: official bus/MRT-feeder positions when fresh; scheduled rail and graceful fallback otherwise.
- Alerts: route subscriptions, favourite relevance, source distinction, and persisted read state.
- Profile: real Supabase identity, preferences, About/Data Sources, and authorized Admin access.
- Admin: role-protected notice lifecycle, source metadata, network overview, and safe account overview.

## Data sources and responsibilities

- Transit network/schedules: official Prasarana GTFS Static feeds from Malaysia's `data.gov.my` for `rapid-rail-kl`, `rapid-bus-kl`, and `rapid-bus-mrtfeeder`.
- Realtime: official Prasarana GTFS-Realtime vehicle positions for Rapid KL bus/MRT feeder where current valid positions exist. The provider does not currently supply trip updates or arrival predictions, and rail has no stable realtime feed.
- Map: Google Maps is the geographic presentation layer. It does not compute SmartRoute transit routes.
- User/admin data: Supabase Auth and RLS-protected Postgres tables.

The submitted normalized snapshot contains 237 routes, 6,352 stops, 11,872 graph edges, 279 representative schedule patterns, and shapes for 236 routes. IDs are namespaced official GTFS identifiers such as `rapid-rail-kl:KJ`.

## Architecture

SmartRoute uses feature-first Clean-Lite layers: presentation -> `ChangeNotifier` controller -> domain contract -> repository/data source. `RoutePlannerService` is a pure weighted Dijkstra graph service. `BundledTransitNetworkRepository` caches the one runtime static network. See `docs/architecture.md`, `docs/data_contracts.md`, and `docs/final_product_story.md`.

## Requirements

- Flutter SDK compatible with Dart `^3.11.1`
- Android SDK and Java 17
- Android device/emulator with internet access
- A Google Cloud key with Maps SDK for Android enabled for live map tiles

## Setup

```bash
git clone https://github.com/yanlok/smartroute.git
cd smartroute
flutter pub get
```

The shared coursework Supabase project uses the committed publishable client configuration. A different safe client environment can be supplied with:

```bash
cp config/env.example.json config/env.local.json
flutter run --dart-define-from-file=config/env.local.json
```

Never put a service-role key, database password, or private API credential in Flutter or Git.

## Google Maps local key

Enable **Maps SDK for Android** in Google Cloud. Restrict the key to Android applications using:

- package name: `com.smartroute.app`
- SHA-1/SHA-256 certificate fingerprint for the actual debug or release signer

Add only to ignored `android/local.properties`:

```properties
MAPS_API_KEY=your_restricted_local_key
```

Do not commit or paste the key into issue/chat logs. Verify by running on Android, opening Plan/Transit/Journey Progress, and confirming Google map tiles, station markers, and GTFS route shapes load without authorization errors.

## Run and verify

```bash
flutter run
git diff --check
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/validate_official_sources.dart
```

Android builds:

```bash
flutter clean
flutter pub get
flutter build apk --debug
flutter build apk --release
```

Complete `FINAL_ANDROID_QA.md` before submission. Build output is intentionally ignored.

## Regenerating the official network

Download and extract the three official Prasarana GTFS ZIPs into category-named directories, then run:

```bash
dart run tool/import_gtfs_network.dart \
  --input=/absolute/path/to/extracted-feeds \
  --output=assets/data/transit_network.json \
  --generated-at=ISO8601_UTC
```

Commit a regenerated snapshot only after reviewing counts, tests, service coverage, and source metadata.

## Team acknowledgement

Original module ownership and Git history are retained: Ernest (Tracking), YL (Route Planning), JC (User Management and Home), CQ (Transit Information and Notifications), and YH (Admin). Final integration builds on those contributions rather than replacing their authorship.

Before final submission, set `yanlok/smartroute` to **PRIVATE** and confirm lecturer and all team members retain access.
