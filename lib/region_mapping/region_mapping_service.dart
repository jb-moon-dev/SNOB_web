// ================================================================
// SNOB Region Mapping Service
// ================================================================
//
// TourAPI 지역 코드
//
//   regionCode  : 2자리
//   sigunguCode : 3자리
//
//                  ↓
//
//        RegionMappingService
//
//                  ↓
//
// 관광지 집중률 API 지역 코드
//
//   areaCd   : 시도 코드
//   signguCd : 5자리 시군구 코드
//
// ================================================================
//
// 일반 지역:
//
//   TourAPI
//   43 / 112
//   충청북도 / 청주시 서원구
//
//              ↓
//
//   집중률 API
//   43 / 43112
//   충청북도 / 청주시 서원구
//
//
//
// 행정구역 개편 등 예외:
//
//   인천
//   전남광주통합특별시
//   화성시
//
// ================================================================


class RegionMappingService {
  // ==============================================================
  // 메인 매핑
  // ==============================================================

  static List<RegionQuery> getQueryRegions({
    required String regionCode,
    required String sigunguCode,
    required String regionName,
  }) {
    final String normalizedRegionCode =
        regionCode.trim();

    final String normalizedSigunguCode =
        sigunguCode.trim();

    final String normalizedRegionName =
        _normalizeName(regionName);

    print('');
    print('==================================================');
    print('SNOB 지역 코드 매핑');
    print('==================================================');
    print('추천 지역 : $regionName');
    print(
      'TourAPI   : '
      '$normalizedRegionCode / '
      '$normalizedSigunguCode',
    );

    // ============================================================
    // 1. 인천 행정구역 개편
    // ============================================================

    final List<RegionQuery>? incheonResult =
        _getIncheonMapping(
      regionName: normalizedRegionName,
    );

    if (incheonResult != null) {
      _printMappingResult(incheonResult);
      return incheonResult;
    }

    // ============================================================
    // 2. 전남광주통합특별시
    // ============================================================

    final List<RegionQuery>? integratedResult =
        _getIntegratedJeonnamGwangjuMapping(
      regionName: normalizedRegionName,
      sigunguCode: normalizedSigunguCode,
    );

    if (integratedResult != null) {
      _printMappingResult(integratedResult);
      return integratedResult;
    }

    // ============================================================
    // 3. 화성시 행정구역 개편
    // ============================================================

    final List<RegionQuery>? hwaseongResult =
        _getHwaseongMapping(
      regionName: normalizedRegionName,
    );

    if (hwaseongResult != null) {
      _printMappingResult(hwaseongResult);
      return hwaseongResult;
    }

    // ============================================================
    // 4. 세종특별자치시
    // ============================================================

    if (normalizedRegionCode == '36') {
      final List<RegionQuery> result = [
        RegionQuery(
          areaCd: '36',
          signguCd: '36110',
          regionName: regionName,
          reason: '세종특별자치시 전체 지역 매핑',
        ),
      ];

      _printMappingResult(result);

      return result;
    }

    // ============================================================
    // 5. 일반 지역
    // ============================================================

    final String? congestionSigunguCode =
        _convertGeneralSigunguCode(
      regionCode: normalizedRegionCode,
      sigunguCode: normalizedSigunguCode,
    );

    if (congestionSigunguCode == null) {
      print('');
      print(
        '❌ 지역 매핑 실패',
      );
      print(
        '지역명: $regionName',
      );
      print(
        'TourAPI: '
        '$normalizedRegionCode / '
        '$normalizedSigunguCode',
      );
      print('==================================================');

      return [];
    }

    final List<RegionQuery> result = [
      RegionQuery(
        areaCd: normalizedRegionCode,
        signguCd: congestionSigunguCode,
        regionName: regionName,
        reason: '일반 지역 코드 자동 변환',
      ),
    ];

    _printMappingResult(result);

    return result;
  }

  // ==============================================================
  // 일반 지역 코드 변환
  // ==============================================================

