import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:vikunja_app/core/network/client.dart';
import 'package:vikunja_app/data/data_sources/settings_data_source.dart';
import 'package:vikunja_app/data/data_sources/task_data_source.dart';
import 'package:vikunja_app/data/repositories/task_repository_impl.dart';
import 'package:vikunja_app/domain/repositories/task_repository.dart';
import 'package:vikunja_app/presentation/manager/widget_controller.dart';

/// Entfernt HTML-Tags aus einem String und dekodiert HTML-Entities.
/// Wichtig für die Task-Beschreibung, da Vikunja diese als HTML speichert.
String stripHtml(String html) {
  // Zuerst HTML-Entities dekodieren
  var text = html
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&#x2F;', '/');

  // HTML-Tags entfernen
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Zeilenumbrüche aus Block-Tags durch echte Newlines ersetzen
  text = text.replaceAllMapped(
    RegExp(r'\s*\n\s*'),
    (_) => ' ',
  );

  // Mehrfache Leerzeichen reduzieren
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  return text;
}

const _actionDonePortName = 'action_done_port_name';
const _notificationActionDone = 'action_done';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  if (notificationResponse.actionId == _notificationActionDone) {
    var id = notificationResponse.id;

    if (id != null) {
      await markAsDone(id);
    }
  }
}

Future<void> markAsDone(int id) async {
  var datasource = SettingsDatasource(FlutterSecureStorage());
  var refreshToken = await datasource.getRefreshToken();
  var base = await datasource.getServer();

  if (refreshToken == null || base == null) {
    return;
  }

  Client client = Client(base: base);

  var ignoreCertificates = await datasource.getIgnoreCertificates();
  client.setIgnoreCerts(ignoreCertificates);

  TaskRepository taskService = TaskRepositoryImpl(TaskDataSource(client));
  var response = await taskService.getTask(id);

  if (response.isSuccessful) {
    var task = response.toSuccess().body;
    task.done = true;
    await taskService.update(task);

    await updateWidget();

    //Call app if opened to update view
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(
      _actionDonePortName,
    );

    if (sendPort != null) {
      sendPort.send(task.id);
    }
  }
}

class NotificationHandler {
  final ReceivePort _receivePort = ReceivePort();
  final List<Function()> _taskChangedListener = List.empty(growable: true);

  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      FlutterLocalNotificationsPlugin();

  final String _doneActionLabel;
  final String _channelDueName;
  final String _channelReminderName;
  final String _channelDescription;
  final String _dueFallbackBody;
  final String _reminderFallbackBody;
  final String _testNotificationTitle;
  final String _testNotificationBody;

  late final AndroidNotificationDetails androidSpecificsDueDate;
  late final AndroidNotificationDetails androidSpecificsReminders;
  late final DarwinNotificationDetails iOSSpecifics;
  late final NotificationDetails platformChannelSpecificsDueDate;
  late final NotificationDetails platformChannelSpecificsReminders;

