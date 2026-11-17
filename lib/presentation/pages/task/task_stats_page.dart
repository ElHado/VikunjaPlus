import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';

enum StatsPeriod {
  today,
  yesterday,
  week,
  month,
  year,
  all,
  custom;

  String label(AppLocalizations l10n) {
    switch (this) {
      case StatsPeriod.today: return l10n.statsToday;
      case StatsPeriod.yesterday: return l10n.statsYesterday;
      case StatsPeriod.week: return l10n.statsWeek;
      case StatsPeriod.month: return l10n.statsMonth;
      case StatsPeriod.year: return l10n.statsYear;
      case StatsPeriod.all: return l10n.statsAll;
      case StatsPeriod.custom: return l10n.statsCustom;
    }
  }
}

class _StatsData {
  final int total;
  final int done;
  final int overdue;
  final int noPriority;
  final int lowPriority;
  final int mediumPriority;
  final int highPriority;
  final Map<String, int> tasksByProject;

  _StatsData({
    this.total = 0,
    this.done = 0,
    this.overdue = 0,
    this.noPriority = 0,
    this.lowPriority = 0,
    this.mediumPriority = 0,
    this.highPriority = 0,
    this.tasksByProject = const {},
  });

  int get open => total - done;
  double get doneRate => total > 0 ? done / total : 0;
}

class TaskStatsPage extends ConsumerStatefulWidget {
  const TaskStatsPage({super.key});

  @override
  ConsumerState<TaskStatsPage> createState() => _TaskStatsPageState();
}

