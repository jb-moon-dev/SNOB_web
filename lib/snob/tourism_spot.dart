class TourismSpot {
  final String contentId;
  final String title;
  final String address;
  final String contentTypeId;

  // 지역 코드
  final String lDongRegnCd;
  final String lDongSignguCd;

  // ⭐ 정확한 지역명
  final String regionName;

  // 관광 분류
  final String lclsSystm1;
  final String lclsSystm2;
  final String lclsSystm3;

  final String modifiedTime;

  // ⭐ 관광지 좌표
  final double? latitude;
  final double? longitude;

  TourismSpot({
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

    // ⭐ 좌표
    required this.latitude,
    required this.longitude,
  });
}