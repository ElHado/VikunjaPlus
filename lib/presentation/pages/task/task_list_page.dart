import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_page_model.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/due_date_card.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/project/kanban/priority_batch.dart';
import 'package:vikunja_app/presentation/widgets/task/add_task_dialog.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

enum _TableColumn {
  title,
  dueDate,
  priority,
  project,
  assignee,
  labels,
}

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  bool _showTableView = false;
  _TableColumn _sortColumn = _TableColumn.dueDate;
  bool _sortAscending = true;

  List<Task> _sortedTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
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
        case _TableColumn.project:
          final aProj = a.project?.title ?? '';
          final bProj = b.project?.title ?? '';
          cmp = aProj.toLowerCase().compareTo(bProj.toLowerCase());
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
    final l10n = AppLocalizations.of(context);
    var pageModel = ref.watch(taskPageControllerProvider);

    return pageModel.when(
      data: (model) {
        return Scaffold(
          appBar: _buildAppBar(ref, context, model.onlyDueDate),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.read(taskPageControllerProvider.notifier).reload();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  ref.read(taskPageControllerProvider.notifier).loadNextPage();
                }
                return false;
              },
              child: _showTableView
                  ? _buildTable(ref, context, model)
                  : _buildList(ref, context, model),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (model.defaultProjectId == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.selectDefaultProject)),
                );
              } else {
                _addItemDialog(ref, context, model.defaultProjectId);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
      error: (err, _) => VikunjaErrorWidget(
        error: err,
        onRetry: () => ref.invalidate(taskPageControllerProvider),
      ),
      loading: () => const LoadingWidget(),
    );
  }

  Widget _buildList(WidgetRef ref, BuildContext context, TaskPageModel model) {
    if (model.tasks.isEmpty) {
      return EmptyView(Icons.list, AppLocalizations.of(context).noTasks);
    } else {
      final itemCount = model.tasks.length + (model.isLoadingNextPage ? 1 : 0);
      return ListView.separated(
        itemCount: itemCount,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 8),
        itemBuilder: (context, index) {
          if (index == model.tasks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SpinKitThreeBounce(
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ),
            );
          }
          return _createListItem(ref, context, model.tasks[index]);
        },
      );
    }
  }

  Widget _buildTable(WidgetRef ref, BuildContext context, TaskPageModel model) {
    if (model.tasks.isEmpty) {
      return EmptyView(Icons.table_chart, AppLocalizations.of(context).noTasks);
    }
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final sorted = _sortedTasks(model.tasks);

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
            DataColumn(label: Text(l10n.title, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.title)),
            DataColumn(label: Text(l10n.dueDateLabel, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.dueDate)),
            DataColumn(label: Text(l10n.priority, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.priority)),
            DataColumn(label: Text(l10n.project, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.project)),
            DataColumn(label: Text(l10n.assignee, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.assignee)),
            DataColumn(label: Text(l10n.labels, style: TextStyle(fontWeight: FontWeight.w600)), onSort: (_, _) => _onSort(_TableColumn.labels)),
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
                        width: 24, height: 24,
                        child: Checkbox(
                          value: task.done,
                          onChanged: (value) {
                            task.done = value ?? false;
                            ref.read(taskPageControllerProvider.notifier).markAsDone(task);
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
                  task.project != null
                      ? Text(task.project!.title, overflow: TextOverflow.ellipsis, maxLines: 1)
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
                DataCell(
                  task.createdBy != null
                      ? Text(task.createdBy!.name, overflow: TextOverflow.ellipsis, maxLines: 1)
                      : Text('-', style: theme.textTheme.bodySmall),
                ),
                DataCell(
                  task.labels.isNotEmpty
                      ? Wrap(
                          spacing: 4, runSpacing: 2,
                          children: task.labels.take(3).map((label) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: label.color?.withValues(alpha: 0.2) ?? theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(label.title, style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
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

  AppBar _buildAppBar(WidgetRef ref, BuildContext context, bool onlyDueDate) {
    return AppBar(
      title: Text("Vikunja+"),
      actions: [
        PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                child: InkWell(
                  onTap: () {
                    _onlyDueDateChanged(ref, context, !onlyDueDate);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context).onlyShowTasksWithDueDate,
                      ),
                      Checkbox(
                        value: onlyDueDate,
                        onChanged: (bool? value) {
                          _onlyDueDateChanged(ref, context, !onlyDueDate);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _showTableView = !_showTableView);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _showTableView
                            ? 'Listenansicht'
                            : 'Tabellenansicht',
                      ),
                      SizedBox(width: 8),
                      Icon(
                        _showTableView ? Icons.view_list : Icons.table_chart,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _onlyDueDateChanged(WidgetRef ref, BuildContext context, bool newValue) {
    Navigator.pop(context);
    ref
        .read(taskPageControllerProvider.notifier)
        .setLandingPageOnlyDueDateTasks(newValue);
  }

  void _addItemDialog(
    WidgetRef ref,
    BuildContext context,
    int defaultProjectId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        onAddTask: (title, dueDate) =>
            _addTask(ref, title, dueDate, defaultProjectId),
      ),
    );
  }

  Future<void> _addTask(
    WidgetRef ref,
    String title,
    DateTime? dueDate,
    int defaultProjectId,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      return;
    }

    var task = Task(
      title: title,
      dueDate: dueDate,
      createdBy: currentUser,
      projectId: defaultProjectId,
    );

    var success = await ref
        .read(taskPageControllerProvider.notifier)
        .addTask(defaultProjectId, task);

    if (ref.context.mounted) {
      if (success) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ref.context).taskAddedSuccess),
          ),
        );
      } else {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ref.context).taskAddError),
          ),
        );
      }
    }
  }

  Widget _createListItem(WidgetRef ref, BuildContext context, Task task) {
    return TaskListItem(
      key: Key(task.id.toString()),
      task: task,
      onTap: () {
        _showTaskBottomSheet(context, task);
      },
      onEdit: () => _onEdit(context, task),
      onCheckedChanged: (value) async {
        var success = await ref
            .read(taskPageControllerProvider.notifier)
            .markAsDone(task);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).taskMarkDoneError),
            ),
          );
        }
      },
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

  void _onEdit(BuildContext context, Task task) {
    Navigator.push<Task?>(
      context,
      MaterialPageRoute(builder: (buildContext) => TaskEditPage(task: task)),
    );
  }
}
