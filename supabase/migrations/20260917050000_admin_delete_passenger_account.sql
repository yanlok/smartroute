create or replace function public.admin_delete_passenger_account(target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid;
  target_role text;
begin
  caller_id := (select auth.uid());
  if caller_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_admin() then
    raise exception 'Access denied. Administrator privileges required.';
  end if;

  if target_user_id = caller_id then
    raise exception 'Administrators cannot delete their own account from the user directory.';
  end if;

  select role into target_role
  from public.user_roles
  where user_id = target_user_id;

  if target_role = 'admin' then
    raise exception 'Administrator accounts cannot be deleted.';
  end if;

  -- 1. Remove avatar files from storage if present
  delete from storage.objects
  where bucket_id = 'avatars'
    and (storage.foldername(name))[1] = target_user_id::text;

  -- 2. Clean any service notices authored by the user to avoid FK restrict constraint
  delete from public.service_notices
  where created_by = target_user_id;

  -- 3. Delete from auth.users (cascades automatically to all dependent public tables)
  delete from auth.users
  where id = target_user_id;

  return true;
end;
$$;

revoke all on function public.admin_delete_passenger_account(uuid) from public, anon;
grant execute on function public.admin_delete_passenger_account(uuid) to authenticated, service_role;
