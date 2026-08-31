# SmartRoute team contribution ownership

This file records original team ownership and the final integration rule. Git history is the authoritative contribution record.

| Contributor | Original module | Final product responsibility built on that work |
| --- | --- | --- |
| Ernest | Real-Time Transit Tracking | official/fallback journey progress, tracking contracts, controllers, repositories, GTFS-derived line/station architecture |
| YL | Smart Route Planning | planner, map, route results, route detail, routing schema contribution |
| JC | User Management and Home | Supabase Auth/session/profile/preferences, favourites/recents ownership, Home aggregation, visual baseline |
| CQ | Transit Information and Notifications | unified Transit catalogue/map/details and in-app alert experience |
| YH | Admin | authorized operational workspace and SmartRoute notice lifecycle |

## Final integration authorization

The team-authorized final product sprint may change any module when required to close a cross-module flow, unify transit identity/data, remove misleading prototype behavior, or make the submitted Android product coherent. This authorization does not permit erasing authorship, rewriting working code merely for ownership, squashing contributor history, or merging directly into `develop`/`main`.

Historical module commits must remain reachable wherever practical. Final conflict-resolution and integration commits may span modules and should acknowledge the foundations they extend.

## Ongoing boundary rules

- Private feature data access remains behind shared contracts, domain models, controllers, or shell callbacks.
- Home is an aggregator and does not own graph routing, Supabase notice filtering, or realtime parsing.
- Planner, Transit, Tracking, Alerts, and Admin exchange canonical route/stop identities rather than importing each other's private widgets.
- Database authorization, not UI visibility, protects admin capabilities.
- After this sprint, ordinary module tasks again require affected-owner review for cross-module changes.

## Branch policy

Final work stays on `feature/final-product-integration` until the team finishes APK QA and explicitly authorizes a merge. Original remote feature branches and their commits must not be rebased or re-authored as part of the final sprint.
