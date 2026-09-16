import 'dart:convert';

import 'package:flutter/services.dart';


// ================================================================
// Substitutability 계산 결과
// ================================================================

class SnobSubstitutabilityResult {
  final Map<String, dynamic> spot;

  // 동일 중분류 관광지 수
  final int sameCategoryCount;

  // 해당 지역 전체 관광지 수
  final int totalRegionCount;

  // Substitutability 점수 (최대 35점)
  final double substitutabilityScore;

  const SnobSubstitutabilityResult({
    required this.spot,
    required this.sameCategoryCount,
    required this.totalRegionCount,
    required this.substitutabilityScore,
  });

  @override
  String toString() {
    final name =
        spot['hubTatsNm'] ?? '이름 없음';

    final category =
        spot['hubCtgryMclsNm'] ?? '카테고리 없음';

    return '''
$name
중분류                 : $category
동일 카테고리 관광지 수 : $sameCategoryCount
지역 전체 관광지 수    : $totalRegionCount
Substitutability 점수 : ${substitutabilityScore.toStringAsFixed(2)}
''';
  }
}


// ================================================================
// Substitutability 계산
// ================================================================
//
// 같은 지역 안에서
// 동일한 중분류의 관광지가 많을수록
// 해당 관광지를 대체할 수 있는 선택지가 많다고 판단한다.
//
// 점수:
//
// (동일 카테고리 관광지 수 / 지역 전체 관광지 수) × 35
//
// 최대 35점
//
// ================================================================

class SnobSubstitutability {

  static const double maxScore = 35.0;

  // --------------------------------------------------------------
  // test.dart에서 생성한 JSON 파일 경로
  // --------------------------------------------------------------
  //
  // pubspec.yaml의 assets에 등록되어 있어야 한다.
  //
  static const String dataPath =
      'assets/data/snob_substitutability_data.json';


  // 전국 지역 데이터
  //
  // 한 번 읽은 뒤 계속 재사용한다.
  Map<String, dynamic>? _data;


  // ==============================================================
  // 전국 관광지 데이터 로드
  // ==============================================================

  Future<void> _loadData() async {

    // 이미 읽었다면 다시 읽지 않는다.
    if (_data != null) {
      return;
    }

    print('');
    print('========================================');
    print('SNOB SUBSTITUTABILITY DATA LOAD');
    print('========================================');

    final jsonString =
        await rootBundle.loadString(dataPath);

    final decoded =
        jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'SNOB 관광지 데이터 JSON 형식이 올바르지 않습니다.',
      );
    }

    _data = decoded;

    print(
      '기준월 : ${_data!['baseYm']}',
    );

    print(
      '지역 수 : ${_data!['regionCount']}',
    );

    print('데이터 로드 완료');
  }


  // ==============================================================
  // Substitutability 계산
  // ==============================================================

  Future<List<SnobSubstitutabilityResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {

    // 전국 데이터 로드
    await _loadData();

    final results =
        <SnobSubstitutabilityResult>[];


    // --------------------------------------------------------------
    // regions 데이터 확인
    // --------------------------------------------------------------

    final regionsData =
        _data!['regions'];

    if (regionsData is! Map) {
      throw Exception(
        'regions 데이터가 올바르지 않습니다.',
      );
    }


    // ==============================================================
    // Center50의 관광지 50개를 하나씩 계산
    // ==============================================================

    for (final spot in spots) {

      final spotName =
          spot['hubTatsNm']?.toString();

      final signguCd =
          spot['signguCd']?.toString();

      final category =
          spot['hubCtgryMclsNm']?.toString();


      // ------------------------------------------------------------
      // 관광지 정보 확인
      // ------------------------------------------------------------

      if (signguCd == null ||
          signguCd.isEmpty ||
          category == null ||
          category.isEmpty) {

        print('');
        print('========================================');
        print('SUBSTITUTABILITY 정보 부족');
        print('관광지 : $spotName');
        print('========================================');

        results.add(
          SnobSubstitutabilityResult(
            spot: spot,
            sameCategoryCount: 0,
            totalRegionCount: 0,
            substitutabilityScore: 0.0,
          ),
        );

        continue;
      }


      try {

        print('');
        print('========================================');
        print('SNOB SUBSTITUTABILITY');
        print('관광지 : $spotName');
        print('지역 코드 : $signguCd');
        print('중분류 : $category');
        print('========================================');


        // ----------------------------------------------------------
        // 해당 지역 데이터 찾기
        // ----------------------------------------------------------

        final regionData =
            regionsData[signguCd];

        if (regionData is! Map) {

          print(
            '해당 지역 데이터를 찾을 수 없습니다: $signguCd',
          );

          results.add(
            SnobSubstitutabilityResult(
              spot: spot,
              sameCategoryCount: 0,
              totalRegionCount: 0,
              substitutabilityScore: 0.0,
            ),
          );

          continue;
        }


        // ----------------------------------------------------------
        // 지역 전체 관광지 수
        // ----------------------------------------------------------

        final totalRegionCount =
            int.tryParse(
                  regionData['totalCount']
                          ?.toString() ??
                      '',
                ) ??
                0;


        // ----------------------------------------------------------
        // 지역의 카테고리별 관광지 수
        // ----------------------------------------------------------

        final categories =
            regionData['categories'];

        int sameCategoryCount = 0;


        if (categories is Map) {

          final categoryCount =
              categories[category];

          sameCategoryCount =
              int.tryParse(
                    categoryCount?.toString() ??
                        '',
                  ) ??
                  0;
        }


        // ----------------------------------------------------------
        // 점수 계산
        //
        // (동일 카테고리 수 / 지역 전체 관광지 수) × 35
        // ----------------------------------------------------------

        double score = 0.0;

        if (totalRegionCount > 0) {

          score =
              (sameCategoryCount /
                      totalRegionCount) *
                  maxScore;
        }


        // ----------------------------------------------------------
        // 점수 범위 제한
        // ----------------------------------------------------------

        score = score.clamp(
          0.0,
          maxScore,
        );


        // ----------------------------------------------------------
        // 로그
        // ----------------------------------------------------------

        print(
          '지역 전체 관광지 수 : '
          '$totalRegionCount',
        );

        print(
          '동일 카테고리 관광지 수 : '
          '$sameCategoryCount',
        );

        print(
          'Substitutability 점수 : '
          '${score.toStringAsFixed(2)}',
        );


        // ----------------------------------------------------------
        // 결과 저장
        // ----------------------------------------------------------

        results.add(
          SnobSubstitutabilityResult(
            spot: spot,
            sameCategoryCount:
                sameCategoryCount,
            totalRegionCount:
                totalRegionCount,
            substitutabilityScore:
                score,
          ),
        );

      } catch (e) {

        print('');
        print('========================================');
        print('SUBSTITUTABILITY 계산 실패');
        print('관광지 : $spotName');
        print('오류 : $e');
        print('========================================');


        // 오류가 발생해도 관광지 자체는 결과에서 유지
        results.add(
          SnobSubstitutabilityResult(
            spot: spot,
            sameCategoryCount: 0,
            totalRegionCount: 0,
            substitutabilityScore: 0.0,
          ),
        );
      }
    }


    // ==============================================================
    // 전체 결과 반환
    // ==============================================================

    print('');
    print('========================================');
    print('SUBSTITUTABILITY 계산 완료');
    print('계산 관광지 수 : ${results.length}');
    print('========================================');

    return results;
  }
}