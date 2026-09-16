import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'user_vector.dart';
import 'region_vector.dart';

class RecommendationEngine {
  // ============================================================
  // SNOB canonical 지역 데이터
  //
  // assets/data/snob_concentration.json
  // 의 records에서 실제 존재하는 지역만 사용한다.
  //
  // 즉, 이 JSON에 없는 지역은 추천하지 않는다.
  // ============================================================

  static Set<String>? _canonicalRegionCache;

  // ============================================================
  // 문자열 정리
  // ============================================================

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // ============================================================
  // canonical 210개 지역 로드
  // ============================================================

  static Future<Set<String>> loadCanonicalRegions() async {
    if (_canonicalRegionCache != null) {
      return _canonicalRegionCache!;
    }

    final text = await rootBundle.loadString(
      'assets/data/snob_concentration.json',
    );

    final decoded = jsonDecode(text);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'snob_concentration.json 형식이 올바르지 않습니다.',
      );
    }

    final records = decoded['records'];

    if (records is! List) {
      throw Exception(
        'snob_concentration.json에 records가 없습니다.',
      );
    }

    final regions = <String>{};

    for (final item in records) {
      if (item is! Map) continue;

      final sido = item['sido']?.toString().trim() ?? '';
      final sigungu = item['sigungu']?.toString().trim() ?? '';

      if (sido.isEmpty || sigungu.isEmpty) {
        continue;
      }

      regions.add(
        _normalize('$sido $sigungu'),
      );
    }

    if (regions.isEmpty) {
      throw Exception(
        'snob_concentration.json에서 canonical 지역을 찾을 수 없습니다.',
      );
    }

    _canonicalRegionCache = regions;

    print(
      '========================================',
    );
    print(
      'SNOB canonical 지역 로드 완료',
    );
    print(
      'canonical 지역 수: ${regions.length}',
    );
    print(
      '========================================',
    );

    return regions;
  }

  // ============================================================
  // RegionVector → canonical 지역만 필터링
  // ============================================================

  static List<RegionVector> filterCanonicalRegions(
    List<RegionVector> regions,
    Set<String> canonicalRegions,
  ) {
    final result = <RegionVector>[];

    for (final region in regions) {
      final name = _normalize(region.regionName);

      if (canonicalRegions.contains(name)) {
        result.add(region);
      } else {
        print(
          '추천 대상 제외: $name',
        );
      }
    }

    return result;
  }

  // ============================================================
  // 지역 유사도 순위
  // ============================================================

  static List<RegionVector> rankRegions(
    UserVector user,
    List<RegionVector> regions,
  ) {
    final result = List<RegionVector>.from(regions);

    result.sort((a, b) {
      final scoreA = similarity(
        user,
        a,
      );

      final scoreB = similarity(
        user,
        b,
      );

      return scoreB.compareTo(scoreA);
    });

    return result;
  }

  // ============================================================
  // 사용자 - 지역 유사도
  // ============================================================

  static double similarity(
    UserVector user,
    RegionVector region,
  ) {
    final natureDistance =
        user.nature - region.nature;

    final hiddenDistance =
        user.hidden - region.hidden;

    final healingDistance =
        user.healing - region.healing;

    final distance = sqrt(
      pow(natureDistance, 2) +
          pow(hiddenDistance, 2) +
          pow(healingDistance, 2),
    );

    return 100 - distance;
  }

  // ============================================================
  // Top 3 중 랜덤 추천
  //
  // 중요:
  // 이 함수는 이제 snob_concentration.json의
  // canonical 210개 지역만 추천한다.
  // ============================================================

  static Future<RegionVector> recommendRandomRegion(
    UserVector user,
    List<RegionVector> regions,
  ) async {
    if (regions.isEmpty) {
      throw Exception(
        '추천 가능한 지역이 없습니다.',
      );
    }

    // ------------------------------------------------------------
    // 1. 실제 canonical 지역 210개 로드
    // ------------------------------------------------------------

    final canonicalRegions =
        await loadCanonicalRegions();

    // ------------------------------------------------------------
    // 2. RegionVector 중 canonical 지역만 남김
    // ------------------------------------------------------------

    final canonicalVectors =
        filterCanonicalRegions(
      regions,
      canonicalRegions,
    );

    if (canonicalVectors.isEmpty) {
      throw Exception(
        'snob_concentration.json의 canonical 지역과 일치하는 '
        '여행 추천 지역이 없습니다.',
      );
    }

    // ------------------------------------------------------------
    // 3. 유사도 순위
    // ------------------------------------------------------------

    final ranked = rankRegions(
      user,
      canonicalVectors,
    );

    // ------------------------------------------------------------
    // 4. Top 3
    // ------------------------------------------------------------

    final top3 = ranked
        .take(
          min(
            3,
            ranked.length,
          ),
        )
        .toList();

    // ------------------------------------------------------------
    // 5. 랜덤 1개
    // ------------------------------------------------------------

    final random = Random();

    final selected =
        top3[random.nextInt(top3.length)];

    print(
      '========================================',
    );
    print(
      'SNOB 지역 추천',
    );
    print(
      '전체 RegionVector: ${regions.length}',
    );
    print(
      'canonical 지역: ${canonicalRegions.length}',
    );
    print(
      'canonical RegionVector: ${canonicalVectors.length}',
    );
    print(
      'Top 3:',
    );

    for (int i = 0; i < top3.length; i++) {
      print(
        '${i + 1}. ${top3[i].regionName}',
      );
    }

    print(
      '최종 추천: ${selected.regionName}',
    );

    print(
      '========================================',
    );

    return selected;
  }
}

