import 'package:flutter/material.dart';

import 'trip/personality_test/personality_test_screen.dart';
import 'trip/course/result_screen.dart';

import '../models/travel_plan.dart';
import '../services/travel_plan_storage.dart';
import '../services/trip_record_storage.dart';
import '../screens/record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TravelPlan? savedPlan;

  bool isLoading = true;

  // ============================================================
  // SNOB Web Color
  // ============================================================

  static const Color snobGreen =
      Color(0xFF21624B);

  static const Color snobDarkGreen =
      Color(0xFF164B39);

  static const Color snobLightGreen =
      Color(0xFFE8F2EC);

  static const Color pageBackground =
      Color(0xFFF8F8F4);

  static const Color primaryText =
      Color(0xFF183A2E);

  static const Color secondaryText =
      Color(0xFF64736C);

  static const Color mutedText =
      Color(0xFF8A9691);

  static const Color cardBorder =
      Color(0xFFE3EAE5);

  @override
  void initState() {
    super.initState();

    _loadTravelPlan();
  }

  // ============================================================
  // 저장된 여행 일정 불러오기
  // ============================================================

  Future<void> _loadTravelPlan() async {
    final plan =
        await TravelPlanStorage.loadTravelPlan();

    if (!mounted) return;

    setState(() {
      savedPlan = plan;
      isLoading = false;
    });
  }

  // ============================================================
  // 일정 화면 열기
  // ============================================================

    Future<void> _openItinerary() async {
    if (savedPlan == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseResultScreen(
          regionName: savedPlan!.regionName,
        ),
      ),
    );

    await _loadTravelPlan();
  }

  // ============================================================
  // 여행 완료 → 날짜 선택 → 기록으로 저장
  // ============================================================

  Future<void> _completeTravel() async {
    if (savedPlan == null) return;

    final plan = savedPlan!;

    final selectedRange =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
      helpText: '여행 기간을 선택해주세요',
      cancelText: '취소',
      confirmText: '완료',
    );

    if (selectedRange == null) {
      return;
    }

    final visitedPlaces = <String>[];

    for (final day in plan.days) {
      for (final spot in day.spots) {
        visitedPlaces.add(spot.name);
      }
    }

    try {
      final record = TripRecord(
        regionName: plan.regionName,
        startDate: selectedRange.start,
        endDate: selectedRange.end,
        diary: '',
        photoPaths: [],
        visitedPlaces: visitedPlaces,
      );

      await TripRecordStorage.saveRecord(record);

      await TravelPlanStorage.deleteTravelPlan();

      if (!mounted) return;

      setState(() {
        savedPlan = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '여행이 완료되었어요 ✨ 기록 탭에서 확인해보세요.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        '여행 완료 처리 실패: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '여행 완료 처리 중 문제가 발생했어요.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 여행 일정 삭제
  // ============================================================

  Future<void> _deleteTravelPlan() async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '여행 일정을 삭제할까요?',
          ),
          content: const Text(
            '저장된 여행 일정이 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await TravelPlanStorage
        .deleteTravelPlan();

    if (!mounted) return;

    setState(() {
      savedPlan = null;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '여행 일정이 삭제됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // 새 여행 만들기
  // ============================================================

  void _startPersonalityTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PersonalityTestScreen(),
      ),
    ).then((_) {
      _loadTravelPlan();
    });
  }

  // ============================================================
  // 여행 기록 화면
  // ============================================================

  void _openRecordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RecordScreen(),
      ),
    );
  }

  // ============================================================
  // 상단 웹 헤더
  // ============================================================

  Widget _buildHeader(
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal:
            isDesktop ? 48 : 22,
        vertical: 20,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1280,
          ),
          child: Row(
            children: [
              const Text(
                'SNOB',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w900,
                  color: snobGreen,
                  letterSpacing: -1.5,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed:
                    _startPersonalityTest,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      snobGreen,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                ),
                child: const Text(
                  '새 여행 시작',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Hero 영역
  // ============================================================

  Widget _buildHero(
    bool isDesktop,
    bool isTablet,
  ) {
    final double heroHeight =
        isDesktop
            ? 430
            : isTablet
                ? 390
                : 420;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal:
            isDesktop ? 48 : 16,
        vertical:
            isDesktop ? 28 : 16,
      ),
      constraints:
          const BoxConstraints(
        maxWidth: 1280,
      ),
      height: heroHeight,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          32,
        ),
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF164B39),
            Color(0xFF2C7056),
            Color(0xFF7FAF92),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right:
                isDesktop ? 60 : -70,
            bottom: -50,
            child: Icon(
              Icons
                  .landscape_outlined,
              size:
                  isDesktop
                      ? 420
                      : 300,
              color: Colors.white
                  .withValues(
                alpha: 0.10,
              ),
            ),
          ),

          Positioned(
            right:
                isDesktop ? 170 : 20,
            top: 40,
            child: Icon(
              Icons
                  .wb_sunny_outlined,
              size: 70,
              color: Colors.white
                  .withValues(
                alpha: 0.25,
              ),
            ),
          ),

          Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  isDesktop
                      ? 72
                      : 28,
              vertical:
                  isDesktop
                      ? 60
                      : 42,
            ),
            child: Align(
              alignment: isDesktop
                  ? Alignment.centerLeft
                  : Alignment.topLeft,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.15,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          999,
                        ),
                      ),
                      child:
                          const Text(
                        'PERSONALIZED TRAVEL',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w800,
                          letterSpacing:
                              1.1,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      '나에게 꼭 맞는\n'
                      '여행지를 찾아보세요.',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            isDesktop
                                ? 48
                                : 36,
                        fontWeight:
                            FontWeight
                                .w900,
                        height: 1.15,
                        letterSpacing:
                            -1.8,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      '나의 여행 성향과 관광지 혼잡도 데이터를 바탕으로\n'
                      '사람이 몰리는 곳을 넘어, 나에게 맞는 여행을 추천해드려요.',
                      style:
                          TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.86,
                        ),
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    FilledButton(
                      onPressed:
                          _startPersonalityTest,
                      style:
                          FilledButton
                              .styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            snobDarkGreen,
                        elevation: 0,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            999,
                          ),
                        ),
                      ),
                      child:
                          const Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Text(
                            '맞춤 여행지 추천받기',
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Icon(
                            Icons
                                .arrow_forward,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 섹션 타이틀
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String description,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: primaryText,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 4),
                action,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) action,
          ],
        );
      },
    );
  }

  // ============================================================
  // 추천 여행지 영역
  // ============================================================

  Widget _buildRecommendationSection(
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              _buildSectionTitle(
                title: 'SNOB 추천 여행지',
                description: '나의 여행 성향에 맞는 여행지를 발견해보세요.',
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useVerticalCard = constraints.maxWidth < 1000;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(useVerticalCard ? 24 : 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
                    ),
                    child: useVerticalCard
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: snobLightGreen,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.explore_outlined,
                                  color: snobGreen,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '나에게 맞는 여행지를 추천받아보세요',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '간단한 여행 성향 테스트를 완료하면 SNOB의 추천 시스템을 통해 나에게 맞는 여행지를 찾아볼 수 있어요.',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryText,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton(
                                  onPressed: _startPersonalityTest,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: snobGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Text(
                                    '추천받기',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: snobLightGreen,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.explore_outlined,
                                  color: snobGreen,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '나에게 맞는 여행지를 추천받아보세요',
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: primaryText,
                                      ),
                                    ),
                                    SizedBox(height: 7),
                                    Text(
                                      '간단한 여행 성향 테스트를 완료하면 SNOB의 추천 시스템을 통해 나에게 맞는 여행지를 찾아볼 수 있어요.',
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: secondaryText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              FilledButton(
                                onPressed: _startPersonalityTest,
                                style: FilledButton.styleFrom(
                                  backgroundColor: snobGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  '추천받기',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 진행 중인 여행
  // ============================================================

  Widget _buildCurrentTripSection(
    bool isDesktop,
  ) {
    if (savedPlan == null ||
        savedPlan!.totalSpotCount <= 0) {
      return const SizedBox.shrink();
    }

    final plan = savedPlan!;

    final firstDay =
        plan.days.isNotEmpty
            ? plan.days.first
            : null;

    final todaySpots =
        firstDay?.spots ?? [];

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(
        horizontal:
            isDesktop ? 48 : 22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1280,
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 60,
              ),

              _buildSectionTitle(
                title: '나의 여행',
                description:
                    '현재 진행 중인 여행을 이어서 관리해보세요.',
                action: TextButton(
                  onPressed:
                      _openItinerary,
                  child:
                      const Text(
                    '전체 일정 보기 →',
                    style:
                        TextStyle(
                      color:
                          snobGreen,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  28,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFDCE8D8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                '진행 중인 여행',
                                style:
                                    TextStyle(
                                  fontSize:
                                      13,
                                  color:
                                      secondaryText,
                                ),
                              ),
                              const SizedBox(
                                height:
                                    7,
                              ),
                              Text(
                                '${plan.regionName} 여행',
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      28,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  color:
                                      primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        PopupMenuButton<
                            String>(
                          onSelected:
                              (value) {
                            if (value ==
                                'delete') {
                              _deleteTravelPlan();
                            }
                          },
                          itemBuilder:
                              (context) =>
                                  const [
                            PopupMenuItem(
                              value:
                                  'delete',
                              child:
                                  Text(
                                '여행 일정 삭제',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _TripInfo(
                          icon: Icons
                              .calendar_today_outlined,
                          text:
                              '${plan.days.length}일 여행',
                        ),
                        _TripInfo(
                          icon: Icons
                              .place_outlined,
                          text:
                              '${plan.totalSpotCount}곳',
                        ),
                      ],
                    ),

                    if (todaySpots
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 28,
                      ),

                      const Text(
                        '오늘의 일정',
                        style:
                            TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color:
                              primaryText,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            todaySpots
                                .take(4)
                                .toList()
                                .asMap()
                                .entries
                                .map(
                          (entry) {
                            final index =
                                entry.key;
                            final spot =
                                entry.value;

                            return Container(
                              constraints:
                                  const BoxConstraints(
                                maxWidth:
                                    300,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    14,
                                vertical:
                                    11,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  999,
                                ),
                              ),
                              child:
                                  Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Container(
                                    width:
                                        23,
                                    height:
                                        23,
                                    alignment:
                                        Alignment
                                            .center,
                                    decoration:
                                        const BoxDecoration(
                                      shape:
                                          BoxShape
                                              .circle,
                                      color:
                                          snobLightGreen,
                                    ),
                                    child:
                                        Text(
                                      '${index + 1}',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            11,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color:
                                            snobGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width:
                                        8,
                                  ),
                                  Flexible(
                                    child:
                                        Text(
                                      spot.name,
                                      maxLines:
                                          1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            13,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color:
                                            primaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ],

                    const SizedBox(
                      height: 28,
                    ),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed:
                              _openItinerary,
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                snobGreen,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  22,
                              vertical:
                                  14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                          ),
                          child:
                              const Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              Text(
                                '일정 계속하기',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              SizedBox(
                                width: 6,
                              ),
                              Icon(
                                Icons
                                    .arrow_forward,
                                size: 17,
                              ),
                            ],
                          ),
                        ),

                        OutlinedButton
                            .icon(
                          onPressed:
                              _completeTravel,
                          icon:
                              const Icon(
                            Icons
                                .check_circle_outline,
                            size: 18,
                          ),
                          label:
                              const Text(
                            '여행 완료',
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                primaryText,
                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFB9C9BE,
                              ),
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  20,
                              vertical:
                                  14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 새 여행 + 여행 기록 영역
  // ============================================================

  Widget _buildActionSection(
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 48 : 22,
        60,
        isDesktop ? 48 : 22,
        70,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool useTwoColumns =
                  constraints.maxWidth >= 1000;

              if (useTwoColumns) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.travel_explore_outlined,
                        title: '새로운 여행을 시작해보세요',
                        description:
                            '나의 여행 성향을 분석하고\n'
                            '나에게 맞는 여행지를 찾아보세요.',
                        buttonText: '맞춤 여행 시작하기',
                        onPressed: _startPersonalityTest,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.auto_stories_outlined,
                        title: '나의 여행 기록',
                        description:
                            '다녀온 여행을 다시 확인하고\n'
                            '나만의 여행을 쌓아보세요.',
                        buttonText: '여행 기록 보기',
                        onPressed: _openRecordScreen,
                        filled: false,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildActionCard(
                    icon: Icons.travel_explore_outlined,
                    title: '새로운 여행을 시작해보세요',
                    description:
                        '나의 여행 성향을 분석하고\n'
                        '나에게 맞는 여행지를 찾아보세요.',
                    buttonText: '맞춤 여행 시작하기',
                    onPressed: _startPersonalityTest,
                    filled: true,
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    icon: Icons.auto_stories_outlined,
                    title: '나의 여행 기록',
                    description:
                        '다녀온 여행을 다시 확인하고\n'
                        '나만의 여행을 쌓아보세요.',
                    buttonText: '여행 기록 보기',
                    onPressed: _openRecordScreen,
                    filled: false,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Action Card
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: filled ? snobGreen : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: filled ? null : Border.all(color: cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackContent = constraints.maxWidth < 520;

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                softWrap: true,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : primaryText,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: filled
                      ? Colors.white.withValues(alpha: 0.78)
                      : secondaryText,
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: filled ? Colors.white : snobGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          );

          final iconBox = Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white.withValues(alpha: 0.14)
                  : snobLightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : snobGreen,
              size: 29,
            ),
          );

          if (stackContent) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(height: 16),
                textContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBox,
              const SizedBox(width: 18),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          pageBackground,
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: snobGreen,
              ),
            )
          : LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final bool isDesktop =
                    constraints.maxWidth >=
                        900;

                final bool isTablet =
                    constraints.maxWidth >=
                            600 &&
                        constraints.maxWidth <
                            900;

                return RefreshIndicator(
                  color: snobGreen,
                  onRefresh:
                      _loadTravelPlan,
                  child:
                      CustomScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child:
                            _buildHero(
                          isDesktop,
                          isTablet,
                        ),
                      ),

                      SliverToBoxAdapter(
                        child:
                            _buildRecommendationSection(
                          isDesktop,
                          isTablet,
                        ),
                      ),

                      SliverToBoxAdapter(
                        child:
                            _buildCurrentTripSection(
                          isDesktop,
                        ),
                      ),

                      SliverToBoxAdapter(
                        child:
                            _buildActionSection(
                          isDesktop,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// 여행 정보
// ============================================================

class _TripInfo
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TripInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color:
              _HomeScreenState
                  .snobGreen,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          text,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                _HomeScreenState
                    .primaryText,
          ),
        ),
      ],
    );
  }
}