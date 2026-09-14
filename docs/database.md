# SmartRoute database

Shared Supabase project: `smartroute` (`lomjlfmikzzdmctyngjv`). Flutter uses only the client publishable key and relies on RLS. Service-role and database credentials must never be committed or embedded in the app.

## Migration history

Migrations replay in this order:

1. `20260818162514_create_user_management.sql`
2. `20260819052050_tighten_user_management_service_role_grants.sql`
3. `20260828090000_create_transit_network_and_route_data.sql`
4. `20260831134745_final_product_persistence_and_notices.sql`
5. `20260831134919_grant_private_schema_usage_for_authorization.sql`
6. `20260831173452_optimize_transit_foreign_keys_and_rls_policies.sql`

The remote database already contained YL's transit schema and exact seed data although its migration-history row was absent. Columns, constraints, indexes, grants, policies, and all seed rows were compared before recording `20260828090000` in `supabase_migrations.schema_migrations`. This repaired history only; it did not recreate tables, rewrite seed data, or touch Auth users.

The three final forward migrations were then applied to the linked project. A non-destructive full replay was also executed in isolated temporary schemas inside a transaction and rolled back. It produced 15 public tables, 23 RLS policies, the expected historical transit seeds, and six source metadata rows.

## Runtime tables

| Table | Purpose | Client access |
| --- | --- | --- |
| `profiles` | Auth-linked name/photo profile | owner; admin read |
| `user_preferences` | notification, location, compatible language value | owner; admin read |
| `favorite_routes` | canonical saved origin/destination/objective | owner only |
| `recent_searches` | canonical journey history, bounded to 20 | owner only |
| `notification_subscriptions` | followed canonical route IDs | owner only |
| `notification_read_state` | per-user notice read timestamp | owner only |
| `user_roles` | passenger/admin authorization | own role; admins may view roles; no client role mutation |
| `service_notices` | official or SmartRoute notice lifecycle | active published read; SmartRoute admin mutation only |
| `source_metadata` | dataset and provider health/freshness | authenticated read; admin mutation |

Historical `transit_*` and `route_template*` tables are retained for migration and contribution continuity. The final app's one runtime network is the larger generated official bundled snapshot, not the small route-template seeds.

## Notice integrity

Passenger queries can see only notices that are published, started, and unexpired. Admins can see drafts and archived records. Admin insert/update policies require `source='smartroute'` and the authenticated creator. The passenger app cannot author an official notice.

## Authorization helper

`private.is_admin()` is `STABLE SECURITY DEFINER`, uses an empty search path with fully qualified objects, and can be executed only by authenticated/service roles. Normal users cannot insert, update, or delete `user_roles`.

## RLS verification

Transaction-scoped QA proved:

- anonymous private-table reads are denied;
- passenger A cannot read or write passenger B's private records;
- owners can persist favourites, recents, subscriptions, and read state;
- a passenger cannot publish a notice;
- an admin can view account summaries and create/update/archive SmartRoute notices;
- QA rows were rolled back and no Auth users were deleted or reset.

The Supabase security advisor's remaining external setting warning is leaked-password protection, which must be enabled in the project Auth settings before production use. New-table performance warnings for missing foreign-key indexes and overlapping profile policies were reconciled in the final optimization migration.
