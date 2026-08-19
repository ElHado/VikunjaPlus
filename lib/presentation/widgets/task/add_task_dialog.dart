import 'package:flutter/material.dart';
import 'package:vikunja_app/domain/entities/new_task_due.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';

class AddTaskDialog extends StatefulWidget {
  final void Function(String title, DateTime? dueDate) onAddTask;
  final String? title;

  const AddTaskDialog({super.key, required this.onAddTask, this.title});

  @override
  State<StatefulWidget> createState() => AddTaskDialogState();
}

class AddTaskDialogState extends State<AddTaskDialog> {
  NewTaskDue newTaskDue = NewTaskDue.none;
  DateTime? dueDate;
  var textController = TextEditingController();

  static const _timePresets = [8, 12, 15, 18, 21];
  int? _selectedHour;

  @override
  void initState() {
    super.initState();

    var title = widget.title;
    if (title != null) {
      textController.text = title;
    }
  }

  void _onDaySelected(NewTaskDue day, DateTime now) {
    FocusScope.of(context).unfocus();
    if (day == NewTaskDue.none || day == NewTaskDue.custom) {
      setState(() {
        newTaskDue = day;
        dueDate = null;
        _selectedHour = null;
      });
      if (day == NewTaskDue.custom) {
        _openCustomPicker();
      }
      return;
    }

    setState(() {
      newTaskDue = day;
      final date = day.calculateDate(now)!;
      // Default time: nearest hour
      _selectedHour = null;
      dueDate = _applyTime(date, _calculateNearestHour(now));
    });
  }

  void _onTimeSelected(int hour) {
    FocusScope.of(context).unfocus();
    if (dueDate == null) return;
    setState(() {
      _selectedHour = hour;
      dueDate = _applyTime(dueDate!, hour);
    });
  }

  DateTime _applyTime(DateTime date, int hour) {
    return DateTime(date.year, date.month, date.day, hour, 0, 0);
  }

  int _calculateNearestHour(DateTime now) {
    if (now.hour <= 9) return 9;
    if (now.hour < 12) return 12;
    if (now.hour < 15) return 15;
    if (now.hour < 18) return 18;
    if (now.hour < 21) return 21;
    return 9;
  }

  Future<void> _openCustomPicker() async {
    final initial = dueDate ?? DateTime.now();
    var selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (_) => DatePickerDialog(
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        initialCalendarMode: DatePickerMode.day,
      ),
    );

    if (!mounted || selectedDate == null) return;

    var selectedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => TimePickerDialog(
        initialTime: TimeOfDay.fromDateTime(initial),
      ),
    );

    if (!mounted || selectedTime == null) return;

    setState(() {
      newTaskDue = NewTaskDue.custom;
      _selectedHour = null;
      dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.all(16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.newTaskName,
              hintText: l10n.newTaskExample,
            ),
            controller: textController,
          ),
          const SizedBox(height: 16),
          Text(l10n.dueDate, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _dayChip(l10n.dueOptionNone, NewTaskDue.none),
              _dayChip(l10n.dueOptionToday, NewTaskDue.today),
              _dayChip(l10n.dueOptionTomorrow, NewTaskDue.tomorrow),
              _dayChip(l10n.dueInOneWeek, NewTaskDue.nextWeek),
              _dayChip(l10n.dueOptionNextMonday, NewTaskDue.nextMonday),
            ],
          ),
          if (newTaskDue != NewTaskDue.none && newTaskDue != NewTaskDue.custom)
            ...[
              const SizedBox(height: 12),
              Text(l10n.dueTime, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final hour in _timePresets)
                    _timeChip('${hour.toString().padLeft(2, '0')}:00', hour),
                ],
              ),
            ],
          if (newTaskDue != NewTaskDue.custom) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(l10n.dueOptionCustom),
                onPressed: () => _onDaySelected(NewTaskDue.custom, now),
              ),
            ),
          ],
          if (dueDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatDueDate(dueDate!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(l10n.add),
          onPressed: () {
            if (textController.text.isNotEmpty) {
              widget.onAddTask(textController.text, dueDate);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _dayChip(String label, NewTaskDue value) {
    return ChoiceChip(
      label: Text(label),
      selected: newTaskDue == value,
      onSelected: (_) => _onDaySelected(value, DateTime.now()),
    );
  }

  Widget _timeChip(String label, int hour) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedHour == hour,
      onSelected: (_) => _onTimeSelected(hour),
    );
  }

  String _formatDueDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} $hour:$minute';
  }
}