class SnobSpot {
  // ==========================================
  // SNOB 내부 관광지 번호
  // ==========================================
  final int? snobSpotNum;

  // ==========================================
  // 한국관광공사 TourAPI 정보
  // ==========================================
  final String contentId;
  final String title;
  final String address;
  final String contentTypeId;

  // 현재 행정구역 정보
  final String lDongRegnCd;
  final String lDongSignguCd;
  final String regionName;

  // 관광지 분류
  final String lclsSystm1;
  final String lclsSystm2;
  final String lclsSystm3;

  // 수정 시간
  final String modifiedTime;

  // 좌표
  final double? latitude;
  final double? longitude;

  // ==========================================
  // 관광지 집중률 API 정보
  // ==========================================
  final double? concentrationRate;
  final String? concentrationBaseYmd;

  // 집중률 API 기준 행정구역
  final String? concentrationAreaCd;
  final String? concentrationAreaNm;
  final String? concentrationSignguCd;
  final String? concentrationSignguNm;

  // ==========================================
  // SNOB 점수
  // ==========================================
  final double? snobScore;

  const SnobSpot({
    this.snobSpotNum,
    required this.contentId,
    required this.title,
    required this.address,
    required this.contentTypeId,
    required this.lDongRegnCd,
    required this.lDongSignguCd,
    required this.regionName,
    required this.lclsSystm1,
    required this.lclsSystm2,
    required this.lclsSystm3,
    required this.modifiedTime,
    this.latitude,
    this.longitude,
    this.concentrationRate,
    this.concentrationBaseYmd,
    this.concentrationAreaCd,
    this.concentrationAreaNm,
    this.concentrationSignguCd,
    this.concentrationSignguNm,
    this.snobScore,
  });

  // ==========================================
  // 집중률 데이터가 붙은 새로운 SnobSpot 생성
  // ==========================================
  SnobSpot copyWith({
    int? snobSpotNum,
    String? contentId,
    String? title,
    String? address,
    String? contentTypeId,
    String? lDongRegnCd,
    String? lDongSignguCd,
    String? regionName,
    String? lclsSystm1,
    String? lclsSystm2,
    String? lclsSystm3,
    String? modifiedTime,
    double? latitude,
    double? longitude,
    double? concentrationRate,
    String? concentrationBaseYmd,
    String? concentrationAreaCd,
    String? concentrationAreaNm,
    String? concentrationSignguCd,
    String? concentrationSignguNm,
    double? snobScore,
  }) {
    return SnobSpot(
      snobSpotNum: snobSpotNum ?? this.snobSpotNum,
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      address: address ?? this.address,
      contentTypeId: contentTypeId ?? this.contentTypeId,
      lDongRegnCd: lDongRegnCd ?? this.lDongRegnCd,
      lDongSignguCd: lDongSignguCd ?? this.lDongSignguCd,
      regionName: regionName ?? this.regionName,
      lclsSystm1: lclsSystm1 ?? this.lclsSystm1,
      lclsSystm2: lclsSystm2 ?? this.lclsSystm2,
      lclsSystm3: lclsSystm3 ?? this.lclsSystm3,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      concentrationRate:
          concentrationRate ?? this.concentrationRate,
      concentrationBaseYmd:
          concentrationBaseYmd ?? this.concentrationBaseYmd,
      concentrationAreaCd:
          concentrationAreaCd ?? this.concentrationAreaCd,
      concentrationAreaNm:
          concentrationAreaNm ?? this.concentrationAreaNm,
      concentrationSignguCd:
          concentrationSignguCd ?? this.concentrationSignguCd,
      concentrationSignguNm:
          concentrationSignguNm ?? this.concentrationSignguNm,
      snobScore: snobScore ?? this.snobScore,
    );
  }

  @override
  String toString() {
    return '''
SnobSpot(
  snobSpotNum: $snobSpotNum,
  contentId: $contentId,
  title: $title,
  regionName: $regionName,
  concentrationRate: $concentrationRate,
  snobScore: $snobScore,
)
''';
  }
}