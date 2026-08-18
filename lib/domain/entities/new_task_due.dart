enum NewTaskDue {
  none,
  today,
  tomorrow,
  nextMonday,
  nextWeek,
  custom;

  DateTime? calculateDate(DateTime currentDateTime) {
    switch (this) {
      case NewTaskDue.none:
        return null;
      case NewTaskDue.today:
        return currentDateTime;
      case NewTaskDue.tomorrow:
        return currentDateTime.add(Duration(days: 1));
      case NewTaskDue.nextMonday:
        return currentDateTime.add(
          Duration(days: (DateTime.monday - currentDateTime.weekday) % 7),
        );
      case NewTaskDue.nextWeek:
        return currentDateTime.add(Duration(days: 7));
      case NewTaskDue.custom:
        return currentDateTime;
    }
  }
}