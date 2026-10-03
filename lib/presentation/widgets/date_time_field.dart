import 'package:flutter/material.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';

class VikunjaDateTimeField extends StatelessWidget {
  final String label;
  final void Function(DateTime?)? onSaved;
  final void Function(DateTime?)? onChanged;
  final DateTime? initialValue;
  final Icon icon;

  const VikunjaDateTimeField({
    super.key,
    required this.label,
    this.onSaved,
    this.onChanged,
    this.initialValue,
    this.icon = const Icon(Icons.date_range),
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = initialValue == null || initialValue!.year <= 1
        ? null
        : initialValue!.toLocal();
    final l10n = AppLocalizations.of(context);
    final displayText = currentValue == null
        ? l10n.noDate
        : '${currentValue.day.toString().padLeft(2)}.'
            '${currentValue.month.toString().padLeft(2)}.'
            '${currentValue.year}'
            ' ${currentValue.hour.toString().padLeft(2)}:'
            '${currentValue.minute.toString().padLeft(2)}';

    return ListTile(
      leading: icon,
      title: Text(label),
      subtitle: Text(displayText),
      onTap: () async {
        var selectedDate = await showDialog<DateTime>(
          context: context,
          builder: (_) => DatePickerDialog(
            initialDate: currentValue ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            initialCalendarMode: DatePickerMode.day,
          ),
        );

        if (selectedDate == null || !context.mounted) return;

        var selectedTime = await showDialog<TimeOfDay>(
          context: context,
          builder: (_) => TimePickerDialog(
            initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
          ),
        );

        if (selectedTime == null) return;

        final newValue = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        onChanged?.call(newValue);
      },
    );
  }
}
