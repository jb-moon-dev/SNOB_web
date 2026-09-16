import 'dart:convert';

/// ============================================================
/// 여행 일정에 들어가는 하나의 관광지
/// ============================================================

class TravelSpot {
  // ------------------------------------------------------------
  // 기본 정보
  // ------------------------------------------------------------

  final String name;
  final String? category;
  final String? address;

  // 실제 좌표
  final double? latitude;
  final double? longitude;

  // ------------------------------------------------------------
  // SNOB 관련
  // ------------------------------------------------------------

  final double? congestion;
  final double? snobScore;

  // ------------------------------------------------------------
  // 관광지 / 카카오 관련
  // ------------------------------------------------------------

  final String? contentId;

  /// Kakao Local place ID
  final String? kakaoPlaceId;

  /// Kakao Map 상세 URL
  final String? kakaoPlaceUrl;

  // ------------------------------------------------------------
  // 일정 관련
  // ------------------------------------------------------------

  /// 해당 장소의 시작 시간 (자정 기준 분)
  final int? startMinute;

  /// 해당 장소에서 머무르는 시간
  final int durationMinutes;

  /// 이전 장소에서 현재 장소까지 이동시간
  final int travelMinutesFromPrevious;

  const TravelSpot({
    required this.name,
    this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.congestion,
    this.snobScore,
    this.contentId,
    this.kakaoPlaceId,
    this.kakaoPlaceUrl,
    this.startMinute,
    this.durationMinutes = 60,
    this.travelMinutesFromPrevious = 0,
  });

  // ============================================================
  // 복사
  // ============================================================

  TravelSpot copyWith({
    String? name,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    double? congestion,
    double? snobScore,
    String? contentId,
    String? kakaoPlaceId,
    String? kakaoPlaceUrl,
    int? startMinute,
    int? durationMinutes,
    int? travelMinutesFromPrevious,
  }) {
    return TravelSpot(
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      congestion: congestion ?? this.congestion,
      snobScore: snobScore ?? this.snobScore,
      contentId: contentId ?? this.contentId,
      kakaoPlaceId: kakaoPlaceId ?? this.kakaoPlaceId,
      kakaoPlaceUrl: kakaoPlaceUrl ?? this.kakaoPlaceUrl,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      travelMinutesFromPrevious:
          travelMinutesFromPrevious ??
              this.travelMinutesFromPrevious,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'address': address,

      'latitude': latitude,
      'longitude': longitude,

      'congestion': congestion,
      'snobScore': snobScore,

      'contentId': contentId,
      'kakaoPlaceId': kakaoPlaceId,
      'kakaoPlaceUrl': kakaoPlaceUrl,

      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'travelMinutesFromPrevious':
          travelMinutesFromPrevious,
    };
  }

  factory TravelSpot.fromJson(
    Map<String, dynamic> json,
  ) {
    return TravelSpot(
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      address: json['address'] as String?,

      latitude:
          (json['latitude'] as num?)?.toDouble(),
      longitude:
          (json['longitude'] as num?)?.toDouble(),

      congestion:
          (json['congestion'] as num?)?.toDouble(),
      snobScore:
          (json['snobScore'] as num?)?.toDouble(),

      contentId:
          json['contentId'] as String?,

      kakaoPlaceId:
          json['kakaoPlaceId'] as String?,

      kakaoPlaceUrl:
          json['kakaoPlaceUrl'] as String?,

      startMinute:
          _asInt(json['startMinute']),

      durationMinutes:
          _asInt(json['durationMinutes']) ?? 60,

      travelMinutesFromPrevious:
          _asInt(
                json['travelMinutesFromPrevious'],
              ) ??
              0,
    );
  }

  // ============================================================
  // 기존 result_screen.dart 호환용 fromMap
  // ============================================================

  factory TravelSpot.fromMap(
    Map<String, dynamic> map,
  ) {
    return TravelSpot.fromJson(map);
  }

  // ============================================================
  // 기존 코드에서 int/String 등이 섞여 들어오는 경우 대응
  // ============================================================

  static int? _asInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}


/// ============================================================
/// 하루 일정
/// ============================================================

class TravelDay {
  int day;

  List<TravelSpot> spots;

