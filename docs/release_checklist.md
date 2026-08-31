# Final release checklist

## Completed engineering gates

- [x] Integration branch created from the latest fetched `origin/develop`.
- [x] User local work preserved in a named stash including untracked files.
- [x] Ernest, YL, and YH unique commits merged without squashing; CQ and JC ancestry retained.
- [x] Official static GTFS normalized into one runtime network.
- [x] Dijkstra route computation replaces production route templates.
- [x] Google Maps Flutter presentation and ignored Android key flow implemented.
- [x] Official bus vehicle-position provider implemented with timestamp/identity truth checks.
- [x] Rail scheduled progress and automatic bus scheduled fallback implemented.
- [x] Supabase favourites, recents, subscriptions, read state, roles, notices, and metadata implemented with RLS.
- [x] Five-tab passenger navigation and real-data Home aggregation implemented.
- [x] Hardcoded admin login and unsupported passenger actions removed.
- [x] Shared Supabase migration drift reconciled without destructive Auth changes.
- [x] Fresh migration replay and multi-role RLS QA completed transactionally.
- [x] Source, dead-end, mock, and realtime-label searches completed.
- [x] README, architecture, product story, data contracts, database, design, testing, and Android QA documentation updated.

## Repeat before handoff

- [x] Remove ordinary first-party source comments only after implementation is frozen.
- [x] Run `git diff --check`.
- [x] Run format, analyze, and all tests.
- [x] Repeat isolated migration replay.
- [x] Run official-source validation and record whether fresh vehicles exist at that time.
- [x] Build debug and release APKs.
- [x] Record debug APK path, bytes, SHA256, and timestamp.
- [ ] Commit coherent checkpoints and push only `feature/final-product-integration`.

## External/manual submission actions

- [ ] Enable Maps SDK for Android in the selected Google Cloud project.
- [ ] Put the restricted key in ignored `android/local.properties` as `MAPS_API_KEY=...`.
- [ ] Restrict the key to Android app `com.smartroute.app` and the actual signing certificate SHA fingerprint.
- [ ] Complete every item in `FINAL_ANDROID_QA.md` on a real Android phone.
- [ ] Confirm a fresh official bus position before marking the bus LIVE closed loop passed.
- [ ] Enable Supabase leaked-password protection.
- [ ] Set `yanlok/smartroute` to PRIVATE and confirm lecturer/team access.
- [ ] Obtain team approval before merging the feature branch.
