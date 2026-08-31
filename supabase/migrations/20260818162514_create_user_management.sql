create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  notifications_enabled boolean not null default true,
  location_enabled boolean not null default true,
  language text not null default 'en' check (language in ('en', 'ms')),
  updated_at timestamptz not null default now()
);


revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.user_preferences from public, anon, authenticated;

grant select, update on table public.profiles to authenticated;
grant select, update on table public.user_preferences to authenticated;

grant select, insert, update, delete on table public.profiles to service_role;
grant select, insert, update, delete on table public.user_preferences to service_role;


alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;

create policy "Users can view own profile"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users can view own preferences"
  on public.user_preferences
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can update own preferences"
  on public.user_preferences
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);


create schema if not exists private;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, photo_url)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(split_part(new.email, '@', 1)), ''),
      'SmartRoute User'
    ),
    nullif(trim(new.raw_user_meta_data ->> 'photo_url'), '')
  );

  insert into public.user_preferences (user_id)
  values (new.id);

  return new;
end;
$$;


revoke execute on function private.handle_new_user() from public, anon, authenticated;


create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();
