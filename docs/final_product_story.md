# One commute, from planning to arrival

SmartRoute turns official Malaysian public-transport data into one actionable Klang Valley commute in support of SDG 9: resilient infrastructure, sustainable mobility, and better access to public transport.

## The passenger story

After Supabase registration or login, Home answers what matters now: an active notice relevant to followed or favourite routes, a fast path to plan, persisted favourite journeys, recent journeys, and the current official dataset scope.

Plan answers how to get there. The passenger chooses real stations/stops or, with preference and OS permission, uses current location to find a nearby origin. SmartRoute runs its own weighted graph search over normalized government GTFS routes, stop sequences, schedules, transfers, and shapes.

Results answer which option to take. Fastest, Fewer transfers, and Least walking are different routing objectives, not renamed duplicates. No precise fare is shown because the imported official data does not provide a defensible fare engine.

Route Detail connects every module. It explains each walking/transit segment, boarding and alighting identity, direction, stop count, schedule, transfer, and relevant active notice. The same route opens in Transit and journey progress.

Journey progress tells the truth about operations. A fresh official Prasarana bus/MRT-feeder position can produce LIVE and a vehicle marker. The provider currently supplies vehicle positions, not arrival predictions. Rail uses SCHEDULED departure, expected timing, GTFS line shape, and station sequence. Empty, stale, invalid, or failed bus telemetry calmly falls back to scheduled information.

Transit answers which line, station, stop, and service the passenger is using. Its list, filters, map, station detail, follow action, colours, and shapes all come from the same canonical transit network used by planning and tracking.

Alerts answers what changed. In-app notices are relevant through explicit route subscriptions or favourite journeys, persist read state, and distinguish verified OFFICIAL data from a SMARTROUTE NOTICE.

Profile answers which personal choices matter. It provides real identity/profile, meaningful notification and location preferences, About/Data Sources, logout, and an authorized Admin entry when the database role permits it.

## The operator story

Admin is not a second fake login. An authorized Supabase user opens a role-protected SmartRoute workspace, sees account/network/source context, creates and publishes a line-specific SmartRoute notice, and archives or expires it. A relevant passenger sees the active notice on Home and Alerts and can mark it read. Admins cannot rewrite government GTFS truth or label their own message as official.

## Team contribution continuity

- Ernest's tracking domain, controllers, repositories, import work, and tests form the tracking foundation.
- YL's planner/results/detail and transit migration contribution form the route-planning foundation.
- JC's Supabase user management and Home visual language form the product and design foundation.
- CQ's Transit Information, map, alert concepts, and tests form the transit/notification foundation.
- YH's admin screens form the operational-workspace foundation.

The integration adds shared contracts and product closure without rewriting contributor commits or hiding their history.
