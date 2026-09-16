import '../snob/tourism_spot.dart';
import 'snob_spot.dart';


// ================================================================
// SNOB 관광지 ↔ 집중률 API 관광지 매핑
// ================================================================
//
// 매칭 순서
//
// 1. 완전 일치
// 2. 정규화 일치
// 3. 괄호 / 부가정보 제거 후 일치
// 4. 단어 순서 무시 후 일치
// 5. 문자열 유사도 기반 보조 매칭
//
// 예:
//
// 해운대 해수욕장
// 해운대(해수욕장)
// 해수욕장 해운대
//
// → 같은 관광지로 판단
//
// 단, 너무 비슷하기만 한 관광지는 잘못 매칭될 수 있으므로
// 일정 점수 이상의 경우에만 최종 매칭한다.
// ================================================================

class SpotMappingService {
  // ==============================================================
  // 매칭 점수
  // ==============================================================

  static const int exactMatchScore = 100;
  static const int normalizedMatchScore = 90;
  static const int simplifiedMatchScore = 80;
  static const int unorderedTokenMatchScore = 70;
  static const int fuzzyMatchScore = 60;

  // 동일 지역 보너스
  static const int regionMatchBonus = 20;

  // 문자열 유사도 최소 기준
  static const double minimumFuzzySimilarity = 0.75;

  // ==============================================================
  // 관광지 이름 정규화
  // ==============================================================
  //
  // 예:
  //
  // "경복궁 "
  // "경 복 궁"
  // "경복궁(사적)"
  //
  // → "경복궁"
  //
  // ==============================================================

  static String normalizeName(
    String name,
  ) {
    String result =
        name.trim().toLowerCase();

    result = result.replaceAll(
      RegExp(r'\s+'),
      '',
    );

    result = result.replaceAll(
      RegExp(
        r'[^\p{L}\p{N}]',
        unicode: true,
      ),
      '',
    );

    return result;
  }


  // ==============================================================
  // 괄호 / 부가정보 제거
  // ==============================================================

  static String simplifyName(
    String name,
  ) {
    String result =
        name.trim();

    // ------------------------------------------------------------
    // 괄호
    // ------------------------------------------------------------

    result = result.replaceAll(
      RegExp(r'\([^)]*\)'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\[[^\]]*\]'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\{[^}]*\}'),
      '',
    );

