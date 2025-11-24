# v1.4.1 – Active vehicle reactive UI

## Summary

This PR finalizes the v1.4.1 hotfix release, making the active vehicle truly reactive across the Fuel and Service tabs, and stabilizing the corresponding tests. It also bumps the app version and prepares the repo for tagging and release.

## Changes

### 1. Active vehicle reactivity

- `FuelTab` and `ServiceTab` now listen to `ActiveVehicleController.activeVehicleIdNotifier`.
- When the active vehicle changes (from the Vehicles tab or Settings), the Fuel and Service lists refresh automatically.
- Fuel/Service forms already default to the active vehicle; this PR aligns the surrounding UI with that behavior so the whole experience is consistent.

### 2. Single source of truth for active vehicle

- The active vehicle is now driven from a single place:
  - Stored in `UiPrefs`.
  - Exposed via `ActiveVehicleController.activeVehicleIdNotifier` as the reactive layer.
- Removed the old Vehicles section from Settings (vehicle management is now fully on the Vehicles tab).
- Avoids duplicated logic and reduces the risk of UI getting “out of sync” with stored prefs.

### 3. Test stabilization

- Fixed the failing tests in `settings_save_toggle_test.dart` by ensuring Hive boxes are initialized correctly.
- Full test suite status at the time of this PR:
  - **162 passing**
  - **13 skipped**
- No flaky tests observed related to the active vehicle logic.

### 4. Version bump

- Updated `pubspec.yaml` to:
  - `version: 1.4.1+20251116`
- Added a new section in `CHANGELOG.md` for **v1.4.1** describing:
  - Active vehicle reactivity improvements.
  - Test stabilization work.
  - No schema or migration changes required.

## Motivation & context

Previously, changing the active vehicle did not always propagate cleanly to the Fuel/Service tabs.  
This could leave the UI showing entries for a different vehicle than the one currently selected as “active”.

This hotfix:

- Ensures that the active vehicle is the single source of truth.
- Keeps the tabs and forms consistent with the selected vehicle.
- Avoids confusing states where the UI appears “stuck” on a previous vehicle.

## Technical notes

- No changes to Hive schemas or stored data formats.
- No breaking changes to public APIs or services.
- The main focus is wiring the UI to listen to the proper reactive notifier and cleaning up old, duplicated paths.

## Testing

- `flutter analyze` – clean except for 2 known, info-level deprecations (expected).
- `flutter test` – all suites:
  - 162 tests passing
  - 13 tests skipped (intentionally)
- Manual sanity checks:
  - Switch active vehicle and verify:
    - Fuel tab entries refresh for the new vehicle.
    - Service tab entries refresh for the new vehicle.
    - Fuel/Service forms default to the correct active vehicle.
  - Verify that Settings no longer exposes the old Vehicles section.

## Risks & rollback

**Risks**

- Any place that assumed a non-reactive active vehicle might be impacted if it was relying on old behavior.
- Potential subtle UI bugs if other widgets were manually caching the active vehicle id instead of listening to the notifier.

**Rollback**

- Safe rollback path: revert this PR and the version/changelog bumps (v1.4.1) to return to the previous stable state.
- No data migrations involved, so reverting is low-risk.

## Checklist

- [x] Code compiles and runs locally.
- [x] `flutter analyze` passes (only expected info-level deprecations).
- [x] `flutter test` passes (162 passing / 13 skipped).
- [x] Changelog updated for v1.4.1.
- [x] Version bumped to 1.4.1+20251116.
- [ ] CI green on this PR.
- [ ] Tag `v1.4.1` created after merge.
