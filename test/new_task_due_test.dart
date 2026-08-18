import 'package:flutter_test/flutter_test.dart';
import 'package:vikunja_app/domain/entities/new_task_due.dart';

void main() {
  group('NewTaskDue.calculateDate', () {
    test('none returns null', () {
      final now = DateTime(2025, 11, 10, 8, 30);
      expect(NewTaskDue.none.calculateDate(now), isNull);
    });

    test('today returns same date', () {
      final base = DateTime(2025, 11, 10, 10, 15);
      final result = NewTaskDue.today.calculateDate(base);
      expect(result, isNotNull);
      expect(result!.year, base.year);
      expect(result.month, base.month);
      expect(result.day, base.day);
    });

    test('tomorrow adds one day', () {
      final base = DateTime(2025, 11, 10, 16, 0);
      final result = NewTaskDue.tomorrow.calculateDate(base);
      expect(result!.day, base.day + 1);
    });

    test('next_monday when today is Monday returns same day', () {
      final monday = DateTime(2025, 11, 10, 7, 0);
      final result = NewTaskDue.nextMonday.calculateDate(monday);
      expect(result!.day, monday.day);
      expect(result.weekday, DateTime.monday);
    });

    test('next_monday when today is Wednesday returns next Monday', () {
      final wednesday = DateTime(2025, 11, 12, 13, 0);
      final result = NewTaskDue.nextMonday.calculateDate(wednesday);
      expect(result!.day, wednesday.day + 5);
      expect(result.weekday, DateTime.monday);
    });

    test('next_week adds seven days', () {
      final base = DateTime(2025, 11, 10, 17, 30);
      final result = NewTaskDue.nextWeek.calculateDate(base);
      expect(result!.day, base.day + 7);
    });

    test('custom returns exact current time', () {
      final base = DateTime(2025, 11, 10, 10, 34, 12, 123, 456);
      final result = NewTaskDue.custom.calculateDate(base);
      expect(result, base);
    });
  });
}