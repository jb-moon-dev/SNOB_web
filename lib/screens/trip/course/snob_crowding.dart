import 'dart:convert';

import 'package:flutter/services.dart';


// ================================================================
// SNOB Crowding Result
// ================================================================

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  final double averageConcentration;

  final double crowdingScore;

  const SnobCrowdingResult({
    required this.spot,
    required this.averageConcentration,
    required this.crowdingScore,
  });

  @override
  String toString() {
    final name =
        spot['hubTatsNm'] ??
        spot['tAtsNm'] ??
        spot['touristSpotName'] ??
        spot['name'] ??
        spot['title'] ??
        '이름 없음';

    return '''
$name
관광지 집중률 평균 : ${averageConcentration.toStringAsFixed(2)}
Crowding 점수      : ${crowdingScore.toStringAsFixed(2)}
''';
  }
}


// ================================================================
// SNOB Crowding
// ================================================================

class SnobCrowding {

  // ==============================================================
  // 점수 설정
  // ==============================================================

  // Crowding 점수가 가질 수 있는 최대값
  static const double maxScore = 45.0;

  // 집중률 데이터를 찾지 못했을 때 사용할 중립 점수
  static const double neutralScore = 27.5;

  // 집중률 데이터를 찾지 못했을 때 사용할 기본 집중률
  static const double defaultConcentration = 50.0;


  // ==============================================================
  // 로컬 JSON 캐시
  // ==============================================================

  static Map<String, List<Map<String, dynamic>>>?
      _concentrationByName;

  static Map<String, List<Map<String, dynamic>>>?
      _concentrationByRegionAndName;


  // ==============================================================
  // 이름 정규화
  // ==============================================================

