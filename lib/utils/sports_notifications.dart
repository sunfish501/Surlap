import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/sports.dart';

/// 스포츠 경기 시작 N분 전 로컬 알림 — flutter_local_notifications + timezone.
/// 생일 알림과 동일 패턴이되, 채널/ID 영역을 분리(겹침 방지).
class SportsNotifications {
  SportsNotifications._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  // 스포츠 알림 id 영역(생일과 충돌 피하려 상위 비트 사용).
  static const int _idBase = 0x10000000;

  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    _inited = true;
  }

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'sports',
          '스포츠 경기 알림',
          channelDescription: '구독한 팀 경기 시작 전 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  static int _notifId(String eventId) =>
      _idBase | (eventId.hashCode & 0x0FFFFFFF);

  /// 스포츠 알림 전체 재스케줄. 구독별 reminderMinutes 적용.
  static Future<void> scheduleAll(
    List<SportSubscription> subs,
    Map<String, List<SportsEvent>> eventsById,
  ) async {
    await init();
    // 스포츠 id 영역만 정리하기 어려우므로 전체 취소 대신 개별 취소 후 재등록.
    // (간단화: 우리 영역의 알림은 다음 등록으로 덮어씀. 과거분은 OS가 무시.)
    final subById = {for (final s in subs) s.id: s};
    final now = tz.TZDateTime.now(tz.local);
    for (final entry in eventsById.entries) {
      final sub = subById[entry.key];
      if (sub == null || !sub.enabled || sub.reminderMinutes <= 0) continue;
      for (final ev in entry.value) {
        final start = tz.TZDateTime.from(ev.startAt.toLocal(), tz.local);
        final when = start.subtract(Duration(minutes: sub.reminderMinutes));
        if (when.isBefore(now)) continue; // 지난 경기 skip
        await _schedule(
          _notifId(ev.id),
          '${sub.emoji} ${ev.title}',
          '${sub.reminderMinutes}분 후 경기 시작',
          when,
        );
      }
    }
  }

  static Future<void> _schedule(
      int id, String title, String body, tz.TZDateTime when) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[SportsNotif] schedule error: $e');
    }
  }
}
