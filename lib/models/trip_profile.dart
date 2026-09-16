import 'dart:convert';

/// 사용자의 여행 성향 정보를 저장하는 모델.
///
/// personality test 결과를 나중에 마이페이지,
/// 여행 기록 등에 다시 사용할 수 있도록 별도의 모델로 관리한다.
class TripProfile {
  final double nature;
  final double city;
  final double people;

  final String? recommendedRegion;

  final DateTime createdAt;

  const TripProfile({
    required this.nature,
    required this.city,
    required this.people,
    this.recommendedRegion,
    required this.createdAt,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'nature': nature,
      'city': city,
      'people': people,
      'recommendedRegion': recommendedRegion,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON에서 생성
  factory TripProfile.fromJson(Map<String, dynamic> json) {
    return TripProfile(
      nature: (json['nature'] as num?)?.toDouble() ?? 0.0,
      city: (json['city'] as num?)?.toDouble() ?? 0.0,
      people: (json['people'] as num?)?.toDouble() ?? 0.0,
      recommendedRegion: json['recommendedRegion']?.toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory TripProfile.fromJsonString(String source) {
    return TripProfile.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  TripProfile copyWith({
    double? nature,
    double? city,
    double? people,
    String? recommendedRegion,
    DateTime? createdAt,
  }) {
    return TripProfile(
      nature: nature ?? this.nature,
      city: city ?? this.city,
      people: people ?? this.people,
      recommendedRegion:
          recommendedRegion ?? this.recommendedRegion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

