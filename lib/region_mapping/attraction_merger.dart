import '../snob/tourism_spot.dart';


// ================================================================
// SNOB 관광지 병합 서비스
// ================================================================
//
// TourAPI 관광지
//       +
// 관광지 집중률 API 관광지
//       ↓
// 최종 관광지 목록
//
// ---------------------------------------------------------------
//
// 1. TourAPI O + 집중률 O
//    → 실제 집중률 사용
//
// 2. TourAPI O + 집중률 X
//    → 중립 집중률 사용
//
// 3. TourAPI X + 집중률 O
//    → 집중률 API 관광지를 최종 목록에 추가
//
// ---------------------------------------------------------------
//
// ※ 집중률 API 전용 관광지는 contentId가 없으므로
//    contentId를 요구하지 않는다.
// ================================================================


class AttractionMerger {
  // ==============================================================
  // 집중률이 없는 TourAPI 관광지에 사용할 중립값
  // ==============================================================

  static const double neutralCongestion = 50.0;


  // ==============================================================
  // 관광지 병합
  // ==============================================================
  //
  // tourismSpots
  // → 한국관광공사 TourAPI 관광지 목록
  //
  // congestionSpots
  // → 관광지 집중률 API 조회 결과
  //
  // 반환
  // → 두 API의 관광지를 합친 최종 목록
  // ==============================================================

  static List<MergedAttraction> merge({
    required List<TourismSpot> tourismSpots,
    required List<Map<String, dynamic>> congestionSpots,
  }) {
    print('');
    print('==================================================');
    print('SNOB 관광지 데이터 병합');
    print('==================================================');
    print('TourAPI 관광지 : ${tourismSpots.length}개');
    print('집중률 API     : ${congestionSpots.length}개');


    // ============================================================
    // 집중률 API 데이터를 관광지명 기준으로 정리
    // ============================================================

    final Map<String, Map<String, dynamic>> congestionMap = {};


    for (final Map<String, dynamic> congestion
        in congestionSpots) {
      final String attractionName =
          _getAttractionName(congestion);

      if (attractionName.isEmpty) {
        continue;
      }

      final String normalizedName =
          _normalizeName(attractionName);

      if (normalizedName.isEmpty) {
        continue;
      }

      // 같은 관광지명이 여러 번 존재하는 경우
      // 마지막 데이터를 덮어쓰지 않고
      // 첫 번째 데이터를 유지한다.
      congestionMap.putIfAbsent(
        normalizedName,
        () => congestion,
      );
    }


    print(
      '집중률 관광지명 : '
      '${congestionMap.length}개',
    );


    // ============================================================
    // 최종 결과
    // ============================================================

    final List<MergedAttraction> results = [];

    // ============================================================
    // 1. TourAPI 관광지 처리
    // ============================================================

    final Set<String> matchedCongestionNames = {};


    for (final TourismSpot spot
        in tourismSpots) {
      final String normalizedTourismName =
          _normalizeName(spot.title);

      final Map<String, dynamic>? congestion =
          congestionMap[normalizedTourismName];


      // ----------------------------------------------------------
      // TourAPI O + 집중률 API O
      // ----------------------------------------------------------

      if (congestion != null) {
        final double congestionRate =
            _getCongestionRate(congestion);

        results.add(
          MergedAttraction(
            title: spot.title,
            address: spot.address,
            regionName: spot.regionName,
            congestion: congestionRate,
            snobScore:
                100.0 - congestionRate,
            fromTourApi: true,
            fromCongestionApi: true,
          ),
        );

        matchedCongestionNames.add(
          normalizedTourismName,
        );

        continue;
      }


      // ----------------------------------------------------------
      // TourAPI O + 집중률 API X
      //
      // 기존처럼 중립값 사용
      // ----------------------------------------------------------

      results.add(
        MergedAttraction(
          title: spot.title,
          address: spot.address,
          regionName: spot.regionName,
          congestion: neutralCongestion,
          snobScore:
              100.0 - neutralCongestion,
          fromTourApi: true,
          fromCongestionApi: false,
        ),
      );
    }


    // ============================================================
    // 2. 집중률 API에만 존재하는 관광지 추가
    // ============================================================

    int congestionOnlyCount = 0;


    for (final MapEntry<String, Map<String, dynamic>> entry
        in congestionMap.entries) {
      final String normalizedName =
          entry.key;

      final Map<String, dynamic> congestion =
          entry.value;


      // ----------------------------------------------------------
      // 이미 TourAPI와 매칭된 관광지는 제외
      // ----------------------------------------------------------

      if (matchedCongestionNames.contains(
        normalizedName,
      )) {
        continue;
      }


      final String attractionName =
          _getAttractionName(congestion);

      if (attractionName.isEmpty) {
        continue;
      }


      final double congestionRate =
          _getCongestionRate(congestion);


      // ----------------------------------------------------------
      // 집중률 API에만 존재하는 관광지
      // ----------------------------------------------------------

      results.add(
        MergedAttraction(
          title: attractionName,
          address: '',
          regionName: _getRegionName(congestion),
          congestion: congestionRate,
          snobScore:
              100.0 - congestionRate,
          fromTourApi: false,
          fromCongestionApi: true,
        ),
      );

      congestionOnlyCount++;
    }


    // ============================================================
    // 결과 출력
    // ============================================================

    print('');
    print('==================================================');
    print('SNOB 관광지 병합 완료');
    print('==================================================');
    print(
      'TourAPI + 집중률 매칭 : '
      '${matchedCongestionNames.length}개',
    );
    print(
      'TourAPI 전용          : '
      '${tourismSpots.length - matchedCongestionNames.length}개',
    );
    print(
      '집중률 API 전용       : '
      '$congestionOnlyCount개',
    );
    print(
      '최종 관광지           : '
      '${results.length}개',
    );
    print('==================================================');


    return results;
  }