  TravelDay({
    required this.day,
    List<TravelSpot>? spots,
  }) : spots = spots ?? [];

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'spots':
          spots.map((e) => e.toJson()).toList(),
    };
  }

  factory TravelDay.fromJson(
    Map<String, dynamic> json,
  ) {
    return TravelDay(
      day: _asInt(json['day']) ?? 1,
      spots:
          (json['spots'] as List?)
                  ?.map(
                    (e) => TravelSpot.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList() ??
              [],
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}


/// ============================================================
/// 여행 계획
/// ============================================================

class TravelPlan {
  String regionName;

  List<TravelDay> days;

  DateTime updatedAt;

  TravelPlan({
    required this.regionName,
    List<TravelDay>? days,
    DateTime? updatedAt,
  })  : days = days ?? [],
        updatedAt =
            updatedAt ?? DateTime.now();

  // ============================================================
  // 생성
  // ============================================================

  factory TravelPlan.create({
    required String regionName,

    // 기존 result_screen.dart와 호환
    int? dayCount,

    List<TravelDay>? days,

    DateTime? updatedAt,
  }) {
    final count =
        dayCount != null && dayCount > 0
            ? dayCount
            : (days?.length ?? 1);

    return TravelPlan(
      regionName: regionName,
      days: days ??
          List.generate(
            count,
            (index) => TravelDay(
              day: index + 1,
            ),
          ),
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // 전체 관광지 수
  // ============================================================

  int get totalSpotCount {
    return days.fold<int>(
      0,
      (total, day) =>
          total + day.spots.length,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'regionName': regionName,
      'days':
          days.map((e) => e.toJson()).toList(),
      'updatedAt':
          updatedAt.toIso8601String(),
    };
  }

  factory TravelPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    return TravelPlan(
      regionName:
          json['regionName'] as String? ?? '',

      days:
          (json['days'] as List?)
                  ?.map(
                    (e) => TravelDay.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList() ??
              [],

      updatedAt:
          DateTime.tryParse(
                json['updatedAt']
                        as String? ??
                    '',
              ) ??
              DateTime.now(),
    );
  }

  // ============================================================
  // 문자열 저장
  // ============================================================

  String encode() {
    return jsonEncode(toJson());
  }

  factory TravelPlan.decode(
    String value,
  ) {
    final decoded = jsonDecode(value);

    return TravelPlan.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  // 기존 travel_plan_storage.dart 호환
  String toJsonString() {
    return encode();
  }

  factory TravelPlan.fromJsonString(
    String value,
  ) {
    return TravelPlan.decode(value);
  }

  // ============================================================
  // Day 찾기
  // ============================================================

  TravelDay getDay(int dayNumber) {
    while (days.length < dayNumber) {
      days.add(
        TravelDay(
          day: days.length + 1,
        ),
      );
    }

    return days.firstWhere(
      (day) => day.day == dayNumber,
      orElse: () {
        final newDay = TravelDay(
          day: dayNumber,
        );

        days.add(newDay);

        return newDay;
      },
    );
  }

  // ============================================================
  // 관광지 추가
  // ============================================================

  void addSpot(
    TravelSpot spot, {
    int? day,
  }) {
    final targetDay =
        getDay(day ?? 1);

    targetDay.spots.add(spot);

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 관광지 삭제
  // ============================================================

  void removeSpot(
    TravelSpot spot, {
    int? day,
  }) {
    final targetDay =
        getDay(day ?? 1);

    targetDay.spots.remove(spot);

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 이름 기준 삭제
  // ============================================================

  void removeSpotByName(
    String spotName, {
    int? day,
  }) {
    final targetDay =
        getDay(day ?? 1);

    targetDay.spots.removeWhere(
      (spot) => spot.name == spotName,
    );

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 특정 Day의 일정 교체
  // ============================================================

  void replaceDaySpots(
    int day,
    List<TravelSpot> spots,
  ) {
    final targetDay =
        getDay(day);

    targetDay.spots =
        List<TravelSpot>.from(spots);

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 전체 일정 초기화
  // ============================================================

  void clear() {
    for (final day in days) {
      day.spots.clear();
    }

    updatedAt = DateTime.now();
  }
}