  NotificationHandler({
    String doneActionLabel = 'Erledigt',
    String channelDueName = 'Fälligkeits-Benachrichtigungen',
    String channelReminderName = 'Erinnerungs-Benachrichtigungen',
    String channelDescription =
        'Benachrichtigungen für fällige Aufgaben und Erinnerungen',
    String dueFallbackBody = 'Fällig.',
    String reminderFallbackBody = 'Erinnerung',
    String testNotificationTitle = 'Test-Benachrichtigung',
    String testNotificationBody = 'Dies ist eine Test-Benachrichtigung',
  })  : _doneActionLabel = doneActionLabel,
        _channelDueName = channelDueName,
        _channelReminderName = channelReminderName,
        _channelDescription = channelDescription,
        _dueFallbackBody = dueFallbackBody,
        _reminderFallbackBody = reminderFallbackBody,
        _testNotificationTitle = testNotificationTitle,
        _testNotificationBody = testNotificationBody {
    androidSpecificsDueDate = AndroidNotificationDetails(
      "Vikunja1",
      _channelDueName,
      channelDescription: _channelDescription,
      icon: 'vikunja_notification_logo',
      importance: Importance.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(_notificationActionDone, _doneActionLabel),
      ],
    );
    androidSpecificsReminders = AndroidNotificationDetails(
      "Vikunja2",
      _channelReminderName,
      channelDescription: _channelDescription,
      icon: 'vikunja_notification_logo',
      importance: Importance.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(_notificationActionDone, _doneActionLabel),
      ],
    );
    iOSSpecifics = DarwinNotificationDetails(
      categoryIdentifier: 'doneCategory',
    );
    platformChannelSpecificsDueDate = NotificationDetails(
      android: androidSpecificsDueDate,
      iOS: iOSSpecifics,
    );
    platformChannelSpecificsReminders = NotificationDetails(
      android: androidSpecificsReminders,
      iOS: iOSSpecifics,
    );
  }

  Future<void> initNotifications() async {
    await _initNotifications();

    initBackgroundCommunication();

    requestIOSPermissions();
    await _requestAndroidExactAlarmPermission();
  }

  Future<void> _requestAndroidExactAlarmPermission() async {
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    if (canSchedule != true) {
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<void> _initNotifications() async {
    var initializationSettingsAndroid = AndroidInitializationSettings(
      'vikunja_logo',
    );
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'doneCategory',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _notificationActionDone,
              _doneActionLabel,
            ),
          ],
        ),
      ],
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    developer.log("Notifications initialised successfully");
  }

  void initBackgroundCommunication() {
    IsolateNameServer.removePortNameMapping(_actionDonePortName);

    final ok = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _actionDonePortName,
    );
    if (!ok) {
      developer.log('Failed to register $_actionDonePortName');
    }

    _receivePort.listen((dynamic message) {
      for (var it in _taskChangedListener) {
        it.call();
      }
    });
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String description,
    FlutterLocalNotificationsPlugin notifsPlugin,
    DateTime scheduledTime,
    String currentTimeZone,
    NotificationDetails platformChannelSpecifics,
  ) async {
    tz.TZDateTime time = tz.TZDateTime.from(
      scheduledTime,
      tz.getLocation(currentTimeZone),
    );

    if (time.difference(tz.TZDateTime.now(tz.getLocation(currentTimeZone))) <
        Duration.zero) {
      return;
    }

    developer.log("scheduled notification for time $time");

    await notifsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: description,
      scheduledDate: time,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id.toString(),
    );
  }

  void sendTestNotification() {
    notificationsPlugin.show(
      id: Random().nextInt(10000000),
      title: _testNotificationTitle,
      body: _testNotificationBody,
      notificationDetails: platformChannelSpecificsReminders,
    );
  }

  void requestIOSPermissions() {
    notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDueNotifications(TaskRepository taskService) async {
    var taskResponse = await taskService.getByFilterString(
      "done=false && (due_date > now || reminders > now)",
      {
        "filter_include_nulls": ["false"],
      },
    );

    if (taskResponse.isSuccessful) {
      // Nur noch geplante (pending) Notifications canceln, nicht alle.
      // Bereits angezeigte Benachrichtigungen bleiben im Shade erhalten,
      // bis der User sie selbst bearbeitet oder wegwischt.
      final pending = await notificationsPlugin.pendingNotificationRequests();
      for (final p in pending) {
        await notificationsPlugin.cancel(id: p.id);
      }
      for (final task in taskResponse.toSuccess().body) {
        if (task.done) continue;
        for (final reminder in task.reminderDates) {
          // Title = Task-Name, Body = Beschreibung (oder Fallback)
          final reminderBody = (task.description.isNotEmpty)
              ? stripHtml(task.description)
              : _reminderFallbackBody;
          await scheduleNotification(
            (reminder.reminder.millisecondsSinceEpoch / 1000).floor(),
            task.title,
            reminderBody,
            notificationsPlugin,
            reminder.reminder,
            await FlutterTimezone.getLocalTimezone(),
            platformChannelSpecificsReminders,
          );
        }
        // Nur Due-Notification schedulen, wenn keine Erinnerungen gesetzt sind
        if (task.hasDueDate && task.reminderDates.isEmpty) {
          // Title = Task-Name, Body = Beschreibung (oder Fallback)
          final dueBody = (task.description.isNotEmpty)
              ? stripHtml(task.description)
              : _dueFallbackBody;
          await scheduleNotification(
            task.id,
            task.title,
            dueBody,
            notificationsPlugin,
            task.dueDate!,
            await FlutterTimezone.getLocalTimezone(),
            platformChannelSpecificsDueDate,
          );
        }
      }
      developer.log("notifications scheduled successfully");
    }
  }

  void addListener(Function() listener) {
    _taskChangedListener.add(listener);
  }

  void removeListener(Function() listener) {
    _taskChangedListener.remove(listener);
  }
}