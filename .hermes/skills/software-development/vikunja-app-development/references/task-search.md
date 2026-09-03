# Task Search

## UI Entry Point

- **Location:** AppBar on `TaskListPage` (start screen) — magnifying glass icon before `...` menu
- **Page:** `TaskSearchPage` (`lib/presentation/pages/task/task_search_page.dart`)

## API Filter Syntax

The Vikunja API supports `title ~ "query"` for fuzzy title search:

```dart
var response = await taskService.getByFilterString(
  'title ~ "${query.trim()}"',
  {"filter_include_nulls": ["false"]},
);
```

**Key points:**
- `~` means "contains" (case-insensitive LIKE)
- The filter includes **both done and undone tasks** (no `done=true/false` filter)
- `filter_include_nulls: false` ensures null fields don't break the filter
- `per_page` is not set — defaults to API limit (usually 50). Pagination not implemented.

## UI Behavior

- **Autofocus** on TextField (`autofocus: true`)
- **Auto-search** on input ≥ 2 characters (via `onChanged`)
- **Manual search** on Enter / keyboard search action (`onSubmitted`, `textInputAction: TextInputAction.search`)
- **Clear button** in AppBar when text is non-empty
- **States:**
  - Initial: `search_off` icon + hint text
  - Loading: `CircularProgressIndicator`
  - Empty results: `search_off` icon + "no results" text
  - Results: `ListView.separated` with `ListTile` per task

## Result List Item

Each result shows:
- `Checkbox` (disabled — read-only indicator of done status)
- `title` (with line-through style if done)
- `DueDateCard` (if has due date)
- `PriorityBatch` (if priority != 0)
- `project.title` (Flexible with ellipsis)
- `onTap` → `TaskBottomSheet(task, onEdit: _onEdit)`

## ARB Keys

- `searchTasks` — Tooltip on search icon
- `searchHint` — Placeholder text in search field
- `searchNoResults` — Empty state message

## Limitations

- No pagination — only returns first page of results
- No filter by project or status (always searches all projects, all statuses)
- `title ~` filter is server-side; search may be slow on large datasets