    return normalizeName(
      result,
    );
  }


  // ==============================================================
  // 관광지 이름 토큰화
  // ==============================================================
  //
  // 단어 순서를 무시한 비교를 위한 전처리
  //
  // 예:
  //
  // "해운대 해수욕장"
  // → ["해운대", "해수욕장"]
  //
  // "해수욕장 해운대"
  // → ["해수욕장", "해운대"]
  //
  // ==============================================================
  
  static List<String> _tokenizeName(
    String name,
  ) {
    String result =
        name.trim().toLowerCase();

    // 괄호, 특수문자를 공백으로 변경
    result = result.replaceAll(
      RegExp(
        r'[()\[\]{}\-_/,.:;|]+',
      ),
      ' ',
    );

    // 연속 공백 제거
    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();

    if (result.isEmpty) {
      return [];
    }

    return result
        .split(' ')
        .where(
          (String token) =>
              token.trim().isNotEmpty,
        )
        .map(
          (String token) =>
              normalizeName(token),
        )
        .where(
          (String token) =>
              token.isNotEmpty,
        )
        .toList();
  }


  // ==============================================================
  // 단어 순서 무시용 키
  // ==============================================================

  static String _createUnorderedTokenKey(
    String name,
  ) {
    final List<String> tokens =
        _tokenizeName(name);

    if (tokens.isEmpty) {
      return '';
    }

    // 중복 토큰 제거
    final List<String> uniqueTokens =
        tokens.toSet().toList();

    // 가나다순 정렬
    uniqueTokens.sort();

    return uniqueTokens.join('|');
  }


  // ==============================================================
  // 문자열 2-gram 생성
  // ==============================================================
  //
  // 공백이 없는 경우까지 어느 정도 대응하기 위해
  // 문자 2개씩 묶어서 비교한다.
  //
  // 예:
  //
  // 해운대해수욕장
  // 해수욕장해운대
  //
  // 순서는 다르지만 비슷한 문자 조합이 많으므로
  // 보조적으로 사용할 수 있다.
  // ==============================================================

  static Set<String> _createBigrams(
    String value,
  ) {
    final String normalized =
        normalizeName(value);

    final Set<String> result = {};

    if (normalized.isEmpty) {
      return result;
    }

    if (normalized.length == 1) {
      result.add(normalized);
      return result;
    }

    for (int i = 0;
        i < normalized.length - 1;
        i++) {
      result.add(
        normalized.substring(
          i,
          i + 2,
        ),
      );
    }

    return result;
  }


  // ==============================================================
  // 문자열 유사도
  // ==============================================================

  static double _calculateFuzzySimilarity(
    String first,
    String second,
  ) {
    final Set<String> firstBigrams =
        _createBigrams(first);

    final Set<String> secondBigrams =
        _createBigrams(second);

    if (firstBigrams.isEmpty ||
        secondBigrams.isEmpty) {
      return 0;
    }

    final int intersection =
        firstBigrams.intersection(
      secondBigrams,
    ).length;

    return (2.0 * intersection) /
        (firstBigrams.length +
            secondBigrams.length);
  }


  // ==============================================================
  // 숫자 변환
  // ==============================================================

  static double? _parseDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text =
        value
            .toString()
            .trim()
            .replaceAll(',', '');

    return double.tryParse(
      text,
    );
  }


  // ==============================================================
  // 지역 코드 비교
  // ==============================================================
  //
  // TourAPI:
  //
  // areaCode  = 43
  // sigungu   = 112
  //
  // 집중률 API:
  //
  // areaCd    = 43
  // signguCd  = 43112
  //
  // 일반 지역은 같은 지역으로 판단한다.
  //
  // 행정구역 개편 지역은 이름 매칭을 우선하고
  // 코드 비교는 보조적으로만 사용한다.
  // ==============================================================

  static bool _isSameRegion(
    TourismSpot spot,
    Map<String, dynamic> congestion,
  ) {
    final String tourismRegion =
        spot.lDongRegnCd.trim();

    final String tourismSigungu =
        spot.lDongSignguCd.trim();

    final String congestionRegion =
        congestion['areaCd']
                ?.toString()
                .trim() ??
            '';

    final String congestionSigungu =
        congestion['signguCd']
                ?.toString()
                .trim() ??
            '';

    if (tourismRegion.isEmpty ||
        congestionRegion.isEmpty) {
      return false;
    }

    // ------------------------------------------------------------
    // 시도 코드가 다르면 다른 지역
    // ------------------------------------------------------------

    if (tourismRegion !=
        congestionRegion) {
      return false;
    }

    // ------------------------------------------------------------
    // 시군구 코드가 없는 경우
    // ------------------------------------------------------------

    if (tourismSigungu.isEmpty ||
        congestionSigungu.isEmpty) {
      return true;
    }

    // ------------------------------------------------------------
    // 완전 일치
    // ------------------------------------------------------------

    if (tourismSigungu ==
        congestionSigungu) {
      return true;
    }

    // ------------------------------------------------------------
    // TourAPI 3자리
    // +
    // 시도 코드
    // =
    // 집중률 API 5자리
    // ------------------------------------------------------------

    final String expectedCode =
        '$tourismRegion'
        '${tourismSigungu.padLeft(3, '0')}';

    if (expectedCode ==
        congestionSigungu) {
      return true;
    }

    return false;
  }


  // ==============================================================
  // 토큰 순서 무시 비교
  // ==============================================================

  static bool _isSameUnorderedTokens(
    String tourismName,
    String congestionName,
  ) {
    final String firstKey =
        _createUnorderedTokenKey(
      tourismName,
    );

    final String secondKey =
        _createUnorderedTokenKey(
      congestionName,
    );

    if (firstKey.isEmpty ||
        secondKey.isEmpty) {
      return false;
    }

    return firstKey ==
        secondKey;
  }


  // ==============================================================
  // 매칭 점수 계산
  // ==============================================================

  static int _calculateMatchScore({
    required TourismSpot tourismSpot,
    required Map<String, dynamic> congestion,
  }) {
    final String tourismName =
        tourismSpot.title.trim();

    final String congestionName =
        congestion['tAtsNm']
                ?.toString()
                .trim() ??
            '';

    if (tourismName.isEmpty ||
        congestionName.isEmpty) {
      return 0;
    }

    final bool sameRegion =
        _isSameRegion(
      tourismSpot,
      congestion,
    );

    // ==========================================================
    // 1. 완전 일치
    // ==========================================================

    if (tourismName ==
        congestionName) {
      int score =
          exactMatchScore;

      if (sameRegion) {
        score += regionMatchBonus;
      }

      return score;
    }


    // ==========================================================
    // 2. 정규화 일치
    // ==========================================================

    if (normalizeName(
          tourismName,
        ) ==
        normalizeName(
          congestionName,
        )) {
      int score =
          normalizedMatchScore;

      if (sameRegion) {
        score += regionMatchBonus;
      }

      return score;
    }


    // ==========================================================
    // 3. 간소화 일치
    // ==========================================================

    if (simplifyName(
          tourismName,
        ) ==
        simplifyName(
          congestionName,
        )) {
      int score =
          simplifiedMatchScore;

      if (sameRegion) {
        score += regionMatchBonus;
      }

      return score;
    }


    // ==========================================================
    // 4. 단어 순서 무시
    // ==========================================================
    //
    // 해운대 해수욕장
    // 해수욕장 해운대
    //
    // → 동일 처리
    // ==========================================================

    if (_isSameUnorderedTokens(
      tourismName,
      congestionName,
    )) {
      int score =
          unorderedTokenMatchScore;

      if (sameRegion) {
        score += regionMatchBonus;
      }

      return score;
    }


    // ==========================================================
    // 5. 문자열 유사도
    // ==========================================================

    final double similarity =
        _calculateFuzzySimilarity(
      tourismName,
      congestionName,
    );

    if (similarity >=
        minimumFuzzySimilarity) {
      int score =
          fuzzyMatchScore;

      if (sameRegion) {
        score += regionMatchBonus;
      }

      return score;
    }

    return 0;
  }


  // ==============================================================
  // 매칭 방식 확인
  // ==============================================================

  static String _getMatchType({
    required String tourismName,
    required String congestionName,
  }) {
    if (tourismName ==
        congestionName) {
      return '완전 일치';
    }

    if (normalizeName(
          tourismName,
        ) ==
        normalizeName(
          congestionName,
        )) {
      return '정규화 일치';
    }

    if (simplifyName(
          tourismName,
        ) ==
        simplifyName(
          congestionName,
        )) {
      return '간소화 일치';
    }

    if (_isSameUnorderedTokens(
      tourismName,
      congestionName,
    )) {
      return '순서 무시 일치';
    }

    final double similarity =
        _calculateFuzzySimilarity(
      tourismName,
      congestionName,
    );

    if (similarity >=
        minimumFuzzySimilarity) {
      return '유사도 일치';
    }

    return '미매칭';
  }


  // ==============================================================
  // 가장 적합한 집중률 데이터 찾기
  // ==============================================================

  static Map<String, dynamic>? _findBestMatch({
    required TourismSpot tourismSpot,
    required List<Map<String, dynamic>>
        congestionData,
  }) {
    Map<String, dynamic>?
        bestMatch;

    int bestScore = 0;

    for (final Map<String, dynamic>
        congestion
        in congestionData) {
      final int score =
          _calculateMatchScore(
        tourismSpot:
            tourismSpot,
        congestion:
            congestion,
      );

      if (score >
          bestScore) {
        bestScore = score;
        bestMatch = congestion;
      }
    }

    return bestMatch;
  }


  // ==============================================================
  // 집중률 데이터 → SNOB 기본 점수
  // ==============================================================

  static double? calculateSnobScore(
    double? concentrationRate,
  ) {
    if (concentrationRate == null) {
      return null;
    }

    final double score =
        100 - concentrationRate;

    return score
        .clamp(
          0,
          100,
        )
        .toDouble();
  }


  // ==============================================================
  // 집중률 데이터 인덱스
  // ==============================================================

  static Map<String,
      List<Map<String, dynamic>>>
      _createCongestionIndex(
    List<Map<String, dynamic>>
        congestionData,
  ) {
    final Map<String,
        List<Map<String, dynamic>>>
        index = {};

    for (final Map<String, dynamic>
        data
        in congestionData) {
      final String name =
          data['tAtsNm']
                  ?.toString()
                  .trim() ??
              '';

      if (name.isEmpty) {
        continue;
      }

      final String normalizedName =
          normalizeName(name);

      if (normalizedName.isEmpty) {
        continue;
      }

      index.putIfAbsent(
        normalizedName,
        () => [],
      );

      index[
              normalizedName]!
          .add(data);
    }

    return index;
  }


  // ==============================================================
  // 관광지 매핑
  // ==============================================================

  static List<SnobSpot> mapSpots({
    required List<TourismSpot>
        tourismSpots,
    required List<Map<String, dynamic>>
        congestionData,
  }) {
    final List<SnobSpot> result =
        [];

    // ------------------------------------------------------------
    // 집중률 데이터 인덱스
    // ------------------------------------------------------------

    final Map<String,
        List<Map<String, dynamic>>>
        congestionIndex =
        _createCongestionIndex(
      congestionData,
    );

    int exactMatched = 0;
    int normalizedMatched = 0;
    int simplifiedMatched = 0;
    int unorderedTokenMatched = 0;
    int fuzzyMatched = 0;
    int unmatched = 0;

    // ==========================================================
    // 관광지 하나씩 처리
    // ==========================================================

    for (final TourismSpot spot
        in tourismSpots) {
      Map<String, dynamic>?
          bestMatch;

      final String normalizedName =
          normalizeName(
        spot.title,
      );

      // ========================================================
      // 1차: 정규화 이름으로 후보 검색
      // ========================================================

      final List<Map<String, dynamic>>
          candidates =
          congestionIndex[
                  normalizedName] ??
              [];

      if (candidates.isNotEmpty) {
        bestMatch =
            _findBestMatch(
          tourismSpot:
              spot,
          congestionData:
              candidates,
        );
      }

      // ========================================================
      // 2차: 전체 데이터 검색
      // ========================================================
      //
      // 정규화 이름이 다르더라도
      // 순서 변경 / 괄호 / 특수문자 차이를 확인한다.
      // ========================================================

      if (bestMatch ==
          null) {
        bestMatch =
            _findBestMatch(
          tourismSpot:
              spot,
          congestionData:
              congestionData,
        );
      }

      // ========================================================
      // 3차: 매칭 실패
      // ========================================================

      if (bestMatch ==
          null) {
        unmatched++;

        print(
          '❌ 집중률 매칭 실패 : '
          '${spot.title}',
        );

        result.add(
          _createSnobSpot(
            spot:
                spot,
            congestion:
                null,
          ),
        );

        continue;
      }

      // ========================================================
      // 매칭 방식 확인
      // ========================================================

      final String tourismName =
          spot.title.trim();

      final String matchedName =
          bestMatch[
                      'tAtsNm']
                  ?.toString()
                  .trim() ??
              '';

      final String matchType =
          _getMatchType(
        tourismName:
            tourismName,
        congestionName:
            matchedName,
      );

      // --------------------------------------------------------
      // 매칭 종류별 카운트
      // --------------------------------------------------------

      switch (matchType) {
        case '완전 일치':
          exactMatched++;
          break;

        case '정규화 일치':
          normalizedMatched++;
          break;

        case '간소화 일치':
          simplifiedMatched++;
          break;

        case '순서 무시 일치':
          unorderedTokenMatched++;
          break;

        case '유사도 일치':
          fuzzyMatched++;
          break;
      }

      // --------------------------------------------------------
      // 디버깅 로그
      // --------------------------------------------------------

      print(
        '✅ 집중률 매칭 : '
        '${spot.title}'
        ' → '
        '$matchedName'
        ' [$matchType]',
      );

      // --------------------------------------------------------
      // 최종 SnobSpot
      // --------------------------------------------------------

      result.add(
        _createSnobSpot(
          spot:
              spot,
          congestion:
              bestMatch,
        ),
      );
    }

    // ==========================================================
    // 결과 출력
    // ==========================================================

    print('');
    print(
      '==========================================',
    );
    print(
      'SNOB 관광지 매핑 결과',
    );
    print(
      '==========================================',
    );

    print(
      'TourAPI 관광지 : '
      '${tourismSpots.length}개',
    );

    print(
      '집중률 API 데이터 : '
      '${congestionData.length}개',
    );

    print('');

    print(
      '완전 일치 : '
      '$exactMatched개',
    );

    print(
      '정규화 일치 : '
      '$normalizedMatched개',
    );

    print(
      '간소화 일치 : '
      '$simplifiedMatched개',
    );

    print(
      '순서 무시 일치 : '
      '$unorderedTokenMatched개',
    );

    print(
      '유사도 일치 : '
      '$fuzzyMatched개',
    );

    print(
      '매칭 실패 : '
      '$unmatched개',
    );

    print('');

    print(
      '최종 SNOB 관광지 : '
      '${result.length}개',
    );

    print(
      '==========================================',
    );

    return result;
  }


  // ==============================================================
  // TourismSpot → SnobSpot
  // ==============================================================

  static SnobSpot _createSnobSpot({
    required TourismSpot spot,
    required Map<String, dynamic>?
        congestion,
  }) {
    // ------------------------------------------------------------
    // 집중률
    // ------------------------------------------------------------

    final double?
        concentrationRate =
        congestion ==
                null
            ? null
            : _parseDouble(
                congestion[
                  'cnctrRate'
                ],
              );

    // ------------------------------------------------------------
    // SNOB 점수
    // ------------------------------------------------------------

    final double? snobScore =
        calculateSnobScore(
      concentrationRate,
    );

    return SnobSpot(
      contentId:
          spot.contentId,
      title:
          spot.title,
      address:
          spot.address,
      contentTypeId:
          spot.contentTypeId,
      lDongRegnCd:
          spot.lDongRegnCd,
      lDongSignguCd:
          spot.lDongSignguCd,
      regionName:
          spot.regionName,
      lclsSystm1:
          spot.lclsSystm1,
      lclsSystm2:
          spot.lclsSystm2,
      lclsSystm3:
          spot.lclsSystm3,
      modifiedTime:
          spot.modifiedTime,
      latitude:
          spot.latitude,
      longitude:
          spot.longitude,

      // ----------------------------------------------------------
      // 집중률 API
      // ----------------------------------------------------------

      concentrationRate:
          concentrationRate,

      concentrationBaseYmd:
          congestion?[
                  'baseYmd']
              ?.toString(),

      concentrationAreaCd:
          congestion?[
                  'areaCd']
              ?.toString(),

      concentrationAreaNm:
          congestion?[
                  'areaNm']
              ?.toString(),

      concentrationSignguCd:
          congestion?[
                  'signguCd']
              ?.toString(),

      concentrationSignguNm:
          congestion?[
                  'signguNm']
              ?.toString(),

      // ----------------------------------------------------------
      // SNOB
      // ----------------------------------------------------------

      snobScore:
          snobScore,
    );
  }


  // ==============================================================
  // 단일 관광지 매칭
  // ==============================================================

  static SnobSpot? mapSingleSpot({
    required TourismSpot tourismSpot,
    required List<Map<String, dynamic>>
        congestionData,
  }) {
    final List<SnobSpot> result =
        mapSpots(
      tourismSpots: [
        tourismSpot,
      ],
      congestionData:
          congestionData,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }
}