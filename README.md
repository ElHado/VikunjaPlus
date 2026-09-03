# Vikunja+ 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-Cross--Platform-02569B?logo=flutter)](https://flutter.dev)

**Vikunja+** is an enhanced, privacy-focused community fork of the official [Vikunja Mobile App](https://github.com/go-vikunja/app). 

Vikunja is a feature-rich, self-hostable task management platform. **Vikunja+** builds upon the official Flutter application to deliver performance improvements, modern Android toolchain updates, battery/notification reliability fixes, flexible views (including Kanban, Table, and Analytics views), cross-project task search, and streamlined task management workflows.

---

## ✨ Key Enhancements & Features

### 📊 Task Analytics & Visual Statistics
* **Dedicated Analytics Tab:** Comprehensive dashboard providing real-time insights into open, completed, and overdue tasks.
* **Time-based Filtering:** Filter task performance and metrics across custom time ranges.
* **Visual Data Analysis:** Visual breakdown and charts for tracking productivity and workload over time.

### 🔍 Cross-Project Search
* **Global Task Search:** Search for tasks across all your projects simultaneously, with full support for filtering both active and completed tasks.

### 📋 Flexible Task Views (Kanban & Sortable Table View)
* **Interactive Table View:** View your tasks in a clean tabular format across all projects, featuring full column sorting and instant completion toggles.
* **Global View Switching:** Easily switch to the Table view project-wide directly from the main screen's top menu (`...`).
* **Instant Kanban Refresh:** Real-time column updates — tasks instantly appear or disappear from Kanban columns upon status updates.

### 🔔 Smart Notifications & Actionable Controls
* **Actionable System Notifications:** Complete tasks or snooze them directly from your system notifications.
* **Informative Snooze Buttons:** Notification buttons display the configured snooze duration (e.g., "+30m") so you always know what action is being taken.
* **Server-Synced Snooze:** Snoozing reschedules both local alerts and the remote server task.
* **Smart Duplication Prevention:** Prevents double alerts when both a reminder and a due date are set (prioritizes the exact reminder time).
* **Clean Text Body:** Strips HTML formatting from task notes to display crisp, readable notifications.

### ⚡ Modern Toolchain & High-Performance Core
* **Updated Stack:** Modernized to **Gradle 9.5.0**, **Android Gradle Plugin (AGP) 9.3.1**, and **Kotlin 2.3.20** targeting **SDK 36**.
* **Smooth Scrolling:** Refactored task list rendering to eliminate micro-stutters across large task lists.
* **Privacy-First & Lightweight:** Telemetry tracking (Sentry) and heavy embedded web views (`html_editor_enhanced` / `flutter_inappwebview`) have been completely removed for faster startup, smaller APK size, and enhanced privacy.

### 📝 Streamlined Task Creation & Input UX
* **Optimized URL & Login Fields:** Improved URL text input handling for hassle-free self-hosted server connections.
* **Quick Date & Time Presets:** Instant day presets (*Today, Tomorrow, 1 Week, Next Monday*) and time quick-picks (*08:00, 10:00, 12:00, 15:00, 18:00, 21:00*).
* **Smart UI Behavior:** Soft keyboard automatically collapses when selecting dates or times to keep input dialogs fully visible.
* **Plain Text Editor:** Replaced heavy webview editors with a lightweight text editor (includes clear formatting loss warnings when modifying rich-text server notes).

### 🏠 Home Screen Widget & System Integration
* **Bi-lingual Home Widget:** Native home screen widget with German and English localization and configurable background refresh intervals.
* **Battery & Permission Setup:** Integrated button in Settings opening Android's native `App Info` screen with quick instructions to configure unrestricted background battery execution for reliable reminders.

---

## 🛠 Tech Stack & Dependencies Update

| Component | Upstream (v0.1.8) | Vikunja+ (v0.5.0) |
| :--- | :--- | :--- |
| **Gradle** | 8.14 | **9.5.0** |
| **AGP** | 8.12.3 | **9.3.1** |
| **Kotlin** | 2.2.20 | **2.3.20** |
| **Target SDK** | Default | **36** |
| **Main Views** | List / Kanban | **List / Kanban / Sortable Table / Task Analytics** |
| **Global Features** | Basic | **Cross-Project Search & Visual Task Analytics** |
| **Telemetry / Sentry** | Enabled | **Removed** |
| **Webview / HTML Editor** | Heavy Webview | **Lightweight Plain Text** |

---

## ⚙️ Configuration & Permissions

To ensure background sync and reminders fire accurately on modern Android devices:
1. Go to **Settings** within Vikunja+.
2. Tap the **App Info** button to open your system's app settings.
3. Disable **Battery Optimization** (allow unrestricted background execution) and grant **Exact Alarm / Notification** permissions.

---

## 🤖 AI Transparency Notice

Parts of the source code optimizations, refactoring, and project assets (such as the app icon) were created with assistance from AI development tools.

---

## 📄 License & Attribution

This project is open-source under the **MIT License**. See the [LICENSE](LICENSE) file for details.

* **Original Work:** Copyright (c) 2026 The go-vikunja/app contributors ([go-vikunja/app](https://github.com/go-vikunja/app))
* **Vikunja+ Fork:** Copyright (c) 2026 **ElHado**
