# Final product modules

SmartRoute presents one commute rather than exposing team module boundaries. Original authorship remains in Git history and the final responsibilities are integrated as follows.

## User Management and Home — JC foundation

Supabase registration, login, session restoration, logout, profile, notifications preference, and location preference remain the user foundation. Home aggregates authenticated identity, relevant notices, favourites, recent journeys, and official network metadata. Unsupported social login, forgot-password, language switching, balance, savings, and fake personal statistics are not shown.

## Smart Route Planning — YL foundation

Plan supports searchable stop/station origin and destination, device location to the nearest stop when permission is available, mode filters, and three graph objectives. Results compare genuinely different paths. Route Detail explains boarding, direction, stops, transfers, scheduled time, and relevant notices, then links to the same transit identity and journey progress.

## Tracking and journey progress — Ernest foundation

Ernest's domain contracts, controllers, repository boundaries, generated GTFS work, and tests remain the base. Production wiring adds official Prasarana bus/MRT-feeder vehicle positions and the canonical network adapter. Fresh matched telemetry is LIVE. Rail and fallback experiences are SCHEDULED with next departure, expected journey timing, GTFS shape, and station sequence.

## Transit and Alerts — CQ foundation

Transit now reads all modes, routes, stops, schedules, coordinates, and shapes from the canonical network. Users filter mode and line, inspect line/station details, open the geographic map, and follow real route identities. Alerts are Supabase-backed, relevant to explicit subscriptions or favourite journeys, source-labelled, and persist read/unread state.

## Admin — YH foundation

The original dashboard contribution has evolved into an authorized workspace using the same Supabase session. It provides account overview, active SmartRoute notices, network metrics, source metadata, line-specific notice create/edit/publish/archive, and a safe user overview. No password is displayed or manipulated. Official transport records are read-only.

## Shared product shell

Primary tabs are Home, Plan, Transit, Alerts, and Profile. Tracking is journey context, not a standalone tab. Profile contains About/Data Sources and exposes Admin only when the database role authorizes it.

## Closed loops

- Plan -> compare -> detail -> save -> Home -> logout/login -> saved favourite.
- Plan -> successful search -> Home/Planner recent journey -> logout/login -> replan.
- Follow a route or save a journey -> relevant active notice on Home and Alerts -> mark read.
- Authorized admin -> publish/expire a SmartRoute notice -> relevant passenger surfaces reflect active state through Supabase.
- Rail route -> scheduled journey progress without a missing-realtime dead end.
- Supported bus route -> fresh official position gives LIVE; invalid, stale, empty, or failed telemetry falls back to scheduled presentation.