  String _normalizeName(dynamic value) {

    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(' ', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('\t', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .toLowerCase();
  }


  // ==============================================================
  // 관광지 이름
  // ==============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {

    final candidates = [
      spot['hubTatsNm'],
      spot['tAtsNm'],
      spot['tatsNm'],
      spot['touristSpotName'],
      spot['touristSpotNm'],
      spot['name'],
      spot['title'],
      spot['spotName'],
    ];

    for (final value in candidates) {

      if (value != null &&
          value.toString().trim().isNotEmpty) {

        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 관광지 집중률 JSON의 관광지 이름
  // ==============================================================

  String _getConcentrationName(
    Map<String, dynamic> data,
  ) {

    // 우리가 만든 JSON 구조
    if (data['name'] != null &&
        data['name'].toString().trim().isNotEmpty) {

      return data['name'].toString().trim();
    }

    // 혹시 다른 형태의 데이터가 들어와도 대응
    final candidates = [
      data['hubTatsNm'],
      data['tAtsNm'],
      data['tatsNm'],
      data['touristSpotName'],
      data['touristSpotNm'],
      data['name'],
      data['title'],
      data['spotName'],
    ];

    for (final value in candidates) {

      if (value != null &&
          value.toString().trim().isNotEmpty) {

        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 집중률
  // ==============================================================

  double? _getConcentrationRate(
    Map<String, dynamic> data,
  ) {

    // 우리가 만든 JSON
    if (data['concentration'] != null) {

      final rate = double.tryParse(
        data['concentration'].toString(),
      );

      if (rate != null &&
          rate >= 0 &&
          rate <= 100) {

        return rate;
      }
    }


    // 혹시 다른 형태의 데이터가 들어와도 대응
    final candidates = [
      data['cnctrRate'],
      data['concentrationRate'],
      data['concentration'],
      data['rate'],
    ];

    for (final value in candidates) {

      if (value == null) {
        continue;
      }

      final rate = double.tryParse(
        value.toString().trim(),
      );

      if (rate == null) {
        continue;
      }

      if (rate < 0 || rate > 100) {
        continue;
      }

      return rate;
    }

    return null;
  }


  // ==============================================================
  // 관광지 시군구 코드
  // ==============================================================

  String? _getSignguCode(
    Map<String, dynamic> spot,
  ) {

    final candidates = [
      spot['signguCd'],
      spot['sigunguCd'],
      spot['signguCode'],
      spot['sigunguCode'],
      spot['sigungu_cd'],
    ];

    for (final value in candidates) {

      if (value != null &&
          value.toString().trim().isNotEmpty) {

        final code = value
            .toString()
            .trim();

        // 5자리 시군구 코드
        if (RegExp(r'^\d+$').hasMatch(code)) {
          return code.padLeft(5, '0');
        }

        return code;
      }
    }

    return null;
  }


  // ==============================================================
  // 문자열 유사도용 정규화
  // ==============================================================

  String _cleanName(String name) {

    return _normalizeName(name)
        .replaceAll('관광지', '')
        .replaceAll('문화관광', '')
        .replaceAll('유원지', '')
        .replaceAll('공원', '');
  }


  // ==============================================================
  // JSON 로드
  // ==============================================================

  Future<void> _loadConcentrationData() async {

    // 이미 불러왔으면 다시 읽지 않는다.
    if (_concentrationByName != null &&
        _concentrationByRegionAndName != null) {

      return;
    }


    print('');
    print('============================================================');
    print('📂 SNOB 관광지 집중률 JSON 로드');
    print('============================================================');


    try {

      final jsonString = await rootBundle.loadString(
        'assets/data/snob_concentration.json',
      );


      final decoded = jsonDecode(
        jsonString,
      );


      if (decoded is! Map<String, dynamic>) {

        throw Exception(
          'snob_concentration.json 형식이 올바르지 않습니다.',
        );
      }


      final records = decoded['records'];


      if (records is! List) {

        throw Exception(
          'JSON에 records가 없습니다.',
        );
      }


      final byName =
          <String, List<Map<String, dynamic>>>{};

      final byRegionAndName =
          <String, List<Map<String, dynamic>>>{};


      for (final item in records) {

        if (item is! Map) {
          continue;
        }


        final data =
            Map<String, dynamic>.from(item);


        final name =
            _normalizeName(
          data['normalizedName'] ??
              _getConcentrationName(data),
        );


        if (name.isEmpty) {
          continue;
        }


        // ----------------------------------------------------------
        // 이름 기준 Map
        // ----------------------------------------------------------

        byName
            .putIfAbsent(
              name,
              () => <Map<String, dynamic>>[],
            )
            .add(data);


        // ----------------------------------------------------------
        // 시군구 + 이름 기준 Map
        // ----------------------------------------------------------

        final rawCode =
            data['sigunguCode'];


        if (rawCode != null &&
            rawCode.toString().trim().isNotEmpty) {

          final code =
              rawCode.toString().trim();


          final regionKey =
              '$code|$name';


          byRegionAndName
              .putIfAbsent(
                regionKey,
                () => <Map<String, dynamic>>[],
              )
              .add(data);
        }
      }


      _concentrationByName =
          byName;

      _concentrationByRegionAndName =
          byRegionAndName;


      print(
        '✅ JSON 로드 성공',
      );

      print(
        '전체 관광지 이름 수 : '
        '${byName.length}',
      );

      print(
        '지역 + 관광지 이름 수 : '
        '${byRegionAndName.length}',
      );

      print(
        '전체 JSON records : '
        '${records.length}',
      );

      print(
        '============================================================',
      );
    }

    catch (e) {

      print('');
      print(
        '❌ 관광지 집중률 JSON 로드 실패',
      );

      print(e);

      print(
        '============================================================',
      );


      // 실패하면 빈 Map을 넣어 이후 코드에서
      // null 오류가 발생하지 않도록 한다.
      _concentrationByName =
          <String, List<Map<String, dynamic>>>{};

      _concentrationByRegionAndName =
          <String, List<Map<String, dynamic>>>{};
    }
  }


  // ==============================================================
  // 지역 + 이름으로 매칭
  // ==============================================================

  List<double>? _findRatesByRegionAndName(
    String spotName,
    String? signguCode,
  ) {

    if (signguCode == null ||
        signguCode.isEmpty) {

      return null;
    }


    final normalizedSpotName =
        _normalizeName(spotName);


    if (normalizedSpotName.isEmpty) {
      return null;
    }


    final key =
        '$signguCode|$normalizedSpotName';


    final dataList =
        _concentrationByRegionAndName?[key];


    if (dataList == null ||
        dataList.isEmpty) {

      return null;
    }


    final rates = <double>[];


    for (final data in dataList) {

      final rate =
          _getConcentrationRate(data);

      if (rate != null) {
        rates.add(rate);
      }
    }


    if (rates.isEmpty) {
      return null;
    }


    print('✅ 지역 + 이름 정확히 일치');
    print('시군구코드 : $signguCode');
    print('관광지     : $normalizedSpotName');

    return rates;
  }


  // ==============================================================
  // 이름으로 매칭
  // ==============================================================
  //
  // 우선순위
  //
  // 1. 정확히 일치
  // 2. 부분 문자열
  // 3. 핵심 이름 비교
  //
  // 단, 같은 이름이 여러 지역에 존재하면
  // 이름만으로 매칭하지 않는다.
  // ==============================================================

  List<double>? _findRatesByName(
    String spotName,
  ) {

    final concentrationByName =
        _concentrationByName;


    if (concentrationByName == null) {
      return null;
    }


    final normalizedSpotName =
        _normalizeName(spotName);


    if (normalizedSpotName.isEmpty) {
      return null;
    }


    // ------------------------------------------------------------
    // 1. 정확히 일치
    // ------------------------------------------------------------

    final exact =
        concentrationByName[normalizedSpotName];


    if (exact != null &&
        exact.isNotEmpty) {

      // 같은 관광지명이 여러 시군구에 있으면
      // 이름만으로 어느 지역인지 알 수 없으므로 사용하지 않는다.
      final regionCodes = exact
          .map(
            (data) =>
                data['sigunguCode']
                    ?.toString()
                    .trim(),
          )
          .where(
            (code) =>
                code != null &&
                code.isNotEmpty,
          )
          .toSet();


      if (regionCodes.length == 1) {

        final rates = <double>[];

        for (final data in exact) {

          final rate =
              _getConcentrationRate(data);

          if (rate != null) {
            rates.add(rate);
          }
        }


        if (rates.isNotEmpty) {

          print('✅ 이름 정확히 일치');
          print(
            '관광지 : $normalizedSpotName',
          );

          return rates;
        }
      }

      else {

        print('');
        print(
          '⚠️ 같은 관광지명이 여러 지역에 존재합니다.',
        );

        print(
          '이름만으로 매칭하지 않습니다.',
        );
      }
    }


    // ------------------------------------------------------------
    // 2. 부분 문자열
    // ------------------------------------------------------------

    MapEntry<String, List<Map<String, dynamic>>>?
        partialMatch;


    for (final entry
        in concentrationByName.entries) {

      final dataName = entry.key;


      if (dataName.contains(
            normalizedSpotName,
          ) ||
          normalizedSpotName.contains(
            dataName,
          )) {

        // 여러 지역에 존재하는 이름이면 제외
        final regionCodes = entry.value
            .map(
              (data) =>
                  data['sigunguCode']
                      ?.toString()
                      .trim(),
            )
            .where(
              (code) =>
                  code != null &&
                  code.isNotEmpty,
            )
            .toSet();


        if (regionCodes.length == 1) {

          partialMatch = entry;

          break;
        }
      }
    }


    if (partialMatch != null) {

      final rates = <double>[];


      for (final data in partialMatch.value) {

        final rate =
            _getConcentrationRate(data);

        if (rate != null) {
          rates.add(rate);
        }
      }


      if (rates.isNotEmpty) {

        print('✅ 이름 부분 일치');

        print(
          'CENTER50 : $normalizedSpotName',
        );

        print(
          'JSON     : ${partialMatch.key}',
        );

        return rates;
      }
    }


    // ------------------------------------------------------------
    // 3. 핵심 이름 비교
    // ------------------------------------------------------------

    final cleanSpotName =
        _cleanName(spotName);


    if (cleanSpotName.isNotEmpty) {

      for (final entry
          in concentrationByName.entries) {

        final cleanJsonName =
            _cleanName(entry.key);


        if (cleanJsonName.isEmpty) {
          continue;
        }


        if (cleanJsonName.contains(
              cleanSpotName,
            ) ||
            cleanSpotName.contains(
              cleanJsonName,
            )) {

          final regionCodes = entry.value
              .map(
                (data) =>
                    data['sigunguCode']
                        ?.toString()
                        .trim(),
              )
              .where(
                (code) =>
                    code != null &&
                    code.isNotEmpty,
              )
              .toSet();


          // 지역이 하나인 경우에만 사용
          if (regionCodes.length != 1) {
            continue;
          }


          final rates = <double>[];


          for (final data in entry.value) {

            final rate =
                _getConcentrationRate(data);

            if (rate != null) {
              rates.add(rate);
            }
          }


          if (rates.isNotEmpty) {

            print('✅ 핵심 이름 일치');

            print(
              'CENTER50 : $cleanSpotName',
            );

            print(
              'JSON     : $cleanJsonName',
            );

            return rates;
          }
        }
      }
    }


    return null;
  }


  // ==============================================================
  // 집중률 → Crowding 점수
  // ==============================================================

  double _calculateCrowdingScore(
    double concentration,
  ) {

    double score =
        (100.0 - concentration) *
            0.45;


    score = score.clamp(
      0.0,
      maxScore,
    );


    return score;
  }


  // ==============================================================
  // Crowding 계산
  // ==============================================================

  Future<List<SnobCrowdingResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {

    final results =
        <SnobCrowdingResult>[];


    // ============================================================
    // 관광지 목록 확인
    // ============================================================

    if (spots.isEmpty) {

      print('');
      print('❌ SNOB CROWDING');
      print('관광지 목록이 비어있습니다.');

      return results;
    }


    // ============================================================
    // JSON 로드
    // ============================================================

    await _loadConcentrationData();


    // ============================================================
    // 데이터 확인
    // ============================================================

    print('');
    print('============================================================');
    print('📊 SNOB CROWDING');
    print('============================================================');

    print(
      'CENTER50 관광지 수 : ${spots.length}',
    );

    print(
      '로컬 집중률 데이터 : '
      '${_concentrationByName?.length ?? 0}',
    );

    print('============================================================');


    // ============================================================
    // 관광지별 계산
    // ============================================================

    for (final spot in spots) {

      final spotName =
          _getSpotName(spot);


      final normalizedSpotName =
          _normalizeName(spotName);


      final signguCode =
          _getSignguCode(spot);


      print('');
      print('============================================================');
      print('🎯 SNOB CROWDING 계산');
      print('============================================================');

      print(
        'CENTER50 관광지 : "$spotName"',
      );

      print(
        '정규화 이름     : "$normalizedSpotName"',
      );

      print(
        '시군구 코드     : "$signguCode"',
      );

      print('============================================================');


      // ----------------------------------------------------------
      // 기본값
      // ----------------------------------------------------------

      double averageConcentration =
          defaultConcentration;


      double crowdingScore =
          neutralScore;


      List<double>? matchedRates;


      String matchMethod =
          '중립값';


      // ==========================================================
      // 1순위
      // 지역 코드 + 관광지명
      // ==========================================================

      matchedRates =
          _findRatesByRegionAndName(
        spotName,
        signguCode,
      );


      if (matchedRates != null &&
          matchedRates.isNotEmpty) {

        matchMethod =
            '시군구코드 + 이름';
      }


      // ==========================================================
      // 2순위
      // 이름만
      // ==========================================================

      if (matchedRates == null ||
          matchedRates.isEmpty) {

        matchedRates =
            _findRatesByName(
          spotName,
        );


        if (matchedRates != null &&
            matchedRates.isNotEmpty) {

          matchMethod =
              '이름';
        }
      }


      // ==========================================================
      // 매칭 성공
      // ==========================================================

      if (matchedRates != null &&
          matchedRates.isNotEmpty) {

        // 여러 값이 있을 경우 평균
        averageConcentration =
            matchedRates.reduce(
                  (a, b) => a + b,
                ) /
                matchedRates.length;


        // 집중률 → Crowding
        crowdingScore =
            _calculateCrowdingScore(
          averageConcentration,
        );


        print('');
        print(
          '✅ 집중률 데이터 매칭 성공',
        );

        print(
          '매칭 방식 : $matchMethod',
        );

        print(
          '관광지    : "$spotName"',
        );

        print(
          '집중률 데이터 개수 : '
          '${matchedRates.length}',
        );

        print(
          '집중률 : '
          '${matchedRates.map(
            (e) => e.toStringAsFixed(2),
          ).join(', ')}',
        );

        print(
          '평균 집중률 : '
          '${averageConcentration.toStringAsFixed(2)}',
        );

        print(
          'Crowding : '
          '${crowdingScore.toStringAsFixed(2)}',
        );
      }


      // ==========================================================
      // 매칭 실패
      // ==========================================================

      else {

        print('');
        print(
          '❌ 집중률 데이터 매칭 실패',
        );

        print(
          'CENTER50 이름 : "$spotName"',
        );

        print(
          '정규화 이름 : "$normalizedSpotName"',
        );

        print(
          '시군구 코드 : "$signguCode"',
        );


        print('');
        print(
          '⚠️ 중립값 적용',
        );

        print(
          '집중률 = $defaultConcentration',
        );

        print(
          'Crowding = $neutralScore',
        );
      }


      // ==========================================================
      // 결과 저장
      // ==========================================================

      results.add(
        SnobCrowdingResult(
          spot: spot,

          averageConcentration:
              averageConcentration,

          crowdingScore:
              crowdingScore,
        ),
      );
    }


    // ============================================================
    // 종료
    // ============================================================

    print('');
    print('============================================================');
    print('🏁 SNOB CROWDING 종료');
    print('============================================================');

    print(
      '최종 관광지 수 : ${results.length}',
    );

    print('============================================================');


    return results;
  }
}