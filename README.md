# SmartRoute

SmartRoute is an intelligent multi-modal public transit routing and navigation mobile application designed for urban commuters.

---

## First-Time Setup

1. **Install Flutter & verify environment:**
   ```bash
   flutter doctor
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/yanlok/smartroute.git
   cd smartroute
   ```

3. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

4. **Create your local environment file:**
   Copy the example template:
   ```bash
   cp config/env.example.json config/env.local.json
   ```

5. **Obtain Supabase credentials:**
   Ask the project owner or team lead for **ONLY**:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`

6. **Update `config/env.local.json`:**
   Replace the placeholder values in `config/env.local.json` with the provided project URL and publishable key.

> [!WARNING]
> **Credential Security:**
> Never put a `service_role` key, secret key, database password, or access token inside the Flutter project or local client configuration.

---

## Running the App

### Method A — VS Code (Recommended)

1. Select your target Flutter device in the bottom-right status bar.
2. Open the **Run and Debug** tab (`Ctrl+Shift+D` / `Cmd+Shift+D`).
3. Choose **SmartRoute (Selected Device)** from the dropdown.
4. Press **F5** to start debugging.

*For quick browser development, choose **SmartRoute (Chrome)** and press **F5**.*

### Method B — Terminal

Run on your default or active device:
```bash
flutter run --dart-define-from-file=config/env.local.json
```

Run directly in Google Chrome:
```bash
flutter run -d chrome \
  --dart-define-from-file=config/env.local.json
```

---

## Common Issues

### `Missing required Supabase environment variables: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY`

- **Cause:** `config/env.local.json` is missing, still contains placeholder values, or the application was launched without `--dart-define-from-file` / the provided VS Code launch configuration.
- **Fix:** Create `config/env.local.json` from `config/env.example.json`, fill in the valid `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, and launch the app using one of the documented methods above.

---

## Team Collaboration Workflow

- **Branching Baseline:** Always base new feature work on the latest `develop` branch:
  ```bash
  git switch develop
  git pull origin develop
  git switch -c feature/<your-feature-name>
  ```
- **Protected Branches:** Do not commit or develop directly on `main` or `develop`.
- **Environment Isolation:** Never commit `config/env.local.json`.
- **Security:** Never share or commit `service_role` credentials.
