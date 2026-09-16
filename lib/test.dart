import 'package:snob/region_mapping/region_mapping_service.dart';
import 'package:snob/services/tourism_api_service.dart';

Future<void> main() async {
  // ============================================================
  // 테스트할 지역 목록
  // ============================================================
  //
  // 일반 지역 + 행정구역 예외 지역을 함께 테스트한다.
  //
  // 각 지역에 대해:
  //
  // 지역명
  //   ↓
  // TourAPI 시도 코드
  //   ↓
  // TourAPI 시군구 코드
  //   ↓
  // RegionMappingService
  //   ↓
  // 집중률 API 코드
  //
  // 를 확인한다.
  // ============================================================

  const List<String> targetRegions = [
    // ----------------------------------------------------------
    // 일반 지역
    // ----------------------------------------------------------

    '서울특별시 성동구',
    '부산광역시 해운대구',
    '대구광역시 서구',
    '대전광역시 유성구',
    '울산광역시 남구',

    '경기도 이천시',
    '경기도 수원시 영통구',

    '충청북도 청주시 서원구',
    '충청남도 계룡시',

    '전남광주통합특별시 여수시',
    '경상북도 상주시',
    '경상남도 김해시',

    '강원특별자치도 평창군',
    '전북특별자치도 전주시 덕진구',

    '제주특별자치도 제주시',

    // ----------------------------------------------------------
    // 인천 행정구역 개편
    // ----------------------------------------------------------

    '인천광역시 영종구',
    '인천광역시 제물포구',
    '인천광역시 서해구',
    '인천광역시 검단구',

    // ----------------------------------------------------------
    // 화성시 행정구역 개편
    // ----------------------------------------------------------

    '경기도 화성시',
    '경기도 화성시 만세구',
    '경기도 화성시 효행구',
    '경기도 화성시 병점구',
    '경기도 화성시 동탄구',

    // ----------------------------------------------------------
    // 전남광주통합특별시
    // ----------------------------------------------------------

    '전남광주통합특별시 동구',
    '전남광주통합특별시 서구',
    '전남광주통합특별시 남구',
    '전남광주통합특별시 북구',
    '전남광주통합특별시 광산구',

    '전남광주통합특별시 목포시',
    '전남광주통합특별시 여수시',
    '전남광주통합특별시 순천시',
    '전남광주통합특별시 나주시',
    '전남광주통합특별시 광양시',
  ];

  print('');
  print('==================================================');
  print('SNOB 전국 지역 코드 매핑 테스트');
  print('==================================================');
  print('총 테스트 지역: ${targetRegions.length}개');
  print('==================================================');

  // ============================================================
  // TourAPI 시도 목록 조회
  // ============================================================

  final List<Map<String, String>> regions =
      await TourismApiService.getRegions();

  print('');
  print('TourAPI 시도 조회 완료');
  print('전체 시도 수: ${regions.length}');
  print('==================================================');

  if (regions.isEmpty) {
    print('');
    print('❌ TourAPI 시도 조회 실패');
    print('테스트를 종료합니다.');
    return;
  }

  // ============================================================
  // 결과 저장
  // ============================================================

  int successCount = 0;
  int failCount = 0;

  final List<String> failedRegions = [];

  // ============================================================
  // 지역별 테스트
  // ============================================================

  for (int i = 0; i < targetRegions.length; i++) {
    final String targetRegion =
        targetRegions[i];

    print('');
    print('');
    print('==================================================');
    print(
      '[${i + 1}/${targetRegions.length}] '
      '$targetRegion',
    );
    print('==================================================');

    Map<String, String>? selectedRegion;
    String? selectedSigunguCode;
    String? selectedSigunguName;

    // ==========================================================
    // 1. TourAPI 시도 찾기
    // ==========================================================

    for (final Map<String, String> region
        in regions) {
      final String regionCode =
          region['code'] ?? '';

      final String regionName =
          region['name'] ?? '';

      // --------------------------------------------------------
      // 시도 자체
      // --------------------------------------------------------

      if (targetRegion == regionName) {
        selectedRegion = region;
        break;
      }

      // --------------------------------------------------------
      // 시도 + 시군구
      // --------------------------------------------------------

      if (!targetRegion.startsWith(
        '$regionName ',
      )) {
        continue;
      }

      final String sigunguName =
          targetRegion
              .substring(
                regionName.length,
              )
              .trim();

      // --------------------------------------------------------
      // 해당 시도의 시군구 조회
      // --------------------------------------------------------

      final List<Map<String, String>>
          sigungus =
          await TourismApiService.getSigungus(
        regionCode,
      );

      // --------------------------------------------------------
      // 시군구 찾기
      // --------------------------------------------------------

      for (final Map<String, String> sigungu
          in sigungus) {
        final String code =
            sigungu['code'] ?? '';

        final String name =
            sigungu['name'] ?? '';

        if (name == sigunguName) {
          selectedRegion = region;
          selectedSigunguCode = code;
          selectedSigunguName = name;

          break;
        }
      }

      if (selectedRegion != null) {
        break;
      }
    }

    // ==========================================================
    // TourAPI 지역 찾기 실패
    // ==========================================================

    if (selectedRegion == null) {
      print('');
      print('❌ TourAPI 지역 찾기 실패');
      print('지역: $targetRegion');

      failCount++;
      failedRegions.add(targetRegion);

      continue;
    }

    final String tourRegionCode =
        selectedRegion['code']!;

    final String tourRegionName =
        selectedRegion['name'] ?? '';

    // ==========================================================
    // 시군구가 없는 경우
    // ==========================================================

    if (selectedSigunguCode == null) {
      final List<Map<String, String>>
          sigungus =
          await TourismApiService.getSigungus(
        tourRegionCode,
      );

      if (sigungus.isNotEmpty) {
        selectedSigunguCode =
            sigungus.first['code'];

        selectedSigunguName =
            sigungus.first['name'];
      }
    }

    if (selectedSigunguCode == null) {
      print('');
      print('❌ TourAPI 시군구 코드 없음');
      print('지역: $targetRegion');

      failCount++;
      failedRegions.add(targetRegion);

      continue;
    }

    // ==========================================================
    // TourAPI 결과 출력
    // ==========================================================

    print('');
    print('TourAPI 결과');
    print(
      '  시도   : '
      '$tourRegionCode / '
      '$tourRegionName',
    );

    print(
      '  시군구 : '
      '$selectedSigunguCode / '
      '$selectedSigunguName',
    );

    // ==========================================================
    // RegionMappingService 실행
    // ==========================================================

    final List<RegionQuery> queries =
        RegionMappingService.getQueryRegions(
      regionCode: tourRegionCode,
      sigunguCode: selectedSigunguCode,
      regionName: targetRegion,
    );

    // ==========================================================
    // 매핑 실패
    // ==========================================================

    if (queries.isEmpty) {
      print('');
      print('❌ 집중률 API 매핑 실패');
      print('지역: $targetRegion');

      failCount++;
      failedRegions.add(targetRegion);

      continue;
    }

    // ==========================================================
    // 매핑 결과 확인
    // ==========================================================

    bool localSuccess = true;

    for (final RegionQuery query
        in queries) {
      print('');
      print('집중률 API 결과');
      print(
        '  areaCd   : ${query.areaCd}',
      );
      print(
        '  signguCd : ${query.signguCd}',
      );
      print(
        '  reason   : ${query.reason}',
      );

      // --------------------------------------------------------
      // 기본 코드 형식 확인
      // --------------------------------------------------------

      if (query.areaCd.isEmpty ||
          query.signguCd.isEmpty) {
        localSuccess = false;

        print(
          '❌ 집중률 API 코드가 비어 있습니다.',
        );

        continue;
      }

      if (!RegExp(
        r'^\d+$',
      ).hasMatch(query.areaCd)) {
        localSuccess = false;

        print(
          '❌ areaCd 형식 오류: '
          '${query.areaCd}',
        );
      }

      if (!RegExp(
        r'^\d{5}$',
      ).hasMatch(query.signguCd)) {
        localSuccess = false;

        print(
          '❌ signguCd 형식 오류: '
          '${query.signguCd}',
        );
      }
    }

    // ==========================================================
    // 지역 최종 판정
    // ==========================================================

    if (localSuccess) {
      print('');
      print('✅ 매핑 성공');

      successCount++;
    } else {
      print('');
      print('❌ 매핑 실패');

      failCount++;
      failedRegions.add(targetRegion);
    }
  }

  // ============================================================
  // 최종 결과
  // ============================================================

  print('');
  print('');
  print('==================================================');
  print('SNOB 전국 지역 코드 매핑 테스트 결과');
  print('==================================================');
  print(
    '전체 테스트 : ${targetRegions.length}개',
  );
  print(
    '매핑 성공    : $successCount개',
  );
  print(
    '매핑 실패    : $failCount개',
  );
  print('==================================================');

  // ============================================================
  // 실패 지역 출력
  // ============================================================

  if (failedRegions.isNotEmpty) {
    print('');
    print('❌ 실패한 지역');
    print('--------------------------------------------------');

    for (final String region
        in failedRegions) {
      print(
        '- $region',
      );
    }

    print('--------------------------------------------------');
  } else {
    print('');
    print('🎉 모든 테스트 지역의 매핑이 성공했습니다.');
  }

  // ============================================================
  // 최종 판정
  // ============================================================

  print('');
  print('==================================================');

  if (failCount == 0) {
    print('✅ 전국 주요 지역 매핑 테스트 통과');
  } else {
    print(
      '⚠️ 일부 지역의 매핑을 확인해야 합니다.',
    );
  }

  print('==================================================');
}
