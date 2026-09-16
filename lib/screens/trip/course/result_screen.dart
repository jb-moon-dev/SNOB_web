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

import 'snob_final.dart';


// ================================================================
// Course Result Screen
// ================================================================

class CourseResultScreen extends StatefulWidget {
  // ============================================================
  // 추천 지역명
  // ============================================================

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
  // ============================================================
  // 상태
  // ============================================================

  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  List<CourseResultData> results = [];

  // ============================================================
  // 여행 일정
  // ============================================================

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

      if (!mounted) {
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
  //
  // 추천 지역명
  // ↓
  // TourAPI 시도 코드 확인
  // ↓
  // TourAPI 시군구 코드 확인
  // ↓
  // 관광지 전체 조회
  // ↓
  // RegionMappingService
  // ↓
  // 집중률 API 조회
  // ↓
  // 관광지 ↔ 집중률 매칭
  // ↓
  // 집중률 API 전용 관광지 추가
  // ↓
  // SnobFinal
  //
  // 집중률 매칭 실패 관광지도 삭제하지 않는다.
  // ==========================================================

  Future<void> _calculateSnob() async {
    try {
      // ==========================================================
      // START
      // ==========================================================

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

        // --------------------------------------------------------
        // 시도 자체인 경우
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // 추천 지역이 이 시도에 속하는지 확인
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // 시군구 조회
        // --------------------------------------------------------

        final List<Map<String, String>>
            sigungus =
            await TourismApiService.getSigungus(
          regionCode,
        );

        debugPrint(
          '   시군구 수: ${sigungus.length}',
        );

        // --------------------------------------------------------
        // 시군구 매칭
        // --------------------------------------------------------

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

      // ----------------------------------------------------------
      // 관광지 샘플 확인
      // ----------------------------------------------------------

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

      // ==========================================================
      // Substitutability에서 사용할 지역 코드
      // ==========================================================

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

        // --------------------------------------------------------
        // 중복 조회 방지
        // --------------------------------------------------------

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

      final List<Map<String, dynamic>>
          spotMaps =
          mappedSpots.map(
        (SnobSpot spot) {
          // ------------------------------------------------------
          // Substitutability용 지역 코드
          // ------------------------------------------------------

          final String? substitutabilitySignguCd =
              spot.concentrationSignguCd ??
                  substitutabilityRegionCode;

          debugPrint(
            'Substitutability 지역 코드 적용: '
            '${spot.title} → '
            '$substitutabilitySignguCd',
          );

          return {
            // ----------------------------------------------------
            // 기본 관광지 데이터
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // 집중률 정보
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // SNOB
            // ----------------------------------------------------

            'snobScore':
                spot.snobScore,

            // ----------------------------------------------------
            // 기존 Sensitivity /
            // Substitutability 호환
            // ----------------------------------------------------

            'hubTatsNm':
                spot.title,

            'hubCtgryMclsNm':
                spot.lclsSystm2,

            'signguCd':
                substitutabilitySignguCd,

            'sigunguCd':
                substitutabilitySignguCd,

            'signguNm':
                spot.concentrationSignguNm ??
                    selectedSigunguName,
          };
        },
      ).toList();

      // ==========================================================
      // ★ 10-1. 집중률 API에만 존재하는 관광지 추가
      // ==========================================================
      //
      // TourAPI O + 집중률 API O
      // → 기존 mappedSpots 사용
      //
      // TourAPI O + 집중률 API X
      // → 기존 mappedSpots 사용 + 중립 집중률
      //
      // TourAPI X + 집중률 API O
      // → 여기에서 새로 추가
      //
      // 실제 TourAPI contentId는 만들지 않는다.
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

      // ----------------------------------------------------------
      // 집중률 API 관광지별 대표 데이터 생성
      // ----------------------------------------------------------
      //
      // 같은 관광지가 날짜별로 여러 번 들어오기 때문에
      // 관광지 + 지역 코드별로 하나만 추가한다.
      //
      // 가장 최근 baseYmd를 우선한다.
      // ----------------------------------------------------------

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

        // --------------------------------------------------------
        // TourAPI에 같은 관광지가 존재하는 경우
        // --------------------------------------------------------

        if (tourismSpotNames
            .contains(normalizedName)) {
          continue;
        }

        // --------------------------------------------------------
        // 같은 이름이어도 지역이 다르면 별도 관광지로 처리
        // --------------------------------------------------------

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

      // ----------------------------------------------------------
      // 집중률 API 전용 관광지 → Map
      // ----------------------------------------------------------

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

        // --------------------------------------------------------
        // 집중률 API의 관광지 정보에서
        // Substitutability JSON의 카테고리를 찾는다.
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // 실제 hubTatsCd가 API에 존재하는 경우에만 사용
        //
        // 없으면 null로 둔다.
        // 가짜 contentId / 가짜 hubTatsCd는 만들지 않는다.
        // --------------------------------------------------------

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
          // ------------------------------------------------------
          // 실제 TourAPI contentId가 없으므로 null
          // ------------------------------------------------------

          'contentId':
              null,

          // ------------------------------------------------------
          // 실제 API에 존재하는 경우에만 사용
          // ------------------------------------------------------

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

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '10-1. 집중률 API 전용 관광지 추가 완료',
      );
      debugPrint(
        '기존 관광지: '
        '${mappedSpots.length}개',
      );
      debugPrint(
        '집중률 전용 추가: '
        '${spotMaps.length - mappedSpots.length}개',
      );
      debugPrint(
        'SNOB 대상 관광지: '
        '${spotMaps.length}개',
      );
      debugPrint(
        '========================================',
      );

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

      if (!mounted) {
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
      // ==========================================================
      // 오류
      // ==========================================================

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

      if (!mounted) {
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
  // ★ Substitutability JSON에서 관광지 카테고리 찾기
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

    // ------------------------------------------------------------
    // 1. 정확한 정규화 이름 매칭
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // 2. 완전 일치
    // ------------------------------------------------------------

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
    final List<dynamic> candidates = [
      spot['lclsSystm2'],
      spot['lclsSystm3'],
      spot['category'],
      spot['contentTypeId'],
      spot['hubCtgryMclsNm'],
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

  Future<void> _addToPlan(
    CourseResultData result,
    int dayNumber,
  ) async {
    if (isSaving) {
      return;
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

      return;
    }

    final TravelSpot spot =
        _createTravelSpot(result);

    // ----------------------------------------------------------
    // 중복 체크
    // ----------------------------------------------------------

    final bool alreadyExists =
        day.spots.any(
      (TravelSpot existingSpot) =>
          existingSpot.name ==
          spot.name,
    );

    if (alreadyExists) {
      Navigator.pop(context);

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

      return;
    }

    // ----------------------------------------------------------
    // 일정 추가
    // ----------------------------------------------------------

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

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);

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
    } catch (e) {
      day.spots.remove(spot);

      if (!mounted) {
        return;
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

    if (!mounted) {
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

                        if (!mounted) {
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
                    color:
                        Colors.grey,
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
                              : () {
                                  _addToPlan(
                                    result,
                                    day.day,
                                  );
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

                              if (!mounted) {
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
  // build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          '코스 추천',
        ),
        actions: [
          if (travelPlan
                  .totalSpotCount >
              0)
            IconButton(
              icon:
                  const Icon(
                Icons
                    .calendar_today_outlined,
              ),
              onPressed:
                  _showPlan,
            ),
        ],
      ),
      body:
          _buildBody(),
    );
  }


  // ============================================================
  // Body
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // 로딩
    // ----------------------------------------------------------

    if (isLoading) {
      return const Center(
        child:
            Column(
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

    // ----------------------------------------------------------
    // 오류
    // ----------------------------------------------------------

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),
          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.grey,
              ),

              const SizedBox(
                height: 15,
              ),

              const Text(
                '코스 추천 중 오류가 발생했습니다.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // 결과 없음
    // ----------------------------------------------------------

    if (results.isEmpty) {
      return const Center(
        child: Text(
          '추천할 관광지가 없습니다.',
          textAlign:
              TextAlign.center,
        ),
      );
    }

    // ----------------------------------------------------------
    // 결과
    // ----------------------------------------------------------

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ========================================================
        // 추천 지역
        // ========================================================

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            14,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                '추천 지역',
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                widget.regionName,
                style:
                    const TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'SNOB 점수가 높은 관광지부터 추천해드려요.',
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const Divider(
          height: 1,
        ),

        // ========================================================
        // 관광지 목록
        // ========================================================

        Expanded(
          child:
              ListView.builder(
            padding:
                const EdgeInsets.all(
              16,
            ),
            itemCount:
                results.length,
            itemBuilder:
                (
              BuildContext context,
              int index,
            ) {
              final CourseResultData
                  result =
                  results[index];

              final Map<String, dynamic>
                  spot =
                  result.spot;

              final String spotName =
                  _getSpotName(
                spot,
              );

              final String category =
                  _getCategory(
                spot,
              );

              final String address =
                  _getAddress(
                spot,
              );

              final bool isAdded =
                  _isAdded(
                spotName,
              );

              final int? addedDay =
                  _getAddedDay(
                spotName,
              );

              return Card(
                elevation: 0,

                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  side: BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),

                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  child:
                      Column(
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child:
                                Text(
                              '${index + 1}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  spotName,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                if (category
                                    .isNotEmpty)
                                  Text(
                                    category,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                      fontSize:
                                          13,
                                    ),
                                  ),

                                if (address
                                    .isNotEmpty)
                                  Text(
                                    address,
                                    maxLines:
                                        2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .grey,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      _ScoreBox(
                        title:
                            'SNOB',
                        value:
                            result.snobScore
                                .toStringAsFixed(
                          1,
                        ),
                        icon:
                            Icons
                                .travel_explore,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton
                                .icon(
                          onPressed:
                              isAdded ||
                                      isSaving
                                  ? null
                                  : () {
                                      _showDaySelector(
                                        result,
                                      );
                                    },

                          icon:
                              Icon(
                            isAdded
                                ? Icons.check
                                : Icons.add,
                          ),

                          label:
                              Text(
                            isAdded
                                ? 'Day $addedDay 일정에 추가됨'
                                : '일정에 추가',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ================================================================
// 점수 박스
// ================================================================

class _ScoreBox
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ScoreBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child:
          Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Colors.grey.shade700,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    fontSize: 11,
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
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}