  // ==============================================================
  // 관광지명 가져오기
  // ==============================================================
  //
  // 집중률 API의 관광지 필드:
  //
  // 관광지
  //
  // API 응답에서 실제로는
  // 'tatsCnctrNm' 등의 필드명이 사용될 수 있으므로
  // 여러 후보를 순서대로 확인한다.
  // ==============================================================

  static String _getAttractionName(
    Map<String, dynamic> data,
  ) {
    const List<String> possibleKeys = [
      '관광지',
      'touristSpot',
      'touristSpotName',
      'spotName',
      'tatsCnctrNm',
      'tatsCnctrNmKor',
      'name',
    ];


    for (final String key
        in possibleKeys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String name =
          value.toString().trim();

      if (name.isNotEmpty) {
        return name;
      }
    }


    return '';
  }


  // ==============================================================
  // 집중률 가져오기
  // ==============================================================

  static double _getCongestionRate(
    Map<String, dynamic> data,
  ) {
    const List<String> possibleKeys = [
      'cnctrRate',
      '집중률',
      'congestion',
      'congestionRate',
    ];


    for (final String key
        in possibleKeys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }


      final double? parsed =
          double.tryParse(
        value
            .toString()
            .replaceAll('%', '')
            .trim(),
      );


      if (parsed != null) {
        // --------------------------------------------------------
        // 집중률은 0~100 범위로 제한
        // --------------------------------------------------------

        if (parsed < 0) {
          return 0.0;
        }

        if (parsed > 100) {
          return 100.0;
        }

        return parsed;
      }
    }


    // 집중률을 읽지 못한 경우
    return neutralCongestion;
  }


  // ==============================================================
  // 집중률 API 지역명 가져오기
  // ==============================================================

  static String _getRegionName(
    Map<String, dynamic> data,
  ) {
    const List<String> possibleKeys = [
      'signguNm',
      'areaNm',
      '시군구',
      '시도',
    ];


    for (final String key
        in possibleKeys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }


      final String name =
          value.toString().trim();

      if (name.isNotEmpty) {
        return name;
      }
    }


    return '';
  }


  // ==============================================================
  // 관광지명 정규화
  // ==============================================================
  //
  // 단순히 공백만 제거한다.
  //
  // 예:
  //
  // "남산 서울 타워"
  //       ↓
  // "남산서울타워"
  //
  // "남산서울타워"
  //       ↓
  // "남산서울타워"
  // ==============================================================

  static String _normalizeName(
    String name,
  ) {
    return name
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .trim()
        .toLowerCase();
  }
}


// ================================================================
// 최종 병합 관광지
// ================================================================
//
// TourAPI 관광지와 집중률 API 관광지를 하나의 객체로 표현한다.
//
// 집중률 API에만 존재하는 관광지는 contentId가 없기 때문에
// contentId를 이 클래스에서 사용하지 않는다.
// ================================================================

class MergedAttraction {
  final String title;
  final String address;
  final String regionName;

  // 집중률
  final double congestion;

  // SNOB 점수
  //
  // 집중률이 낮을수록 높은 점수
  //
  // 100 - 집중률
  final double snobScore;

  // 데이터 출처
  final bool fromTourApi;
  final bool fromCongestionApi;


  const MergedAttraction({
    required this.title,
    required this.address,
    required this.regionName,
    required this.congestion,
    required this.snobScore,
    required this.fromTourApi,
    required this.fromCongestionApi,
  });


  @override
  String toString() {
    return '''
MergedAttraction(
  title: $title,
  address: $address,
  regionName: $regionName,
  congestion: $congestion,
  snobScore: $snobScore,
  fromTourApi: $fromTourApi,
  fromCongestionApi: $fromCongestionApi,
)
''';
  }
}
