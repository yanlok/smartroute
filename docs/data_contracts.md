# Final data contracts

## Transit identity

Every transport feature uses the same canonical identity:

- `TransitRoute.id`: `<feed_category>:<route_id>`
- `TransitRoute.gtfsId`: official GTFS `route_id`
- `TransitStop.id`: `<feed_category>:<stop_id>`
- `TransitStop.gtfsId`: official GTFS `stop_id`
- `TransitPattern.gtfsTripId`: official representative `trip_id`
- `LiveVehicle.vehicleId`: official realtime vehicle descriptor ID or entity ID
- `LiveVehicle.tripId`: official realtime `trip_id` when supplied

The source namespace prevents collisions between the three official feeds. Planner, Route Detail, Transit, map markers, tracking, subscriptions, favourites, notices, and admin route selectors exchange canonical IDs, never display-name joins.

## Transit network contract

`TransitNetworkRepository.loadNetwork()` returns a normalized `TransitNetwork` containing metadata, routes, stops, edges, and schedule patterns. The bundled implementation caches the parsed snapshot. Consumers do not parse JSON or GTFS files.

`JourneyOption` contains objective, origin/destination IDs, duration, transfers, walking metres, and ordered `JourneySegment` objects. Each transit segment references a canonical route and stop sequence. `JourneyMapProjector` converts the computed result to GTFS-shape coordinates for map presentation.

## Tracking contracts

`LineDirectoryRepository` adapts the canonical route and stop objects to Ernest's tracking domain. `TrackingRepository.watchVehicles()` returns `LiveVehicle` objects. `isLive` is a hard truth invariant: it is true only for fresh official telemetry. Schedule-derived `ArrivalEstimate` objects always use `isLive=false`.

## Location contract

`LocationRepository.currentLocation()` returns either a coordinate or a typed permission/service failure. `PlannerController` combines this with the user's stored location preference. A denied permission never prevents manual planning.

## Saved journeys

`SavedJourneyRepository` owns `FavoriteJourney` and `RecentJourney`. Both store canonical origin/destination stop IDs. Favourites also store objective and label. Recent history is de-duplicated by user/origin/destination and bounded to 20 rows.

## Notices

`ServiceNotice` contains canonical `routeId`, severity, lifecycle, active time range, and source:

- `official`: ingested only from a verified official source; passenger/admin clients cannot author it.
- `smartRoute`: created by an authorized SmartRoute admin.

`NoticeRepository` exposes active/all notices according to RLS, route subscriptions, read state, admin checks, source metadata, and safe user summaries. `NoticeController.relevantNotices` intersects active notices with explicit subscriptions or route IDs derived from favourite journeys and respects `notifications_enabled`.

## User and admin contracts

Supabase Auth supplies the session user. Profile rows share the Auth UUID. `user_roles` is read-only to normal clients; `private.is_admin()` supplies authorization to RLS. Admin UI visibility is a convenience only—database policies remain the security boundary.
