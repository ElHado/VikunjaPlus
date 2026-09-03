import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';

enum StatsPeriod {
  today,
  week,
  month,
  year,
  all,
  custom;

  String label(AppLocalizations l10n) {
    switch (this) {
      case StatsPeriod.today: return l10n.statsToday;
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
  StatsPeriod _selectedPeriod = StatsPeriod.all;
  DateTime? _customStart;
  DateTime? _customEnd;
  _StatsData? _stats;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  DateTime? get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case StatsPeriod.today:
        return DateTime(now.year, now.month, now.day);
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
      case StatsPeriod.week:
      case StatsPeriod.month:
      case StatsPeriod.year:
        return now;
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

      String timeFilter = '';
      if (start != null) {
        final s = start.toIso8601String().split('T')[0];
        timeFilter += 'due_date >= "$s 00:00:00"';
      }
      if (end != null) {
        if (timeFilter.isNotEmpty) timeFilter += ' && ';
        final e = end.toIso8601String().split('T')[0];
        timeFilter += 'due_date <= "$e 23:59:59"';
      }
      // Bei Zeitraum: Datum beachten, sonst alle Tasks
      final baseFilter = timeFilter.isEmpty ? '' : '$timeFilter && ';

      // Alle Tasks mit Pagination abrufen (API limitiert auf 50/Seite)
      List<Task> allTasks = [];
      int page = 1;
      int totalPages = 1;

      while (page <= totalPages) {
        final response = await taskService.getByFilterString(
          '${baseFilter}(done=false || done=true)',
          {'filter_include_nulls': ['false'], 'per_page': ['100'], 'page': ['$page']},
        );

        if (!response.isSuccessful) {
          if (allTasks.isEmpty) {
            if (mounted) setState(() { _error = true; _loading = false; });
            return;
          }
          break;
        }

        // Pagination-Header auslesen
        final headers = response.toSuccess().headers;
        if (page == 1) {
          totalPages = int.tryParse(headers['x-pagination-total-pages'] ?? '1') ?? 1;
        }

        allTasks.addAll(response.toSuccess().body);
        page++;
      }

      // Erledigte Tasks
      List<Task> doneTasks = [];
      page = 1;
      totalPages = 1;
      while (page <= totalPages) {
        final response = await taskService.getByFilterString(
          '${baseFilter}done=true',
          {'filter_include_nulls': ['false'], 'per_page': ['100'], 'page': ['$page']},
        );
        if (!response.isSuccessful) break;
        if (page == 1) {
          totalPages = int.tryParse(response.toSuccess().headers['x-pagination-total-pages'] ?? '1') ?? 1;
        }
        doneTasks.addAll(response.toSuccess().body);
        page++;
      }

      // Überfällige Tasks (immer aktuell, kein Zeitraum-Filter)
      final now = DateTime.now();
      final nowStr = now.toIso8601String().split('T')[0];
      List<Task> overdueTasks = [];
      page = 1;
      totalPages = 1;
      while (page <= totalPages) {
        final response = await taskService.getByFilterString(
          'done=false && due_date < "$nowStr 00:00:00"',
          {'filter_include_nulls': ['false'], 'per_page': ['100'], 'page': ['$page']},
        );
        if (!response.isSuccessful) break;
        if (page == 1) {
          totalPages = int.tryParse(response.toSuccess().headers['x-pagination-total-pages'] ?? '1') ?? 1;
        }
        overdueTasks.addAll(response.toSuccess().body);
        page++;
      }

      // Statistik berechnen
      int noPri = 0, lowPri = 0, medPri = 0, highPri = 0;
      Map<String, int> projCount = {};

      for (final t in allTasks) {
        final pri = t.priority ?? 0;
        if (pri == 0) noPri++;
        else if (pri <= 1) lowPri++;
        else if (pri <= 2) medPri++;
        else highPri++;

        if (t.project != null) {
          projCount[t.project!.title] = (projCount[t.project!.title] ?? 0) + 1;
        }
      }

      final sortedProjects = projCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _stats = _StatsData(
          total: allTasks.length,
          done: doneTasks.length,
          overdue: overdueTasks.length,
          noPriority: noPri,
          lowPriority: lowPri,
          mediumPriority: medPri,
          highPriority: highPri,
          tasksByProject: Map.fromEntries(sortedProjects.take(5)),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
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