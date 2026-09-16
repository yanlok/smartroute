# Admin Delete Account Specification & Design

- **Topic:** Admin Passenger Account Deletion
- **Date:** 2026-09-17
- **Target Module:** Admin Workspace & Alerts/Notices Repository
- **Owning Module / Collaborator:** Admin (YH foundation) / User Management (JC foundation)

---

## 1. Overview & Problem Statement

Administrators currently have visibility into all passenger and admin accounts via the `_AdminUserDirectory` in `AdminDashboardScreen`. However, there is no mechanism for an administrator to delete an account. 

To satisfy the requirement ("admin can delete account. must delete clear and no bug, include supabase"), the deletion must:
1. Completely remove the account from Supabase Auth (`auth.users`) so credentials and login access are invalidated.
2. Atomically cascade-delete all related data across user tables (`profiles`, `user_preferences`, `user_roles`, `favorite_routes`, `favorite_stations`, `recent_searches`, `notification_subscriptions`, `notification_read_state`, `arrival_reminders`, `tracking_sessions`).
3. Clean up user-uploaded media from Supabase storage (`avatars` bucket).
4. Guard against foreign-key violations on tables with restricted references (`service_notices.created_by`).
5. Prevent privilege escalation or self-lockout: administrators cannot delete other administrators or themselves.
6. Provide an intuitive, safe Flutter UI with clear confirmation dialogs and immediate local state updates.

---

## 2. Architecture & Data Flow

```text
Admin taps 'Delete Account' (Card button or Details bottom sheet)
                          ↓
              Confirmation Dialog (AlertDialog)
                          ↓
    NoticeController.deletePassengerAccount(userId)
                          ↓
    NoticeRepository.deletePassengerAccount(userId)
                          ↓
  SupabaseNoticeRepository -> rpc('admin_delete_passenger_account')
                          ↓
  PostgreSQL SECURITY DEFINER Function (PostgreSQL Transaction):
    1. Verify caller is_admin()
    2. Check target != auth.uid()
    3. Check target role != 'admin'
    4. Delete avatars in storage.objects for target
    5. Clean service_notices authored by target (if any)
    6. DELETE FROM auth.users WHERE id = target_user_id
         ↳ CASCADE to profiles, user_preferences, favorite_routes,
           favorite_stations, recent_searches, subscriptions, etc.
                          ↓
  Return Success (boolean)
                          ↓
  NoticeController removes user from local _users list & notifies listeners
                          ↓
  Admin UI closes dialog & bottom sheet, shows success SnackBar
```

---

## 3. Database Layer (Supabase Migration)

### Forward Migration: `supabase/migrations/20260917050000_admin_delete_passenger_account.sql`

```sql
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
  caller_id := auth.uid();
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
```

---

## 4. Contract & Repository Layer

### 4.1 Interface: `lib/shared/contracts/notice_repository.dart`
Add method:
```dart
Future<void> deletePassengerAccount(String userId);
```

### 4.2 Implementation: `lib/features/alerts/data/supabase_notice_repository.dart`
Implement method:
```dart
@override
Future<void> deletePassengerAccount(String userId) async {
  try {
    await _client.rpc('admin_delete_passenger_account', params: {
      'target_user_id': userId,
    });
  } catch (error) {
    throw NoticeRepositoryException('Failed to delete passenger account.');
  }
}
```

---

## 5. Application Layer: `NoticeController`

In `lib/features/alerts/application/notice_controller.dart`:
```dart
Future<bool> deletePassengerAccount(String userId) async {
  if (_isSaving) return false;
  _isSaving = true;
  _errorMessage = null;
  notifyListeners();
  try {
    await _repository.deletePassengerAccount(userId);
    _users = _users.where((u) => u.id != userId).toList();
    return true;
  } catch (e) {
    _errorMessage = 'Passenger account could not be deleted. Please try again.';
    return false;
  } finally {
    _isSaving = false;
    notifyListeners();
  }
}
```

---

## 6. Presentation Layer: `AdminDashboardScreen`

In `_AdminUserDirectoryState`:
1. Add `_handleDeleteUser(AdminUserSummary user)` displaying confirmation dialog:
   - Destructive alert style (`AppColors.primary`).
   - Clearly states passenger's name and that profile, saved routes, and history will be wiped.
   - Cancel and Delete Account buttons.
   - Loading indicator while saving.
2. In passenger list tile trailing:
   - If `user.role != 'admin'`, display an `IconButton(icon: Icon(Icons.delete_outline_rounded))` with tooltip "Delete Account".
3. In `_showUserDetail(AdminUserSummary user)` bottom sheet:
   - If `user.role != 'admin'`, add a prominent `FilledButton.icon` or `OutlinedButton.icon` with red color scheme to delete the account.

---

## 7. Testing Strategy

1. **Repository Unit Tests (`supabase_notice_repository_test.dart`):**
   - Calls RPC `admin_delete_passenger_account` with the target user ID.
   - Throws `NoticeRepositoryException` on error.
2. **Controller Unit Tests (`notice_controller_test.dart`):**
   - Successfully deletes passenger account and removes user from `controller.users`.
   - Handles failure by setting `errorMessage` and preserving list.
3. **Widget Tests (`admin_dashboard_screen_test.dart`):**
   - Passenger item displays delete button; Admin item does not.
   - Tapping delete opens confirmation dialog.
   - Confirming deletion invokes `deletePassengerAccount`.
