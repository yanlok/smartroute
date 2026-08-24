# SmartRoute

SmartRoute is an intelligent multi-modal public transit routing and navigation mobile application designed for urban commuters.

---

## Quick Start (Zero-Setup)

The project includes default client configuration for the shared development environment. No manual `.env` or local configuration file is required.

### 1. First-Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/yanlok/smartroute.git
cd smartroute

# 2. Install dependencies
flutter pub get

# 3. Run the application
flutter run
```

### 2. Running in VS Code (F5)

1. Open the project in VS Code.
2. Select your target device in the bottom-right status bar (e.g. Android Emulator, iOS Simulator, or Chrome).
3. Press **F5** (or open **Run and Debug** and choose **SmartRoute**).

*For quick browser development, select **SmartRoute (Chrome)** from the Run and Debug dropdown and press **F5**.*

---

## Environment Configuration & Optional Overrides

The application comes pre-configured with default client credentials for the shared Supabase development database:

- `SUPABASE_URL`: Pre-configured to the shared SmartRoute Supabase instance.
- `SUPABASE_PUBLISHABLE_KEY`: Pre-configured with the client publishable key.

### Optional Local Overrides

If you wish to test with custom credentials or a local Supabase instance:

1. Copy the example configuration file:
   ```bash
   cp config/env.example.json config/env.local.json
   ```
2. Update `config/env.local.json` with your custom values.
3. Run the app with:
   ```bash
   flutter run --dart-define-from-file=config/env.local.json
   ```
   Or select **SmartRoute (Custom env.local.json)** in VS Code.

> [!WARNING]
> **Credential Security:**
> Never commit a `service_role` key, secret key, database password, or access token inside the Flutter project or repository.

---

## Team Collaboration Workflow

- **Branching Baseline:** Always branch off the latest `develop` branch:
  ```bash
  git switch develop
  git pull origin develop
  git switch -c feature/<your-feature-name>
  ```
- **Protected Branches:** Do not commit directly to `main` or `develop`.
- **Security:** Never share or commit `service_role` or administrative database credentials.