class _TaskStatsPageState extends ConsumerState<TaskStatsPage> {
  StatsPeriod _selectedPeriod = StatsPeriod.month;
  DateTime? _customStart;
  DateTime? _customEnd;
  _StatsData? _stats;
  bool _loading = false;
  bool _error = false;
  // Tägliche Erledigungszahlen für den Heatmap
  Map<int, int> _dailyCounts = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPeriod();
    _loadStats();
  }

  Future<void> _loadSavedPeriod() async {
    try {
      final storage = FlutterSecureStorage();
      final saved = await storage.read(key: 'stats_selected_period');
      if (saved != null && saved.isNotEmpty) {
        for (final p in StatsPeriod.values) {
          if (p.name == saved) {
            _selectedPeriod = p;
            break;
          }
        }
      }
    } catch (_) {
      // Standard (Dieser Monat) bei Fehler
    }
  }

  Future<void> _savePeriod() async {
    try {
      final storage = FlutterSecureStorage();
      await storage.write(
        key: 'stats_selected_period',
        value: _selectedPeriod.name,
      );
    } catch (_) {}
  }

  DateTime? get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case StatsPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case StatsPeriod.yesterday:
        return DateTime(now.year, now.month, now.day - 1);
      case StatsPeriod.week:
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 1);
      case StatsPeriod.month:
        return DateTime(now.year, now.month, 1);
      case StatsPeriod.year:
        return DateTime(now.year, 1, 1);
      case StatsPeriod.all:
        return null;
      case StatsPeriod.custom:
        return _customStart;
    }
  }

  DateTime? get _periodEnd {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case StatsPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case StatsPeriod.yesterday:
        return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
      case StatsPeriod.week:
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 7, 23, 59, 59);
      case StatsPeriod.month:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case StatsPeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case StatsPeriod.all:
        return null;
      case StatsPeriod.custom:
        return _customEnd;
    }
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = false; });
    try {
      final taskService = ref.read(taskRepositoryProvider);
      final start = _periodStart;
      final end = _periodEnd;

      // Alle Tasks mit Pagination abrufen (API limitiert auf 50/Seite)
      List<Task> allTasks = [];
      int page = 1;
      int totalPages = 1;

      while (page <= totalPages) {
        final response = await taskService.getByFilterString(
          'done=false || done=true',
          {'filter_include_nulls': ['false'], 'per_page': ['100'], 'page': ['$page']},
        );

        if (!response.isSuccessful) {
          if (allTasks.isEmpty) {
            if (mounted) setState(() { _error = true; _loading = false; });
            return;
          }
          break;
        }

        final headers = response.toSuccess().headers;
        if (page == 1) {
          totalPages = int.tryParse(headers['x-pagination-total-pages'] ?? '1') ?? 1;
        }

        allTasks.addAll(response.toSuccess().body);
        page++;
      }

      // Zeitraum-Filter in-memory (API hat Probleme mit komplexen Datums-Filtern)
      List<Task> filteredTasks = allTasks;
      if (start != null || end != null) {
        filteredTasks = allTasks.where((task) {
          if (!task.hasDueDate) {
            return start == null; // ohne Datum nur bei "Alles"
          }
          if (start != null && task.dueDate!.isBefore(start)) {
            return false;
          }
          if (end != null && task.dueDate!.isAfter(end)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Erledigte Tasks (in-memory gefiltert)
      final doneTasks = filteredTasks.where((t) => t.done).toList();

      // Tägliche Erledigungszahlen für Heatmap (immer letzte 365 Tage, unabhängig vom Filter)
      final dailyCounts = <int, int>{};
      for (final t in allTasks.where((t) => t.done)) {
        final day = t.doneAt ?? t.dueDate;
        if (day == null) continue;
        final diff = DateTime.now().difference(day).inDays;
        if (diff >= 0 && diff < 365) {
          final key = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        }
      }

      // Überfällige Tasks (in-memory: done=false + due_date < now)
      final now = DateTime.now();
      final overdueTasks = allTasks.where((t) => !t.done && t.hasDueDate && t.dueDate!.isBefore(now)).toList();

      // Statistik berechnen (basierend auf gefilterten Tasks)
      int noPri = 0, lowPri = 0, medPri = 0, highPri = 0;
      Map<String, int> projCount = {};

      for (final t in filteredTasks) {
        final pri = t.priority ?? 0;
        if (pri == 0) {
          noPri++;
        } else if (pri <= 1) {
          lowPri++;
        } else if (pri <= 2) {
          medPri++;
        } else {
          highPri++;
        }

        if (t.project != null) {
          projCount[t.project!.title] = (projCount[t.project!.title] ?? 0) + 1;
        }
      }

      final sortedProjects = projCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _stats = _StatsData(
          total: filteredTasks.length,
          done: doneTasks.length,
          overdue: overdueTasks.length,
          noPriority: noPri,
          lowPriority: lowPri,
          mediumPriority: medPri,
          highPriority: highPri,
          tasksByProject: Map.fromEntries(sortedProjects.take(5)),
        );
        _dailyCounts = dailyCounts;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() { _error = true; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        actions: [
          PopupMenuButton<StatsPeriod>(
            initialValue: _selectedPeriod,
            onSelected: (period) {
              if (period == StatsPeriod.custom) {
                _showDateRangePicker();
              } else {
                setState(() => _selectedPeriod = period);
                _savePeriod();
                _loadStats();
              }
            },
            itemBuilder: (_) => StatsPeriod.values.map((p) =>
              PopupMenuItem(
                value: p,
                child: Text(p.label(l10n)),
              ),
            ).toList(),
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.statsError),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _loadStats, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (_stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyView(Icons.bar_chart, l10n.statsNoData),
        ),
      );
    }

    final stats = _stats!;
    final textMuted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Zeitraum-Anzeige
          Center(
            child: Chip(
              avatar: Icon(Icons.date_range, size: 16),
              label: Text(_selectedPeriod.label(l10n)),
            ),
          ),
          const SizedBox(height: 16),

          // Übersicht-Karten
          _buildStatCard(
            theme, l10n.statsTotal, '${stats.total}',
            Icons.task_alt, Colors.blue, null,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildStatCard(
                theme, l10n.statsDone, '${stats.done}',
                Icons.check_circle, Colors.green, textMuted,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                theme, l10n.statsOpen, '${stats.open}',
                Icons.pending, Colors.orange, textMuted,
              )),
            ],
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            theme, l10n.statsOverdue, '${stats.overdue}',
            Icons.warning_amber, Colors.red, textMuted,
          ),
          const SizedBox(height: 24),

          // Erledigungsrate (Ring)
          Text(l10n.statsDoneRate, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: stats.doneRate,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${(stats.doneRate * 100).toInt()}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Prioritäts-Verteilung
          Text(l10n.statsByPriority, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildProgressBar(theme, l10n.statsPriorityNone, stats.noPriority, stats.total, Colors.grey),
          _buildProgressBar(theme, l10n.priorityLow, stats.lowPriority, stats.total, Colors.green),
          _buildProgressBar(theme, l10n.priorityMedium, stats.mediumPriority, stats.total, Colors.orange),
          _buildProgressBar(theme, l10n.priorityHigh, stats.highPriority, stats.total, Colors.red),
          const SizedBox(height: 24),

          // Top-Projekte
          if (stats.tasksByProject.isNotEmpty) ...[
            Text(l10n.statsTopProjects, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...stats.tasksByProject.entries.map((e) => _buildProjectBar(
              theme, e.key, e.value, stats.total,
            )),
          ],

          // GitHub-Gras (letzte 365 Tage)
          const SizedBox(height: 24),
          Text(l10n.statsHeatmap, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildHeatmap(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color, Color? subtitleColor) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(label, style: TextStyle(color: subtitleColor)),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, String label, int count, int total, Color color) {
    final ratio = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text('$count', style: theme.textTheme.bodySmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: color, minHeight: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectBar(ThemeData theme, String name, int count, int total) {
    final ratio = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
              Text('$count', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    if (_dailyCounts.isEmpty) return Text(AppLocalizations.of(context).statsNoData);

    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(Duration(days: 363));

    // Maximale Tagesanzahl für Farbskalierung
    int maxCount = 1;
    for (final c in _dailyCounts.values) {
      if (c > maxCount) maxCount = c;
    }

    // 7 Zeilen (Mo-So) × 52 Spalten (Wochen, links=alt, rechts=neu)
    const dayLabels = ['', 'M', '', 'M', '', 'F', ''];
    final rows = <Widget>[];
    // für jeden Wochentag eine Zeile
    for (int dow = 0; dow < 7; dow++) {
      final cells = <Widget>[];
      // Tage durchgehen, jeder Tag ist genau einer Spalte (Woche) zugeordnet
      for (int week = 0; week < 52; week++) {
        final dayNum = week * 7 + dow;
        final dt = startDate.add(Duration(days: dayNum));
        if (dt.isAfter(endDate)) {
          cells.add(const SizedBox(width: 12, height: 12));
          continue;
        }
        final key = dt.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
        final count = _dailyCounts[key] ?? 0;
        final intensity = maxCount > 1 ? (count / maxCount) : count;
        final green = (0.15 + intensity * 0.85 * 255).round();
        cells.add(Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: count == 0
                ? Colors.transparent
                : Color.fromARGB(255, 35, green.clamp(0, 255), 35),
            borderRadius: BorderRadius.circular(2),
          ),
        ));
      }
      rows.add(SizedBox(
        height: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              child: Text(dayLabels[dow], style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
            ),
            ...cells,
          ],
        ),
      ));
    }

    return SizedBox(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.statsHeatmap, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            children: [
              Text('0', style: Theme.of(context).textTheme.bodySmall),
              Container(width: 12, height: 12, color: Colors.transparent),
              Container(width: 12, height: 12, color: Color.fromARGB(255, 35, 60, 35)),
              Container(width: 12, height: 12, color: Color.fromARGB(255, 35, 150, 35)),
              Container(width: 12, height: 12, color: Color.fromARGB(255, 35, 220, 35)),
              Text('$maxCount', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(
                    height: 120,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12, child: _buildMonthLabels()),
                          const SizedBox(height: 4),
                          Column(children: rows),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthLabels() {
    final labels = <Widget>[];
    final startDate = DateTime.now().subtract(Duration(days: 363));
    int year = DateTime.now().year;
    int prevMonth = DateTime.now().month;
    for (int m = 0; m < 12; m++) {
      int month = (DateTime.now().month - 1 - m + 12) % 12 + 1;
      // Jahr wechseln wenn wir von Januar zurück zu Dezember gehen
      if (m > 0 && month > prevMonth) year -= 1;
      prevMonth = month;

      final firstAt = DateTime(year, month, 1);
      final diff = firstAt.difference(startDate).inDays;
      if (diff < 0 || diff > 363) continue;

      final weekPos = diff ~/ 7;
      labels.add(Positioned(
        left: 14 + weekPos * 12.0,
        top: 0,
        child: Text(
          ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][month - 1],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ));
    }
    return SizedBox(
      width: 52 * 12 + 14,
      child: Stack(children: labels),
    );
  }

  Future<void> _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now()),
    );
    if (range != null && mounted) {
      setState(() {
        _customStart = range.start;
        _customEnd = range.end;
        _selectedPeriod = StatsPeriod.custom;
      });
      _loadStats();
    }
  }
}