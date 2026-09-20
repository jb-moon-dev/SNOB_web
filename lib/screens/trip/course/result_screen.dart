import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/travel_plan.dart';
import '../../../services/travel_plan_storage.dart';
import '../../../services/tourism_api_service.dart';
import '../../../services/congestion_service.dart';
import 'package:snob/snob/tourism_spot.dart';

import '../../../region_mapping/region_mapping_service.dart';
import '../../../region_mapping/spot_mapping_service.dart';
import '../../../region_mapping/snob_spot.dart';

import '../../../widgets/tourism_image.dart';

import 'snob_final.dart';
import '../../home_screen.dart';


// ================================================================
// Course Result Screen
// ================================================================

class CourseResultScreen extends StatefulWidget {
  final String regionName;

  const CourseResultScreen({
    super.key,
    required this.regionName,
  });

  @override
  State<CourseResultScreen> createState() =>
      _CourseResultScreenState();
}


// ================================================================
// 관광지 결과
// ================================================================

class CourseResultData {
  final Map<String, dynamic> spot;
  final double averageConcentration;
  final double snobScore;

  const CourseResultData({
    required this.spot,
    required this.averageConcentration,
    required this.snobScore,
  });
}


// ================================================================
// State
// ================================================================

class _CourseResultScreenState
    extends State<CourseResultScreen> {
  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  List<CourseResultData> results = [];

  late TravelPlan travelPlan;


  // ============================================================
  // initState
  // ============================================================

  @override
  void initState() {
    super.initState();

    travelPlan = TravelPlan.create(
      regionName: widget.regionName,
    );

    _initializeTravelPlan();

    _calculateSnob();
  }


  // ============================================================
  // 저장된 여행 일정 불러오기
  // ============================================================

  Future<void> _initializeTravelPlan() async {
    try {
      final TravelPlan? savedPlan =
          await TravelPlanStorage.loadTravelPlan();

      if (!context.mounted) {
        return;
      }

      if (savedPlan != null &&
          _normalizeName(savedPlan.regionName) ==
              _normalizeName(widget.regionName)) {
        setState(() {
          travelPlan = savedPlan;
        });

        debugPrint(
          '저장된 여행 일정 불러오기 완료: '
          '${savedPlan.regionName}',
        );

        debugPrint(
          '저장된 관광지 수: '
          '${savedPlan.totalSpotCount}',
        );
      } else {
        debugPrint(
          '현재 지역에 해당하는 저장된 일정이 없습니다.',
        );
      }
    } catch (e) {
      debugPrint(
        '여행 일정 불러오기 오류: $e',
      );
    }
  }


  // ============================================================
  // 전체 SNOB 계산
  // ============================================================

  Future<void> _calculateSnob() async {
    try {
      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'COURSE RESULT 시작',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '추천 지역 원본: ${widget.regionName}',
      );

      final String normalizedTarget =
          _normalizeName(widget.regionName);

      debugPrint(
        '추천 지역 정규화: $normalizedTarget',
      );


      // ==========================================================
      // 1. TourAPI 시도 조회
      // ==========================================================

      final List<Map<String, String>> regions =
          await TourismApiService.getRegions();

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '1. TourAPI 시도 조회',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '시도 수: ${regions.length}',
      );

      if (regions.isEmpty) {
        throw Exception(
          'TourAPI 시도 정보를 가져오지 못했습니다.',
        );
      }


      // ==========================================================
      // 2. 추천 지역의 시도 / 시군구 찾기
      // ==========================================================

      Map<String, String>? selectedRegion;
      String? selectedSigunguCode;
      String? selectedSigunguName;

      for (final Map<String, String> region
          in regions) {
        final String regionCode =
            region['code']?.trim() ?? '';

        final String regionName =
            region['name']?.trim() ?? '';

        final String normalizedRegion =
            _normalizeName(regionName);

        if (normalizedTarget ==
            normalizedRegion) {
          selectedRegion = region;

          debugPrint(
            '✅ 시도 자체 매칭',
          );

          debugPrint(
            '   $regionCode / $regionName',
          );

          break;
        }

        if (!normalizedTarget
            .startsWith(normalizedRegion)) {
          continue;
        }

        final String sigunguName =
            normalizedTarget
                .substring(
                  normalizedRegion.length,
                )
                .trim();

        debugPrint('');
        debugPrint(
          '✅ 시도 매칭 후보',
        );
        debugPrint(
          '   시도: $regionCode / $regionName',
        );
        debugPrint(
          '   찾는 시군구: $sigunguName',
        );

        final List<Map<String, String>>
            sigungus =
            await TourismApiService.getSigungus(
          regionCode,
        );

        debugPrint(
          '   시군구 수: ${sigungus.length}',
        );

        for (final Map<String, String> sigungu
            in sigungus) {
          final String code =
              sigungu['code']?.trim() ?? '';

          final String name =
              sigungu['name']?.trim() ?? '';

          final String normalizedSigungu =
              _normalizeName(name);

          if (normalizedSigungu ==
              sigunguName) {
            selectedRegion = region;

            selectedSigunguCode = code;

            selectedSigunguName = name;

            debugPrint('');
            debugPrint(
              '✅✅ 최종 TourAPI 지역 매칭 성공',
            );
            debugPrint(
              '   추천 지역: ${widget.regionName}',
            );
            debugPrint(
              '   시도: $regionCode / $regionName',
            );
            debugPrint(
              '   시군구: $code / $name',
            );

            break;
          }
        }

        if (selectedRegion != null) {
          break;
        }
      }


      // ==========================================================
      // 3. 지역 매칭 실패
      // ==========================================================

      if (selectedRegion == null) {
        throw Exception(
          '추천 지역의 TourAPI 지역 코드를 '
          '찾을 수 없습니다.\n'
          '지역: ${widget.regionName}',
        );
      }

      final String regionCode =
          selectedRegion['code']?.trim() ?? '';

      final String selectedRegionName =
          selectedRegion['name']?.trim() ?? '';


      // ==========================================================
      // 4. 시군구 코드 예외
      // ==========================================================

      if (selectedSigunguCode == null) {
        final List<Map<String, String>>
            sigungus =
            await TourismApiService.getSigungus(
          regionCode,
        );

        if (sigungus.isNotEmpty) {
          selectedSigunguCode =
              sigungus.first['code']?.trim();

          selectedSigunguName =
              sigungus.first['name']?.trim();
        }
      }

      if (selectedSigunguCode == null ||
          selectedSigunguCode!.isEmpty) {
        throw Exception(
          '추천 지역의 시군구 코드를 '
          '찾을 수 없습니다.\n'
          '지역: ${widget.regionName}',
        );
      }


      // ==========================================================
      // 5. 최종 TourAPI 지역 확인
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '5. 최종 TourAPI 지역',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '추천 지역 원본: ${widget.regionName}',
      );
      debugPrint(
        '추천 지역 정규화: $normalizedTarget',
      );
      debugPrint(
        '시도: '
        '$regionCode / '
        '$selectedRegionName',
      );
      debugPrint(
        '시군구: '
        '$selectedSigunguCode / '
        '$selectedSigunguName',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 6. 관광지 전체 조회
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '6. TourAPI 관광지 조회',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        'regionCode: $regionCode',
      );
      debugPrint(
        'sigunguCode: $selectedSigunguCode',
      );
      debugPrint(
        'regionName: ${widget.regionName}',
      );

      final List<TourismSpot> tourismSpots =
          await TourismApiService
              .getTourismSpotsByLegalDong(
        regionCode,
        selectedSigunguCode!,
        widget.regionName,
      );

      debugPrint(
        'TourAPI 관광지 수: '
        '${tourismSpots.length}',
      );

      if (tourismSpots.isNotEmpty) {
        debugPrint('');
        debugPrint(
          'TourAPI 관광지 샘플:',
        );

        final int sampleCount =
            tourismSpots.length < 5
                ? tourismSpots.length
                : 5;

        for (int i = 0;
            i < sampleCount;
            i++) {
          final TourismSpot spot =
              tourismSpots[i];

          debugPrint(
            '  ${i + 1}. '
            '${spot.title}'
            ' | contentId: ${spot.contentId}'
            ' | lDongRegnCd: ${spot.lDongRegnCd}'
            ' | lDongSignguCd: ${spot.lDongSignguCd}',
          );
        }
      }


      // ==========================================================
      // 7. 집중률 API 지역 매핑
      // ==========================================================

      final List<RegionQuery> regionQueries =
          RegionMappingService.getQueryRegions(
        regionCode: regionCode,
        sigunguCode: selectedSigunguCode!,
        regionName: widget.regionName,
      );

      if (regionQueries.isEmpty) {
        throw Exception(
          '집중률 API 지역 매핑 결과가 없습니다.\n'
          '추천 지역: ${widget.regionName}\n'
          'TourAPI: '
          '$regionCode / '
          '$selectedSigunguCode',
        );
      }

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '7. 집중률 API 지역 매핑',
      );
      debugPrint(
        '========================================',
      );

      for (final RegionQuery query
          in regionQueries) {
        debugPrint(
          'TourAPI 지역'
          ' : '
          '$regionCode / '
          '$selectedSigunguCode',
        );

        debugPrint(
          '집중률 API'
          ' : '
          '${query.areaCd} / '
          '${query.signguCd}',
        );

        debugPrint(
          '이유'
          ' : '
          '${query.reason}',
        );

        debugPrint(
          '----------------------------------------',
        );
      }

      final String substitutabilityRegionCode =
          regionQueries.first.signguCd;

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'Substitutability 지역 코드',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '지역 코드: $substitutabilityRegionCode',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 8. 집중률 API 조회
      // ==========================================================

      final CongestionService
          congestionService =
          CongestionService();

      final List<Map<String, dynamic>>
          allCongestionData = [];

      final Set<String>
          queriedRegions = {};

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '8. 집중률 API 조회',
      );
      debugPrint(
        '========================================',
      );

      for (final RegionQuery query
          in regionQueries) {
        final String key =
            '${query.areaCd}|'
            '${query.signguCd}';

        if (queriedRegions
            .contains(key)) {
          debugPrint(
            '중복 지역 조회 생략: $key',
          );

          continue;
        }

        queriedRegions.add(key);

        debugPrint('');
        debugPrint(
          '집중률 API 요청',
        );
        debugPrint(
          'areaCd: ${query.areaCd}',
        );
        debugPrint(
          'signguCd: ${query.signguCd}',
        );

        final List<Map<String, dynamic>>
            data =
            await congestionService
                .getAllCongestion(
          areaCd:
              query.areaCd,
          signguCd:
              query.signguCd,
        );

        allCongestionData.addAll(data);

        debugPrint(
          '집중률 데이터 추가: '
          '$key → ${data.length}개',
        );
      }

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '집중률 API 조회 완료',
      );
      debugPrint(
        '전체 집중률 데이터: '
        '${allCongestionData.length}개',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 9. 관광지 ↔ 집중률 매핑
      // ==========================================================

      final List<SnobSpot>
          mappedSpots =
          SpotMappingService.mapSpots(
        tourismSpots:
            tourismSpots,
        congestionData:
            allCongestionData,
      );

      final int matchedCount =
          mappedSpots
              .where(
                (SnobSpot spot) =>
                    spot.concentrationRate !=
                    null,
              )
              .length;

      final int unmatchedCount =
          mappedSpots.length -
              matchedCount;

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '9. 관광지 매핑 완료',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        'TourAPI 관광지: '
        '${tourismSpots.length}개',
      );
      debugPrint(
        '최종 관광지: '
        '${mappedSpots.length}개',
      );
      debugPrint(
        '집중률 매칭 성공: '
        '$matchedCount개',
      );
      debugPrint(
        '집중률 매칭 실패: '
        '$unmatchedCount개',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 10. SnobSpot → Map
      // ==========================================================

      final List<Map<String, dynamic>> spotMaps = [];

      for (final SnobSpot spot in mappedSpots) {
        final String? substitutabilitySignguCd =
            spot.concentrationSignguCd ??
                substitutabilityRegionCode;

        debugPrint(
          'Substitutability 지역 코드 적용: '
          '${spot.title} → '
          '$substitutabilitySignguCd',
        );

        // 실제 대체관광 데이터의 사람이 읽을 수 있는
        // 중분류명을 우선 사용합니다.
        // 예: 문화관광, 역사관광
        String category = '';

        if (substitutabilitySignguCd != null &&
            substitutabilitySignguCd.isNotEmpty) {
          try {
            category =
                await _findSubstitutabilityCategory(
              signguCd:
                  substitutabilitySignguCd,
              spotName:
                  spot.title,
            );
          } catch (e) {
            debugPrint(
              '매핑 관광지 카테고리 조회 실패: '
              '${spot.title} → $e',
            );
          }
        }

        // JSON에서 찾지 못한 경우에만 기존 값을 사용합니다.
        // VE03 같은 내부 코드는 화면에 노출하지 않습니다.
        if (category.isEmpty) {
          final String fallbackCategory =
              spot.lclsSystm2?.toString().trim() ?? '';

          if (fallbackCategory.isNotEmpty &&
              !RegExp(r'^[A-Z]{2}\d+$')
                  .hasMatch(fallbackCategory)) {
            category = fallbackCategory;
          }
        }

        spotMaps.add({
          'contentId':
              spot.contentId,
          'title':
              spot.title,
          'address':
              spot.address,
          'contentTypeId':
              spot.contentTypeId,
          'lDongRegnCd':
              spot.lDongRegnCd,
          'lDongSignguCd':
              spot.lDongSignguCd,
          'regionName':
              spot.regionName,
          'lclsSystm1':
              spot.lclsSystm1,
          'lclsSystm2':
              spot.lclsSystm2,
          'lclsSystm3':
              spot.lclsSystm3,
          'modifiedTime':
              spot.modifiedTime,
          'latitude':
              spot.latitude,
          'longitude':
              spot.longitude,
          'concentrationRate':
              spot.concentrationRate,
          'concentrationBaseYmd':
              spot.concentrationBaseYmd,
          'concentrationAreaCd':
              spot.concentrationAreaCd,
          'concentrationAreaNm':
              spot.concentrationAreaNm,
          'concentrationSignguCd':
              spot.concentrationSignguCd,
          'concentrationSignguNm':
              spot.concentrationSignguNm,
          'snobScore':
              spot.snobScore,
          'hubTatsNm':
              spot.title,
          'hubCtgryMclsNm':
              category,
          'signguCd':
              substitutabilitySignguCd,
          'sigunguCd':
              substitutabilitySignguCd,
          'signguNm':
              spot.concentrationSignguNm ??
                  selectedSigunguName,
        });
      }


      // ==========================================================
      // 10-1. 집중률 API 전용 관광지 추가
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '10-1. 집중률 API 전용 관광지 확인',
      );
      debugPrint(
        '========================================',
      );

      final Set<String>
          tourismSpotNames = {};

      for (final TourismSpot spot
          in tourismSpots) {
        final String normalizedName =
            SpotMappingService.normalizeName(
          spot.title,
        );

        if (normalizedName.isNotEmpty) {
          tourismSpotNames.add(
            normalizedName,
          );
        }
      }

      final Map<String, Map<String, dynamic>>
          congestionOnlySpots = {};

      for (final Map<String, dynamic> data
          in allCongestionData) {
        final String name =
            data['tAtsNm']
                    ?.toString()
                    .trim() ??
                '';

        if (name.isEmpty) {
          continue;
        }

        final String normalizedName =
            SpotMappingService.normalizeName(
          name,
        );

        if (normalizedName.isEmpty) {
          continue;
        }

        final String areaCd =
            data['areaCd']
                    ?.toString()
                    .trim() ??
                '';

        final String signguCd =
            data['signguCd']
                    ?.toString()
                    .trim() ??
                '';

        if (tourismSpotNames
            .contains(normalizedName)) {
          continue;
        }

        final String congestionKey =
            '$areaCd|'
            '$signguCd|'
            '$normalizedName';

        final Map<String, dynamic>?
            existing =
            congestionOnlySpots[
                congestionKey];

        if (existing == null) {
          congestionOnlySpots[
              congestionKey] = data;

          continue;
        }

        final String existingDate =
            existing['baseYmd']
                    ?.toString() ??
                '';

        final String currentDate =
            data['baseYmd']
                    ?.toString() ??
                '';

        if (currentDate.compareTo(
              existingDate,
            ) >
            0) {
          congestionOnlySpots[
              congestionKey] = data;
        }
      }

      debugPrint(
        '집중률 API 전용 관광지: '
        '${congestionOnlySpots.length}개',
      );


      for (final Map<String, dynamic> data
          in congestionOnlySpots.values) {
        final String name =
            data['tAtsNm']
                    ?.toString()
                    .trim() ??
                '';

        final String areaCd =
            data['areaCd']
                    ?.toString()
                    .trim() ??
                '';

        final String signguCd =
            data['signguCd']
                    ?.toString()
                    .trim() ??
                '';

        final String signguNm =
            data['signguNm']
                    ?.toString()
                    .trim() ??
                '';

        final double? concentrationRate =
            _toDouble(
          data['cnctrRate'],
        );

        if (name.isEmpty ||
            signguCd.isEmpty ||
            concentrationRate == null) {
          continue;
        }

        String category = '';

        try {
          category =
              await _findSubstitutabilityCategory(
            signguCd:
                signguCd,
            spotName:
                name,
          );
        } catch (e) {
          debugPrint(
            '카테고리 조회 실패: '
            '$name → $e',
          );
        }

        final String? hubTatsCd =
            data['hubTatsCd']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? data['hubTatsCd']
                .toString()
                .trim()
            : null;

        final double? snobScore =
            SpotMappingService
                .calculateSnobScore(
          concentrationRate,
        );

        spotMaps.add({
          'contentId':
              null,
          'hubTatsCd':
              hubTatsCd,
          'title':
              name,
          'hubTatsNm':
              name,
          'address':
              signguNm.isEmpty
                  ? widget.regionName
                  : signguNm,
          'contentTypeId':
              '12',
          'lDongRegnCd':
              areaCd,
          'lDongSignguCd':
              signguCd.length >= 5
                  ? signguCd.substring(
                      signguCd.length - 3,
                    )
                  : signguCd,
          'regionName':
              widget.regionName,
          'lclsSystm1':
              '',
          'lclsSystm2':
              category,
          'lclsSystm3':
              '',
          'modifiedTime':
              '',
          'latitude':
              null,
          'longitude':
              null,
          'concentrationRate':
              concentrationRate,
          'concentrationBaseYmd':
              data['baseYmd'],
          'concentrationAreaCd':
              data['areaCd'],
          'concentrationAreaNm':
              data['areaNm'],
          'concentrationSignguCd':
              signguCd,
          'concentrationSignguNm':
              signguNm,
          'snobScore':
              snobScore,
          'hubCtgryMclsNm':
              category,
          'signguCd':
              signguCd,
          'sigunguCd':
              signguCd,
          'signguNm':
              signguNm,
        });

        debugPrint(
          '➕ 집중률 API 전용 추가: '
          '$name'
          ' | 집중률: '
          '${concentrationRate.toStringAsFixed(2)}'
          ' | 카테고리: '
          '${category.isEmpty ? "없음" : category}'
          ' | hubTatsCd: '
          '${hubTatsCd ?? "없음"}',
        );
      }


      // ==========================================================
      // 11. SnobFinal
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '11. SNOB FINAL',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '대상 관광지: '
        '${spotMaps.length}개',
      );

      final SnobFinal
          snobFinal =
          SnobFinal();

      final List<SnobFinalResult>
          calculatedResults =
          await snobFinal.calculate(
        spotMaps,
      );

      debugPrint(
        'SNOB FINAL 결과 수: '
        '${calculatedResults.length}개',
      );


      // ==========================================================
      // 12. 화면용 결과 변환
      // ==========================================================

      final List<CourseResultData>
          finalResults =
          calculatedResults.map(
        (SnobFinalResult result) {
          return CourseResultData(
            spot: result.spot,
            averageConcentration:
                result.averageConcentration,
            snobScore:
                result.totalScore,
          );
        },
      ).toList();


      // ==========================================================
      // 13. 화면 업데이트
      // ==========================================================

      if (!context.mounted) {
        return;
      }

      setState(() {
        results = finalResults;
        isLoading = false;
        errorMessage = null;
      });


      // ==========================================================
      // 14. 최종 결과 로그
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'SNOB 계산 완료',
      );
      debugPrint(
        '최종 관광지 수: '
        '${finalResults.length}',
      );
      debugPrint(
        '========================================',
      );

      for (int i = 0;
          i < finalResults.length;
          i++) {
        final CourseResultData result =
            finalResults[i];

        debugPrint(
          '[${i + 1}] '
          '${_getSpotName(result.spot)}'
          ' | SNOB: '
          '${result.snobScore.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'COURSE RESULT 오류',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        'Exception: $e',
      );
      debugPrint(
        '추천 지역: ${widget.regionName}',
      );
      debugPrint(
        '========================================',
      );

      if (!context.mounted) {
        return;
      }

      setState(() {
        errorMessage =
            e.toString();

        isLoading = false;
      });
    }
  }


  // ============================================================
  // Substitutability JSON에서 관광지 카테고리 찾기
  // ============================================================

  Future<String> _findSubstitutabilityCategory({
    required String signguCd,
    required String spotName,
  }) async {
    const String dataPath =
        'assets/data/snob_substitutability_data.json';

    final String jsonString =
        await rootBundle.loadString(
      dataPath,
    );

    final dynamic decoded =
        jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      return '';
    }

    final dynamic regions =
        decoded['regions'];

    if (regions is! Map) {
      return '';
    }

    final dynamic region =
        regions[signguCd];

    if (region is! Map) {
      return '';
    }

    final dynamic spots =
        region['spots'];

    if (spots is! List) {
      return '';
    }

    final String normalizedTarget =
        SpotMappingService.normalizeName(
      spotName,
    );

    for (final dynamic item
        in spots) {
      if (item is! Map) {
        continue;
      }

      final String name =
          item['hubTatsNm']
                  ?.toString()
                  .trim() ??
              '';

      final String category =
          item['hubCtgryMclsNm']
                  ?.toString()
                  .trim() ??
              '';

      if (name.isEmpty ||
          category.isEmpty) {
        continue;
      }

      if (SpotMappingService.normalizeName(
            name,
          ) ==
          normalizedTarget) {
        return category;
      }
    }

    for (final dynamic item
        in spots) {
      if (item is! Map) {
        continue;
      }

      final String name =
          item['hubTatsNm']
                  ?.toString()
                  .trim() ??
              '';

      final String category =
          item['hubCtgryMclsNm']
                  ?.toString()
                  .trim() ??
              '';

      if (name == spotName &&
          category.isNotEmpty) {
        return category;
      }
    }

    return '';
  }


  // ============================================================
  // 이름 정규화
  // ============================================================

  String _normalizeName(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .trim();
  }


  // ============================================================
  // 관광지 이름
  // ============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['title'],
      spot['name'],
      spot['tAtsNm'],
      spot['hubTatsNm'],
    ];

    for (final dynamic value in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return '이름 없음';
  }


  // ============================================================
  // 카테고리
  // ============================================================

  String _getCategory(
    Map<String, dynamic> spot,
  ) {
    // 사람이 읽을 수 있는 중분류명을 가장 우선합니다.
    final List<dynamic> candidates = [
      spot['hubCtgryMclsNm'],
      spot['category'],
      spot['lclsSystm2'],
      spot['lclsSystm3'],
    ];

    for (final dynamic value in candidates) {
      if (value == null) {
        continue;
      }

      final String category =
          value.toString().trim();

      if (category.isEmpty) {
        continue;
      }

      // VE03, LC01 같은 내부 분류 코드는
      // 화면에 직접 표시하지 않습니다.
      if (RegExp(r'^[A-Z]{2}\d+$')
          .hasMatch(category)) {
        continue;
      }

      return category;
    }

    return '';
  }


  // ============================================================
  // 주소
  // ============================================================

  String _getAddress(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['address'],
      spot['addr1'],
      spot['addr2'],
      spot['signguNm'],
    ];

    for (final dynamic value in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return '';
  }


  // ============================================================
  // 숫자 변환
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }


  // ============================================================
  // Map → TravelSpot
  // ============================================================

  TravelSpot _createTravelSpot(
    CourseResultData result,
  ) {
    final Map<String, dynamic> spot =
        result.spot;

    final String name =
        _getSpotName(spot);

    final String category =
        _getCategory(spot);

    final String address =
        _getAddress(spot);

    final double? latitude =
        _toDouble(
      spot['latitude'] ??
          spot['lat'] ??
          spot['y'] ??
          spot['mapy'],
    );

    final double? longitude =
        _toDouble(
      spot['longitude'] ??
          spot['lng'] ??
          spot['lon'] ??
          spot['x'] ??
          spot['mapx'],
    );

    final String? contentId =
        spot['contentId']
            ?.toString();

    final String? kakaoPlaceId =
        spot['kakaoPlaceId']
            ?.toString();

    final String? kakaoPlaceUrl =
        spot['kakaoPlaceUrl']
            ?.toString();

    return TravelSpot(
      name: name,
      category:
          category.isEmpty
              ? null
              : category,
      address:
          address.isEmpty
              ? null
              : address,
      latitude: latitude,
      longitude: longitude,
      congestion:
          result.averageConcentration,
      snobScore:
          result.snobScore,
      contentId:
          contentId,
      kakaoPlaceId:
          kakaoPlaceId,
      kakaoPlaceUrl:
          kakaoPlaceUrl,
      startMinute: null,
      durationMinutes: 60,
      travelMinutesFromPrevious: 0,
    );
  }


  // ============================================================
  // 특정 Day 찾기
  // ============================================================

  TravelDay? _findDay(
    int dayNumber,
  ) {
    for (final TravelDay day
        in travelPlan.days) {
      if (day.day == dayNumber) {
        return day;
      }
    }

    return null;
  }


  // ============================================================
  // 관광지를 일정에 추가
  // ============================================================

  Future<bool> _addToPlan(
    CourseResultData result,
    int dayNumber,
  ) async {
    if (isSaving) {
      return false;
    }

    final TravelDay? day =
        _findDay(dayNumber);

    if (day == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '해당 여행 일정을 찾을 수 없습니다.',
          ),
        ),
      );

      return false;
    }

    final TravelSpot spot =
        _createTravelSpot(result);

    final bool alreadyExists =
        day.spots.any(
      (TravelSpot existingSpot) =>
          existingSpot.name ==
          spot.name,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}은(는) '
            '이미 Day $dayNumber에 '
            '추가되어 있어요.',
          ),
        ),
      );

      return false;
    }

    setState(() {
      isSaving = true;
    });

    day.spots.add(spot);

    travelPlan.updatedAt =
        DateTime.now();

    try {
      await TravelPlanStorage.saveTravelPlan(
        travelPlan,
      );

      if (!context.mounted) {
        return false;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}이(가) '
            'Day $dayNumber 일정에 '
            '추가됐어요.',
          ),
          duration:
              const Duration(
            seconds: 1,
          ),
        ),
      );

      return true;
    } catch (e) {
      day.spots.remove(spot);

      if (!context.mounted) {
        return false;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '일정 저장 중 오류가 발생했습니다.\n'
            '$e',
          ),
        ),
      );

      return false;
    }
  }


  // ============================================================
  // 일정에 이미 추가됐는지 확인
  // ============================================================

  bool _isAdded(
    String spotName,
  ) {
    return travelPlan.days
        .expand(
          (TravelDay day) =>
              day.spots,
        )
        .any(
      (TravelSpot spot) =>
          spot.name == spotName,
    );
  }


  // ============================================================
  // 관광지가 몇 일차에 있는지
  // ============================================================

  int? _getAddedDay(
    String spotName,
  ) {
    for (final TravelDay day
        in travelPlan.days) {
      final bool exists =
          day.spots.any(
        (TravelSpot spot) =>
            spot.name == spotName,
      );

      if (exists) {
        return day.day;
      }
    }

    return null;
  }


  // ============================================================
  // Day 추가
  // ============================================================

  Future<void> _addDay() async {
    final int nextDay =
        travelPlan.days.isEmpty
            ? 1
            : travelPlan.days
                    .map(
                      (TravelDay day) =>
                          day.day,
                    )
                    .reduce(
                      (int a, int b) =>
                          a > b ? a : b,
                    ) +
                1;

    travelPlan.days.add(
      TravelDay(
        day: nextDay,
      ),
    );

    travelPlan.days.sort(
      (TravelDay a, TravelDay b) =>
          a.day.compareTo(b.day),
    );

    travelPlan.updatedAt =
        DateTime.now();

    await TravelPlanStorage.saveTravelPlan(
      travelPlan,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Day $nextDay이 추가됐어요.',
        ),
        duration:
            const Duration(
          seconds: 1,
        ),
      ),
    );
  }


  // ============================================================
  // 현재 일정 보기
  // ============================================================

  void _showPlan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setModalState,
          ) {
            return SafeArea(
              child: Container(
                constraints:
                    BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context)
                              .size
                              .height *
                          0.8,
                ),
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  travelPlan
                                      .regionName,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        22,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${travelPlan.totalSpotCount}곳의 관광지가 추가됨',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            icon:
                                const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Expanded(
                        child:
                            ListView(
                          children: [
                            ...travelPlan
                                .days
                                .map(
                              (
                                TravelDay day,
                              ) {
                                return _buildDaySection(
                                  day,
                                  setModalState,
                                );
                              },
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  () async {
                                await _addDay();

                                if (mounted) {
                                  setModalState(
                                    () {},
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons.add,
                              ),
                              label:
                                  const Text(
                                '여행 일정 추가',
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ============================================================
  // Day 하나 표시
  // ============================================================

  Widget _buildDaySection(
    TravelDay day,
    StateSetter setModalState,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'DAY ${day.day}',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  '${day.spots.length}곳',
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            if (day.spots.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Text(
                  '아직 추가한 관광지가 없어요.',
                  style:
                      TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),
              )
            else
              ...day.spots
                  .asMap()
                  .entries
                  .map(
                (
                  MapEntry<int, TravelSpot> entry,
                ) {
                  final int index =
                      entry.key;

                  final TravelSpot spot =
                      entry.value;

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading:
                        CircleAvatar(
                      radius: 17,
                      child: Text(
                        '${index + 1}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      spot.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    subtitle:
                        spot.category !=
                                null
                            ? Text(
                                spot.category!,
                              )
                            : null,
                    trailing:
                        IconButton(
                      icon:
                          const Icon(
                        Icons
                            .delete_outline,
                      ),
                      onPressed:
                          () async {
                        day.spots
                            .removeWhere(
                          (
                            TravelSpot item,
                          ) =>
                              item.name ==
                              spot.name,
                        );

                        travelPlan
                                .updatedAt =
                            DateTime.now();

                        await TravelPlanStorage
                            .saveTravelPlan(
                          travelPlan,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        setState(
                          () {},
                        );

                        setModalState(
                          () {},
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // 일정 추가 Day 선택
  // ============================================================

  void _showDaySelector(
    CourseResultData result,
  ) {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext context,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '어느 날에 추가할까요?',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  _getSpotName(
                    result.spot,
                  ),
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ...travelPlan.days.map(
                  (
                    TravelDay day,
                  ) {
                    return ListTile(
                      leading:
                          CircleAvatar(
                        child:
                            Text(
                          '${day.day}',
                        ),
                      ),
                      title:
                          Text(
                        'Day ${day.day}',
                      ),
                      subtitle:
                          Text(
                        '${day.spots.length}곳',
                      ),
                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),
                      onTap:
                          isSaving
                              ? null
                              : () async {
                                  final bool added =
                                      await _addToPlan(
                                    result,
                                    day.day,
                                  );

                                  if (added &&
                                      context.mounted) {
                                    Navigator.pop(
                                      context,
                                    );
                                  }
                                },
                    );
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                OutlinedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                              Navigator.pop(
                                context,
                              );

                              await _addDay();

                              if (!context.mounted) {
                                return;
                              }

                              _showDaySelector(
                                result,
                              );
                            },
                  icon:
                      const Icon(
                    Icons.add,
                  ),
                  label:
                      const Text(
                    '새로운 Day 추가',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      48,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ============================================================
  // 대표 관광지
  // ============================================================

  CourseResultData? get _representativeResult {
    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }


  // ============================================================
  // 코스 전체 일정 만들기 진입
  // ============================================================
  //
  // 현재 기존 로직은 관광지별 일정 추가 방식이므로
  // 첫 번째 추천 관광지의 기존 Day 선택 화면으로 연결한다.
  // ============================================================

  void _startCoursePlanning() {
    final CourseResultData? first =
        _representativeResult;

    if (first == null) {
      return;
    }

    _showDaySelector(first);
  }


  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F5),
      body:
          _buildBody(),
    );
  }


  // ============================================================
  // Body
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(
              height: 20,
            ),
            Text(
              '관광지와 SNOB 점수를 분석하고 있어요.',
              style:
                  TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              '잠시만 기다려주세요.',
              style:
                  TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      );
    }


    if (errorMessage != null) {
      return _buildErrorState();
    }


    if (results.isEmpty) {
      return const Center(
        child: Text(
          '추천할 관광지가 없습니다.',
          textAlign:
              TextAlign.center,
        ),
      );
    }


    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isDesktop =
            constraints.maxWidth >= 900;

        return Column(
          children: [
            _buildWebHeader(
              isDesktop,
            ),

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1240,
                    ),
                    child:
                        isDesktop
                            ? _buildDesktopCourse()
                            : _buildMobileCourse(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  // ============================================================
  // Web Header
  // ============================================================

  Widget _buildWebHeader(
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        border:
            Border(
          bottom:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1240,
          ),
          child: Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  isDesktop ? 20 : 16,
              vertical: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'SNOB',
                    style:
                        TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          -1,
                      color:Color(0xFF21624B),
                    ),
                  ),
                ),

                const Spacer(),

                if (isDesktop)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed:
                            _showPlan,
                        icon:
                            const Icon(
                          Icons
                              .calendar_today_outlined,
                          size: 18,
                        ),
                        label:
                            const Text(
                          '여행 일정',
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      TextButton(
                        onPressed:
                            () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child:
                            const Text(
                          '홈 화면',
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    onPressed:
                        _showPlan,
                    icon:
                        const Icon(
                      Icons
                          .calendar_today_outlined,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ============================================================
  // Desktop
  // ============================================================

  Widget _buildDesktopCourse() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildPageTitle(),

        const SizedBox(
          height: 28,
        ),

        Container(
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              28,
            ),
            border:
                Border.all(
              color:
                  Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.04,
                ),
                blurRadius:
                    30,
                offset:
                    const Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child:
                    _buildCourseSummary(),
              ),

              Container(
                width:
                    1,
                height:
                    650,
                color:
                    Colors.grey.shade200,
              ),

              Expanded(
                flex: 6,
                child:
                    _buildCourseTimeline(),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ============================================================
  // Mobile
  // ============================================================

  Widget _buildMobileCourse() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildPageTitle(),

        const SizedBox(
          height: 24,
        ),

        _buildCourseSummary(),

        const SizedBox(
          height: 28,
        ),

        _buildCourseTimeline(),
      ],
    );
  }


  // ============================================================
  // 페이지 제목
  // ============================================================

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '추천 코스',
          style:
              TextStyle(
            fontSize:
                MediaQuery.of(context)
                    .size
                    .width >=
                    900
                ? 16
                : 14,
            color:
                Colors.grey.shade600,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          widget.regionName,
          style:
              TextStyle(
            fontSize:
                MediaQuery.of(context)
                    .size
                    .width >=
                    900
                ? 42
                : 32,
            fontWeight:
                FontWeight.w800,
            letterSpacing:
                -1.2,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Text(
          'SNOB 점수를 기준으로 나에게 맞는 여행지를 연결한 추천 코스예요.',
          style:
              TextStyle(
            fontSize:
                MediaQuery.of(context)
                    .size
                    .width >=
                    900
                ? 16
                : 14,
            color:
                Colors.grey.shade600,
            height:
                1.5,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // 코스 대표 정보
  // ============================================================

  Widget _buildCourseSummary() {
    final CourseResultData? representative =
        _representativeResult;

    return Padding(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildRepresentativeImage(
            representative,
          ),

          const SizedBox(
            height: 24,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.black,
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child:
                const Text(
              'SNOB RECOMMENDED COURSE',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    10,
                fontWeight:
                    FontWeight.bold,
                letterSpacing:
                    0.7,
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            widget.regionName,
            style:
                const TextStyle(
              fontSize:
                  30,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  -0.8,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            '${results.length}곳의 추천 관광지',
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize:
                  14,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          _buildSummaryStats(),

          const SizedBox(
            height: 24,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton(
              onPressed:
                  _startCoursePlanning,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.black,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical:
                      17,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child:
                  const Text(
                '이 코스로 여행 일정 만들기',
                style:
                    TextStyle(
                  fontSize:
                      15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Center(
            child:
                Text(
              '관광지를 선택하면 원하는 Day에 추가할 수 있어요.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize:
                    12,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // 대표 이미지
  // ============================================================

  Widget _buildRepresentativeImage(
    CourseResultData? result,
  ) {
    final String? contentId =
        result?.spot['contentId']
            ?.toString();

    final bool hasImage =
        contentId != null &&
            contentId.trim().isNotEmpty &&
            contentId != 'null';

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child:
          SizedBox(
        width:
            double.infinity,
        height:
            280,
        child:
            hasImage
                ? TourismImage(
                    contentId:
                        contentId,
                    width:
                        double.infinity,
                    height:
                        280,
                    fit:
                        BoxFit.cover,
                  )
                : _buildNoImageBox(
                    height:
                        280,
                  ),
      ),
    );
  }


  // ============================================================
  // 요약 통계
  // ============================================================

  Widget _buildSummaryStats() {
    final double averageSnob =
        results.isEmpty
            ? 0
            : results
                    .map(
                      (
                        CourseResultData result,
                      ) =>
                          result.snobScore,
                    )
                    .reduce(
                      (
                        double a,
                        double b,
                      ) =>
                          a + b,
                    ) /
                results.length;

    final double averageCongestion =
        results.isEmpty
            ? 0
            : results
                    .map(
                      (
                        CourseResultData result,
                      ) =>
                          result.averageConcentration,
                    )
                    .reduce(
                      (
                        double a,
                        double b,
                      ) =>
                          a + b,
                    ) /
                results.length;

    return Row(
      children: [
        Expanded(
          child:
              _buildStatItem(
            icon:
                Icons
                    .location_on_outlined,
            label:
                '추천 관광지',
            value:
                '${results.length}곳',
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
              _buildStatItem(
            icon:
                Icons
                    .travel_explore,
            label:
                '평균 SNOB',
            value:
                averageSnob
                    .toStringAsFixed(
                  1,
                ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
              _buildStatItem(
            icon:
                Icons
                    .groups_outlined,
            label:
                '평균 집중률',
            value:
                averageCongestion
                    .toStringAsFixed(
                  1,
                ),
          ),
        ),
      ],
    );
  }


  // ============================================================
  // 통계 아이템
  // ============================================================

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF6F7F4,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size:
                18,
            color:
                Colors.grey.shade700,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            label,
            style:
                TextStyle(
              fontSize:
                  10,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize:
                  16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // 관광지 Timeline
  // ============================================================

  Widget _buildCourseTimeline() {
    return Padding(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여행 코스',
                      style:
                          TextStyle(
                        fontSize:
                            22,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      '추천 순서대로 여행지를 확인해보세요.',
                      style:
                          TextStyle(
                        fontSize:
                            13,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    '현재 일정 보기',
                onPressed:
                    _showPlan,
                icon:
                    const Icon(
                  Icons
                      .calendar_today_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          ...results
              .asMap()
              .entries
              .map(
            (
              MapEntry<int, CourseResultData>
                  entry,
            ) {
              return _buildCourseStop(
                index:
                    entry.key,
                result:
                    entry.value,
                isLast:
                    entry.key ==
                        results.length -
                            1,
              );
            },
          ),
        ],
      ),
    );
  }


  // ============================================================
  // 관광지 하나
  // ============================================================

  Widget _buildCourseStop({
    required int index,
    required CourseResultData result,
    required bool isLast,
  }) {
    final Map<String, dynamic> spot =
        result.spot;

    final String spotName =
        _getSpotName(spot);

    final String category =
        _getCategory(spot);

    final String address =
        _getAddress(spot);

    final String? contentId =
        spot['contentId']
            ?.toString();

    final bool hasImage =
        contentId != null &&
            contentId.trim().isNotEmpty &&
            contentId != 'null';

    final bool isAdded =
        _isAdded(
      spotName,
    );

    final int? addedDay =
        _getAddedDay(
      spotName,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width:
                  34,
              child:
                  Column(
                children: [
                  Container(
                    width:
                        34,
                    height:
                        34,
                    alignment:
                        Alignment.center,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.black,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        Text(
                      '${index + 1}',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  if (!isLast)
                    Container(
                      width:
                          1,
                      height:
                          130,
                      margin:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            8,
                      ),
                      color:
                          Colors.grey.shade300,
                    ),
                ],
              ),
            ),

            const SizedBox(
              width:
                  14,
            ),

            Expanded(
              child:
                  Container(
                margin:
                    const EdgeInsets.only(
                  bottom:
                      16,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                            child:
                                SizedBox(
                              width:
                                  130,
                              height:
                                  110,
                              child:
                                  hasImage
                                      ? TourismImage(
                                          contentId:
                                              contentId,
                                          width:
                                              130,
                                          height:
                                              110,
                                          fit:
                                              BoxFit.cover,
                                        )
                                      : _buildNoImageBox(
                                          height:
                                              110,
                                          width:
                                              130,
                                        ),
                            ),
                          ),

                          const SizedBox(
                            width:
                                14,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spotName,
                                  maxLines:
                                      2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight.w800,
                                    height:
                                        1.2,
                                  ),
                                ),

                                if (category
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height:
                                        7,
                                  ),
                                  Text(
                                    category,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                      color:
                                          Colors.grey.shade600,
                                    ),
                                  ),
                                ],

                                if (address
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height:
                                        5,
                                  ),
                                  Text(
                                    address,
                                    maxLines:
                                        2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          11,
                                      color:
                                          Colors.grey.shade500,
                                      height:
                                          1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildCourseScore(
                              result,
                            ),
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          SizedBox(
                            height:
                                40,
                            child:
                                isAdded
                                    ? Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              13,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              const Color(
                                            0xFFEFF7EF,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child:
                                            Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              size:
                                                  16,
                                              color:
                                                  Colors.green,
                                            ),
                                            const SizedBox(
                                              width:
                                                  5,
                                            ),
                                            Text(
                                              'Day $addedDay',
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    12,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed:
                                            isSaving
                                                ? null
                                                : () {
                                                    _showDaySelector(
                                                      result,
                                                    );
                                                  },
                                        style:
                                            OutlinedButton.styleFrom(
                                          foregroundColor:
                                              Colors.black,
                                          side:
                                              BorderSide(
                                            color:
                                                Colors.grey.shade300,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child:
                                            const Text(
                                          '일정에 추가',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ============================================================
  // 코스 점수
  // ============================================================

  Widget _buildCourseScore(
    CourseResultData result,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,
        vertical:
            9,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF6F7F4,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons.travel_explore,
            size:
                18,
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'SNOB',
                  style:
                      TextStyle(
                    fontSize:
                        9,
                    color:
                        Colors.grey.shade600,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                Text(
                  result.snobScore.toStringAsFixed(1),
                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          Text(
            '집중률 '
            '${result.averageConcentration.toStringAsFixed(1)}',
            style:
                TextStyle(
              fontSize:
                  10,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // 이미지 없음
  // ============================================================

  Widget _buildNoImageBox({
    required double height,
    double? width,
  }) {
    return Container(
      width:
          width,
      height:
          height,
      color:
          const Color(
        0xFFE9ECE5,
      ),
      child:
          Center(
        child:
            Icon(
          Icons
              .landscape_outlined,
          size:
              42,
          color:
              Colors.grey.shade500,
        ),
      ),
    );
  }


  // ============================================================
  // 오류 화면
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child:
            ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth:
                560,
          ),
          child:
              Container(
            padding:
                const EdgeInsets.all(
              32,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child:
                Column(
              children: [
                Container(
                  width:
                      64,
                  height:
                      64,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      Icon(
                    Icons
                        .error_outline,
                    size:
                        32,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height:
                      18,
                ),

                const Text(
                  '코스 추천 중 오류가 발생했습니다.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      12,
                ),

                Text(
                  errorMessage!,
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize:
                        13,
                    color:
                        Colors.grey.shade600,
                    height:
                        1.5,
                  ),
                ),

                const SizedBox(
                  height:
                      24,
                ),

                OutlinedButton(
                  onPressed:
                      () {
                    setState(() {
                      isLoading =
                          true;
                      errorMessage =
                          null;
                    });

                    _calculateSnob();
                  },
                  child:
                      const Text(
                    '다시 시도',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}