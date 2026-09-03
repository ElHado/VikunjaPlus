# Task Statistics Screen

## Overview

The `TaskStatsPage` (`lib/presentation/pages/task/task_stats_page.dart`) is a dedicated statistics tab showing task metrics across configurable time periods. It lives between Projects and Settings in the bottom navigation bar.

## Architecture

- **Widget:** `ConsumerStatefulWidget` with `_StatsData` state class
- **Data Source:** `taskRepositoryProvider.getByFilterString()` — 3 parallel API calls
- **Period Filter:** `StatsPeriod` enum (today, week, month, year, all, custom)
- **Custom Period:** `showDateRangePicker()` → `_customStart` / `_customEnd`

## Displayed Metrics

| Section | Widget | Data Source |
|---|---|---|
| Total Tasks | Card + Icon | `allResponse` (no done filter) |
| Completed / Open | Row of 2 Cards | `doneResponse` / `all - done` |
| Overdue | Card (red) | `overdueResponse` (done=false, due_date < now) |
| Completion Rate | CircularProgressIndicator (120x120) | `done / total` |
| By Priority | 4 LinearProgressIndicator bars | Priority count from `allTasks` iteration |
| Top Projects | 5 LinearProgressIndicator bars | `Map<String, int>` sorted by count |

## API Filter Strings

```dart
// All tasks in period
'created >= "${start.toIso8601String()}" && created <= "${end.toIso8601String()}" && (done=false || done=true)'

// Completed tasks in period
'${periodFilter} && done=true'

// Overdue tasks (no period filter — always current)
'done=false && due_date < "${DateTime.now().toIso8601String()}"'
```

## Period Calculation

```dart
case StatsPeriod.today:
  return DateTime(now.year, now.month, now.day);
case StatsPeriod.week:
  return DateTime(now.year, now.month, now.day - now.weekday + 1);
case StatsPeriod.month:
  return DateTime(now.year, now.month, 1);
case StatsPeriod.year:
  return DateTime(now.year, 1, 1);
```

## ARB Keys (19 new keys)

- `statsTab` — Tab label in NavigationBar
- `statsTitle` — AppBar title
- `statsToday` / `statsWeek` / `statsMonth` / `statsYear` / `statsAll` / `statsCustom` — Period labels
- `statsTotal` / `statsDone` / `statsOpen` / `statsOverdue` — Metric card labels
- `statsDoneRate` — Section header
- `statsByPriority` — Section header
- `statsPriorityNone` — Label for no-priority tasks
- `statsTopProjects` — Section header
- `statsNoData` / `statsError` — Empty/error states

## Implementation Notes

- **3 parallel API calls** — could be optimized to 2 (all tasks + done tasks, calculate overdue client-side)
- **`per_page: ['500']`** — hardcoded limit; pagination not implemented
- **Error handling:** catches all exceptions, shows retry button with `FilledButton.tonal`
- **Period in AppBar:** `PopupMenuButton<StatsPeriod>` with `initialValue`
- **Custom period:** `showDateRangePicker()` with `DateTime(2020)` as `firstDate`
- **RefreshIndicator** wraps the whole ListView