import 'package:flutter/material.dart';

import '../course/result_screen.dart';
import 'personality_test_screen.dart';

import '../../../services/tourism_api_service.dart';
import '../../../widgets/tourism_image.dart';

import '../../../snob/tourism_spot.dart';
import '../../../widgets/snob_logo.dart';


class ResultScreen extends StatelessWidget {
  // ============================================================
  // 심리테스트 결과 유형
  // ============================================================

  final String personalityType;

  // ============================================================
  // 추천 지역
  // ============================================================

  final String recommendedRegion;

  // ============================================================
  // SNOB Web 디자인 색상
  // ============================================================

  static const Color snobGreen =
      Color(0xFF5B8C68);

  static const Color backgroundColor =
      Color(0xFFF6F7F3);

  static const Color textColor =
      Color(0xFF1F2A24);

  const ResultScreen({
    super.key,
    required this.personalityType,
    required this.recommendedRegion,
  });

  // ============================================================
  // 추천 지역의 관광지 목록 가져오기
  //
  // 기존 API 연결 그대로 사용
  // ============================================================

  Future<List<TourismSpot>>
      _loadRecommendedSpots() async {
    try {
      final region =
          recommendedRegion.trim();

      if (region.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 1. TourAPI 시도 목록
      // ----------------------------------------------------------

      final regions =
          await TourismApiService.getRegions();

      Map<String, String>? matchedRegion;

      for (final item in regions) {
        final name =
            item['name']?.trim() ?? '';

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
          '추천 관광지 조회 실패: 시도 매칭 실패 → $region',
        );

        return [];
      }

      final regionCode =
          matchedRegion['code']?.trim() ?? '';

      final sidoName =
          matchedRegion['name']?.trim() ?? '';

      if (regionCode.isEmpty ||
          sidoName.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 2. 시군구 목록
      // ----------------------------------------------------------

      final sigungus =
          await TourismApiService.getSigungus(
        regionCode,
      );

      Map<String, String>? matchedSigungu;

      for (final item in sigungus) {
        final sigunguName =
            item['name']?.trim() ?? '';

        if (sigunguName.isEmpty) {
          continue;
        }

        final fullName =
            '$sidoName $sigunguName';

        if (fullName == region) {
          matchedSigungu = item;
          break;
        }
      }

      if (matchedSigungu == null) {
        debugPrint(
          '추천 관광지 조회 실패: 시군구 매칭 실패 → $region',
        );

        return [];
      }

      final sigunguCode =
          matchedSigungu['code']?.trim() ?? '';

      final sigunguName =
          matchedSigungu['name']?.trim() ?? '';

      if (sigunguCode.isEmpty ||
          sigunguName.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 3. 기존 관광지 API
      // ----------------------------------------------------------

      final spots =
          await TourismApiService
              .getTourismSpotsByLegalDong(
        regionCode,
        sigunguCode,
        region,
      );

      // ----------------------------------------------------------
      // 4. contentId가 있는 관광지만 사용
      //
      // 기존 대표 관광지 선택 조건과 동일
      // ----------------------------------------------------------

      final validSpots =
          spots.where(
        (spot) =>
            spot.contentId
                .trim()
                .isNotEmpty,
      ).toList();

      debugPrint(
        '추천 관광지 ${validSpots.length}개 조회 → $region',
      );

      return validSpots;
    } catch (e, stackTrace) {
      debugPrint(
        '추천 관광지 조회 오류: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return [];
    }
  }

  // ============================================================
  // 대표 관광지
  //
  // 기존 로직과 동일하게 첫 번째 contentId 관광지를 사용
  // ============================================================

  Future<TourismSpot?>
      _loadRepresentativeSpot() async {
    final spots =
        await _loadRecommendedSpots();

    if (spots.isEmpty) {
      return null;
    }

    final spot = spots.first;

    debugPrint(
      '========================================',
    );
    debugPrint('대표 관광지 선택');
    debugPrint(
      '지역: $recommendedRegion',
    );
    debugPrint(
      '관광지: ${spot.title}',
    );
    debugPrint(
      'contentId: ${spot.contentId}',
    );
    debugPrint(
      '========================================',
    );

    return spot;
  }

  // ============================================================
  // 홈으로 이동
  // ============================================================

  void _goHome(
    BuildContext context,
  ) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // 성향 테스트 다시 하기
  // ============================================================

  void _restartTest(
    BuildContext context,
  ) {
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
  //
  // 기존 연결 그대로 유지
  // ============================================================

  void _goToCourseRecommendation(
    BuildContext context,
  ) {
    final region =
        recommendedRegion.trim();

    if (region.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        builder: (_) =>
            CourseResultScreen(
          regionName: region,
        ),
      ),
    );
  }

  // ============================================================
  // 웹 헤더
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black
                .withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
            child: Row(
              children: [
                // ------------------------------------------------
                // SNOB 로고
                // ------------------------------------------------

                SnobLogo(
                  onTap: () {
                    _goHome(context);
                  },
                ),

                const Spacer(),

                // ------------------------------------------------
                // 현재 페이지
                // ------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration:
                      BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: const Text(
                    'MY TRAVEL TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 1.1,
                      color: textColor,
                    ),
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
  // 유형 카드
  // ============================================================

  Widget _buildPersonalitySection(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal:
            isMobile ? 24 : 44,
        vertical:
            isMobile ? 30 : 42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.035),
            blurRadius: 30,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // 작은 제목
          // ------------------------------------------------------

          const Text(
            'YOUR TRAVEL PERSONALITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 1.3,
              color: snobGreen,
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // 메인 제목
          // ------------------------------------------------------

          Text(
            '당신의 여행 성향',
            style: TextStyle(
              fontSize:
                  isMobile ? 30 : 40,
              height: 1.2,
              fontWeight:
                  FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // 유형
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  isMobile ? 20 : 28,
              vertical:
                  isMobile ? 24 : 30,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '여행자 유형',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  personalityType,
                  style: TextStyle(
                    fontSize:
                        isMobile ? 28 : 34,
                    height: 1.25,
                    fontWeight:
                        FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  '당신의 여행 성향을 바탕으로 '
                  'SNOB가 잘 어울리는 여행 지역을 추천했어요.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 대표 추천 지역
  // ============================================================

  Widget _buildRecommendedRegion(
    bool isMobile,
  ) {
    return FutureBuilder<
        TourismSpot?>(
      future:
          _loadRepresentativeSpot(),
      builder: (
        context,
        snapshot,
      ) {
        final isLoading =
            snapshot.connectionState ==
                ConnectionState.waiting;

        final spot =
            snapshot.data;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(28),
            border: Border.all(
              color: Colors.black
                  .withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 30,
                offset:
                    const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior:
              Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // 이미지
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height:
                    isMobile ? 230 : 360,
                child: isLoading
                    ? Container(
                        color:
                            Colors.grey.shade100,
                        child:
                            const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : TourismImage(
                        contentId:
                            spot?.contentId,
                        width:
                            double.infinity,
                        height:
                            isMobile
                                ? 230
                                : 360,
                        fit: BoxFit.cover,
                      ),
              ),

              // --------------------------------------------------
              // 지역 정보
              // --------------------------------------------------

              Padding(
                padding:
                    EdgeInsets.all(
                  isMobile ? 24 : 34,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '당신에게 추천하는 여행지',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: 0.5,
                        color: snobGreen,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      recommendedRegion,
                      style: TextStyle(
                        fontSize:
                            isMobile
                                ? 28
                                : 38,
                        fontWeight:
                            FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      spot?.title ??
                          '추천 여행 지역',
                      style: TextStyle(
                        fontSize:
                            isMobile
                                ? 18
                                : 22,
                        fontWeight:
                            FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      '당신의 여행 성향과 잘 맞는 지역의 '
                      '관광지를 확인해보세요.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 관광지 카드
  // ============================================================

  Widget _buildSpotCard(
    TourismSpot spot,
  ) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.035),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // 관광지 이미지
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 180,
            child: TourismImage(
              contentId:
                  spot.contentId,
              width:
                  double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

          // ------------------------------------------------------
          // 관광지 정보
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  spot.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight:
                        FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color:
                          Colors.grey.shade500,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Expanded(
                      child: Text(
                        recommendedRegion,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                // ------------------------------------------------
                // 현재 데이터에서 실제로 확인 가능한 정보
                // ------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'SNOB 추천 지역',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      color: snobGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 추천 관광지 목록
  // ============================================================

  Widget _buildRecommendedSpots(
    bool isMobile,
  ) {
    return FutureBuilder<
        List<TourismSpot>>(
      future:
          _loadRecommendedSpots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            height: 220,
            alignment:
                Alignment.center,
            child:
                const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        final spots =
            snapshot.data ?? [];

        if (spots.isEmpty) {
          return Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(32),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.travel_explore,
                  size: 42,
                  color:
                      Colors.grey.shade400,
                ),
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  '추천 관광지를 불러오지 못했어요.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // --------------------------------------------------------
        // 웹
        // --------------------------------------------------------

        if (!isMobile) {
          return SizedBox(
            height: 390,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount: spots.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width: 18,
              ),
              itemBuilder:
                  (context, index) {
                return _buildSpotCard(
                  spots[index],
                );
              },
            ),
          );
        }

        // --------------------------------------------------------
        // 모바일
        // --------------------------------------------------------

        return Column(
          children:
              spots.map(
            (spot) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                child:
                    _buildMobileSpotCard(
                  spot,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  // ============================================================
  // 모바일 관광지 카드
  // ============================================================

  Widget _buildMobileSpotCard(
    TourismSpot spot,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.05),
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 210,
            child: TourismImage(
              contentId:
                  spot.contentId,
              width:
                  double.infinity,
              height: 210,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  spot.title,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  recommendedRegion,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'SNOB 추천 지역',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      color: snobGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 하단 액션 영역
  // ============================================================

  Widget _buildBottomActions(
    BuildContext context,
    bool isMobile,
  ) {
    return Column(
      children: [
        // --------------------------------------------------------
        // 여행 계획하기
        // --------------------------------------------------------

        SizedBox(
          width: double.infinity,
          height: 60,
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
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  snobGreen,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '이 지역으로 여행 계획하기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --------------------------------------------------------
        // 다시 하기
        // --------------------------------------------------------

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              _restartTest(context);
            },
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  textColor,
              side: BorderSide(
                color: Colors.grey.shade300,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),
            child: const Text(
              '여행 성향 다시 테스트하기',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) {
          return;
        }

        _goHome(context);
      },
      child: Scaffold(
        backgroundColor:
            backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // 헤더
              // ==================================================

              _buildHeader(context),

              // ==================================================
              // 본문
              // ==================================================

              Expanded(
                child: LayoutBuilder(
                  builder: (
                    context,
                    constraints,
                  ) {
                    final isMobile =
                        constraints.maxWidth <
                            700;

                    return SingleChildScrollView(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal:
                            isMobile
                                ? 18
                                : 32,
                        vertical:
                            isMobile
                                ? 28
                                : 54,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 1200,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              // ==================================
                              // 1. 여행 성향
                              // ==================================

                              _buildPersonalitySection(
                                isMobile,
                              ),

                              SizedBox(
                                height:
                                    isMobile
                                        ? 28
                                        : 42,
                              ),

                              // ==================================
                              // 2. 추천 지역
                              // ==================================

                              _buildRecommendedRegion(
                                isMobile,
                              ),

                              SizedBox(
                                height:
                                    isMobile
                                        ? 38
                                        : 54,
                              ),

                              // ==================================
                              // 3. 추천 관광지
                              // ==================================

                              Text(
                                '추천 관광지',
                                style: TextStyle(
                                  fontSize:
                                      isMobile
                                          ? 26
                                          : 32,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      textColor,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                '추천 지역에서 만나볼 수 있는 '
                                '관광지를 확인해보세요.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),

                              const SizedBox(
                                height: 22,
                              ),

                              _buildRecommendedSpots(
                                isMobile,
                              ),

                              SizedBox(
                                height:
                                    isMobile
                                        ? 34
                                        : 52,
                              ),

                              // ==================================
                              // 4. 여행 계획
                              // ==================================

                              _buildBottomActions(
                                context,
                                isMobile,
                              ),

                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}