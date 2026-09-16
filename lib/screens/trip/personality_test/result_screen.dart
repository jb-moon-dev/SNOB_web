import 'package:flutter/material.dart';

import '../course/result_screen.dart';
import 'personality_test_screen.dart';

import '../../../services/tourism_api_service.dart';
import '../../../widgets/tourism_image.dart';

import '../../../snob/tourism_spot.dart';

class ResultScreen extends StatelessWidget {
  // ============================================================
  // 심리테스트 결과 유형
  // ============================================================

  final String personalityType;

  // ============================================================
  // 추천 지역
  // ============================================================

  final String recommendedRegion;

  const ResultScreen({
    super.key,
    required this.personalityType,
    required this.recommendedRegion,
  });

  // ============================================================
  // 추천 지역의 대표 관광지 가져오기
  // ============================================================

  Future<TourismSpot?> _loadRepresentativeSpot() async {
    try {
      final region = recommendedRegion.trim();

      if (region.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // 1. TourAPI 시도 목록 가져오기
      // ----------------------------------------------------------

      final regions = await TourismApiService.getRegions();

      Map<String, String>? matchedRegion;

      for (final item in regions) {
        final name = item['name']?.trim() ?? '';

        if (name.isEmpty) {
          continue;
        }

        if (region.startsWith(name)) {
          matchedRegion = item;
          break;
        }
      }

      if (matchedRegion == null) {
        debugPrint(
          '대표 관광지 조회 실패: 시도 매칭 실패 → $region',
        );

        return null;
      }

      final regionCode = matchedRegion['code']?.trim() ?? '';

      final sidoName = matchedRegion['name']?.trim() ?? '';

      if (regionCode.isEmpty || sidoName.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // 2. 시군구 목록 가져오기
      // ----------------------------------------------------------

      final sigungus = await TourismApiService.getSigungus(
        regionCode,
      );

      Map<String, String>? matchedSigungu;

      for (final item in sigungus) {
        final sigunguName = item['name']?.trim() ?? '';

        if (sigunguName.isEmpty) {
          continue;
        }

        final fullName = '$sidoName $sigunguName';

        if (fullName == region) {
          matchedSigungu = item;
          break;
        }
      }

      if (matchedSigungu == null) {
        debugPrint(
          '대표 관광지 조회 실패: 시군구 매칭 실패 → $region',
        );

        return null;
      }

      final sigunguCode = matchedSigungu['code']?.trim() ?? '';

      final sigunguName = matchedSigungu['name']?.trim() ?? '';

      if (sigunguCode.isEmpty || sigunguName.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // 3. 해당 지역 관광지 가져오기
      // ----------------------------------------------------------

      final spots =
          await TourismApiService.getTourismSpotsByLegalDong(
        regionCode,
        sigunguCode,
        '$sidoName $sigunguName',
      );

      // ----------------------------------------------------------
      // 4. contentId가 있는 관광지 하나 선택
      // ----------------------------------------------------------

      for (final spot in spots) {
        if (spot.contentId.trim().isNotEmpty) {
          debugPrint(
            '========================================',
          );
          debugPrint('대표 관광지 선택');
          debugPrint('지역: $region');
          debugPrint('관광지: ${spot.title}');
          debugPrint(
            'contentId: ${spot.contentId}',
          );
          debugPrint(
            '========================================',
          );

          return spot;
        }
      }

      debugPrint(
        '대표 관광지 없음 → $region',
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint(
        '대표 관광지 조회 오류: $e',
      );
      debugPrint(
        stackTrace.toString(),
      );

      return null;
    }
  }

  // ============================================================
  // 홈으로 이동
  // ============================================================

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // 성향 테스트 다시 하기
  // ============================================================

  void _restartTest(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const PersonalityTestScreen(),
      ),
    );
  }

  // ============================================================
  // 코스 추천
  // ============================================================

  void _goToCourseRecommendation(
    BuildContext context,
  ) {
    final region = recommendedRegion.trim();

    if (region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '추천 지역을 확인할 수 없습니다.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseResultScreen(
          regionName: region,
        ),
      ),
    );
  }

  // ============================================================
  // build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) return;

        _goHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '여행 성향 결과',
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              _goHome(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // ==================================================
                  // 제목
                  // ==================================================

                  const Text(
                    '✨ 당신의 여행 성향',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // 여행 유형
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(24),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),
                      color:
                          Colors.grey.shade100,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '당신의 여행 유형',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          personalityType,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // 추천 지역
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(24),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '📍 추천 여행 지역',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // 대표 관광지 이미지
                        // ==================================================

                        FutureBuilder<TourismSpot?>(
                          future:
                              _loadRepresentativeSpot(),
                          builder: (
                            context,
                            snapshot,
                          ) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),
                                child:
                                    const Center(
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final spot =
                                snapshot.data;

                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              child: TourismImage(
                                contentId:
                                    spot?.contentId,
                                width:
                                    double.infinity,
                                height: 180,
                                fit:
                                    BoxFit.cover,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Text(
                          recommendedRegion,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          '당신의 여행 성향과 가장 잘 맞는 지역이에요.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================================
                  // 다시 하기
                  // ============================================================

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        _restartTest(context);
                      },
                      child: const Text(
                        '다시 하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // 코스 추천
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          recommendedRegion
                                  .trim()
                                  .isEmpty
                              ? null
                              : () {
                                  _goToCourseRecommendation(
                                    context,
                                  );
                                },
                      child: const Text(
                        '코스 추천 넘어가기 →',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
