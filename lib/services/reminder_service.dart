import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

class ReminderService {
  ReminderService._();

  static final instance = ReminderService._();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String userId, String taskId)? _onReminderTap;
  String? _pendingTapPayload;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_supported || _initialized) return;
    tzdata.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _handleTapPayload(response.payload),
    );
    _initialized = true;
    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _handleTapPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  void setOnReminderTap(void Function(String userId, String taskId) handler) {
    _onReminderTap = handler;
    final payload = _pendingTapPayload;
    if (payload != null) {
      _pendingTapPayload = null;
      _handleTapPayload(payload);
    }
  }

  void clearOnReminderTap() => _onReminderTap = null;

  void _handleTapPayload(String? payload) {
    if (payload == null || !payload.startsWith('taskflow:')) return;
    final parts = payload.split(':');
    if (parts.length != 3) return;
    final handler = _onReminderTap;
    if (handler == null) {
      _pendingTapPayload = payload;
    } else {
      handler(parts[1], parts[2]);
    }
  }

  Future<bool> scheduleTaskReminder({
    required String userId,
    required String taskId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    final id = _notificationId(userId, taskId);
    if (!_supported || reminderAt.isBefore(DateTime.now())) {
      await cancelTaskReminder(userId: userId, taskId: taskId);
      return false;
    }
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool('notificationsEnabled') ?? true)) {
      await cancelTaskReminder(userId: userId, taskId: taskId);
      return false;
    }
    await initialize();
    final permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      await cancelTaskReminder(userId: userId, taskId: taskId);
      return false;
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task reminders',
          channelDescription: 'Reminders for scheduled tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'taskflow:$userId:$taskId',
    );
    return true;
  }

  Future<void> cancelTaskReminder({
    required String userId,
    required String taskId,
  }) async {
    if (!_supported) return;
    await initialize();
    await _notifications.cancel(id: _notificationId(userId, taskId));
  }

  Future<bool> syncTasks({
    required String userId,
    required List<Task> tasks,
    required String reminderTitle,
    required String Function(String) bodyFor,
  }) async {
    if (!_supported) return false;
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool('notificationsEnabled') ?? true)) {
      await _notifications.cancelAll();
      return true;
    }
    await initialize();
    final activeIds = <int>{};
    var allScheduled = true;
    for (final task in tasks) {
      final reminderAt = task.reminderAt;
      if (task.status == TaskStatus.done ||
          reminderAt == null ||
          !reminderAt.isAfter(DateTime.now())) {
        continue;
      }
      activeIds.add(_notificationId(userId, task.id));
      final scheduled = await scheduleTaskReminder(
        userId: userId,
        taskId: task.id,
        title: reminderTitle,
        body: bodyFor(task.title),
        reminderAt: reminderAt,
      );
      allScheduled = allScheduled && scheduled;
    }
    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      if (!activeIds.contains(request.id)) {
        await _notifications.cancel(id: request.id);
      }
    }
    return allScheduled;
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  int _notificationId(String userId, String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in '$userId:$taskId'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
