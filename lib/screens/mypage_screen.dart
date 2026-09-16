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
      final isLoggedIn =
          await KakaoAuthService.checkToken();

      if (!isLoggedIn) {
        user = null;
        return;
      }

      user = await UserApi.instance.me();
    } catch (e) {
      debugPrint(
        '카카오 사용자 정보 조회 실패: $e',
      );
    }
  }

  // ============================================================
  // 여행 일정
  // ============================================================

  Future<void> _loadTravelPlan() async {
    try {
      savedPlan =
          await TravelPlanStorage.loadTravelPlan();
    } catch (e) {
      debugPrint(
        '여행 일정 조회 실패: $e',
      );
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

      personalityType =
          personality['personalityType'];

      recommendedRegion =
          personality['recommendedRegion'];
    } catch (e) {
      debugPrint(
        '여행 성향 조회 실패: $e',
      );
    }
  }

  // ============================================================
  // 로그아웃
  // ============================================================

  Future<void> _showLogoutDialog() async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
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
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
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
          builder: (_) =>
              const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        '로그아웃 실패: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        builder: (_) =>
            const PersonalityTestScreen(),
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
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHandle(),

                const SizedBox(height: 24),

                const Text(
                  '나의 여행 성향',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
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
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 25,
                          fontWeight:
                              FontWeight.bold,
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
                        recommendedRegion ??
                            '추천 지역 없음',
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
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
                    style:
                        OutlinedButton.styleFrom(
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
        user?.kakaoAccount?.profile
                ?.nickname ??
            '여행자';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              12,
              24,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHandle(),

                const SizedBox(height: 24),

                const Text(
                  '계정 정보',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildInfoRow(
                  icon:
                      Icons.person_outline,
                  title: '닉네임',
                  value: nickname,
                ),

                const SizedBox(height: 18),

                _buildInfoRow(
                  icon:
                      Icons.login_rounded,
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

  Future<void>
      _showDeleteAccountDialog() async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            '정말 탈퇴할까요?',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            '카카오 계정과 SNOB의 연결이 해제됩니다.\n'
            '저장된 여행 정보도 삭제할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('취소'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                '탈퇴하기',
                style: TextStyle(
                  color: Colors.red,
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

      await TravelPlanStorage
          .deleteTravelPlan();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        '회원 탈퇴 실패: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
      // 배경색은 main.dart의 scaffoldBackgroundColor 사용

      appBar: AppBar(
        // AppBar 색상과 elevation은 main.dart의 appBarTheme 사용

        titleSpacing: 20,

        title: const Text(
          '마이',
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  40,
                ),
                children: [
                  _buildProfile(),

                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    '내 정보',
                  ),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    icon:
                        Icons.person_outline,
                    title: '계정 정보',
                    onTap:
                        _showAccountInfo,
                  ),

                  _buildDivider(),

                  _buildMenuItem(
                    icon:
                        Icons.luggage_outlined,
                    title:
                        '현재 진행 중인 여행',
                    subtitle:
                        _currentTripSubtitle(),
                    onTap: savedPlan != null
                        ? _openCurrentTrip
                        : () {
                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '진행 중인 여행이 없어요.',
                                ),
                              ),
                            );
                          },
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    '나의 여행',
                  ),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    icon:
                        Icons.psychology_outlined,
                    title:
                        '나의 여행 성향',
                    subtitle:
                        _personalitySubtitle(),
                    onTap:
                        _showPersonalityInfo,
                  ),

                  _buildDivider(),

                  _buildMenuItem(
                    icon: Icons
                        .favorite_border_rounded,
                    title: '저장한 장소',
                    subtitle:
                        '마음에 담아둔 여행지',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SavedPlacesScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  _buildSnobMessage(),

                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    '설정',
                  ),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    icon: Icons
                        .notifications_none_rounded,
                    title: '알림 설정',
                    subtitle:
                        'SNOB 알림을 관리해요',
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

                  _buildDivider(),

                  _buildMenuItem(
                    icon: Icons
                        .description_outlined,
                    title:
                        '개인정보처리방침',
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

                  _buildDivider(),

                  _buildMenuItem(
                    icon:
                        Icons.logout_rounded,
                    title: '로그아웃',
                    onTap:
                        _showLogoutDialog,
                  ),

                  _buildDivider(),

                  _buildMenuItem(
                    icon:
                        Icons.person_off_outlined,
                    title: '회원 탈퇴',
                    titleColor:
                        Colors.red.shade400,
                    iconColor:
                        Colors.red.shade300,
                    onTap:
                        _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // 현재 여행
  // ============================================================

  String _currentTripSubtitle() {
    if (savedPlan == null) {
      return '진행 중인 여행이 없어요';
    }

    return '${savedPlan!.regionName} 여행 · '
        '${savedPlan!.days.length}일 · '
        '${savedPlan!.totalSpotCount}곳';
  }

  // ============================================================
  // 성향
  // ============================================================

  String _personalitySubtitle() {
    if (personalityType == null) {
      return '아직 여행 성향을 알아보지 않았어요';
    }

    if (recommendedRegion == null) {
      return personalityType!;
    }

    return '$personalityType · 추천 지역 $recommendedRegion';
  }

  // ============================================================
  // 프로필
  // ============================================================

  Widget _buildProfile() {
    final nickname =
        user?.kakaoAccount?.profile
                ?.nickname ??
            '여행자';

    final profileImage =
        user?.kakaoAccount?.profile
            ?.profileImageUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor:
              Colors.grey.shade100,
          backgroundImage:
              profileImage != null
                  ? NetworkImage(
                      profileImage,
                    )
                  : null,
          child: profileImage == null
              ? Icon(
                  Icons
                      .person_outline_rounded,
                  size: 30,
                  color:
                      Colors.grey.shade400,
                )
              : null,
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '$nickname님',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '오늘도 나만의 여행을 찾아볼까요? 🧳',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  // ============================================================
  // Menu
  // ============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 2,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: iconColor ??
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          titleColor ??
                              Colors.black87,
                    ),
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons
                  .chevron_right_rounded,
              size: 21,
              color:
                  Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Divider
  // ============================================================

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: Colors.grey.shade100,
      indent: 53,
    );
  }

  // ============================================================
  // SNOB
  // ============================================================

  Widget _buildSnobMessage() {
    final message =
        _snobMessages[
          DateTime.now().day %
              _snobMessages.length
        ];

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration:
          BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Center(
              child: Text(
                '🌿',
                style:
                    TextStyle(
                  fontSize: 21,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  '오늘의 SNOB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
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
  // Bottom Sheet handle
  // ============================================================

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade300,
          borderRadius:
              BorderRadius.circular(
            10,
          ),
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
          color:
              Colors.grey.shade600,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
