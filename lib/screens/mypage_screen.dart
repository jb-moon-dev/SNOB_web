import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'onboarding_screen.dart';
import 'itinerary_screen.dart';

import '../services/kakao_auth_service.dart';
import '../services/travel_plan_storage.dart';
import '../services/personality_storage.dart';

import '../models/travel_plan.dart';
import '../screens/trip/personality_test/personality_test_screen.dart';
import '../screens/trip/saved_places_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/record_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? user;

  TravelPlan? savedPlan;

  String? personalityType;
  String? recommendedRegion;

  bool isLoading = true;

  static const Color _snobGreen = Color(0xFF5F8F72);
  static const Color _snobDarkGreen = Color(0xFF3F664F);
  static const Color _cream = Color(0xFFF7F5EC);
  static const Color _lightGreen = Color(0xFFEAF2EC);

  final List<String> _snobMessages = [
    '오늘은 조금 천천히 걸어볼까요? 🌿',
    '유명한 곳보다, 나에게 좋은 곳.',
    '당신만의 여행을 찾아보세요 🧳',
    '사람이 적은 곳에 특별한 풍경이 있을지도 몰라요.',
    '오늘의 여행도 SNOB답게 ✨',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // 전체 데이터
  // ============================================================

  Future<void> _loadData() async {
    await Future.wait([
      _loadUser(),
      _loadTravelPlan(),
      _loadPersonality(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // 사용자
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final isLoggedIn = await KakaoAuthService.checkToken();

      if (!isLoggedIn) {
        user = null;
        return;
      }

      user = await UserApi.instance.me();
    } catch (e) {
      debugPrint('카카오 사용자 정보 조회 실패: $e');
    }
  }

  // ============================================================
  // 여행 일정
  // ============================================================

  Future<void> _loadTravelPlan() async {
    try {
      savedPlan = await TravelPlanStorage.loadTravelPlan();
    } catch (e) {
      debugPrint('여행 일정 조회 실패: $e');
    }
  }

  // ============================================================
  // 여행 성향
  // ============================================================

  Future<void> _loadPersonality() async {
    try {
      final personality =
          await PersonalityStorage.loadPersonality();

      if (personality == null) {
        personalityType = null;
        recommendedRegion = null;
        return;
      }

      personalityType = personality['personalityType'];
      recommendedRegion = personality['recommendedRegion'];
    } catch (e) {
      debugPrint('여행 성향 조회 실패: $e');
    }
  }

  // ============================================================
  // 로그아웃
  // ============================================================

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '로그아웃할까요?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '다음에 다시 만나길 바라요 🧳',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      await KakaoAuthService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('로그아웃 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '로그아웃 중 문제가 발생했습니다.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 성향 테스트
  // ============================================================

  Future<void> _startPersonalityTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PersonalityTestScreen(),
      ),
    );

    await _loadPersonality();

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // 현재 여행
  // ============================================================

  Future<void> _openCurrentTrip() async {
    if (savedPlan == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItineraryScreen(
          travelPlan: savedPlan!,
        ),
      ),
    );

    await _loadTravelPlan();

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // 여행 기록
  // ============================================================

  Future<void> _openTravelRecords() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecordScreen(),
      ),
    );
  }

  // ============================================================
  // 성향 상세
  // ============================================================

  void _showPersonalityInfo() {
    if (personalityType == null) {
      _startPersonalityTest();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),

                const SizedBox(height: 24),

                const Text(
                  '나의 여행 성향',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '나의 여행 유형',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        personalityType!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: _snobDarkGreen,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 18),

                      const Text(
                        '추천 여행 지역',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        recommendedRegion ?? '추천 지역 없음',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startPersonalityTest();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _snobGreen,
                      side: const BorderSide(
                        color: _snobGreen,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '여행 성향 다시 알아보기',
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
  // 계정 정보
  // ============================================================

  void _showAccountInfo() {
    final nickname =
        user?.kakaoAccount?.profile?.nickname ?? '여행자';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),

                const SizedBox(height: 24),

                const Text(
                  '계정 정보',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildInfoRow(
                  icon: Icons.person_outline,
                  title: '닉네임',
                  value: nickname,
                ),

                const SizedBox(height: 18),

                _buildInfoRow(
                  icon: Icons.login_rounded,
                  title: '로그인',
                  value: '카카오',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 회원 탈퇴
  // ============================================================

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '정말 탈퇴할까요?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '카카오 계정과 SNOB의 연결이 해제됩니다.\n'
            '저장된 여행 정보도 삭제할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '탈퇴하기',
                style: TextStyle(
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await UserApi.instance.unlink();

      await TravelPlanStorage.deleteTravelPlan();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('회원 탈퇴 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '회원 탈퇴 중 문제가 발생했습니다.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text(
          '마이',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;
                  final contentWidth =
                      constraints.maxWidth > 1180
                          ? 1100.0
                          : constraints.maxWidth;

                  return SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 28,
                      12,
                      isMobile ? 16 : 28,
                      50,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildProfileCard(),

                            const SizedBox(height: 28),

                            _buildSectionTitle(
                              '나의 여행',
                            ),

                            const SizedBox(height: 12),

                            _buildTravelCards(
                              isMobile: isMobile,
                            ),

                            const SizedBox(height: 28),

                            _buildSectionTitle(
                              '나의 여행 성향',
                            ),

                            const SizedBox(height: 12),

                            _buildPersonalityCard(),

                            const SizedBox(height: 28),

                            _buildSnobMessage(),

                            const SizedBox(height: 28),

                            _buildSectionTitle(
                              '설정',
                            ),

                            const SizedBox(height: 12),

                            _buildSettingsCard(),

                            const SizedBox(height: 24),

                            _buildAccountActions(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ============================================================
  // Section
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _snobDarkGreen,
      ),
    );
  }

  // ============================================================
  // 프로필 카드
  // ============================================================

  Widget _buildProfileCard() {
    final nickname =
        user?.kakaoAccount?.profile?.nickname ?? '여행자';

    final profileImage =
        user?.kakaoAccount?.profile?.profileImageUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lightGreen,
            _cream,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 39,
              backgroundColor: Colors.white,
              backgroundImage: profileImage != null
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      size: 38,
                      color: _snobGreen,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$nickname님',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: _snobDarkGreen,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  '오늘도 나만의 여행을 찾아볼까요? 🧳',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 14),

                InkWell(
                  onTap: _showAccountInfo,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 15,
                          color: _snobGreen,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '계정 정보',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _snobDarkGreen,
                          ),
                        ),
                      ],
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
  // 여행 카드
  // ============================================================

  Widget _buildTravelCards({
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        children: [
          _buildCurrentTripCard(),
          const SizedBox(height: 12),
          _buildSavedPlacesCard(),
          const SizedBox(height: 12),
          _buildRecordCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCurrentTripCard(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSavedPlacesCard(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildRecordCard(),
        ),
      ],
    );
  }

  // ============================================================
  // 현재 여행
  // ============================================================

  Widget _buildCurrentTripCard() {
    final hasTrip = savedPlan != null;

    return _buildFeatureCard(
      icon: Icons.luggage_outlined,
      iconBackground: _lightGreen,
      iconColor: _snobGreen,
      title: '현재 진행 중인 여행',
      titleColor: _snobDarkGreen,
      description: hasTrip
          ? '${savedPlan!.regionName} · '
              '${savedPlan!.days.length}일 · '
              '${savedPlan!.totalSpotCount}곳'
          : '진행 중인 여행이 없어요.',
      buttonText: hasTrip ? '여행 일정 보기' : '여행 시작하기',
      onTap: hasTrip
          ? _openCurrentTrip
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '진행 중인 여행이 없어요.',
                  ),
                ),
              );
            },
    );
  }

  // ============================================================
  // 저장한 장소
  // ============================================================

  Widget _buildSavedPlacesCard() {
    return _buildFeatureCard(
      icon: Icons.favorite_border_rounded,
      iconBackground: _cream,
      iconColor: _snobGreen,
      title: '저장한 여행',
      titleColor: _snobDarkGreen,
      description: '마음에 담아둔 여행지를 다시 만나보세요.',
      buttonText: '저장한 장소 보기',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SavedPlacesScreen(),
          ),
        );
      },
    );
  }

  // ============================================================
  // 여행 기록
  // ============================================================

  Widget _buildRecordCard() {
    return _buildFeatureCard(
      icon: Icons.photo_library_outlined,
      iconBackground: _lightGreen,
      iconColor: _snobGreen,
      title: '여행 기록',
      titleColor: _snobDarkGreen,
      description: '다녀온 여행과 소중한 순간을 확인해보세요.',
      buttonText: '여행 기록 보기',
      onTap: _openTravelRecords,
    );
  }

  // ============================================================
  // 공통 기능 카드
  // ============================================================

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 205,
          ),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _snobGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _snobGreen,
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
  // 여행 성향 카드
  // ============================================================

  Widget _buildPersonalityCard() {
    final hasPersonality = personalityType != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _showPersonalityInfo,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: _snobGreen,
                  size: 29,
                ),
              ),

              const SizedBox(width: 17),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPersonality
                          ? personalityType!
                          : '아직 여행 성향을 알아보지 않았어요',
                      style: TextStyle(
                        fontSize: hasPersonality ? 18 : 15,
                        fontWeight: FontWeight.bold,
                        color: hasPersonality
                            ? _snobDarkGreen
                            : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      hasPersonality
                          ? recommendedRegion != null
                              ? '추천 지역 · $recommendedRegion'
                              : '나의 여행 성향을 확인해보세요.'
                          : '나에게 맞는 여행 스타일을 찾아보세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 오늘의 SNOB
  // ============================================================

  Widget _buildSnobMessage() {
    final message =
        _snobMessages[
          DateTime.now().day % _snobMessages.length
        ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                '🌿',
                style: TextStyle(
                  fontSize: 23,
                ),
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
                  '오늘의 SNOB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _snobGreen,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
  // 설정
  // ============================================================

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.notifications_none_rounded,
            title: '알림 설정',
            subtitle: 'SNOB 알림을 관리해요',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationSettingsScreen(),
                ),
              );
            },
          ),

          _buildSettingsDivider(),

          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: '개인정보처리방침',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          _buildSettingsDivider(),

          _buildSettingsItem(
            icon: Icons.logout_rounded,
            title: '로그아웃',
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: _snobGreen,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              size: 21,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: Colors.grey.shade100,
      indent: 74,
    );
  }

  // ============================================================
  // 계정 액션
  // ============================================================

  Widget _buildAccountActions() {
    return Center(
      child: TextButton.icon(
        onPressed: _showDeleteAccountDialog,
        icon: Icon(
          Icons.person_off_outlined,
          size: 17,
          color: Colors.red.shade300,
        ),
        label: Text(
          '회원 탈퇴',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.shade400,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Bottom Sheet handle
  // ============================================================

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // Account row
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}