// lib/services/workout_notification_service.dart
//
// Persistent interactive notification shown while a session is running.
// Tapping Pause/Reprendre sends a broadcast that SessionPlayerScreen listens to.
//
// Setup required:
//   1. pubspec.yaml:  flutter_local_notifications: ^17.0.0
//   2. android/app/src/main/AndroidManifest.xml — add inside <manifest>:
//
//      <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//      And inside <application>:
//      <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
//      <receiver android:exported="true"
//                android:name=".WorkoutActionReceiver">
//        <intent-filter>
//          <action android:name="WORKOUT_PAUSE"/>
//          <action android:name="WORKOUT_RESUME"/>
//          <action android:name="WORKOUT_STOP"/>
//        </intent-filter>
//      </receiver>

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WorkoutNotificationService {
  static const _notifId = 42;
  static const _channelId = 'workout_channel';
  static const _channelName = 'Séance en cours';

  static const actionPause  = 'WORKOUT_PAUSE';
  static const actionResume = 'WORKOUT_RESUME';
  static const actionStop   = 'WORKOUT_STOP';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Call once at app startup (e.g. in main.dart before runApp).
  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Show or update the persistent notification.
  static Future<void> show({
    required String sessionName,
    required String exerciseName,
    required int round,
    required int totalRounds,
    required int exerciseIndex,
    required int totalExercises,
    required bool paused,
  }) async {
    final statusLine = paused
        ? '⏸ En pause'
        : 'Exercice ${exerciseIndex + 1}/$totalExercises · Tour $round/$totalRounds';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Contrôlez votre séance depuis la barre de notifications',
      importance: Importance.low,      // silent — no sound, no heads-up
      priority: Priority.low,
      ongoing: true,                   // can't be swiped away
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.workout,
      actions: [
        AndroidNotificationAction(
          paused ? actionResume : actionPause,
          paused ? '▶ Reprendre' : '⏸ Pause',
          showsUserInterface: true,    // brings app to foreground
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          actionStop,
          '✕ Arrêter',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      _notifId,
      sessionName,
      '${paused ? "⏸ En pause" : "▶ En cours"} · $exerciseName\n$statusLine',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Dismiss the notification (call when session ends or screen is closed).
  static Future<void> dismiss() async {
    await _plugin.cancel(_notifId);
  }
}