create table public.tracking_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  route_id text not null,
  route_name text not null,
  mode text not null,
  origin_stop_id text not null,
  origin_stop_name text not null,
  destination_stop_id text,
  destination_stop_name text,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'cancelled')),
  current_station_name text,
  stops_completed smallint not null default 0 check (stops_completed >= 0),
  total_stops smallint not null default 0 check (total_stops >= 0),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_minutes smallint,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index tracking_sessions_user_started_idx
  on public.tracking_sessions (user_id, started_at desc);

create index tracking_sessions_route_id_idx
  on public.tracking_sessions (route_id);

create trigger tracking_sessions_set_updated_at
before update on public.tracking_sessions
for each row execute function private.set_updated_at();

alter table public.tracking_sessions enable row level security;

revoke all on table public.tracking_sessions from public, anon, authenticated;
grant select, insert, update, delete on table public.tracking_sessions to authenticated;
grant select, insert, update, delete on table public.tracking_sessions to service_role;

create policy "Users manage own tracking sessions"
on public.tracking_sessions for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
