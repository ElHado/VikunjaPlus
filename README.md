# Vikunja+ — Fork of the Vikunja Cross-Platform App

**Vikunja+** is a personal fork of the official [Vikunja App](https://github.com/go-vikunja/app) (MIT License).

Vikunja is a fluffy, open-source, self-hostable to-do app. This fork contains
customizations and enhancements for personal use.

## Changes from Original (v0.1.8 → v0.3.1)

### Build & Tooling
- Gradle: 8.14 → **9.5.0**
- AGP: 8.12.3 → **9.3.1**
- Kotlin: 2.2.20 → **2.3.20**
- compileSdk: flutter-default → **36**
- `android.newDsl=false` for AGP 9 compatibility
- `kotlin.incremental=false` to prevent cache conflicts on Windows

### Removed Dependencies
- **Sentry** (DSN belonged to upstream developers)
- **Version check** (GitHub API call to go-vikunja/app)
- **`html_editor_enhanced`** + entire `flutter_inappwebview` family (replaced by plain text editor)
- **`cronet_http`** (replaced by `IOClient()` fallback)
- 29 transitive dependencies cleaned up

### Branding
- App name: **Vikunja → Vikunja+**
- Custom app icon + notification icon
- User-Agent: `"Vikunja+ Mobile App"`
- README + AI transparency notice
- LICENSE: Original copyright (go-vikunja/app) + **ElHado**

### Notifications
- HTML tags stripped from task descriptions
- Task title as notification title, description as body text
- **Snooze button** ("Remind") — configurable duration (15 min – 24h)
- **No duplicate notifications** (reminder overrides due date notification)
- Widget localized to German (English via system locale)
- Widget updates on app start

### Task Dialog
- **Day presets:** None, Today, Tomorrow, 1 Week, Next Monday
- **Time presets:** 08:00, 10:00, 12:00, 15:00, 18:00, 21:00
- **"Custom"** opens date+time picker directly (with preselection)
- **Keyboard hides** on selection
- HTML editor replaced by **plain text** with format warning

### Kanban Board
- Tasks appear **immediately** after adding
- Tasks disappear **immediately** after completing

### Background Refresh
- Slider instead of text field (15 min – 6 h)
- Default: **30 minutes** (was 0=off)

### Settings
- **Server URL** displayed above version
- **Version number** (`v0.3.1`)
- **Fork link** clickable → GitHub
- **MIT License** notice
- **Snooze duration** slider (15 min – 6 h + 24h/Tomorrow)

### Scrolling
- All lists use standard Flutter ListView with efficient rendering
- No excessive rebuilds — Riverpod state management ensures minimal widget updates

### Misc
- Task sorting per project (manual / chronological)
- `custom_lint.log` added to `.gitignore`
- `dueOptionThisWeekend` and `dueOptionLaterThisWeek` removed (simplified day selection)
- ARB locales (DE/EN) kept 100% in sync
- Unused constants cleaned up (`repo`, `vStandardVerticalPadding`)
- `disableRefresh`/`motionPhoto` properties removed from entities

## AI Transparency Notice

Parts of the source code and the app icon were created with
assistance from AI tools.

## License

MIT License — see [LICENSE](LICENSE).

Original copyright: (c) 2026 The go-vikunja/app contributors
Fork copyright: (c) 2026 ElHado