  static String? _convertGeneralSigunguCode({
    required String regionCode,
    required String sigunguCode,
  }) {
    // ------------------------------------------------------------
    // 코드가 없는 경우
    // ------------------------------------------------------------

    if (regionCode.isEmpty ||
        sigunguCode.isEmpty) {
      return null;
    }

    // ------------------------------------------------------------
    // 숫자인지 확인
    // ------------------------------------------------------------

    if (!RegExp(
      r'^\d+$',
    ).hasMatch(sigunguCode)) {
      return null;
    }

    // ------------------------------------------------------------
    // 이미 5자리 코드라면 그대로 사용
    // ------------------------------------------------------------

    if (sigunguCode.length == 5) {
      return sigunguCode;
    }

    // ------------------------------------------------------------
    // TourAPI 시군구 코드 = 3자리
    //
    // 예:
    //
    // 200 → 200
    // 500 → 500
    // 112 → 112
    //
    // ------------------------------------------------------------

    final String paddedSigunguCode =
        sigunguCode.padLeft(
      3,
      '0',
    );

    // ------------------------------------------------------------
    // 시도 코드 + 시군구 코드
    //
    // 11 + 200 = 11200
    // 41 + 500 = 41500
    // 43 + 112 = 43112
    // 47 + 250 = 47250
    // ------------------------------------------------------------

    final String congestionCode =
        '$regionCode$paddedSigunguCode';

    // ------------------------------------------------------------
    // 집중률 API 시군구 코드 = 5자리
    // ------------------------------------------------------------

    if (congestionCode.length != 5) {
      return null;
    }

    return congestionCode;
  }

  // ==============================================================
  // 인천광역시
  // ==============================================================

  static List<RegionQuery>? _getIncheonMapping({
    required String regionName,
  }) {
    if (!regionName.contains('인천광역시')) {
      return null;
    }

    // ------------------------------------------------------------
    // 영종구
    //
    // TourAPI
    // 28 / 155 / 영종구
    //
    // 집중률 API
    // 28 / 28110 / 중구
    // ------------------------------------------------------------

    if (regionName.contains('영종구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28110',
          regionName: regionName,
          reason:
              '영종구 → 기존 인천 중구 집중률 데이터',
        ),
      ];
    }

    // ------------------------------------------------------------
    // 제물포구
    //
    // TourAPI
    // 28 / 125 / 제물포구
    //
    // 집중률 API
    // 28 / 28110 / 중구
    // ------------------------------------------------------------

    if (regionName.contains('제물포구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28110',
          regionName: regionName,
          reason:
              '제물포구 → 기존 인천 중구 집중률 데이터',
        ),
      ];
    }

    // ------------------------------------------------------------
    // 서해구
    //
    // TourAPI
    // 28 / 275 / 서해구
    //
    // 집중률 API
    // 28 / 28260 / 서구
    // ------------------------------------------------------------

    if (regionName.contains('서해구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28260',
          regionName: regionName,
          reason:
              '서해구 → 기존 인천 서구 집중률 데이터',
        ),
      ];
    }

    // ------------------------------------------------------------
    // 검단구
    //
    // TourAPI
    // 28 / 290 / 검단구
    //
    // 집중률 API
    // 28 / 28260 / 서구
    // ------------------------------------------------------------

    if (regionName.contains('검단구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28260',
          regionName: regionName,
          reason:
              '검단구 → 기존 인천 서구 집중률 데이터',
        ),
      ];
    }

    // ------------------------------------------------------------
    // 나머지 인천 지역
    //
    // 일반 규칙:
    //
    // 28 + 3자리
    //
    // 예:
    // 185 → 28185
    // 200 → 28200
    // 237 → 28237
    // 245 → 28245
    // 710 → 28710
    // 720 → 28720
    //
    // 따라서 null을 반환해서
    // 일반 매핑 로직으로 넘긴다.
    // ------------------------------------------------------------

    return null;
  }

  // ==============================================================
  // 전남광주통합특별시
  // ==============================================================

  static List<RegionQuery>?
      _getIntegratedJeonnamGwangjuMapping({
    required String regionName,
    required String sigunguCode,
  }) {
    if (!regionName.contains(
      '전남광주통합특별시',
    )) {
      return null;
    }

    // ============================================================
    // 기존 광주광역시
    // ============================================================
    //
    // TourAPI
    //
    // 12 / 210 → 동구
    // 12 / 240 → 서구
    // 12 / 270 → 남구
    // 12 / 300 → 북구
    // 12 / 330 → 광산구
    //
    // 집중률 API
    //
    // 29 / 29110
    // 29 / 29140
    // 29 / 29155
    // 29 / 29170
    // 29 / 29200
    // ============================================================

    const Map<String, String> gwangjuMapping = {
      '210': '29110',
      '240': '29140',
      '270': '29155',
      '300': '29170',
      '330': '29200',
    };

    final String? gwangjuSigunguCode =
        gwangjuMapping[sigunguCode];

    if (gwangjuSigunguCode != null) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: gwangjuSigunguCode,
          regionName: regionName,
          reason:
              '전남광주통합특별시 기존 광주광역시 지역 매핑',
        ),
      ];
    }

    // ============================================================
    // 기존 전라남도
    // ============================================================
    //
    // TourAPI:
    //
    // 12 / 110 / 목포시
    // 12 / 130 / 여수시
    // 12 / 150 / 순천시
    // 12 / 170 / 나주시
    // 12 / 190 / 광양시
    // ...
    //
    // 집중률 API:
    //
    // 46 / 46110
    // 46 / 46130
    // 46 / 46150
    // 46 / 46170
    // 46 / 46230
    // ...
    //
    // 전남의 경우 기존 3자리 시군구 코드 앞에
    // 46을 붙이는 형태를 사용한다.
    // ============================================================

    // ============================================================

