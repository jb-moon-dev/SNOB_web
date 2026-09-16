import 'package:flutter/material.dart';

import '../../models/travel_plan.dart';
import '../../services/travel_plan_storage.dart';
import '../../services/kakao_local_service.dart';
import '../../services/route_service.dart';
import 'place_search_sheet.dart';

class ItineraryScreen extends StatefulWidget {
  final TravelPlan travelPlan;

  const ItineraryScreen({
    super.key,
    required this.travelPlan,
  });

  @override
  State<ItineraryScreen> createState() =>
      _ItineraryScreenState();
}

class _ItineraryScreenState
    extends State<ItineraryScreen> {
  late TravelPlan travelPlan;

  int selectedDayIndex = 0;

  static const int defaultStartMinute =
      9 * 60;

  final RouteService _routeService =
      RouteService();

  bool _recalculatingRoutes = false;

  int _routeCalculationToken = 0;

  // ============================================================
  // ★ 추가: 구간별 자동차 이동시간
  // key = 현재 장소의 index
  // value = 이전 장소 → 현재 장소 자동차 이동시간
  // ============================================================

  final Map<int, int> _carTravelMinutes = {};

  @override
  void initState() {
    super.initState();

    travelPlan = widget.travelPlan;

    if (travelPlan.days.isEmpty) {
      travelPlan.days.add(
        TravelDay(day: 1),
      );
    }

    _normalizeCurrentDay();

    // 기존 일정 중 좌표가 있는 장소의
    // 이동시간을 실제 API 기준으로 한 번 계산
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _updateTravelTimes(
        showMessage: false,
      );
    });
  }

  @override
  void dispose() {
    _routeService.dispose();
    super.dispose();
  }

  // ============================================================
  // 현재 Day
  // ============================================================

  TravelDay get currentDay {
    _normalizeCurrentDay();
    return travelPlan.days[
        selectedDayIndex];
  }

  void _normalizeCurrentDay() {
    if (travelPlan.days.isEmpty) {
      travelPlan.days.add(
        TravelDay(day: 1),
      );
    }

    if (selectedDayIndex >=
        travelPlan.days.length) {
      selectedDayIndex = 0;
    }

    if (selectedDayIndex < 0) {
      selectedDayIndex = 0;
    }
  }

  // ============================================================
  // 저장
  // ============================================================

  Future<void> _savePlan() async {
    travelPlan.updatedAt =
        DateTime.now();

    await TravelPlanStorage.saveTravelPlan(
      travelPlan,
    );
  }

  // ============================================================
  // 시간
  // ============================================================

  String _formatMinute(int? minute) {
    if (minute == null) {
      return '--:--';
    }

    final hour =
        (minute ~/ 60) % 24;
    final min =
        minute % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${min.toString().padLeft(2, '0')}';
  }

  String _durationText(
    int minutes,
  ) {
    if (minutes < 60) {
      return '$minutes분';
    }

    final hour =
        minutes ~/ 60;
    final remain =
        minutes % 60;

    if (remain == 0) {
      return '$hour시간';
    }

    return '$hour시간 $remain분';
  }

  int? get _dayStartMinute {
    if (currentDay.spots.isEmpty) {
      return null;
    }

    return currentDay
        .spots
        .first
        .startMinute;
  }

  // ============================================================
  // 시간 자동 계산
  // ============================================================

  void _recalculateTimes({
    int? startMinute,
  }) {
    final spots =
        currentDay.spots;

    if (spots.isEmpty) {
      return;
    }

    int currentMinute =
        startMinute ??
            spots.first.startMinute ??
            defaultStartMinute;

    for (
      int i = 0;
      i < spots.length;
      i++
    ) {
      final spot =
          spots[i];

      spots[i] =
          spot.copyWith(
        startMinute:
            currentMinute,
        travelMinutesFromPrevious:
            i == 0
                ? 0
                : spot
                    .travelMinutesFromPrevious,
      );

      currentMinute +=
          spot.durationMinutes;

      if (i <
          spots.length - 1) {
        currentMinute +=
            spots[i + 1]
                .travelMinutesFromPrevious;
      }
    }
  }

  // ============================================================
  // ★ 실제 좌표 기반 이동시간 계산
  // 도보 + 자동차를 함께 계산
  // ============================================================

  Future<void> _updateTravelTimes({
    bool showMessage = true,
  }) async {
    final spots =
        List<TravelSpot>.from(
      currentDay.spots,
    );

    if (spots.length < 2) {
      _carTravelMinutes.clear();
      return;
    }

    final token =
        ++_routeCalculationToken;

    setState(() {
      _recalculatingRoutes = true;
    });

    bool hasFallback = false;
    bool hasMissingCoordinates =
        false;

    // 이번 계산에서 사용할 자동차 이동시간
    final Map<int, int> newCarTravelMinutes =
        {};

    try {
      for (
        int i = 1;
        i < spots.length;
        i++
      ) {
        final previous =
            spots[i - 1];

        final current =
            spots[i];

        // ------------------------------------------------------
        // 좌표가 없으면 API 호출 불가능
        // ------------------------------------------------------

        if (previous.latitude ==
                null ||
            previous.longitude ==
                null ||
            current.latitude ==
                null ||
            current.longitude ==
                null) {
          hasMissingCoordinates =
              true;
          continue;
        }

        // ------------------------------------------------------
        // ★ 도보 이동시간
        // 기존 로직 그대로 유지
        // ------------------------------------------------------

        final walkingRoute =
            await _routeService
                .getWalkingRoute(
          startLatitude:
              previous.latitude!,
          startLongitude:
              previous.longitude!,
          endLatitude:
              current.latitude!,
          endLongitude:
              current.longitude!,
        );

        if (!mounted) {
          return;
        }

        if (token !=
            _routeCalculationToken) {
          return;
        }

        spots[i] =
            current.copyWith(
          travelMinutesFromPrevious:
              walkingRoute.durationMinutes,
        );

        if (!walkingRoute.fromApi) {
          hasFallback = true;
        }

        // ------------------------------------------------------
        // ★ 자동차 이동시간
        // Kakao Mobility 자동차 실제 경로
        // ------------------------------------------------------

        try {
          final drivingRoute =
              await _routeService
                  .getDrivingRoute(
            startLatitude:
                previous.latitude!,
            startLongitude:
                previous.longitude!,
            endLatitude:
                current.latitude!,
            endLongitude:
                current.longitude!,
          );

          newCarTravelMinutes[i] =
              drivingRoute.durationMinutes;
        } catch (_) {
          // 자동차 API 실패 시
          // 화면에는 자동차 시간을 표시하지 않음
        }

        if (!mounted) {
          return;
        }

        if (token !=
            _routeCalculationToken) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      if (token !=
          _routeCalculationToken) {
        return;
      }

      setState(() {
        for (
          int i = 0;
          i < spots.length;
          i++
        ) {
          currentDay.spots[i] =
              spots[i];
        }

        // ★ 자동차 이동시간 저장
        _carTravelMinutes
          ..clear()
          ..addAll(
            newCarTravelMinutes,
          );

        _recalculateTimes();
      });

      await _savePlan();

      if (!mounted ||
          !showMessage) {
        return;
      }

      String message;

      if (hasMissingCoordinates) {
        message =
            '좌표가 없는 장소는 이동시간을 계산하지 못했어요.';
      } else if (hasFallback) {
        message =
            '도보 이동시간을 기준으로 일정이 계산됐어요.';
      } else {
        message =
            '도보와 자동차 이동시간을 계산했어요.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
    } finally {
      if (mounted &&
          token ==
              _routeCalculationToken) {
        setState(() {
          _recalculatingRoutes =
              false;
        });
      }
    }
  }

  // ============================================================
  // 시작 시간
  // ============================================================

  Future<void>
      _showStartTimePicker() async {
    final initialMinute =
        _dayStartMinute ??
            defaultStartMinute;

    final initialTime =
        TimeOfDay(
      hour:
          (initialMinute ~/ 60) % 24,
      minute:
          initialMinute % 60,
    );

    final picked =
        await showTimePicker(
      context: context,
      initialTime:
          initialTime,
      helpText:
          '여행 시작 시간을 선택하세요',
      cancelText: '취소',
      confirmText: '설정',
    );

    if (picked == null) {
      return;
    }

    final newMinute =
        picked.hour * 60 +
            picked.minute;

    setState(() {
      _recalculateTimes(
        startMinute:
            newMinute,
      );
    });

    await _savePlan();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '여행 시작 시간이 '
          '${_formatMinute(newMinute)}로 설정됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // 장소 검색
  // ============================================================

  Future<void>
      _showPlaceSearch() async {
    final place =
        await showModalBottomSheet<
            KakaoPlace>(
      context: context,
      isScrollControlled:
          true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor:
          Colors.white,
      builder: (_) {
        return const SizedBox(
          height: 650,
          child:
              PlaceSearchSheet(),
        );
      },
    );

    if (place == null) {
      return;
    }

    await _addKakaoPlace(
      place,
    );
  }

  // ============================================================
  // Kakao 장소 추가
  // ============================================================

  Future<void> _addKakaoPlace(
    KakaoPlace place,
  ) async {
    final alreadyExists =
        currentDay.spots.any(
      (spot) =>
          spot.kakaoPlaceId ==
              place.id ||
          spot.name ==
              place.name,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            '이미 같은 장소가 일정에 있어요.',
          ),
        ),
      );
      return;
    }

    final isFirst =
        currentDay.spots.isEmpty;

    final spot =
        TravelSpot(
      name:
          place.name,
      category:
          place.categoryName,
      address:
          place.displayAddress,
      latitude:
          place.latitude,
      longitude:
          place.longitude,
      kakaoPlaceId:
          place.id,
      kakaoPlaceUrl:
          place.placeUrl,
      startMinute:
          null,
      durationMinutes:
          _defaultDurationForCategory(
        place.categoryName,
      ),
      travelMinutesFromPrevious:
          isFirst
              ? 0
              : 20,
    );

    setState(() {
      currentDay.spots.add(
        spot,
      );

      _recalculateTimes();
    });

    // 새 장소가 추가됐으므로
    // 실제 좌표 기반 이동시간 다시 계산
    await _updateTravelTimes(
      showMessage: false,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          '${place.name}이(가) 일정에 추가됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // 카테고리별 기본 체류시간
  // ============================================================

  int _defaultDurationForCategory(
    String? category,
  ) {
    final value =
        category ?? '';

    if (value.contains('박물관') ||
        value.contains('미술관')) {
      return 90;
    }

    if (value.contains('공원') ||
        value.contains('자연')) {
      return 90;
    }

    if (value.contains('전망')) {
      return 60;
    }

    if (value.contains('식당') ||
        value.contains('음식')) {
      return 60;
    }

    if (value.contains('카페')) {
      return 60;
    }

    return 60;
  }

  // ============================================================
  // 이동시간 수동 변경
  // ============================================================

  Future<void> _changeTravelTime(
    TravelSpot spot,
  ) async {
    final options =
        <int>[
      5,
      10,
      15,
      20,
      30,
      40,
      45,
      60,
      90,
    ];

    final selected =
        await showModalBottomSheet<
            int>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16,
                  ),
                  child:
                      Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        Text(
                      '이동 시간 직접 설정',
                      style:
                          TextStyle(
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...options.map(
                  (
                    minutes,
                  ) {
                    final selected =
                        spot.travelMinutesFromPrevious ==
                            minutes;

                    return ListTile(
                      leading:
                          Icon(
                        Icons
                            .directions_walk_outlined,
                        color: selected
                            ? Theme.of(
                                context,
                              )
                                .colorScheme
                                .primary
                            : Colors
                                .grey,
                      ),
                      title:
                          Text(
                        _durationText(
                          minutes,
                        ),
                      ),
                      trailing:
                          selected
                              ? Icon(
                                  Icons
                                      .check,
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .primary,
                                )
                              : null,
                      onTap:
                          () {
                        Navigator.pop(
                          sheetContext,
                          minutes,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    final index =
        currentDay.spots
            .indexOf(spot);

    if (index == -1) {
      return;
    }

    setState(() {
      currentDay.spots[index] =
          spot.copyWith(
        travelMinutesFromPrevious:
            selected,
      );

      _recalculateTimes();
    });

    await _savePlan();
  }

  // ============================================================
  // 체류시간 변경
  // ============================================================

  Future<void> _changeDuration(
    TravelSpot spot,
  ) async {
    final options =
        <int>[
      30,
      45,
      60,
      90,
      120,
      150,
      180,
    ];

    final selected =
        await showModalBottomSheet<
            int>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16,
                  ),
                  child:
                      Align(
                    alignment:
                        Alignment.centerLeft,
                    child:
                        Text(
                      '머무르는 시간',
                      style:
                          TextStyle(
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...options.map(
                  (
                    minutes,
                  ) {
                    final selected =
                        spot.durationMinutes ==
                            minutes;

                    return ListTile(
                      leading:
                          Icon(
                        Icons
                            .schedule_outlined,
                        color: selected
                            ? Theme.of(
                                context,
                              )
                                .colorScheme
                                .primary
                            : Colors
                                .grey,
                      ),
                      title:
                          Text(
                        _durationText(
                          minutes,
                        ),
                      ),
                      trailing:
                          selected
                              ? Icon(
                                  Icons
                                      .check,
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .primary,
                                )
                              : null,
                      onTap:
                          () {
                        Navigator.pop(
                          sheetContext,
                          minutes,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    final index =
        currentDay.spots
            .indexOf(spot);

    if (index == -1) {
      return;
    }

    setState(() {
      currentDay.spots[index] =
          spot.copyWith(
        durationMinutes:
            selected,
      );

      _recalculateTimes();
    });

    await _savePlan();
  }

  // ============================================================
  // 삭제
  // ============================================================

  Future<void> _removeSpot(
    TravelSpot spot,
  ) async {
    setState(() {
      currentDay.spots
          .remove(spot);

      if (currentDay.spots
          .isNotEmpty) {
        currentDay.spots[0] =
            currentDay.spots[0]
                .copyWith(
          travelMinutesFromPrevious:
              0,
        );

        _recalculateTimes();
      }
    });

    await _updateTravelTimes(
      showMessage: false,
    );

    await _savePlan();
  }

  // ============================================================
  // ★ 드래그 순서 변경
  // ============================================================

  Future<void> _reorderSpots(
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex >
        oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final spot =
          currentDay.spots
              .removeAt(
        oldIndex,
      );

      currentDay.spots.insert(
        newIndex,
        spot,
      );

      if (currentDay.spots
          .isNotEmpty) {
        currentDay.spots[0] =
            currentDay.spots[0]
                .copyWith(
          travelMinutesFromPrevious:
              0,
        );
      }

      _recalculateTimes();
    });

    // 순서가 바뀌었으므로
    // 새로운 구간들을 실제 API로 재계산
    await _updateTravelTimes(
      showMessage: true,
    );

    await _savePlan();
  }

  // ============================================================
  // 전체 시간 재계산
  // ============================================================

  Future<void> _resetTimes() async {
    if (currentDay.spots
        .isEmpty) {
      return;
    }

    final start =
        _dayStartMinute ??
            defaultStartMinute;

    setState(() {
      _recalculateTimes(
        startMinute:
            start,
      );
    });

    await _savePlan();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          '일정 시간이 다시 계산됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // Day 요약
  // ============================================================

  Widget _buildDaySummary() {
    final spots =
        currentDay.spots;

    int totalDuration = 0;
    int totalTravel = 0;

    for (final spot
        in spots) {
      totalDuration +=
          spot.durationMinutes;

      totalTravel +=
          spot.travelMinutesFromPrevious;
    }

    final lastSpot =
        spots.isEmpty
            ? null
            : spots.last;

    int? finishMinute;

    if (lastSpot != null &&
        lastSpot.startMinute !=
            null) {
      finishMinute =
          lastSpot.startMinute! +
              lastSpot.durationMinutes;
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 15,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
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
      child: Row(
        children: [
          Expanded(
            child:
                _SummaryItem(
              title:
                  '방문 장소',
              value:
                  '${spots.length}곳',
            ),
          ),
          Expanded(
            child:
                _SummaryItem(
              title:
                  '체류',
              value:
                  _durationText(
                totalDuration,
              ),
            ),
          ),
          Expanded(
            child:
                _SummaryItem(
              title:
                  '이동',
              value:
                  _durationText(
                totalTravel,
              ),
            ),
          ),
          Expanded(
            child:
                _SummaryItem(
              title:
                  '종료 예상',
              value:
                  finishMinute ==
                          null
                      ? '--:--'
                      : _formatMinute(
                          finishMinute,
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 시작시간 카드
  // ============================================================

  Widget _buildStartTimeCard() {
    final start =
        _dayStartMinute;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        2,
      ),
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        gradient:
            LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(
                  0.10,
                ),
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(
                  0.04,
                ),
          ],
        ),
        border:
            Border.all(
          color: Theme.of(
            context,
          )
              .colorScheme
              .primary
              .withOpacity(
                0.16,
              ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color: Theme.of(
                context,
              )
                  .colorScheme
                  .primary
                  .withOpacity(
                    0.12,
                  ),
              borderRadius:
                  BorderRadius
                      .circular(
                14,
              ),
            ),
            child:
                Icon(
              Icons
                  .wb_sunny_outlined,
              color:
                  Theme.of(
                context,
              )
                      .colorScheme
                      .primary,
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
                const Text(
                  '오늘 여행 시작',
                  style:
                      TextStyle(
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  start ==
                          null
                      ? '시작 시간을 정해주세요'
                      : '${_formatMinute(start)}부터 시작',
                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
                if (start !=
                    null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '실제 이동시간을 기준으로 이후 일정이 자동 계산됩니다.',
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          SizedBox(
            width: 64,
            child: OutlinedButton(
              onPressed:
                  _showStartTimePicker,
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      8,
                  vertical:
                      10,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
              ),
              child:
                  Text(
                start == null
                    ? '설정'
                    : '변경',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Day 선택
  // ============================================================

  Widget _buildDaySelector() {
    return SizedBox(
      height: 72,
      child:
          ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
        ),
        itemCount:
            travelPlan.days
                .length,
        itemBuilder:
            (context, index) {
          final day =
              travelPlan
                  .days[index];

          final selected =
              index ==
                  selectedDayIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDayIndex =
                    index;
              });

              _updateTravelTimes(
                showMessage:
                    false,
              );
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    200,
              ),
              width: 76,
              margin:
                  const EdgeInsets
                      .only(
                right: 10,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? Theme.of(
                        context,
                      )
                        .colorScheme
                        .primary
                    : Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                border:
                    Border.all(
                  color: selected
                      ? Theme.of(
                          context,
                        )
                          .colorScheme
                          .primary
                      : Colors.grey
                          .shade200,
                ),
              ),
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    'DAY ${day.day}',
                    style:
                        TextStyle(
                      fontSize:
                          12,
                      color: selected
                          ? Colors
                              .white
                          : Colors
                              .grey,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${day.spots.length}곳',
                    style:
                        TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight
                              .bold,
                      color: selected
                          ? Colors
                              .white
                          : Colors
                              .black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ★ 이동 구간
  // 도보 + 자동차 시간 표시
  // ============================================================

  Widget _buildTravelSegment(
    TravelSpot spot,
    int index,
  ) {
    if (index == 0) {
      return const SizedBox.shrink();
    }

    final walkingMinutes =
        spot.travelMinutesFromPrevious;

    final carMinutes =
        _carTravelMinutes[index];

    return Padding(
      padding:
          const EdgeInsets.only(
        left: 61,
        right: 16,
        top: 2,
        bottom: 2,
      ),
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        onTap: () =>
            _changeTravelTime(
          spot,
        ),
        child:
            Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                12,
            vertical:
                9,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.grey.shade50,
            borderRadius:
                BorderRadius
                    .circular(
              14,
            ),
            border:
                Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child:
              Row(
            children: [
              Icon(
                Icons
                    .more_vert,
                size: 18,
                color:
                    Colors.grey
                        .shade500,
              ),
              const SizedBox(
                width: 7,
              ),

              // ------------------------------------------------
              // 도보
              // ------------------------------------------------

              Icon(
                Icons
                    .directions_walk_outlined,
                size: 17,
                color:
                    Colors.grey
                        .shade600,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                '도보 ${_durationText(walkingMinutes)}',
                style:
                    TextStyle(
                  fontSize:
                      12,
                  color:
                      Colors.grey
                          .shade600,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),

              // ------------------------------------------------
              // 구분점
              // ------------------------------------------------

              const SizedBox(
                width: 8,
              ),

              Text(
                '·',
                style:
                    TextStyle(
                  fontSize:
                      13,
                  color:
                      Colors.grey
                          .shade400,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // ------------------------------------------------
              // 자동차
              // ------------------------------------------------

              Icon(
                Icons
                    .directions_car_outlined,
                size: 17,
                color:
                    Colors.grey
                        .shade600,
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child:
                    Text(
                  carMinutes ==
                          null
                      ? '자동차 계산 중'
                      : '차 ${_durationText(carMinutes)}',
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    color:
                        Colors.grey
                            .shade600,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ),

              // ------------------------------------------------
              // 수정 아이콘
              // ------------------------------------------------

              Icon(
                Icons
                    .edit_outlined,
                size: 15,
                color:
                    Colors.grey
                        .shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 장소 카드
  // ============================================================

  Widget _buildSpotCard(
    TravelSpot spot,
    int index,
  ) {
    final start =
        spot.startMinute;

    final finish =
        start == null
            ? null
            : start +
                spot.durationMinutes;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 4,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          SizedBox(
            width: 52,
            child:
                Column(
              children: [
                Text(
                  _formatMinute(
                    start,
                  ),
                  style:
                      const TextStyle(
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  finish == null
                      ? ''
                      : _formatMinute(
                          finish,
                        ),
                  style:
                      TextStyle(
                    fontSize:
                        10,
                    color: Colors
                        .grey
                        .shade500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 22,
            child:
                Column(
              children: [
                Container(
                  width: 2,
                  height: 8,
                  color: Colors
                      .grey
                      .shade300,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration:
                      BoxDecoration(
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary,
                    shape:
                        BoxShape
                            .circle,
                  ),
                ),
                if (index <
                    currentDay
                            .spots
                            .length -
                        1)
                  Container(
                    width: 2,
                    height: 120,
                    color: Colors
                        .grey
                        .shade300,
                  ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Dismissible(
              key:
                  ValueKey(
                '${currentDay.day}_${spot.kakaoPlaceId ?? spot.name}_$index',
              ),
              direction:
                  DismissDirection
                      .endToStart,
              background:
                  Container(
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 10,
                ),
                alignment:
                    Alignment
                        .centerRight,
                padding:
                    const EdgeInsets
                        .only(
                  right: 20,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors
                      .red
                      .shade100,
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .delete_outline,
                  color: Colors
                      .red,
                ),
              ),
              onDismissed:
                  (_) {
                _removeSpot(
                  spot,
                );
              },
              child:
                  Card(
                elevation:
                    0,
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 10,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                  side:
                      BorderSide(
                    color: Colors
                        .grey
                        .shade200,
                  ),
                ),
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    16,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Expanded(
                            child:
                                Text(
                              spot.name,
                              style:
                                  const TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                          ReorderableDragStartListener(
                            index:
                                index,
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                left:
                                    8,
                              ),
                              child:
                                  Icon(
                                Icons
                                    .drag_handle,
                                color: Colors
                                    .grey
                                    .shade400,
                              ),
                            ),
                          ),
                          PopupMenuButton<
                              String>(
                            padding:
                                EdgeInsets.zero,
                            icon:
                                Icon(
                              Icons
                                  .more_horiz,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                            onSelected:
                                (value) {
                              if (value ==
                                  'duration') {
                                _changeDuration(
                                  spot,
                                );
                              }

                              if (value ==
                                  'travel') {
                                _changeTravelTime(
                                  spot,
                                );
                              }

                              if (value ==
                                  'route') {
                                _updateTravelTimes();
                              }

                              if (value ==
                                  'delete') {
                                _removeSpot(
                                  spot,
                                );
                              }
                            },
                            itemBuilder:
                                (_) =>
                                    const [
                              PopupMenuItem(
                                value:
                                    'duration',
                                child:
                                    Text(
                                  '체류시간 변경',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'travel',
                                child:
                                    Text(
                                  '이동시간 직접 변경',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'route',
                                child:
                                    Text(
                                  '실제 경로로 다시 계산',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'delete',
                                child:
                                    Text(
                                  '삭제',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (spot.category !=
                          null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          spot.category!,
                          style:
                              TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                      if (spot.address !=
                          null) ...[
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          spot.address!,
                          maxLines:
                              1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color: Colors.grey.shade500,
                            fontSize:
                                11,
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 14,
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              12,
                          vertical:
                              10,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .grey
                              .shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .schedule_outlined,
                              size:
                                  16,
                              color:
                                  Theme.of(
                                context,
                              )
                                      .colorScheme
                                      .primary,
                            ),
                            const SizedBox(
                              width:
                                  7,
                            ),
                            Text(
                              start ==
                                      null
                                  ? '시간 미정'
                                  : '${_formatMinute(start)} → ${_formatMinute(finish)}',
                              style:
                                  const TextStyle(
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _durationText(
                                spot
                                    .durationMinutes,
                              ),
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Wrap(
                        spacing:
                            7,
                        runSpacing:
                            7,
                        children: [
                          _InfoChip(
                            icon:
                                Icons.schedule,
                            text:
                                '체류 ${_durationText(spot.durationMinutes)}',
                          ),
                          if (index >
                              0)
                            _InfoChip(
                              icon:
                                  Icons.directions_walk_outlined,
                              text:
                                  '이동 ${_durationText(spot.travelMinutesFromPrevious)}',
                            ),
                          if (spot.snobScore !=
                              null)
                            _InfoChip(
                              icon:
                                  Icons.eco_outlined,
                              text:
                                  'SNOB ${spot.snobScore!.toStringAsFixed(0)}',
                            ),
                          if (spot.latitude !=
                                  null &&
                              spot.longitude !=
                                  null)
                            const _InfoChip(
                              icon:
                                  Icons.gps_fixed,
                              text:
                                  '좌표 확인',
                            ),
                        ],
                      ),
                      if (spot.congestion !=
                          null) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .people_outline,
                              size:
                                  14,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                            const SizedBox(
                              width:
                                  5,
                            ),
                            Text(
                              '평균 혼잡도 '
                              '${spot.congestion!.toStringAsFixed(1)}',
                              style:
                                  TextStyle(
                                fontSize:
                                    11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Timeline
  // ============================================================

  Widget _buildTimeline() {
    return Stack(
      children: [
        ReorderableListView.builder(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            160,
          ),
          buildDefaultDragHandles:
              false,
          itemCount:
              currentDay
                  .spots
                  .length,
          onReorder:
              _reorderSpots,
          itemBuilder:
              (context, index) {
            final spot =
                currentDay
                    .spots[index];

            return Column(
              key:
                  ValueKey(
                'timeline_${currentDay.day}_${spot.kakaoPlaceId ?? spot.name}_$index',
              ),
              children: [
                if (index >
                    0)
                  _buildTravelSegment(
                    spot,
                    index,
                  ),
                _buildSpotCard(
                  spot,
                  index,
                ),
              ],
            );
          },
        ),
        if (_recalculatingRoutes)
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child:
                Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    14,
                vertical:
                    10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.black87,
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
              child:
                  const Row(
                mainAxisSize:
                    MainAxisSize
                        .min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    '실제 이동 경로 계산 중...',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // Empty
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .primary
                    .withOpacity(
                      0.08,
                    ),
                shape:
                    BoxShape
                        .circle,
              ),
              child:
                  Icon(
                Icons
                    .route_outlined,
                size: 42,
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            const Text(
              '아직 일정이 없어요.',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '장소를 검색해서 추가하면\n'
              '실제 위치를 기준으로 이동시간도 계산해드려요.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            FilledButton.icon(
              onPressed:
                  _showPlaceSearch,
              icon:
                  const Icon(
                Icons.search,
              ),
              label:
                  const Text(
                '장소 검색',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasSpots =
        currentDay
            .spots
            .isNotEmpty;

    return Scaffold(
      appBar:
          AppBar(
        title:
            Text(
          '${travelPlan.regionName} 여행',
        ),
        actions: [
          PopupMenuButton<
              String>(
            onSelected:
                (value) {
              if (value ==
                  'route') {
                _updateTravelTimes();
              }

              if (value ==
                  'reset_time') {
                _resetTimes();
              }
            },
            itemBuilder:
                (_) =>
                    const [
              PopupMenuItem(
                value:
                    'route',
                child:
                    Text(
                  '실제 이동시간 다시 계산',
                ),
              ),
              PopupMenuItem(
                value:
                    'reset_time',
                child:
                    Text(
                  '일정 시간 다시 계산',
                ),
              ),
            ],
          ),
        ],
      ),
      body:
          Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          _buildDaySelector(),
          const SizedBox(
            height: 10,
          ),
          _buildStartTimeCard(),
          _buildDaySummary(),
          const Divider(
            height: 1,
          ),
          Expanded(
            child: hasSpots
                ? _buildTimeline()
                : _buildEmptyState(),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 116,
        height: 52,
        child: FloatingActionButton.extended(
          onPressed: _showPlaceSearch,
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(
            Icons.search,
            size: 20,
          ),
          label: const Text(
            '장소 검색',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Info Chip
// ============================================================

class _InfoChip
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize
                .min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors
                .grey.shade700,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style:
                TextStyle(
              fontSize: 11,
              color: Colors
                  .grey.shade700,
              fontWeight:
                  FontWeight
                      .w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Summary Item
// ============================================================

class _SummaryItem
    extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          title,
          style:
              TextStyle(
            fontSize: 10,
            color: Colors
                .grey.shade600,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow
                  .ellipsis,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight
                    .bold,
          ),
        ),
      ],
    );
  }
}