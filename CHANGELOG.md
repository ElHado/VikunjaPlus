# Changelog

All notable changes to the **Vikunja+** project will be documented in this file.

---

## [0.4.5] - 2026-08-24

### Added
* **Global Table View Switch:** Added project-wide Table view toggle in the main screen overflow menu (`...`).
* **Table Sorting:** Table view columns are now fully sortable.
* **Informative Snooze Action:** Push notification snooze button now explicitly displays the configured snooze duration (e.g., "+30m") for better visibility.

---

## [0.4.0] - 2026-08-24

### Added
* **Table View:** Introduced a dedicated Tabular view for tasks.

### Fixed
* **Table View Checkboxes:** Resolved an issue where checkboxes were displaying incorrect states in Table view.

---

## [0.3.2] - 2026-08-20

### Fixed
* **Scrolling Performance:** Optimized list scrolling behavior across large task lists to eliminate stutter.
* **Notification Labels:** Renamed misleading "Remind" action label to "Snooze" / "Reschedule".

### Changed
* **App Package ID:** Renamed package identifier from `io.vikunja.app` to `vikunjaplus.app`.
* **Login URL Input:** Optimized URL text fields for smoother self-hosted server setup.

### Added
* **Android Settings Integration:** Added a button in App Settings that opens Android's system `AppInfo` screen with instructions for setting up reliable notification permissions and battery exclusions.

---

## [0.3.1] - 2026-08-20

### Added
* **Task Time Preset:** Added `10:00 AM` preset option and shifted `09:00 AM` to `08:00 AM` in the quick task creation dialog for better daily coverage.
* **Interactive Snooze Action:** Added a functional "Snooze" button directly in system push notifications.
  * Configurable snooze duration settings.
  * Synchronizes rescheduled time back to the Vikunja server task.

### Changed
* **Custom User-Agent:** Updated app User-Agent header to `Vikunja+ Mobile App` for cleaner server logging and identification.

### Fixed
* **List Rendering:** Further optimizations for smoother task list scrolling and widget rebuilds.

---

## [0.3.0] - 2026-08-19

### Changed
* **HTML Editor Replacement:** Replaced `html_editor_enhanced` and removed `flutter_inappwebview_android` dependency (unblocking modern Gradle/AGP updates).
* **Plain Text Fields:** Task descriptions and comments now use clean plain-text fields with visual warnings (orange) when saving rich-text server tasks. Existing HTML descriptions from server remain readable.

### Fixed
* **Keyboard UX:** Automatically collapses soft keyboard when selecting dates or times in task creation to keep dialogs visible.
* **Duplicate Notifications:** Resolved duplicate notification alerts when both a reminder and a due date are set (reminder takes priority).

### Toolchain Upgrades
* **Gradle:** Upgraded 8.14 ➔ 9.1.0 ➔ **9.5.0**
* **AGP:** Upgraded 8.12.3 ➔ 9.0.1 ➔ **9.3.1**
* **Kotlin:** Upgraded to **2.3.20**

---

## [0.2.4] - 2026-08-18

### Added
* **Widget Localization:** Added German and English translation support for the Home Screen Widget.
* **Widget Refresh:** Widget automatically updates on app launch and according to background interval settings.
* **Preset Time Slots:** Time picker preset options added to quick task creation.
* **Server URL Display:** Server URL now visibly displayed under settings.

### Changed
* **Task Dialog Overhaul:** Redesigned date/time selection UI. Custom date picker now directly inherits template selections.
* **Kanban Board:** Added automatic board refresh upon completing or modifying tasks.

---

## [0.2.3] - 2026-08-18

### Added
* **Branding:** Rebranded app as **Vikunja+** with a new app logo.
* **License & Attribution:** Added MIT License and fork attribution back to upstream repository.

### Housekeeping
* Cleaned up unused constants and legacy configurations.

---

## [0.2.2] - 2026-08-17

### Removed
* **Sentry Telemetry:** Removed all Sentry tracking, DSN initializations, error scope captures, and dialogs. Replaced exceptions with `developer.log()`.
* **Upstream Update Checker:** Removed GitHub API calls to `go-vikunja/app` (updates handled via F-Droid / Play Store).

### Fixed
* Fixed `AppLocalizations` initialization context issues in `initState()`.
* Re-enabled visible app version display in settings.

---

## [0.2.1] - 2026-08-16

### Added
* **Enhanced Push Notifications:** Formatted push notifications with task title, plain text notes, and an inline "Mark as Done" action button.
* **Background Refresh Slider:** Replaced raw text input with an intuitive background refresh slider (15 min – 6 hrs, default: 30 mins).
* **Chronological Task Sorting:** Added per-project task sorting options (manual vs. chronological).

---

## [0.2.0] - 2026-08-16

### Added
* German translation (DE) localization support.
* Initial branding updates and UI text truncation fixes.

---

## [0.1.9] - 2026-08-14

### Fixed
* Fixed notification persistence across app restarts.
* Resolved unhandled network HTTP exceptions.
* Fixed list reordering bug (`onReorder` ➔ `onReorderItem`).
* Resolved all `dart analyze` compiler warnings/errors.

---

## [0.1.8]

* Initial upstream release baseline from `go-vikunja/app`.