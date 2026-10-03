import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/pages/task/task_comments_page.dart';

enum TaskActionsVariant { menu, icons }

enum _TaskAction { comments, edit, reschedule }

class TaskActions extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final void Function(DateTime?)? onReschedule;
  final TaskActionsVariant variant;
  final VoidCallback? onBeforeAction;

  const TaskActions({
    super.key,
    required this.task,
    required this.onEdit,
    this.onReschedule,
    required this.variant,
    this.onBeforeAction,
  });

  void _openComments(BuildContext context) {
    onBeforeAction?.call();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaskCommentsPage(taskId: task.id, taskTitle: task.title),
      ),
    );
  }

  void _edit() {
    onBeforeAction?.call();
    onEdit();
  }

  Future<void> _onReschedule(BuildContext context) async {
    onBeforeAction?.call();
    if (onReschedule == null) return;

    // Token in lokaler Zeit für den Picker (Server speichert UTC)
    final localDue = task.dueDate?.toLocal() ?? DateTime.now();

    var selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (_) => DatePickerDialog(
        initialDate: localDue,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        initialCalendarMode: DatePickerMode.day,
      ),
    );

    if (selectedDate == null || !context.mounted) return;

    var selectedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) =>
          TimePickerDialog(
            initialTime: TimeOfDay.fromDateTime(localDue),
          ),
    );

    if (selectedTime == null || !context.mounted) return;

    // Lokale Zeit → in UTC für Server-API
    final localNew = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    onReschedule?.call(localNew.toUtc());
  }

  void _handleMenuAction(BuildContext context, _TaskAction action) {
    switch (action) {
      case _TaskAction.comments:
        _openComments(context);
        break;
      case _TaskAction.edit:
        _edit();
        break;
      case _TaskAction.reschedule:
        unawaited(_onReschedule(context));
        break;
    }
  }

  List<PopupMenuEntry<_TaskAction>> _menuItems(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final items = <PopupMenuEntry<_TaskAction>>[
      PopupMenuItem(
        value: _TaskAction.comments,
        child: Text(localizations.comments),
      ),
      if (onReschedule != null)
        PopupMenuItem(
          value: _TaskAction.reschedule,
          child: Text(localizations.reschedule),
        ),
      PopupMenuItem(value: _TaskAction.edit, child: Text(localizations.edit)),
    ];
    return items;
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case TaskActionsVariant.menu:
        return PopupMenuButton<_TaskAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => _handleMenuAction(context, action),
          itemBuilder: _menuItems,
        );
      case TaskActionsVariant.icons:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _openComments(context),
              icon: const Icon(Icons.comment),
              tooltip: AppLocalizations.of(context).comments,
            ),
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          ],
        );
    }
  }
}
