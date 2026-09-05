
revoke all on table public.profiles from service_role;
grant select, insert, update, delete on table public.profiles to service_role;

revoke all on table public.user_preferences from service_role;
grant select, insert, update, delete on table public.user_preferences to service_role;
