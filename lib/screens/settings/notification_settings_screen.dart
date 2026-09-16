import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationSettingsScreen
    extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen>
      createState() =>
          _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ============================================================
  // 알림 플러그인
  // ============================================================

  final FlutterLocalNotificationsPlugin
      _notifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // 알림 ID
  // ============================================================

  static const int recommendationNotificationId = 1001;
  static const int reminderNotificationId = 1002;
  static const int snobNotificationId = 1003;

  // ============================================================
  // 알림 설정
  // ============================================================

  bool travelRecommendation = true;
  bool travelReminder = true;
  bool snobMessage = true;

  bool isLoading = true;

  // ============================================================
  // 초기화
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeNotifications();
  }

  // ============================================================
  // 알림 초기화
  // ============================================================

  Future<void> _initializeNotifications() async {
    // 시간대 데이터 초기화
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    // Android 알림 권한 요청
    final androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation
        ?.requestNotificationsPermission();

    // 저장된 설정 불러오기
    await _loadSettings();

    // 현재 설정에 맞게 알림 예약
    await _syncNotifications();
  }

  // ============================================================
  // 저장된 설정 불러오기
  // ============================================================

  Future<void> _loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      travelRecommendation =
          prefs.getBool(
                'notification_recommendation',
              ) ??
              true;

      travelReminder =
          prefs.getBool(
                'notification_reminder',
              ) ??
              true;

      snobMessage =
          prefs.getBool(
                'notification_snob',
              ) ??
              true;

      isLoading = false;
    });
  }

  // ============================================================
  // 설정 저장 + 실제 알림 변경
  // ============================================================

  Future<void> _setValue(
    String key,
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      key,
      value,
    );

    // 여행지 추천
    if (key ==
        'notification_recommendation') {
      if (value) {
        await _scheduleRecommendation();
      } else {
        await _notifications.cancel(
          id: recommendationNotificationId,
        );
      }
    }

    // 여행 일정
    if (key ==
        'notification_reminder') {
      if (value) {
        await _scheduleTravelReminder();
      } else {
        await _notifications.cancel(
          id: reminderNotificationId,
        );
      }
    }

    // 오늘의 SNOB
    if (key ==
        'notification_snob') {
      if (value) {
        await _scheduleSnobMessage();
      } else {
        await _notifications.cancel(
          id: snobNotificationId,
        );
      }
    }
  }

  // ============================================================
  // 현재 설정에 맞게 알림 전체 동기화
  // ============================================================

  Future<void> _syncNotifications() async {
    if (travelRecommendation) {
      await _scheduleRecommendation();
    } else {
      await _notifications.cancel(
        id: recommendationNotificationId,
      );
    }

    if (travelReminder) {
      await _scheduleTravelReminder();
    } else {
      await _notifications.cancel(
        id: reminderNotificationId,
      );
    }

    if (snobMessage) {
      await _scheduleSnobMessage();
    } else {
      await _notifications.cancel(
        id: snobNotificationId,
      );
    }
  }

  // ============================================================
  // 여행지 추천 알림
  // 매일 오전 10시
  // ============================================================

  Future<void> _scheduleRecommendation() async {
    await _notifications.cancel(
      id: recommendationNotificationId,
    );

    final scheduledDate =
        _nextInstanceOfTime(
      10,
      0,
    );

    const androidDetails =
        AndroidNotificationDetails(
      'snob_recommendation',
      '여행지 추천',
      channelDescription:
          'SNOB 맞춤 여행지 추천 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: recommendationNotificationId,
      title: '오늘의 여행지 추천 🌿',
      body: '오늘 당신에게 어울리는 여행지를 확인해보세요.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }

  // ============================================================
  // 여행 일정 알림
  // 매일 오전 8시
  // ============================================================

  Future<void> _scheduleTravelReminder() async {
    await _notifications.cancel(
      id: reminderNotificationId,
    );

    final scheduledDate =
        _nextInstanceOfTime(
      8,
      0,
    );

    const androidDetails =
        AndroidNotificationDetails(
      'snob_travel_reminder',
      '여행 일정 알림',
      channelDescription:
          'SNOB 여행 일정 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: reminderNotificationId,
      title: '오늘의 SNOB 여행 🗺️',
      body: '오늘의 여행 일정을 확인해보세요.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }

  // ============================================================
  // 오늘의 SNOB 알림
  // 매일 오후 9시
  // ============================================================

  Future<void> _scheduleSnobMessage() async {
    await _notifications.cancel(
      id: snobNotificationId,
    );

    final scheduledDate =
        _nextInstanceOfTime(
      21,
      0,
    );

    final messages = [
      '오늘도 조금 덜 붐비는 여행을 해볼까요?',
      '유명한 곳보다 나만 아는 곳으로 떠나보세요.',
      '사람이 적을수록 여행은 더 특별할 수 있어요.',
      '오늘의 여행은 조금 천천히 걸어보세요.',
      '당신만의 여행지를 찾아보세요.',
    ];

    final index =
        DateTime.now().day %
            messages.length;

    final androidDetails =
        AndroidNotificationDetails(
      'snob_daily_message',
      '오늘의 SNOB',
      channelDescription:
          '매일 새로운 SNOB 여행 문구',
      importance:
          Importance.defaultImportance,
      priority:
          Priority.defaultPriority,
    );

    final notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: snobNotificationId,
      title: '오늘의 SNOB ✨',
      body: messages[index],
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }

  // ============================================================
  // 다음 알림 시간 계산
  // ============================================================

  tz.TZDateTime _nextInstanceOfTime(
    int hour,
    int minute,
  ) {
    final now =
        tz.TZDateTime.now(tz.local);

    var scheduledDate =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 해당 시간이 지났다면 다음 날
    if (scheduledDate
        .isBefore(now)) {
      scheduledDate =
          scheduledDate.add(
        const Duration(days: 1),
      );
    }

    return scheduledDate;
  }

  // ============================================================
  // 테스트 알림
  // ============================================================

  Future<void> _showTestNotification() async {
    const androidDetails =
        AndroidNotificationDetails(
      'snob_test',
      'SNOB 테스트',
      channelDescription:
          'SNOB 알림 테스트',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: 9999,
      title: 'SNOB 알림 테스트 🔔',
      body: '알림이 정상적으로 작동하고 있어요!',
      notificationDetails: notificationDetails,
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                40,
              ),
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 24,
                ),

                _buildSwitch(
                  title: '여행지 추천',
                  subtitle:
                      '나에게 맞는 여행지를 알려드려요.',
                  value:
                      travelRecommendation,
                  onChanged: (value) {
                    setState(() {
                      travelRecommendation =
                          value;
                    });

                    _setValue(
                      'notification_recommendation',
                      value,
                    );
                  },
                ),

                _buildDivider(),

                _buildSwitch(
                  title: '여행 일정 알림',
                  subtitle:
                      '여행 일정과 관련된 알림을 받아요.',
                  value:
                      travelReminder,
                  onChanged: (value) {
                    setState(() {
                      travelReminder =
                          value;
                    });

                    _setValue(
                      'notification_reminder',
                      value,
                    );
                  },
                ),

                _buildDivider(),

                _buildSwitch(
                  title: '오늘의 SNOB',
                  subtitle:
                      '매일 새로운 여행 문구를 받아요.',
                  value:
                      snobMessage,
                  onChanged: (value) {
                    setState(() {
                      snobMessage =
                          value;
                    });

                    _setValue(
                      'notification_snob',
                      value,
                    );
                  },
                ),

                const SizedBox(
                  height: 30,
                ),

                // ------------------------------------------------
                // 테스트 버튼
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _showTestNotification,
                    style:
                        OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      '알림 테스트하기',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // 헤더
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.notifications_none,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'SNOB 알림',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '원하는 알림만 선택해서 받아보세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Switch
  // ============================================================

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Divider
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
    );
  }
}
