create table public.favorite_stations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  station_id text not null,
  route_id text not null,
  label text not null check (char_length(trim(label)) between 1 and 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, station_id, route_id)
);

create index favorite_stations_user_updated_idx
  on public.favorite_stations (user_id, updated_at desc);

create trigger favorite_stations_set_updated_at
before update on public.favorite_stations
for each row execute function private.set_updated_at();

alter table public.favorite_stations enable row level security;

revoke all on table public.favorite_stations from public, anon, authenticated;
grant select, insert, update, delete on table public.favorite_stations to authenticated;
grant select, insert, update, delete on table public.favorite_stations to service_role;

create policy "Users manage own favorite stations"
on public.favorite_stations for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
