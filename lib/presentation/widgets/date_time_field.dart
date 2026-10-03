import 'package:flutter/material.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';

class VikunjaDateTimeField extends StatelessWidget {
  final String label;
  final void Function(DateTime?)? onChanged;
  final DateTime? initialValue;
  final Icon icon;

  const VikunjaDateTimeField({
    super.key,
    required this.label,
    this.onChanged,
    this.initialValue,
    this.icon = const Icon(Icons.date_range),
  });

  @override
  Widget build(BuildContext context) {
    return _pickerListTile(
      context,
      icon,
      label,
      initialValue,
      (newValue) {
        // onChanged kann auch null liefern (bei entferntem Reminder)
        onChanged?.call(newValue);
      },
    );
  }
}

/// Baut einen ListTile der auf Tap DatePicker + TimePicker öffnet.
/// Setzt `onChanged(null)` wenn der User den Picker abbricht.
Widget _pickerListTile(
  BuildContext context,
  Icon icon,
  String label,
  DateTime? value,
  void Function(DateTime?)? onChanged,
) {
  final l10n = AppLocalizations.of(context);
  final displayText = (value == null || value.year <= 1)
      ? l10n.noDate
      : _formatDate(value);

  return ListTile(
    leading: icon,
    title: Text(label),
    subtitle: Text(displayText),
    onTap: () async {
      var selectedDate = await showDialog<DateTime>(
        context: context,
        builder: (_) => DatePickerDialog(
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          initialCalendarMode: DatePickerMode.day,
        ),
      );

      if (selectedDate == null || !context.mounted) {
        onChanged?.call(null);
        return;
      }

      var selectedTime = await showDialog<TimeOfDay>(
        context: context,
        builder: (_) =>
            TimePickerDialog(
              initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
            ),
      );

      if (selectedTime == null) {
        onChanged?.call(null);
        return;
      }

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

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d.$m.${dt.year} $h:$min';
}