// 기존 전라남도 지역

// ============================================================



const Map<String, String> jeonnamMapping = {

  '110': '46110', // 목포시

  '130': '46130', // 여수시

  '150': '46150', // 순천시

  '170': '46170', // 나주시

  '190': '46230', // 광양시

};



final String? jeonnamSigunguCode =

    jeonnamMapping[sigunguCode];



if (jeonnamSigunguCode != null) {

  return [

    RegionQuery(

      areaCd: '46',

      signguCd: jeonnamSigunguCode,

      regionName: regionName,

      reason:

          '전남광주통합특별시 기존 전라남도 지역 매핑',

    ),

  ];

}

    return [];
  }

  // ==============================================================
  // 화성시 행정구역 개편
  // ==============================================================

  static List<RegionQuery>? _getHwaseongMapping({
    required String regionName,
  }) {
    final bool isHwaseong =
        regionName.contains('화성시') ||
        regionName.contains('만세구') ||
        regionName.contains('효행구') ||
        regionName.contains('병점구') ||
        regionName.contains('동탄구');

    if (!isHwaseong) {
      return null;
    }

    // ------------------------------------------------------------
    // TourAPI
    //
    // 41 / 590 → 화성시
    // 41 / 591 → 만세구
    // 41 / 593 → 효행구
    // 41 / 595 → 병점구
    // 41 / 597 → 동탄구
    //
    // 집중률 API
    //
    // 41 / 41590 → 기존 화성시
    //
    // ------------------------------------------------------------

    return [
      RegionQuery(
        areaCd: '41',
        signguCd: '41590',
        regionName: regionName,
        reason:
            '화성시 및 신설 구 → 기존 화성시 집중률 데이터',
      ),
    ];
  }

  // ==============================================================
  // 결과 출력
  // ==============================================================

  static void _printMappingResult(
    List<RegionQuery> queries,
  ) {
    print('');

    if (queries.isEmpty) {
      print(
        '❌ 매핑 결과 없음',
      );

      print('==================================================');

      return;
    }

    print(
      '✅ 지역 매핑 성공',
    );

    for (final RegionQuery query
        in queries) {
      print(
        '   areaCd   : ${query.areaCd}',
      );

      print(
        '   signguCd : ${query.signguCd}',
      );

      print(
        '   지역명   : ${query.regionName}',
      );

      print(
        '   이유     : ${query.reason}',
      );
    }

    print('==================================================');
  }

  // ==============================================================
  // 지역명 정규화
  // ==============================================================

  static String _normalizeName(
    String name,
  ) {
    return name
        .replaceAll(' ', '')
        .trim();
  }
}


// ================================================================
// 관광지 집중률 API 조회 지역
// ================================================================

class RegionQuery {
  final String areaCd;
  final String signguCd;
  final String regionName;
  final String reason;

  const RegionQuery({
    required this.areaCd,
    required this.signguCd,
    required this.regionName,
    required this.reason,
  });

  @override
  String toString() {
    return '''
RegionQuery(
  areaCd: $areaCd,
  signguCd: $signguCd,
  regionName: $regionName,
  reason: $reason,
)
''';
  }
}
