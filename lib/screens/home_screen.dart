import 'package:flutter/material.dart'; 
 
import 'trip/personality_test/personality_test_screen.dart'; 
import 'itinerary_screen.dart'; 
 
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
            ItineraryScreen( 
          travelPlan: savedPlan!, 
        ), 
      ), 
    ); 
 
    // 일정 화면에서 수정했을 수 있으므로 
    // 돌아온 뒤 최신 데이터 다시 불러오기 
    await _loadTravelPlan(); 
  } 
 
// ============================================================ 
// 여행 완료 → 날짜 선택 → 기록으로 저장 
// ============================================================ 
 
Future<void> _completeTravel() async { 
  if (savedPlan == null) return; 
 
  final plan = savedPlan!; 
 
  // ---------------------------------------------------------- 
  // 1. 여행 날짜 선택 
  // ---------------------------------------------------------- 
 
  final selectedRange = await showDateRangePicker( 
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
 
  // 날짜 선택을 취소한 경우 
  if (selectedRange == null) { 
    return; 
  } 
 
  // ---------------------------------------------------------- 
  // 2. 방문한 관광지 이름 가져오기 
  // ---------------------------------------------------------- 
 
  final visitedPlaces = <String>[]; 
 
  for (final day in plan.days) { 
    for (final spot in day.spots) { 
      visitedPlaces.add(spot.name); 
    } 
  } 
 
  // ---------------------------------------------------------- 
  // 3. 여행 기록 생성 
  // ---------------------------------------------------------- 
 
  try { 
    final record = TripRecord( 
      regionName: plan.regionName, 
 
      // 캘린더에서 선택한 여행 기간 
      startDate: selectedRange.start, 
      endDate: selectedRange.end, 
 
      diary: '', 
      photoPaths: [], 
      visitedPlaces: visitedPlaces, 
    ); 
 
    // -------------------------------------------------------- 
    // 4. 기록 저장 
    // -------------------------------------------------------- 
 
    await TripRecordStorage.saveRecord(record); 
 
    // -------------------------------------------------------- 
    // 5. 현재 진행 중인 여행 삭제 
    // -------------------------------------------------------- 
 
    await TravelPlanStorage.deleteTravelPlan(); 
 
    if (!mounted) return; 
 
    setState(() { 
      savedPlan = null; 
    }); 
 
    // -------------------------------------------------------- 
    // 6. 완료 메시지 
    // -------------------------------------------------------- 
 
    ScaffoldMessenger.of(context).showSnackBar( 
      const SnackBar( 
        content: Text( 
          '여행이 완료되었어요 ✨ 기록 탭에서 확인해보세요.', 
        ), 
      ), 
    ); 
  } catch (e) { 
    debugPrint('여행 완료 처리 실패: $e'); 
 
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
      // 테스트 후 돌아왔을 때 
      // 새로 저장된 여행 일정 확인 
      _loadTravelPlan(); 
    }); 
  } 
 
  // ============================================================ 
  // 진행 중인 여행 카드 
  // ============================================================ 
 
  Widget _buildCurrentTripCard() { 
    if (savedPlan == null) { 
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
      margin: const EdgeInsets.symmetric( 
        horizontal: 20, 
      ), 
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration( 
        borderRadius: 
            BorderRadius.circular(24), 

        // 기존 쨍한 연두색(primaryContainer)을
        // 차분한 세이지 그린으로 변경
        color: const Color(0xFFDCE8D8), 
      ), 
      child: Column( 
        crossAxisAlignment: 
            CrossAxisAlignment.start, 
        children: [ 
          // ------------------------------------------------------ 
          // 상단 
          // ------------------------------------------------------ 
 
          Row( 
            children: [ 
              Expanded( 
                child: Column( 
                  crossAxisAlignment: 
                      CrossAxisAlignment.start, 
                  children: [ 
                    Text( 
                      '진행 중인 여행', 
                      style: TextStyle( 
                        fontSize: 13, 
                        color: Theme.of(context) 
                            .colorScheme 
                            .onPrimaryContainer 
                            .withValues( 
                              alpha: 0.7, 
                            ), 
                      ), 
                    ), 
                    const SizedBox(height: 5), 
                    Text( 
                      '${plan.regionName} 여행', 
                      style: 
                          const TextStyle( 
                        fontSize: 23, 
                        fontWeight: 
                            FontWeight.bold, 
                      ), 
                    ), 
                  ], 
                ), 
              ), 
 
              PopupMenuButton<String>( 
                onSelected: (value) { 
                  if (value == 'delete') { 
                    _deleteTravelPlan(); 
                  } 
                }, 
                itemBuilder: 
                    (context) => const [ 
                  PopupMenuItem( 
                    value: 'delete', 
                    child: Text( 
                      '여행 일정 삭제', 
                    ), 
                  ), 
                ], 
              ), 
            ], 
          ), 
 
          const SizedBox(height: 20), 
 
          // ------------------------------------------------------ 
          // 여행 정보 
          // ------------------------------------------------------ 
 
          Row( 
            children: [ 
              _TripInfo( 
                icon: 
                    Icons.calendar_today_outlined, 
                text: 
                    '${plan.days.length}일 여행', 
              ), 
              const SizedBox(width: 15), 
              _TripInfo( 
                icon: 
                    Icons.place_outlined, 
                text: 
                    '${plan.totalSpotCount}곳', 
              ), 
            ], 
          ), 
 
          const SizedBox(height: 20), 
 
          // ------------------------------------------------------ 
          // 오늘의 일정 
          // ------------------------------------------------------ 
 
          if (todaySpots.isNotEmpty) ...[ 
            Text( 
              '오늘의 일정', 
              style: TextStyle( 
                fontSize: 13, 
                fontWeight: 
                    FontWeight.bold, 
                color: Theme.of(context) 
                    .colorScheme 
                    .onPrimaryContainer, 
              ), 
            ), 
 
            const SizedBox(height: 10), 
 
            ...todaySpots 
                .take(3) 
                .toList() 
                .asMap() 
                .entries 
                .map( 
              (entry) { 
                final index = 
                    entry.key; 
                final spot = 
                    entry.value; 
 
                return Padding( 
                  padding: 
                      const EdgeInsets.only( 
                    bottom: 8, 
                  ), 
                  child: Row( 
                    children: [ 
                      Container( 
                        width: 24, 
                        height: 24, 
                        alignment: 
                            Alignment.center, 
                        decoration: 
                            BoxDecoration( 
                          shape: 
                              BoxShape.circle, 
                          color: Theme.of( 
                            context, 
                          ) 
                              .colorScheme 
                              .surface, 
                        ), 
                        child: Text( 
                          '${index + 1}', 
                          style: 
                              const TextStyle( 
                            fontSize: 12, 
                            fontWeight: 
                                FontWeight.bold, 
                          ), 
                        ), 
                      ), 
                      const SizedBox( 
                        width: 10, 
                      ), 
                      Expanded( 
                        child: Text( 
                          spot.name, 
                          style: 
                              const TextStyle( 
                            fontSize: 14, 
                          ), 
                          maxLines: 1, 
                          overflow: 
                              TextOverflow 
                                  .ellipsis, 
                        ), 
                      ), 
                    ], 
                  ), 
                ); 
              }, 
            ), 
          ] else ...[ 
            Text( 
              '아직 추가한 관광지가 없어요.', 
              style: TextStyle( 
                color: Theme.of(context) 
                    .colorScheme 
                    .onPrimaryContainer 
                    .withValues( 
                      alpha: 0.7, 
                    ), 
              ), 
            ), 
          ], 
 
          const SizedBox(height: 18), 
 
          // ------------------------------------------------------ 
          // 일정 계속하기 
          // ------------------------------------------------------ 
 
          SizedBox( 
            width: double.infinity, 
            child: FilledButton( 
              onPressed: 
                  _openItinerary, 
              style: FilledButton.styleFrom( 
                backgroundColor: 
                    Theme.of(context) 
                        .colorScheme 
                        .surface, 
                foregroundColor: 
                    Theme.of(context) 
                        .colorScheme 
                        .onSurface, 
                padding: 
                    const EdgeInsets.symmetric( 
                  vertical: 14, 
                ), 
                shape: 
                    RoundedRectangleBorder( 
                  borderRadius: 
                      BorderRadius.circular( 
                    14, 
                  ), 
                ), 
              ), 
              child: const Row( 
                mainAxisAlignment: 
                    MainAxisAlignment.center, 
                children: [ 
                  Text( 
                    '일정 계속하기', 
                    style: TextStyle( 
                      fontWeight: 
                          FontWeight.bold, 
                    ), 
                  ), 
                  SizedBox(width: 6), 
                  Icon( 
                    Icons.arrow_forward, 
                    size: 18, 
                  ), 
                ], 
              ), 
            ), 
          ), 
 
          const SizedBox(height: 10), 
          SizedBox( 
            width: double.infinity, 
            child: OutlinedButton.icon( 
              onPressed: _completeTravel, 
              icon: const Icon( 
                Icons.check_circle_outline, 
              ), 
              label: const Text( 
                '여행 완료', 
              ), 
              style: OutlinedButton.styleFrom( 
                foregroundColor: Theme.of(context) 
                .colorScheme 
                .onPrimaryContainer, 
                side: BorderSide( 
                  color: Theme.of(context) 
                  .colorScheme 
                  .onPrimaryContainer 
                  .withValues(alpha: 0.25), 
                ), 
                padding: const EdgeInsets.symmetric( 
                  vertical: 14, 
                ), 
                shape: RoundedRectangleBorder( 
                  borderRadius: 
                  BorderRadius.circular(14), 
                ), 
              ), 
            ), 
          ), 
        ], 
      ), 
    ); 
  } 
 
  // ============================================================ 
  // 새 여행 만들기 카드 
  // ============================================================ 
 
  Widget _buildNewTripCard() { 
    return Container( 
      width: double.infinity, 
      margin: const EdgeInsets.symmetric( 
        horizontal: 20, 
      ), 
      padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration( 
        borderRadius: 
            BorderRadius.circular(24), 
        border: Border.all( 
          color: Colors.grey.shade200, 
        ), 
      ), 
      child: Column( 
        children: [ 
          Icon( 
            Icons.travel_explore, 
            size: 45, 
            color: Theme.of(context) 
                .colorScheme 
                .primary, 
          ), 
 
          const SizedBox(height: 15), 
 
          const Text( 
            '새로운 여행을 시작해보세요', 
            style: TextStyle( 
              fontSize: 19, 
              fontWeight: 
                  FontWeight.bold, 
            ), 
          ), 
 
          const SizedBox(height: 8), 
 
          Text( 
            '여행 성향을 분석해서\n' 
            '나에게 맞는 여행지를 찾아드려요.', 
            textAlign: 
                TextAlign.center, 
            style: TextStyle( 
              color: 
                  Colors.grey.shade600, 
              height: 1.5, 
            ), 
          ), 
 
          const SizedBox(height: 20), 
 
          SizedBox( 
            width: double.infinity, 
            child: FilledButton.icon( 
              onPressed: 
                  _startPersonalityTest, 
              icon: const Icon( 
                Icons.psychology_outlined, 
              ), 
              label: const Text( 
                '여행 성향 테스트 시작', 
              ), 
              style: 
                  FilledButton.styleFrom( 
                padding: 
                    const EdgeInsets.symmetric( 
                  vertical: 14, 
                ), 
                shape: 
                    RoundedRectangleBorder( 
                  borderRadius: 
                      BorderRadius.circular( 
                    14, 
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
  // 화면 
  // ============================================================ 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        title: const Text('홈'), 
      ), 
 
      body: isLoading 
          ? const Center( 
              child: 
                  CircularProgressIndicator(), 
            ) 
          : RefreshIndicator( 
              onRefresh: 
                  _loadTravelPlan, 
              child: ListView( 
                padding: 
                    const EdgeInsets.only( 
                  top: 20, 
                  bottom: 40, 
                ), 
                children: [ 
                  // ------------------------------------------------ 
                  // 인사 
                  // ------------------------------------------------ 
 
                  const Padding( 
                    padding: 
                        EdgeInsets.symmetric( 
                      horizontal: 20, 
                    ), 
                    child: Column( 
                      crossAxisAlignment: 
                          CrossAxisAlignment 
                              .start, 
                      children: [ 
                        Text( 
                          '안녕하세요 👋', 
                          style: TextStyle( 
                            fontSize: 14, 
                            color: Colors.grey, 
                          ), 
                        ), 
                        SizedBox(height: 5), 
                        Text( 
                          '어디로 떠나볼까요?', 
                          style: 
                              TextStyle( 
                            fontSize: 26, 
                            fontWeight: 
                                FontWeight.bold, 
                          ), 
                        ), 
                      ], 
                    ), 
                  ), 
 
                  const SizedBox( 
                    height: 25, 
                  ), 
 
                  // ------------------------------------------------ 
                  // 진행 중인 여행 
                  // ------------------------------------------------ 
 
                  if (savedPlan != null && 
                      savedPlan! 
                              .totalSpotCount > 
                          0) 
                    _buildCurrentTripCard() 
                  else 
                    _buildNewTripCard(), 
 
                  const SizedBox( 
                    height: 25, 
                  ), 
 
                  // ------------------------------------------------ 
                  // 새 여행 만들기 
                  // ------------------------------------------------ 
 
                  if (savedPlan != null && 
                      savedPlan! 
                              .totalSpotCount > 
                          0) 
                    Padding( 
                      padding: 
                          const EdgeInsets 
                              .symmetric( 
                        horizontal: 20, 
                      ), 
                      child: 
                          OutlinedButton.icon( 
                        onPressed: 
                            _startPersonalityTest, 
                        icon: const Icon( 
                          Icons.add, 
                        ), 
                        label: const Text( 
                          '새 여행 만들기', 
                        ), 
                        style: OutlinedButton 
                            .styleFrom( 
                          padding: 
                              const EdgeInsets 
                                  .symmetric( 
                            vertical: 14, 
                          ), 
                          shape: 
                              RoundedRectangleBorder( 
                            borderRadius: 
                                BorderRadius 
                                    .circular( 
                              14, 
                            ), 
                          ), 
                        ), 
                      ), 
                    ), 
                ], 
              ), 
            ), 
    ); 
  } 
} 
 
// ============================================================ 
// 여행 정보 
// ============================================================ 
 
class _TripInfo extends StatelessWidget { 
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
        ), 
        const SizedBox(width: 5), 
        Text( 
          text, 
          style: 
              const TextStyle( 
            fontSize: 13, 
            fontWeight: 
                FontWeight.w500, 
          ), 
        ), 
      ], 
    ); 
  } 
} 