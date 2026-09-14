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
7. `20260913090000_create_arrival_reminders.sql` (forward migration; apply through the normal Supabase migration workflow)

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
| `arrival_reminders` | station/route schedule reminders and lifecycle state | owner only |
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

<<<<<<< HEAD
    RECENT_SEARCHES {
        uuid id PK
        uuid user_id FK "references auth.users.id"
        string origin
        string destination
        timestamptz searched_at
    }
```

---

## 3. Schema Specifications (JC User Management)

### 3.1 `public.profiles`
Stores user profile information linked directly to Supabase Auth. Created automatically via `private.handle_new_user()` upon auth user registration.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Matches Supabase Auth user ID |
| `full_name` | `TEXT` | `NOT NULL` | User's display name (extracted from metadata or email local-part) |
| `photo_url` | `TEXT` | `NULL` | Optional URL to user's profile image / avatar |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Account creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

**Privileges & Grants:**
- `authenticated`: `SELECT`, `UPDATE`
- `service_role`: `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- `anon` / `PUBLIC`: None (revoked)

**RLS Policies:**
- `SELECT`: `(select auth.uid()) = id`
- `UPDATE`: `(select auth.uid()) = id` with check `(select auth.uid()) = id`

---

### 3.2 `public.user_preferences`
Stores persistent user application settings and travel preferences. Created automatically via `private.handle_new_user()` upon auth user registration.

> **Note on `location_enabled`:** This column stores the user's **application-level preference** indicating whether they want location-based SmartRoute features. It is NOT the authoritative Android/iOS operating system permission state; OS permission must still be requested and checked via the platform when location services are invoked.

#### Fields:
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `user_id` | `UUID` | `PRIMARY KEY`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Associated user ID |
| `notifications_enabled` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | In-app notification preference |
| `location_enabled` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | In-app location feature preference |
| `language` | `TEXT` | `NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'ms'))` | Machine-readable language code |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last modification timestamp |

#### Language Mapping Reference:
- `'en'` -> English (Malaysia)
- `'ms'` -> Bahasa Melayu

**Privileges & Grants:**
- `authenticated`: `SELECT`, `UPDATE`
- `service_role`: `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- `anon` / `PUBLIC`: None (revoked)

**RLS Policies:**
- `SELECT`: `(select auth.uid()) = user_id`
- `UPDATE`: `(select auth.uid()) = user_id` with check `(select auth.uid()) = user_id`

---

### 3.3 Database Trigger: `on_auth_user_created`
- **Schema & Name:** `private.handle_new_user()`
- **Event:** `AFTER INSERT ON auth.users FOR EACH ROW`
- **Behavior:**
  - Extracts `full_name` from metadata with email local-part and `'SmartRoute User'` fallbacks.
  - Normalizes `photo_url` metadata (null if empty or whitespace).
  - Inserts row into `public.profiles`.
  - Inserts default preferences row into `public.user_preferences`.
  - Function execution revoked from client roles (`PUBLIC`, `anon`, `authenticated`).

---

## 4. Static Transit Network & Route Data (YL)

The route planner uses public, read-only reference data seeded by
`20260828090000_create_transit_network_and_route_data.sql`:

- `public.transit_lines`: Klang Valley LRT, MRT, Monorail, KTM, BRT, and bus lines with their mode and display color.
- `public.transit_stations`: station names and coordinates used by the planner and map.
- `public.station_lines`: ordered station membership for each line and interchange markers.
- `public.transit_links`: adjacent station travel estimates and stop counts for route calculation.
- `public.route_templates`: tested origin/destination options with estimated duration, fare, and transfers.
- `public.route_template_segments`: ordered walk and transit legs for step-by-step route details.

These are static planning estimates based on the published Klang Valley network. They are not a real-time arrival or service-status source. The six tables enable `SELECT` for `anon` and `authenticated` and are writable only by `service_role`; RLS is enabled on every table.

## 5. Planned Future Tables (JC Data Ownership)

### 4.1 `public.favorite_routes` (Planned)
Stores saved transit journeys for quick one-tap access.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique favorite route ID |
| `user_id` | `UUID` | `NOT NULL`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Route owner |
| `label` | `TEXT` | `NOT NULL` | User-defined label (e.g. "Home to Work") |
| `origin` | `TEXT` | `NOT NULL` | Origin station / stop identifier |
| `destination` | `TEXT` | `NOT NULL` | Destination station / stop identifier |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

---

### 4.2 `public.recent_searches` (Planned)
Stores historical journey searches for convenient autofill on Home and Planner screens.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique search log ID |
| `user_id` | `UUID` | `NOT NULL`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Searching user ID |
| `origin` | `TEXT` | `NOT NULL` | Origin station / stop searched |
| `destination` | `TEXT` | `NOT NULL` | Destination station / stop searched |
| `searched_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Search execution timestamp |

---

## 6. Integration Guidelines for Client Code

1. **Repository Encapsulation:**
   - Flutter controllers and UI widgets must **never** execute raw Supabase queries directly.
   - All queries must be encapsulated inside `data/` and accessed via domain repository interfaces.

2. **DTO & Domain Model Separation:**
   - Data layer classes must map raw JSON maps into strongly typed immutable domain entities before exposing them to the application layer.

3. **Offline & Error Resilience:**
   - Handle database disconnections, network timeouts, and RLS permission failures gracefully with domain-level error objects.
=======
The Supabase security advisor's remaining external setting warning is leaked-password protection, which must be enabled in the project Auth settings before production use. New-table performance warnings for missing foreign-key indexes and overlapping profile policies were reconciled in the final optimization migration.
>>>>>>> origin/develop
