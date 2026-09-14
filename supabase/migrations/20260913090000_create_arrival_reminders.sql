create table public.arrival_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  station_id text not null,
  route_id text not null,
  expected_arrival timestamptz not null,
  lead_time_minutes smallint not null check (lead_time_minutes between 1 and 60),
  status text not null default 'active'
    check (status in ('active', 'triggered', 'expired', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, station_id, route_id, expected_arrival)
);

create index arrival_reminders_user_expected_idx
  on public.arrival_reminders (user_id, expected_arrival);

create trigger arrival_reminders_set_updated_at
before update on public.arrival_reminders
for each row execute function private.set_updated_at();

alter table public.arrival_reminders enable row level security;

revoke all on table public.arrival_reminders from public, anon, authenticated;
grant select, insert, update, delete on table public.arrival_reminders to authenticated;
grant select, insert, update, delete on table public.arrival_reminders to service_role;

create policy "Users manage own arrival reminders"
on public.arrival_reminders for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
