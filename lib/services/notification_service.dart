import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles all local notification scheduling for SpendWise.
///
/// Call [init] once at app startup (before [runApp]).
/// Call [requestPermission] once after the user completes setup.
/// Notifications are automatically rescheduled on each app start.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'spendwise_reminders';
  static const String _channelName = 'Expense Reminders';
  static const String _channelDesc =
      'Daily reminders to log your meals and expenses';

  // Fixed notification IDs — never reuse these for other purposes.
  static const int _idBreakfast = 1;
  static const int _idLunch = 2;
  static const int _idDinner = 3;
  static const int _idSummary = 4;

  // ─────────────────────────────────────────────────────────────────── init ──

  /// Initialises the plugin and timezone database.
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> init() async {
    // Load all timezone data and set device local timezone.
    tz.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      // localTz could be a String or TimezoneInfo depending on the package version
      final tzName = (localTz is String) ? localTz : (localTz as dynamic).name ?? localTz.toString();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Fallback: UTC. Notifications will still fire, just at wrong local time
      // in edge cases — acceptable degradation.
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
  }

  // ────────────────────────────────────────────────────── permission request ──

  /// Requests the POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted (or if the platform doesn't need it).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  // ────────────────────────────────────────────────────── schedule / cancel ──

  /// Schedules (or re-schedules) all 4 daily reminders.
  /// Safe to call multiple times — each call replaces the previous schedule.
  static Future<void> scheduleAll() async {
    await _schedule(_idBreakfast, '🍳 Did you add your breakfast expense?',
        hour: 9, minute: 0);
    await _schedule(_idLunch, '🍱 Did you add your lunch expense?',
        hour: 14, minute: 30);
    await _schedule(_idDinner, '🍽️ Did you add your dinner expense?',
        hour: 20, minute: 30);
    await _schedule(_idSummary, '📝 Have you added all of today\'s expenses?',
        hour: 21, minute: 45);
  }

  /// Cancels all 4 daily reminders.
  static Future<void> cancelAll() async {
    await _plugin.cancel(id: _idBreakfast);
    await _plugin.cancel(id: _idLunch);
    await _plugin.cancel(id: _idDinner);
    await _plugin.cancel(id: _idSummary);
  }

  // ─────────────────────────────────────────────────────────────── helpers ──

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    ),
  );

  static Future<void> _schedule(
    int id,
    String body, {
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // If the time has already passed today, start from tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'SpendWise',
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }
}
