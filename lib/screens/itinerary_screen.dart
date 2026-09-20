import 'package:flutter/material.dart';

import '../../models/travel_plan.dart';
import '../../services/travel_plan_storage.dart';
import '../../services/kakao_local_service.dart';
import '../../services/route_service.dart';
import 'place_search_sheet.dart';
import '../../widgets/tourism_image.dart';

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

  static const int defaultStartMinute = 9 * 60;

  final RouteService _routeService = RouteService();

  bool _recalculatingRoutes = false;

  int _routeCalculationToken = 0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return travelPlan.days[selectedDayIndex];
  }

  void _normalizeCurrentDay() {
    if (travelPlan.days.isEmpty) {
      travelPlan.days.add(
        TravelDay(day: 1),
      );
    }

    if (selectedDayIndex >= travelPlan.days.length) {
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
    travelPlan.updatedAt = DateTime.now();

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

    final hour = (minute ~/ 60) % 24;
    final min = minute % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${min.toString().padLeft(2, '0')}';
  }

  String _durationText(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    }

    final hour = minutes ~/ 60;
    final remain = minutes % 60;

    if (remain == 0) {
      return '$hour시간';
    }

    return '$hour시간 $remain분';
  }

  int? get _dayStartMinute {
    if (currentDay.spots.isEmpty) {
      return null;
    }

    return currentDay.spots.first.startMinute;
  }

  // ============================================================
  // 시간 자동 계산
  // ============================================================

  void _recalculateTimes({
    int? startMinute,
  }) {
    final spots = currentDay.spots;

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
      final spot = spots[i];

      spots[i] = spot.copyWith(
        startMinute: currentMinute,
        travelMinutesFromPrevious:
            i == 0
                ? 0
                : spot.travelMinutesFromPrevious,
      );

      currentMinute += spot.durationMinutes;

      if (i < spots.length - 1) {
        currentMinute +=
            spots[i + 1].travelMinutesFromPrevious;
      }
    }
  }

  // ============================================================
  // 실제 좌표 기반 이동시간 계산
  // ============================================================

  Future<void> _updateTravelTimes({
    bool showMessage = true,
  }) async {
    final spots = List<TravelSpot>.from(
      currentDay.spots,
    );

    if (spots.length < 2) {
      _carTravelMinutes.clear();
      return;
    }

    final token = ++_routeCalculationToken;

    setState(() {
      _recalculatingRoutes = true;
    });

    bool hasFallback = false;
    bool hasMissingCoordinates = false;

    final Map<int, int> newCarTravelMinutes = {};

    try {
      for (
        int i = 1;
        i < spots.length;
        i++
      ) {
        final previous = spots[i - 1];
        final current = spots[i];

        if (previous.latitude == null ||
            previous.longitude == null ||
            current.latitude == null ||
            current.longitude == null) {
          hasMissingCoordinates = true;
          continue;
        }

        final walkingRoute =
            await _routeService.getWalkingRoute(
          startLatitude: previous.latitude!,
          startLongitude: previous.longitude!,
          endLatitude: current.latitude!,
          endLongitude: current.longitude!,
        );

        if (!mounted) {
          return;
        }

        if (token != _routeCalculationToken) {
          return;
        }

        spots[i] = current.copyWith(
          travelMinutesFromPrevious:
              walkingRoute.durationMinutes,
        );

        if (!walkingRoute.fromApi) {
          hasFallback = true;
        }

        try {
          final drivingRoute =
              await _routeService.getDrivingRoute(
            startLatitude: previous.latitude!,
            startLongitude: previous.longitude!,
            endLatitude: current.latitude!,
            endLongitude: current.longitude!,
          );

          newCarTravelMinutes[i] =
              drivingRoute.durationMinutes;
        } catch (_) {}

        if (!mounted) {
          return;
        }

        if (token != _routeCalculationToken) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      if (token != _routeCalculationToken) {
        return;
      }

      setState(() {
        for (
          int i = 0;
          i < spots.length;
          i++
        ) {
          currentDay.spots[i] = spots[i];
        }

        _carTravelMinutes
          ..clear()
          ..addAll(newCarTravelMinutes);

        _recalculateTimes();
      });

      await _savePlan();

      if (!mounted || !showMessage) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted &&
          token == _routeCalculationToken) {
        setState(() {
          _recalculatingRoutes = false;
        });
      }
    }
  }

  // ============================================================
  // 시작 시간
  // ============================================================

  Future<void> _showStartTimePicker() async {
    final initialMinute =
        _dayStartMinute ?? defaultStartMinute;

    final initialTime = TimeOfDay(
      hour: (initialMinute ~/ 60) % 24,
      minute: initialMinute % 60,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '여행 시작 시간을 선택하세요',
      cancelText: '취소',
      confirmText: '설정',
    );

    if (picked == null) {
      return;
    }

    final newMinute =
        picked.hour * 60 + picked.minute;

    setState(() {
      _recalculateTimes(
        startMinute: newMinute,
      );
    });

    await _savePlan();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _showPlaceSearch() async {
    final place = await showModalBottomSheet<KakaoPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return const SizedBox(
          height: 650,
          child: PlaceSearchSheet(),
        );
      },
    );

    if (place == null) {
      return;
    }

    await _addKakaoPlace(place);
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
          spot.kakaoPlaceId == place.id ||
          spot.name == place.name,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '이미 같은 장소가 일정에 있어요.',
          ),
        ),
      );
      return;
    }

    final isFirst = currentDay.spots.isEmpty;

    final spot = TravelSpot(
      name: place.name,
      category: place.categoryName,
      address: place.displayAddress,
      latitude: place.latitude,
      longitude: place.longitude,
      kakaoPlaceId: place.id,
      kakaoPlaceUrl: place.placeUrl,
      startMinute: null,
      durationMinutes:
          _defaultDurationForCategory(
        place.categoryName,
      ),
      travelMinutesFromPrevious:
          isFirst ? 0 : 20,
    );

    setState(() {
      currentDay.spots.add(spot);

      _recalculateTimes();
    });

    await _updateTravelTimes(
      showMessage: false,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
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
    final value = category ?? '';

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
    final options = <int>[
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
        await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이동 시간 직접 설정',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...options.map(
                  (minutes) {
                    final selected =
                        spot.travelMinutesFromPrevious ==
                            minutes;

                    return ListTile(
                      leading: Icon(
                        Icons.directions_walk_outlined,
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.grey,
                      ),
                      title: Text(
                        _durationText(minutes),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            )
                          : null,
                      onTap: () {
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
        currentDay.spots.indexOf(spot);

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
    final options = <int>[
      30,
      45,
      60,
      90,
      120,
      150,
      180,
    ];

    final selected =
        await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '머무르는 시간',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...options.map(
                  (minutes) {
                    final selected =
                        spot.durationMinutes ==
                            minutes;

                    return ListTile(
                      leading: Icon(
                        Icons.schedule_outlined,
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.grey,
                      ),
                      title: Text(
                        _durationText(minutes),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            )
                          : null,
                      onTap: () {
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
        currentDay.spots.indexOf(spot);

    if (index == -1) {
      return;
    }

    setState(() {
      currentDay.spots[index] =
          spot.copyWith(
        durationMinutes: selected,
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
      currentDay.spots.remove(spot);

      if (currentDay.spots.isNotEmpty) {
        currentDay.spots[0] =
            currentDay.spots[0].copyWith(
          travelMinutesFromPrevious: 0,
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
  // 드래그 순서 변경
  // ============================================================

  Future<void> _reorderSpots(
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final spot =
          currentDay.spots.removeAt(oldIndex);

      currentDay.spots.insert(
        newIndex,
        spot,
      );

      if (currentDay.spots.isNotEmpty) {
        currentDay.spots[0] =
            currentDay.spots[0].copyWith(
          travelMinutesFromPrevious: 0,
        );
      }

      _recalculateTimes();
    });

    await _updateTravelTimes(
      showMessage: true,
    );

    await _savePlan();
  }

  // ============================================================
  // 전체 시간 재계산
  // ============================================================

  Future<void> _resetTimes() async {
    if (currentDay.spots.isEmpty) {
      return;
    }

    final start =
        _dayStartMinute ??
            defaultStartMinute;

    setState(() {
      _recalculateTimes(
        startMinute: start,
      );
    });

    await _savePlan();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '일정 시간이 다시 계산됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // 일정 완료
  // ============================================================

  void _onTravelComplete() {
    /*
     * 현재 제공된 ItineraryScreen에는
     * 여행 완료/TripRecord 생성 로직이 존재하지 않음.
     *
     * 따라서 기존 저장 로직을 임의로 변경하지 않기 위해
     * 여기서는 기존 완료 로직을 호출하지 않는다.
     *
     * 실제 완료 로직이 다른 파일에 있다면
     * 이 메서드에 해당 함수만 연결하면 된다.
     */
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '여행 완료 기능은 기존 완료 처리와 연결해주세요.',
        ),
      ),
    );
  }

  // ============================================================
  // Day 요약
  // ============================================================

  Widget _buildDaySummary() {
    final spots = currentDay.spots;

    int totalDuration = 0;
    int totalTravel = 0;

    for (final spot in spots) {
      totalDuration += spot.durationMinutes;
      totalTravel +=
          spot.travelMinutesFromPrevious;
    }

    final lastSpot =
        spots.isEmpty ? null : spots.last;

    int? finishMinute;

    if (lastSpot != null &&
        lastSpot.startMinute != null) {
      finishMinute =
          lastSpot.startMinute! +
              lastSpot.durationMinutes;
    }

    return Row(
      children: [
        Expanded(
          child: _WebSummaryItem(
            icon: Icons.location_on_outlined,
            title: '방문 장소',
            value: '${spots.length}곳',
          ),
        ),
        Expanded(
          child: _WebSummaryItem(
            icon: Icons.timelapse_outlined,
            title: '체류',
            value: _durationText(
              totalDuration,
            ),
          ),
        ),
        Expanded(
          child: _WebSummaryItem(
            icon: Icons.directions_walk_outlined,
            title: '이동',
            value: _durationText(
              totalTravel,
            ),
          ),
        ),
        Expanded(
          child: _WebSummaryItem(
            icon: Icons.flag_outlined,
            title: '종료 예상',
            value: finishMinute == null
                ? '--:--'
                : _formatMinute(
                    finishMinute,
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 시작 시간
  // ============================================================

  Widget _buildStartTimeCard() {
    final start = _dayStartMinute;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.09),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 여행 시작',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  start == null
                      ? '시작 시간을 정해주세요'
                      : '${_formatMinute(start)}부터 시작',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _showStartTimePicker,
            child: Text(
              start == null ? '설정' : '변경',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 웹 Day 카드
  // ============================================================

  Widget _buildWebDayCards() {
    return Column(
      children: [
        for (
          int index = 0;
          index < travelPlan.days.length;
          index++
        )
          _buildWebDayCard(
            travelPlan.days[index],
            index,
          ),
      ],
    );
  }

  Widget _buildWebDayCard(
    TravelDay day,
    int index,
  ) {
    final selected =
        selectedDayIndex == index;

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedDayIndex = index;
        });

        await _updateTravelTimes(
          showMessage: false,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .primary
              : Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.15),
                    blurRadius: 18,
                    offset:
                        const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                        .withOpacity(0.16)
                    : Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY ${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                              .withOpacity(0.75)
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.spots.length}곳의 여행지',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.chevron_right
                  : Icons.chevron_right,
              color: selected
                  ? Colors.white
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 이동 구간
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
      padding: const EdgeInsets.only(
        left: 76,
        right: 20,
        top: 2,
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () => _changeTravelTime(
          spot,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_walk_outlined,
                size: 17,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                '도보 ${_durationText(walkingMinutes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '·',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.directions_car_outlined,
                size: 17,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  carMinutes == null
                      ? '자동차 계산 중'
                      : '차 ${_durationText(carMinutes)}',
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 15,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 관광지 이미지
  // ============================================================

  Widget _buildSpotImage(
    TravelSpot spot,
  ) {
    /*
     * TravelSpot에 contentId가 있는 경우
     * 기존 TourismImage를 사용한다.
     *
     * contentId가 없는 Kakao 장소는
     * 임의 이미지를 사용하지 않고 기본 화면을 표시한다.
     */

    final dynamic contentId =
        spot.contentId;

    if (contentId == null ||
        contentId.toString().trim().isEmpty) {
      return Container(
        color: const Color(0xFFF0F2F0),
        child: Icon(
          Icons.landscape_outlined,
          size: 34,
          color: Colors.grey.shade400,
        ),
      );
    }

    return TourismImage(
      contentId: contentId.toString(),
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
    );
  }

  // ============================================================
  // 장소 카드
  // ============================================================

  Widget _buildSpotCard(
    TravelSpot spot,
    int index,
  ) {
    final start = spot.startMinute;

    final finish = start == null
        ? null
        : start + spot.durationMinutes;

    return Dismissible(
      key: ValueKey(
        '${currentDay.day}_'
        '${spot.kakaoPlaceId ?? spot.name}_'
        '$index',
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        margin:
            const EdgeInsets.only(bottom: 12),
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),
      onDismissed: (_) {
        _removeSpot(spot);
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.025),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // 순서
              // --------------------------------------------------

              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // --------------------------------------------------
              // 이미지
              // --------------------------------------------------

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: SizedBox(
                  width: 145,
                  height: 150,
                  child: _buildSpotImage(spot),
                ),
              ),

              const SizedBox(width: 18),

              // --------------------------------------------------
              // 정보
              // --------------------------------------------------

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              spot.name,
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle,
                              color: Colors
                                  .grey.shade400,
                            ),
                          ),

                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz,
                              color: Colors
                                  .grey.shade600,
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
                                child: Text(
                                  '체류시간 변경',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'travel',
                                child: Text(
                                  '이동시간 직접 변경',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'route',
                                child: Text(
                                  '실제 경로로 다시 계산',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'delete',
                                child: Text(
                                  '삭제',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (spot.category != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          spot.category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],

                      if (spot.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          spot.address!,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 15),

                      // 시간
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF7F8F6,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .schedule_outlined,
                              size: 17,
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              start == null
                                  ? '시간 미정'
                                  : '${_formatMinute(start)}'
                                    ' → '
                                    '${_formatMinute(finish)}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _durationText(
                                spot.durationMinutes,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _InfoChip(
                            icon:
                                Icons.schedule,
                            text:
                                '체류 ${_durationText(spot.durationMinutes)}',
                          ),
                          if (index > 0)
                            _InfoChip(
                              icon: Icons
                                  .directions_walk_outlined,
                              text:
                                  '이동 ${_durationText(spot.travelMinutesFromPrevious)}',
                            ),
                          if (spot.snobScore != null)
                            _InfoChip(
                              icon:
                                  Icons.eco_outlined,
                              text:
                                  'SNOB ${spot.snobScore!.toStringAsFixed(0)}',
                            ),
                        ],
                      ),

                      if (spot.congestion != null) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .people_outline,
                              size: 14,
                              color: Colors
                                  .grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '평균 혼잡도 '
                              '${spot.congestion!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
  // Timeline
  // ============================================================

  Widget _buildTimeline() {
    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(
            0,
            4,
            0,
            160,
          ),
          buildDefaultDragHandles: false,
          itemCount: currentDay.spots.length,
          onReorder: _reorderSpots,
          itemBuilder: (context, index) {
            final spot =
                currentDay.spots[index];

            return Column(
              key: ValueKey(
                'timeline_'
                '${currentDay.day}_'
                '${spot.kakaoPlaceId ?? spot.name}_'
                '$index',
              ),
              children: [
                if (index > 0)
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
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '실제 이동 경로 계산 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 42,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '아직 일정이 없어요.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '장소를 검색해서 추가하면\n'
              '실제 위치를 기준으로 이동시간도 계산해드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showPlaceSearch,
              icon: const Icon(Icons.search),
              label: const Text('장소 검색'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 웹 헤더
  // ============================================================

  Widget _buildWebHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'TRAVEL PLANNER',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${travelPlan.regionName} 여행',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '여행 날짜별 일정을 한눈에 확인하고 '
                '원하는 순서로 자유롭게 수정해보세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        OutlinedButton.icon(
          onPressed: _updateTravelTimes,
          icon: const Icon(
            Icons.route_outlined,
            size: 18,
          ),
          label: const Text(
            '이동시간 다시 계산',
          ),
        ),

        const SizedBox(width: 10),

        FilledButton.icon(
          onPressed: _showPlaceSearch,
          icon: const Icon(
            Icons.add_location_alt_outlined,
            size: 18,
          ),
          label: const Text(
            '장소 추가',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 여행 완료 영역
  // ============================================================

  Widget _buildCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '여행 준비가 끝났나요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '여행을 마친 후 완료 버튼을 눌러 기록을 남길 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          FilledButton.icon(
            onPressed: null,
            icon: Icon(
              Icons.check_circle_outline,
            ),
            label: Text(
              '여행 완료',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Desktop
  // ============================================================

  Widget _buildDesktopLayout() {
    final hasSpots =
        currentDay.spots.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        40,
        34,
        40,
        80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1280,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildWebHeader(),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // Day 목록
                  // ------------------------------------------------

                  SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '여행 일정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildWebDayCards(),
                      ],
                    ),
                  ),

                  const SizedBox(width: 28),

                  // ------------------------------------------------
                  // 선택된 Day
                  // ------------------------------------------------

                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        border: Border.all(
                          color: Colors
                              .grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                              0.025,
                            ),
                            blurRadius: 20,
                            offset:
                                const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'DAY ${currentDay.day}',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            12,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color: Theme.of(
                                          context,
                                        )
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      '오늘의 여행 일정',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            23,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _showStartTimePicker,
                                icon: const Icon(
                                  Icons
                                      .schedule_outlined,
                                  size: 17,
                                ),
                                label: Text(
                                  _dayStartMinute ==
                                          null
                                      ? '시작 시간 설정'
                                      : _formatMinute(
                                          _dayStartMinute,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          _buildDaySummary(),

                          const SizedBox(
                            height: 14,
                          ),

                          _buildStartTimeCard(),

                          const SizedBox(
                            height: 24,
                          ),

                          if (hasSpots)
                            _buildTimeline()
                          else
                            SizedBox(
                              height: 400,
                              child:
                                  _buildEmptyState(),
                            ),

                          const SizedBox(
                            height: 10,
                          ),

                          _buildCompleteCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Mobile
  // ============================================================

  Widget _buildMobileLayout() {
    final hasSpots =
        currentDay.spots.isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            18,
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'TRAVEL PLANNER',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${travelPlan.regionName} 여행',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection:
                      Axis.horizontal,
                  itemCount:
                      travelPlan.days.length,
                  itemBuilder:
                      (context, index) {
                    final day =
                        travelPlan.days[index];

                    final selected =
                        selectedDayIndex ==
                            index;

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          selectedDayIndex =
                              index;
                        });

                        await _updateTravelTimes(
                          showMessage: false,
                        );
                      },
                      child:
                          AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 200,
                        ),
                        width: 82,
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
                              BorderRadius.circular(
                            16,
                          ),
                          border: Border.all(
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
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Text(
                              'DAY ${day.day}',
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${day.spots.length}곳',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : Colors.black,
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
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            child: Column(
              children: [
                _buildStartTimeCard(),

                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: _buildDaySummary(),
                ),

                const SizedBox(height: 14),

                if (hasSpots)
                  _buildTimeline()
                else
                  SizedBox(
                    height: 400,
                    child: _buildEmptyState(),
                  ),

                const SizedBox(height: 10),

                _buildCompleteCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${travelPlan.regionName} 여행',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'route') {
                _updateTravelTimes();
              }

              if (value == 'reset_time') {
                _resetTimes();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'route',
                child: Text(
                  '실제 이동시간 다시 계산',
                ),
              ),
              PopupMenuItem(
                value: 'reset_time',
                child: Text(
                  '일정 시간 다시 계산',
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return _buildDesktopLayout();
          }

          return _buildMobileLayout();
        },
      ),
      floatingActionButton:
          MediaQuery.of(context).size.width < 1000
              ? SizedBox(
                  width: 120,
                  height: 52,
                  child: FloatingActionButton.extended(
                    onPressed: _showPlaceSearch,
                    backgroundColor:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    icon: const Icon(
                      Icons.search,
                      size: 20,
                    ),
                    label: const Text(
                      '장소 추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        26,
                      ),
                    ),
                  ),
                )
              : null,
    );
  }
}

// ================================================================
// Web Summary Item
// ================================================================

class _WebSummaryItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _WebSummaryItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// Info Chip
// ================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}