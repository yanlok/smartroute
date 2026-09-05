create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'passenger' check (role in ('passenger', 'admin')),
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null
);

create table public.favorite_routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null check (char_length(trim(label)) between 1 and 80),
  origin_stop_id text not null,
  destination_stop_id text not null,
  objective text not null default 'fastest'
    check (objective in ('fastest', 'fewer_transfers', 'least_walking')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (origin_stop_id <> destination_stop_id),
  unique (user_id, origin_stop_id, destination_stop_id, objective)
);

create table public.recent_searches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  origin_stop_id text not null,
  destination_stop_id text not null,
  searched_at timestamptz not null default now(),
  check (origin_stop_id <> destination_stop_id),
  unique (user_id, origin_stop_id, destination_stop_id)
);

create table public.notification_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  route_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, route_id)
);

create table public.service_notices (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 120),
  body text not null check (char_length(trim(body)) between 1 and 1000),
  severity text not null check (severity in ('info', 'warning', 'severe')),
  source text not null default 'smartroute'
    check (source in ('official', 'smartroute')),
  route_id text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);

create table public.notification_read_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  notice_id uuid not null references public.service_notices(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (user_id, notice_id)
);

create table public.source_metadata (
  source_id text primary key,
  display_name text not null,
  source_type text not null
    check (source_type in ('static', 'realtime', 'map', 'database')),
  status text not null check (status in ('healthy', 'stale', 'error', 'unconfigured')),
  checked_at timestamptz not null,
  data_timestamp timestamptz,
  record_count bigint check (record_count is null or record_count >= 0),
  details text not null default ''
);

create index favorite_routes_user_updated_idx
  on public.favorite_routes (user_id, updated_at desc);
create index recent_searches_user_searched_idx
  on public.recent_searches (user_id, searched_at desc);
create index notification_subscriptions_user_idx
  on public.notification_subscriptions (user_id);
create index notification_subscriptions_route_idx
  on public.notification_subscriptions (route_id);
create index service_notices_route_status_time_idx
  on public.service_notices (route_id, status, starts_at, ends_at);
create index service_notices_created_by_idx
  on public.service_notices (created_by);
create index notification_read_state_notice_idx
  on public.notification_read_state (notice_id);
create index user_roles_granted_by_idx
  on public.user_roles (granted_by);

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = (select auth.uid())
      and role = 'admin'
  );
$$;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.trim_recent_searches()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.recent_searches
  where id in (
    select id
    from public.recent_searches
    where user_id = new.user_id
    order by searched_at desc, id desc
    offset 20
  );
  return new;
end;
$$;

create trigger favorite_routes_set_updated_at
before update on public.favorite_routes
for each row execute function private.set_updated_at();

create trigger service_notices_set_updated_at
before update on public.service_notices
for each row execute function private.set_updated_at();

create trigger recent_searches_trim_history
after insert or update on public.recent_searches
for each row execute function private.trim_recent_searches();

revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated, service_role;
revoke all on function private.set_updated_at() from public, anon, authenticated;
grant execute on function private.set_updated_at() to service_role;
revoke all on function private.trim_recent_searches() from public, anon, authenticated;
grant execute on function private.trim_recent_searches() to service_role;

alter table public.user_roles enable row level security;
alter table public.favorite_routes enable row level security;
alter table public.recent_searches enable row level security;
alter table public.notification_subscriptions enable row level security;
alter table public.service_notices enable row level security;
alter table public.notification_read_state enable row level security;
alter table public.source_metadata enable row level security;

revoke all on table public.user_roles, public.favorite_routes,
  public.recent_searches, public.notification_subscriptions,
  public.service_notices, public.notification_read_state,
  public.source_metadata from public, anon, authenticated;

grant select on table public.user_roles to authenticated;
grant select, insert, update, delete on table public.favorite_routes,
  public.recent_searches, public.notification_subscriptions,
  public.notification_read_state to authenticated;
grant select, insert, update, delete on table public.service_notices to authenticated;
grant select, insert, update, delete on table public.source_metadata to authenticated;
grant select, insert, update, delete on table public.user_roles,
  public.favorite_routes, public.recent_searches,
  public.notification_subscriptions, public.service_notices,
  public.notification_read_state, public.source_metadata to service_role;

create policy "Users can view own role"
on public.user_roles for select to authenticated
using ((select auth.uid()) = user_id or (select private.is_admin()));

create policy "Users manage own favorite routes"
on public.favorite_routes for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users manage own recent searches"
on public.recent_searches for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users manage own notification subscriptions"
on public.notification_subscriptions for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users view active notices and admins view all"
on public.service_notices for select to authenticated
using (
  (select private.is_admin())
  or (
    status = 'published'
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  )
);

create policy "Admins create SmartRoute notices"
on public.service_notices for insert to authenticated
with check (
  (select private.is_admin())
  and source = 'smartroute'
  and created_by = (select auth.uid())
);

create policy "Admins update SmartRoute notices"
on public.service_notices for update to authenticated
using ((select private.is_admin()) and source = 'smartroute')
with check (
  (select private.is_admin())
  and source = 'smartroute'
  and created_by = (select auth.uid())
);

create policy "Admins delete SmartRoute notices"
on public.service_notices for delete to authenticated
using ((select private.is_admin()) and source = 'smartroute');

create policy "Users manage own notice read state"
on public.notification_read_state for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Authenticated users view source health"
on public.source_metadata for select to authenticated
using (true);

create policy "Admins create source health"
on public.source_metadata for insert to authenticated
with check ((select private.is_admin()));

create policy "Admins update source health"
on public.source_metadata for update to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "Admins delete source health"
on public.source_metadata for delete to authenticated
using ((select private.is_admin()));

create policy "Admins can view profiles"
on public.profiles for select to authenticated
using ((select private.is_admin()));

create policy "Admins can view preferences"
on public.user_preferences for select to authenticated
using ((select private.is_admin()));

insert into public.source_metadata (
  source_id, display_name, source_type, status, checked_at,
  data_timestamp, record_count, details
)
values
  ('gtfs-static-rail', 'Rapid KL rail GTFS', 'static', 'healthy',
    '2026-08-31T12:21:11Z', '2026-08-31T12:21:11Z', 8,
    'Official bundled schedule snapshot from data.gov.my.'),
  ('gtfs-static-bus-kl', 'Rapid KL bus GTFS', 'static', 'healthy',
    '2026-08-31T12:21:11Z', '2026-08-31T12:21:11Z', 137,
    'Official bundled schedule snapshot from data.gov.my.'),
  ('gtfs-static-mrtfeeder', 'MRT feeder bus GTFS', 'static', 'healthy',
    '2026-08-31T12:21:11Z', '2026-08-31T12:21:11Z', 92,
    'Official bundled schedule snapshot from data.gov.my.'),
  ('gtfs-rt-bus-kl', 'Rapid KL bus vehicle positions', 'realtime', 'healthy',
    '2026-08-31T12:21:11Z', '2026-08-31T12:21:11Z', null,
    'Official GTFS-Realtime vehicle-position feed.'),
  ('gtfs-rt-mrtfeeder', 'MRT feeder vehicle positions', 'realtime', 'healthy',
    '2026-08-31T12:21:11Z', '2026-08-31T12:21:11Z', null,
    'Official GTFS-Realtime vehicle-position feed.'),
  ('google-maps-android', 'Google Maps for Android', 'map', 'unconfigured',
    '2026-08-31T12:21:11Z', null, null,
    'A restricted local Android API key is required for live map tiles.');
