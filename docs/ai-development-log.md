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

### Entry 2026-08-19-04
- **Date:** 2026-08-19
- **Developer:** JC
- **Task ID:** JC-USER-04
- **AI Tool:** Gemini 3.7 Flash
- **Prompt Purpose:** User database security hardening and first reviewed Supabase migration deployment.
- **Files Changed:**
  - `lib/features/user_management/data/repositories/supabase_auth_repository.dart`
  - `test/features/user_management/data/repositories/supabase_auth_repository_test.dart`
  - `supabase/migrations/20260818162514_create_user_management.sql`
  - `docs/database.md`
  - `docs/ai-development-log.md`
- **Verification Performed:** `dart format` on user management code and test paths, `flutter analyze`, `flutter test` running all 57 tests, and `supabase link --project-ref lomjlfmikzzdmctyngjv`.
- **Human Review:** Pending JC manual walkthrough. Technical architecture/database review pending.
- **Deployment Status:** Migration SQL hardened and validated locally with full test suite passing. Remote deployment paused because Supabase CLI authentication / organization access for project `lomjlfmikzzdmctyngjv` is required.

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
