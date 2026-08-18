# SmartRoute Final Submission & Release Checklist

This checklist prepares the SmartRoute repository and team for final coursework evaluation and release readiness.

---

## 1. Coursework & Repository Governance

- [ ] **Repository Privacy:** Confirm that the GitHub repository is set to **Private** before final submission.
- [ ] **Contribution Distribution:** Verify git commit logs demonstrate clear, authentic, and active contributions across all team members (JC, Ernest, YL, CQ, YH).
- [ ] **Individual Module Understanding:** Ensure every team member is thoroughly prepared to explain their owned module's code, architecture, data flow, and design choices.
- [ ] **AI Assistance Disclosure:** Verify that AI tool usage is transparently and accurately recorded in `docs/ai-development-log.md` in accordance with coursework guidelines.
- [ ] **Code Hygiene:** Clean up temporary debug print statements, obsolete TODO comments, and scratch files.

---

## 2. Malaysian Open Data Compliance

- [ ] **Open Data Ingestion:** Verify that the app correctly incorporates and cites required Malaysian public transit open data (e.g., data.gov.my transit datasets, Prasarana GTFS feeds, static station schedules).
- [ ] **Domain Terms Accuracy:** Confirm accurate local transit nomenclature (LRT Kelana Jaya / Sri Petaling, MRT Kajang / Putrajaya, Monorail, BRT Sunway, Rapid KL buses).

---

## 3. Technical & Quality Verification

Before tagging the final release commit:

```bash
# 1. Check code formatting across all files
dart format --output=none --set-exit-if-changed .

# 2. Perform strict static analysis
flutter analyze

# 3. Execute all unit and widget tests
flutter test
```

- [ ] `dart format` returns clean.
- [ ] `flutter analyze` returns 0 issues.
- [ ] `flutter test` completes with 100% passing tests.
- [ ] Full smoke test completed on physical device or simulator.
- [ ] All 5 main navigation tabs function seamlessly without crashes.
