# AI Development Log

This document records the transparent disclosure of AI assistance used throughout the development of SmartRoute, ensuring academic integrity and adherence to coursework guidelines.

---

## Log Entry Template

Team members must log significant AI interactions using the template below:

```markdown
### Entry [YYYY-MM-DD-01]
- **Date:** YYYY-MM-DD
- **Developer:** [JC / Ernest / YL / CQ / YH]
- **Task ID:** [e.g. TASK-JC-01]
- **AI Tool:** [e.g. Antigravity CLI / Claude / Gemini / GitHub Copilot]
- **Prompt Purpose:** [Brief summary of the prompt, task, or request given to the AI]
- **Files Changed:**
  - `path/to/file1.dart`
  - `path/to/file2.dart`
- **Verification Performed:** [e.g. dart format, flutter analyze, flutter test, manual UI validation]
- **Human Review:** [Brief summary of code inspection, changes made by the developer, and verification outcome]
```

---

## Development Log Entries

### Entry 2026-08-19-06
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-05
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** Integration of real Supabase email/password authentication with the existing SmartRoute Login/Register UI and AppShell session gate.
- **Files Changed:**
  - `lib/main.dart`
  - `lib/features/login/screens/login_screen.dart`
  - `lib/features/user_management/application/auth_controller.dart`
  - `test/widget_test.dart`
  - `test/features/login/screens/login_screen_test.dart`
  - `test/features/user_management/application/auth_controller_test.dart`
  - `docs/ai-development-log.md`
- **Verification Performed:** `dart format` on all target application and test paths, full `flutter analyze` (0 errors/warnings on task files), and `flutter test` running all 70 unit, widget, and configuration tests.
- **Human Review:** Pending JC manual walkthrough. Technical architecture/code review pending.

---

### Entry 2026-08-19-05
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-04C
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** Normalize and tighten service_role table privileges to CRUD operations only.
- **Files Changed:**
  - `supabase/migrations/20260819052050_tighten_user_management_service_role_grants.sql`
  - `docs/ai-development-log.md`
- **Verification Performed:** `supabase db push --dry-run` (confirmed only new migration pending), `supabase db push` (deployed successfully), `supabase migration list` (both migrations applied locally and remotely), post-deploy dry-run (confirmed database up to date), and `supabase db lint --linked` (0 schema errors).
- **Human Review:** Pending JC manual walkthrough. Technical architecture/database review performed with ChatGPT as review assistant.
- **Deployment Status:** Successfully deployed migration `20260819052050_tighten_user_management_service_role_grants.sql` to remote project `lomjlfmikzzdmctyngjv`. Revoked excess privileges (`TRUNCATE`, `REFERENCES`, `TRIGGER`, `MAINTAIN`) from `service_role`, restricting it strictly to `SELECT`, `INSERT`, `UPDATE`, `DELETE` on `public.profiles` and `public.user_preferences`.

---

### Entry 2026-08-19-04
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-04 / JC-USER-04B
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** User database security hardening, Supabase CLI account authorization, and first reviewed migration deployment.
- **Files Changed:**
  - `lib/features/user_management/data/repositories/supabase_auth_repository.dart`
  - `test/features/user_management/data/repositories/supabase_auth_repository_test.dart`
  - `supabase/migrations/20260818162514_create_user_management.sql`
  - `docs/database.md`
  - `docs/ai-development-log.md`
- **Verification Performed:** `dart format` on user management code and test paths, `flutter analyze`, `flutter test` (all 57 tests passing), `supabase link --project-ref lomjlfmikzzdmctyngjv`, `supabase db push --dry-run` (1 pending migration confirmed), `supabase db push` (deployment successful), `supabase migration list` (verified applied locally and remotely), post-deploy dry-run (confirmed remote database up to date), and `supabase db lint --linked` (0 schema errors across `extensions`, `private`, `public`).
- **Human Review:** Pending JC manual walkthrough. Technical architecture/database review pending.
- **Deployment Status:** Successfully deployed migration `20260818162514_create_user_management.sql` to remote project `lomjlfmikzzdmctyngjv` (`smartroute`). Tables `public.profiles` and `public.user_preferences` with RLS, explicit table grants, and `private.handle_new_user()` trigger are active and verified.

---

### Entry 2026-08-19-03
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-03
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** Implementation and isolated testing of the Supabase-backed authentication repository.
- **Files Changed:**
  - `pubspec.yaml`
  - `pubspec.lock`
  - `lib/features/user_management/domain/exceptions/auth_repository_exception.dart`
  - `lib/features/user_management/data/repositories/supabase_auth_repository.dart`
  - `lib/features/user_management/application/auth_controller.dart`
  - `test/features/user_management/data/repositories/supabase_auth_repository_test.dart`
  - `test/features/user_management/application/auth_controller_test.dart`
  - `docs/ai-development-log.md`
- **Verification Performed:** `dart format` on user management code and test paths, `flutter analyze` on project, and `flutter test` running all repository, controller, and model test suites.
- **Human Review:** Pending JC manual walkthrough. Technical architecture/code review pending.

---

### Entry 2026-08-19-02
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-02
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** Supabase SDK bootstrap, environment configuration, and registration contract correction.
- **Files Changed:**
  - `pubspec.yaml`
  - `pubspec.lock`
  - `lib/main.dart`
  - `lib/core/config/app_config.dart`
  - `lib/features/user_management/application/auth_controller.dart`
  - `lib/features/user_management/domain/models/registration_result.dart`
  - `lib/features/user_management/domain/repositories/auth_repository.dart`
  - `test/core/config/app_config_test.dart`
  - `test/features/user_management/application/auth_controller_test.dart`
  - `test/features/user_management/domain/models/user_models_test.dart`
  - `docs/modules.md`
  - `docs/ai-development-log.md`
- **Verification Performed:** `dart format` across targeted files, full `flutter analyze`, and `flutter test` executing all unit/model/config suites.
- **Human Review:** Pending JC manual walkthrough. Technical architecture/code review performed with ChatGPT as review assistant.

---

### Entry 2026-08-19-01
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-01
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** Architecture V2 normalization of existing user management foundation.
- **Files Changed:**
  - `.github/workflows/supabase-deploy.yml`
  - `lib/features/user_management/application/auth_controller.dart`
  - `lib/features/user_management/domain/models/app_user.dart`
  - `lib/features/user_management/domain/models/user_preferences.dart`
  - `lib/features/user_management/domain/repositories/auth_repository.dart`
  - `supabase/migrations/20260818162514_create_user_management.sql`
  - `test/features/user_management/application/auth_controller_test.dart`
  - `test/features/user_management/domain/models/user_models_test.dart`
- **Verification Performed:** `dart format`, `flutter analyze` on user management layer, and `flutter test` running all 23 unit tests.
- **Human Review:** Pending JC manual walkthrough. Technical architecture/code review performed with ChatGPT as review assistant.
