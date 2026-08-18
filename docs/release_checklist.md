# SmartRoute Final Submission & Release Checklist

This checklist prepares the SmartRoute repository and team for final coursework evaluation and release readiness.

---

## 1. Coursework & Repository Governance

- [ ] **Repository Privacy:** Confirm that the GitHub repository is set to **Private** before final submission.
- [ ] **Contribution Distribution:** Verify git commit logs demonstrate clear, authentic, and active contributions across all team members (JC, Ernest, YL, CQ, YH).
- [ ] **Team Size Compliance:** Confirm team size complies with coursework rules OR lecturer approval for any exception has been confirmed and documented before submission.
- [ ] **Individual Module Understanding:** Ensure every team member is thoroughly prepared to explain their owned module's code, architecture, data flow, and design choices.
- [ ] **AI Assistance Disclosure:** Verify that AI tool usage is transparently and accurately recorded in `docs/ai-development-log.md` in accordance with coursework guidelines.
- [ ] **Code Hygiene & Comment Policy:**
  - Remove all source-code comments from the submitted codebase when required by the coursework specification.
  - *Important:* Perform this comment removal **ONLY** during final submission cleanup so valuable development context is not prematurely destroyed during active development.
  - Remove temporary debug print statements and scratch files.

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
- [ ] All main navigation tabs function seamlessly without crashes.
