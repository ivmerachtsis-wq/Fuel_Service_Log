# AI Continuous Dev Cycle

**Ροή:**
- Πρωί → AI + Copilot αναπτύσσουν νέα modules στο branch `ai-dev`.
- Απόγευμα → Ο Ηλίας κάνει QA, δοκιμές σε Android/Windows.
- Βράδυ → Feedback σε ChatGPT για επόμενο κύκλο.

**Κανόνες:**
- Analyzer = 0 warnings.
- 1 feature ανά PR.
- Commit naming:
  - [AI] feat(pdf): add tables
  - [AI] fix(stats): null check
  - [USER] review: approved build #X
- Nightly check: `tools\ai_build_check.bat`

**Branch Naming Προτάσεις:**
- feature/pdf-polish
- feature/graphs-kpis
- feature/settings-integrity
- feature/cloud-sync
- feature/pro-tier

**Release Flow:**
1. Αναπτύσσουμε στο `ai-dev`.
2. Δημιουργία μικρών PRs προς `windows-base`.
3. QA & merge όταν Analyzer = 0 και tests PASS.
4. Tag έκδοσης (semver) με changelog bullets.

**Nightly Script:**
Τρέξε: `tools\ai_build_check.bat` και αποθήκευσε τα logs στο `logs/` με όνομα `analyzer_<YYYY-MM-DD>.log`.

**Changelog Bullets Παράδειγμα:**
- feat(pdf): Active Vehicle Report (EL/EN)
- perf(cache): snapshot preload, debounce writes
- fix(ui): null guard in stats chart

**Next Milestones (M10+):**
- Advanced PDF Styling (grouping, footer summary)
- Cloud sync (encrypted snapshot upload)
- Pro tier feature flags
