import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vikunja_app/core/utils/calculate_item_position.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/project_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/project/project_detail_page.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/project/project_task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class ProjectTaskList extends ConsumerWidget {
  final Project project;

  const ProjectTaskList(this.project, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var projectController = ref.watch(projectControllerProvider(project));

    return projectController.when(
      data: (pageModel) {
        List<Widget> children = [];
        if (project.subprojects.isNotEmpty) {
          if (pageModel.tasks.isNotEmpty) {
            children.add(
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  AppLocalizations.of(context).projectSection,
                ),
              ),
            );
            children.add(SliverToBoxAdapter(child: Divider()));
          }
          children.addAll(_buildProjectList(context));
        }
        if (pageModel.tasks.isNotEmpty) {
          if (project.subprojects.isNotEmpty) {
            children.add(
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  AppLocalizations.of(context).tasksSection,
                ),
              ),
            );
            children.add(SliverToBoxAdapter(child: Divider()));
          }
          children.add(_buildTaskList(ref, pageModel.tasks));
        }

        if (pageModel.isLoadingNextPage) {
          children.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SpinKitThreeBounce(
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        }

        if (children.isNotEmpty) {
          return CustomScrollView(
            slivers: children,
          );
        } else {
          return EmptyView(
            Icons.list,
            AppLocalizations.of(context).noTasksOrSubproject,
          );
        }
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  List<Widget> _buildProjectList(BuildContext context) {
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subproject = project.subprojects.toList()[index];
          return ListTile(
            leading: Icon(Icons.list),
            onTap: () => _navigateToDetail(context, subproject),
            title: Text(
              subproject.title,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          );
        }, childCount: project.subprojects.length),
      ),
    ];
  }

  Widget _buildTaskList(WidgetRef ref, List<Task> tasks) {
    // Nur nach Fälligkeitsdatum sortieren, wenn die Option aktiviert ist
    // (wird im Projekt-Bearbeiten-Menü umgeschaltet).
    final projectController = ref.watch(projectControllerProvider(project));
    final chronologicalSort =
        projectController.valueOrNull?.chronologicalSort ?? false;

    if (chronologicalSort) {
      final sorted = List<Task>.from(tasks)
        ..sort((a, b) {
          if (!a.hasDueDate && !b.hasDueDate) return 0;
          if (!a.hasDueDate) return 1;
          if (!b.hasDueDate) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      return _buildReorderableList(ref, sorted);
    }
    return _buildReorderableList(ref, tasks);
  }

  Widget _buildReorderableList(WidgetRef ref, List<Task> taskList) {
    return SliverReorderableList(
      itemBuilder: (context, index) {
        final task = taskList[index];
        return ReorderableDelayedDragStartListener(
          key: Key('task_${task.id}'),
          index: index,
          child: RepaintBoundary(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTile(ref, task),
                  if (index < taskList.length - 1) const Divider(height: 1),
                ],
              ),
            ),
          ),
        );
      },
      itemCount: taskList.length,
      onReorderItem: (oldIndex, newIndex) {
        if (newIndex < -1) newIndex = -1;

        final reorderList = List<Task>.from(taskList);
        final moved = reorderList.removeAt(oldIndex);
        final insertIndex = newIndex == -1
            ? 0
            : newIndex.clamp(0, reorderList.length);
        reorderList.insert(insertIndex, moved);

        final before = insertIndex == 0
            ? null
            : reorderList[insertIndex - 1].position;
        final after = insertIndex == reorderList.length - 1
            ? null
            : reorderList[insertIndex + 1].position;
        final newPos = calculateItemPosition(
          positionBefore: before,
          positionAfter: after,
        );

        ref
            .read(projectControllerProvider(project).notifier)
            .reorderTasks(
              project: project,
              newOrderedTasks: reorderList,
              movedTaskId: moved.id,
              newPosition: newPos,
            )
            .then((success) {
              if (!success && ref.context.mounted) {
                ScaffoldMessenger.of(ref.context).showSnackBar(
                  const SnackBar(content: Text('Failed to reorder task')),
                );
              }
            });
      },
    );
  }

  Widget _buildTile(WidgetRef ref, Task task) {
    return ProjectTaskListItem(
      key: Key(task.id.toString()),
      task: task,
      onTap: () => _showTaskBottomSheet(ref, task),
      onEdit: () => _onEdit(ref, task),
      onCheckedChanged: (value) async {
        var success = await ref
            .read(projectControllerProvider(project).notifier)
            .markAsDone(task);
        if (!success && ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(ref.context).failedToMarkDone),
            ),
          );
        }
      },
    );
  }

  void _showTaskBottomSheet(WidgetRef ref, Task task) {
    showModalBottomSheet<void>(
      context: ref.context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (BuildContext context) {
        return TaskBottomSheet(task: task, onEdit: () => _onEdit(ref, task));
      },
    );
  }

  void _onEdit(WidgetRef ref, Task task) async {
    var editedTask = await Navigator.push<Task?>(
      ref.context,
      MaterialPageRoute(builder: (buildContext) => TaskEditPage(task: task)),
    );

    if (editedTask != null) {
      ref.read(projectControllerProvider(project).notifier).reload();
    }
  }

  void _navigateToDetail(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ProjectDetailPage(
            key: Key(project.id.toString()),
            project: project,
          );
        },
      ),
    );
  }
}
