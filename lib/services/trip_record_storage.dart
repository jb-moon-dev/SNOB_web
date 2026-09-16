import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// 여행 기록 데이터
/// ============================================================

class TripRecord {
  final String regionName;

  /// 기록이 저장된 날짜
  final DateTime createdAt;

  /// 여행 시작일
  final DateTime startDate;

  /// 여행 종료일
  final DateTime endDate;

  /// 여행 일기
  final String diary;

  /// 여행 사진 경로
  final List<String> photoPaths;

  /// 여행 당시의 성향
  final String? personalityType;

  /// 추천 지역
  final String? recommendedRegion;

  /// 방문 장소 이름
  final List<String> visitedPlaces;

  TripRecord({
    required this.regionName,
    DateTime? createdAt,

    /// 시작일을 따로 지정하지 않으면
    /// 기록 생성일을 사용
    DateTime? startDate,

    /// 종료일을 따로 지정하지 않으면
    /// 시작일을 사용
    DateTime? endDate,

    this.diary = '',
    List<String>? photoPaths,
    this.personalityType,
    this.recommendedRegion,
    List<String>? visitedPlaces,
  })  : createdAt = createdAt ?? DateTime.now(),
        startDate = startDate ?? createdAt ?? DateTime.now(),
        endDate = endDate ?? startDate ?? createdAt ?? DateTime.now(),
        photoPaths = photoPaths ?? [],
        visitedPlaces = visitedPlaces ?? [];

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'regionName': regionName,

      // 기존 데이터
      'createdAt': createdAt.toIso8601String(),

      // 새로 추가된 여행 기간
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),

      'diary': diary,
      'photoPaths': photoPaths,
      'personalityType': personalityType,
      'recommendedRegion': recommendedRegion,
      'visitedPlaces': visitedPlaces,
    };
  }

  factory TripRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    // ----------------------------------------------------------
    // 기존 기록의 createdAt
    // ----------------------------------------------------------

    final createdAt =
        DateTime.tryParse(
              json['createdAt'] as String? ?? '',
            ) ??
            DateTime.now();

    // ----------------------------------------------------------
    // 여행 시작일
    //
    // 새 기록에는 startDate가 존재하고,
    // 기존 기록에는 없을 수 있음.
    //
    // 기존 기록이라면 createdAt을 사용.
    // ----------------------------------------------------------

    final startDate =
        DateTime.tryParse(
              json['startDate'] as String? ?? '',
            ) ??
            createdAt;

    // ----------------------------------------------------------
    // 여행 종료일
    //
    // 새 기록에는 endDate가 존재하고,
    // 기존 기록에는 없을 수 있음.
    //
    // 기존 기록이라면 startDate를 사용.
    // ----------------------------------------------------------

    final endDate =
        DateTime.tryParse(
              json['endDate'] as String? ?? '',
            ) ??
            startDate;

    return TripRecord(
      regionName:
          json['regionName'] as String? ?? '',

      createdAt: createdAt,

      startDate: startDate,

      endDate: endDate,

      diary:
          json['diary'] as String? ?? '',

      photoPaths:
          (json['photoPaths'] as List?)
                  ?.map(
                    (e) => e.toString(),
                  )
                  .toList() ??
              [],

      personalityType:
          json['personalityType'] as String?,

      recommendedRegion:
          json['recommendedRegion'] as String?,

      visitedPlaces:
          (json['visitedPlaces'] as List?)
                  ?.map(
                    (e) => e.toString(),
                  )
                  .toList() ??
              [],
    );
  }

  String encode() {
    return jsonEncode(toJson());
  }

  factory TripRecord.decode(
    String value,
  ) {
    final decoded = jsonDecode(value);

    return TripRecord.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}

/// ============================================================
/// 여행 기록 저장소
/// ============================================================

class TripRecordStorage {
  static const String _key = 'trip_records';

  // ============================================================
  // 전체 기록 불러오기
  // ============================================================

  static Future<List<TripRecord>> loadRecords() async {
    final prefs =
        await SharedPreferences.getInstance();

    final source =
        prefs.getString(_key);

    if (source == null || source.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (e) => TripRecord.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 기록 저장
  // ============================================================

  static Future<void> saveRecord(
    TripRecord record,
  ) async {
    final records =
        await loadRecords();

    records.insert(0, record);

    await _saveAll(records);
  }

  // ============================================================
  // 기록 수정
  // ============================================================

  static Future<void> updateRecord(
    int index,
    TripRecord record,
  ) async {
    final records =
        await loadRecords();

    if (index < 0 ||
        index >= records.length) {
      return;
    }

    records[index] = record;

    await _saveAll(records);
  }

  // ============================================================
  // 기록 삭제
  // ============================================================

  static Future<void> deleteRecord(
    int index,
  ) async {
    final records =
        await loadRecords();

    if (index < 0 ||
        index >= records.length) {
      return;
    }

    records.removeAt(index);

    await _saveAll(records);
  }

  // ============================================================
  // 전체 삭제
  // ============================================================

  static Future<void> deleteAll() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }

  // ============================================================
  // 내부 저장
  // ============================================================

  static Future<void> _saveAll(
    List<TripRecord> records,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        records
            .map(
              (e) => e.toJson(),
            )
            .toList(),
      ),
    );
  }
}