import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/project_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/due_date_card.dart';
import 'package:vikunja_app/presentation/widgets/project/kanban/priority_batch.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

enum _TableColumn {
  title,
  dueDate,
  priority,
  assignee,
  labels,
  identifier,
}

class ProjectTableView extends ConsumerWidget {
  final Project project;

  const ProjectTableView(this.project, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectController = ref.watch(projectControllerProvider(project));
    final l10n = AppLocalizations.of(context);

    return projectController.when(
      data: (pageModel) {
        if (pageModel.tasks.isEmpty) {
          return EmptyView(Icons.table_chart, l10n.noTasks);
        }
        return _SortableTable(
          project: project,
          tasks: pageModel.tasks,
          l10n: l10n,
          ref: ref,
        );
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }
}

class _SortableTable extends StatefulWidget {
  final Project project;
  final List<Task> tasks;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _SortableTable({
    required this.project,
    required this.tasks,
    required this.l10n,
    required this.ref,
  });

  @override
  State<_SortableTable> createState() => _SortableTableState();
}

class _SortableTableState extends State<_SortableTable> {
  _TableColumn _sortColumn = _TableColumn.dueDate;
  bool _sortAscending = true;

  List<Task> get _sortedTasks {
    final sorted = List<Task>.from(widget.tasks);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case _TableColumn.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case _TableColumn.dueDate:
          if (!a.hasDueDate && !b.hasDueDate) {
            cmp = 0;
          } else if (!a.hasDueDate) {
            cmp = 1;
          } else if (!b.hasDueDate) {
            cmp = -1;
          } else {
            cmp = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case _TableColumn.priority:
          cmp = (a.priority ?? 0).compareTo(b.priority ?? 0);
          break;
        case _TableColumn.assignee:
          final aName = a.createdBy?.name ?? '';
          final bName = b.createdBy?.name ?? '';
          cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
          break;
        case _TableColumn.labels:
          final aLabel = a.labels.isNotEmpty ? a.labels.first.title : '';
          final bLabel = b.labels.isNotEmpty ? b.labels.first.title : '';
          cmp = aLabel.toLowerCase().compareTo(bLabel.toLowerCase());
          break;
        case _TableColumn.identifier:
          cmp = a.identifier.toLowerCase().compareTo(b.identifier.toLowerCase());
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void _onSort(_TableColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = _sortedTasks;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _sortColumn.index,
          sortAscending: _sortAscending,
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest,
          ),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 72,
          columnSpacing: 24,
          horizontalMargin: 16,
          columns: [
            DataColumn(
              label: Text(widget.l10n.title, style: TextStyle(fontWeight: FontWeight.w600)),
              onSort: (_, _) => _onSort(_TableColumn.title),
            ),
            DataColumn(
              label: Text(widget.l10n.dueDateLabel, style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: false,
              onSort: (_, _) => _onSort(_TableColumn.dueDate),
            ),
            DataColumn(
              label: Text(widget.l10n.priority, style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: false,
              onSort: (_, _) => _onSort(_TableColumn.priority),
            ),
            DataColumn(
              label: Text(widget.l10n.assignee, style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: false,
              onSort: (_, _) => _onSort(_TableColumn.assignee),
            ),
            DataColumn(
              label: Text(widget.l10n.labels, style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: false,
              onSort: (_, _) => _onSort(_TableColumn.labels),
            ),
          ],
          rows: sorted.map((task) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (sorted.indexOf(task).isEven) {
                  return theme.colorScheme.surfaceContainerLow;
                }
                return null;
              }),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: task.done,
                          onChanged: (value) {
                            task.done = value ?? false;
                            widget.ref
                                .read(projectControllerProvider(widget.project).notifier)
                                .markAsDone(task);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => _showTaskBottomSheet(context, task),
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: task.done
                                ? TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  task.hasDueDate
                      ? DueDateCard(task.dueDate!)
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
                DataCell(
                  task.priority != null && task.priority != 0
                      ? PriorityBatch(task.priority!)
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
                DataCell(
                  task.createdBy != null
                      ? Text(
                          task.createdBy?.name ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
                DataCell(
                  task.labels.isNotEmpty
                      ? Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: task.labels.take(3).map((label) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: label.color?.withValues(alpha: 0.2) ?? theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label.title,
                                style: TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        )
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTaskBottomSheet(BuildContext context, Task task) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (BuildContext context) {
        return TaskBottomSheet(
          task: task,
          onEdit: () => _onEdit(context, task),
        );
      },
    );
  }

  void _onEdit(BuildContext context, Task task) async {
    Navigator.of(context).pop();
    final editedTask = await Navigator.push<Task?>(
      context,
      MaterialPageRoute(builder: (buildContext) => TaskEditPage(task: task)),
    );
    if (editedTask != null) {
      widget.ref.read(projectControllerProvider(widget.project).notifier).reload();
    }
  }
}