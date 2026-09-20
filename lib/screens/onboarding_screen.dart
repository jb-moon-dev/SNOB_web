import 'package:flutter/material.dart';

import '../services/kakao_auth_service.dart';
import '../widgets/bottom_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isLoading = false;

  final PageController _pageController =
      PageController();

  int currentPage = 0;

  final int totalPages = 5;

  static const Color snobGreen =
      Color(0xFF21624B);

  static const Color snobDarkGreen =
      Color(0xFF164B39);

  static const Color snobLightGreen =
      Color(0xFFE8F2EC);

  static const Color pageBackground =
      Color(0xFFF7F8F4);

  static const Color primaryText =
      Color(0xFF183A2E);

  static const Color secondaryText =
      Color(0xFF5F6F68);

  static const Color mutedText =
      Color(0xFF8A9691);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // 카카오 로그인
  // 기존 로그인 로직 그대로 유지
  // ============================================================

  Future<void> kakaoLogin() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print("카카오 버튼 클릭");

    final user =
        await KakaoAuthService.login(context);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (user != null) {
      print(
        "카카오 로그인 성공 (사용자 ID: ${user.id})",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const BottomNavigation(),
        ),
      );
    } else {
      print("카카오 로그인 실패");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "카카오 로그인에 실패했습니다.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // 다음 페이지
  // ============================================================

  void nextPage() {
    if (currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration:
            const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ============================================================
  // 건너뛰기
  // ============================================================

  void skipOnboarding() {
    _pageController.animateToPage(
      totalPages - 1,
      duration:
          const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final double screenWidth =
                constraints.maxWidth;

            final double screenHeight =
                constraints.maxHeight;

            final bool isMobile =
                screenWidth < 600;

            final bool isTablet =
                screenWidth >= 600 &&
                screenWidth < 1000;

            final bool isDesktop =
                screenWidth >= 1000;

            return Column(
              children: [
                // ==================================================
                // 상단 영역
                // ==================================================

                _buildTopBar(
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),

                // ==================================================
                // 페이지
                // ==================================================

                Expanded(
                  child: PageView(
                    controller:
                        _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    children: [
                      _buildSnobIntroPage(
                        screenHeight:
                            screenHeight,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      _buildSnobIndexPage(
                        screenHeight:
                            screenHeight,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      _buildPersonalityPage(
                        screenHeight:
                            screenHeight,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      _buildHowToUsePage(
                        screenHeight:
                            screenHeight,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                      _buildLoginPage(
                        screenHeight:
                            screenHeight,
                        isMobile: isMobile,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // 하단 영역
                // ==================================================

                if (currentPage <
                    totalPages - 1)
                  _buildBottomBar(
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // 상단 영역
  // ============================================================

  Widget _buildTopBar({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return SizedBox(
      height: isMobile ? 58 : 68,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1180,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isMobile ? 18 : 28,
            ),
            child: Row(
              children: [
                Text(
                  'SNOB',
                  style: TextStyle(
                    fontSize:
                        isMobile ? 21 : 24,
                    fontWeight:
                        FontWeight.w800,
                    color: snobGreen,
                    letterSpacing: -1.2,
                  ),
                ),
                const Spacer(),
                if (currentPage <
                    totalPages - 1)
                  TextButton(
                    onPressed:
                        skipOnboarding,
                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          secondaryText,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w500,
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
  // 하단 영역
  // ============================================================

  Widget _buildBottomBar({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (isMobile) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          18,
        ),
        child: Column(
          children: [
            _buildPageIndicator(),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: _buildNextButton(),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 1180,
      ),
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(
          isTablet ? 24 : 28,
          8,
          isTablet ? 24 : 28,
          isTablet ? 20 : 24,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildPageIndicator(),
            ),

            SizedBox(
              width: isTablet ? 18 : 24,
            ),

            SizedBox(
              width: isTablet ? 170 : 190,
              height: 48,
              child: _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 페이지 인디케이터
  // ============================================================

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: List.generate(
        totalPages - 1,
        (index) {
          final bool isSelected =
              currentPage == index;

          return AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
            margin:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            width:
                isSelected ? 24 : 7,
            height: 7,
            decoration:
                BoxDecoration(
              color: isSelected
                  ? snobGreen
                  : const Color(
                      0xFFD7DED9,
                    ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 다음 버튼
  // ============================================================

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: snobGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
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
      child: Text(
        currentPage == totalPages - 2
            ? 'SNOB 시작하기'
            : '다음',
        style: const TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // 공통 페이지 컨테이너
  //
  // PC:
  // - 화면 높이를 기준으로 콘텐츠를 축소
  // - 가능하면 한 화면에 모두 표시
  //
  // 모바일:
  // - 콘텐츠가 길어지면 세로 스크롤 허용
  // ============================================================

  Widget _buildPageContainer({
    required Widget child,
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double availableHeight =
        screenHeight -
            (isMobile ? 58 : 68) -
            (isMobile ? 125 : 80);

    double verticalPadding;

    if (isDesktop) {
      if (availableHeight < 650) {
        verticalPadding = 8;
      } else if (availableHeight < 760) {
        verticalPadding = 14;
      } else {
        verticalPadding = 24;
      }
    } else if (isTablet) {
      verticalPadding = 14;
    } else {
      verticalPadding = 20;
    }

    final Widget content =
        Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 760,
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal:
                isDesktop
                    ? 40
                    : isTablet
                        ? 30
                        : 20,
            vertical:
                verticalPadding,
          ),
          child: child,
        ),
      ),
    );

    // 모바일만 세로 스크롤을 허용한다.
    if (isMobile) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    // 태블릿/PC는 콘텐츠를 화면 높이에 맞춰 축소해서
    // 한 페이지 안에 표시한다. 스크롤은 발생하지 않는다.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  // ============================================================
  // 공통 상단 비주얼
  // ============================================================

  Widget _buildNatureVisual({
    required IconData icon,
    required String label,
    double height = 190,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFFEAF5EE),
            Color(0xFFD5EADF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        border: Border.all(
          color:
              const Color(0xFFD3E4D9),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 28,
            child: Icon(
              Icons
                  .wb_sunny_outlined,
              size: 34,
              color:
                  const Color(
                0xFF78A88B,
              ),
            ),
          ),

          Positioned(
            bottom: -20,
            left: -10,
            child: Icon(
              Icons
                  .landscape_outlined,
              size: 170,
              color:
                  const Color(
                0xFFB7D4C1,
              ),
            ),
          ),

          Positioned(
            bottom: -15,
            right: 30,
            child: Icon(
              Icons
                  .forest_outlined,
              size: 125,
              color:
                  const Color(
                0xFF8EB99D,
              ),
            ),
          ),

          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.9),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: snobGreen,
              ),
            ),
          ),

          Positioned(
            left: 28,
            bottom: 22,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.9),
                borderRadius:
                    BorderRadius.circular(
                  999,
                ),
              ),
              child: Text(
                label,
                style:
                    const TextStyle(
                  color: snobGreen,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1. SNOB 소개
  // ============================================================

  Widget _buildSnobIntroPage({
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double visualHeight =
        isDesktop
            ? screenHeight < 760
                ? 165
                : 200
            : isTablet
                ? 185
                : 220;

    return _buildPageContainer(
      screenHeight: screenHeight,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildNatureVisual(
            icon:
                Icons.travel_explore_outlined,
            label:
                '나만의 여행을 찾아보세요',
            height: visualHeight,
          ),

          SizedBox(
            height:
                isDesktop ? 28 : 34,
          ),

          Text(
            '모두의 여행에서,\n오직 나만의 여행으로',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize:
                  isDesktop
                      ? 32
                      : isTablet
                          ? 31
                          : 30,
              fontWeight:
                  FontWeight.w800,
              color: primaryText,
              letterSpacing: -1.2,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            '사람들이 몰리는 유명 관광지만이 아닌\n'
            '나에게 맞는 새로운 여행지를 찾아보세요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: secondaryText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. SNOB 지수
  // ============================================================

  Widget _buildSnobIndexPage({
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double visualHeight =
        isDesktop
            ? screenHeight < 760
                ? 125
                : 145
            : isTablet
                ? 150
                : 170;

    final double titleSize =
        isDesktop ? 28 : 30;

    final double cardVerticalPadding =
        isDesktop ? 12 : 16;

    return _buildPageContainer(
      screenHeight: screenHeight,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildNatureVisual(
            icon: Icons.eco_outlined,
            label:
                '덜 붐빌수록 높은 SNOB',
            height: visualHeight,
          ),

          SizedBox(
            height:
                isDesktop ? 16 : 26,
          ),

          Text(
            'SNOB 지수',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight:
                  FontWeight.w800,
              color: primaryText,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            '덜 붐비는 여행지일수록\n'
            '더 높은 SNOB 지수를 받아요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: secondaryText,
              height: 1.5,
            ),
          ),

          SizedBox(
            height:
                isDesktop ? 16 : 24,
          ),

          _buildIndexCard(
            title: 'SNOB 92',
            description:
                '여유롭게 여행하기 좋은 곳',
            icon:
                Icons.eco_outlined,
            isHigh: true,
            verticalPadding:
                cardVerticalPadding,
          ),

          const SizedBox(height: 8),

          _buildIndexCard(
            title: 'SNOB 76',
            description:
                '비교적 여유로운 관광지',
            icon:
                Icons.park_outlined,
            isHigh: false,
            verticalPadding:
                cardVerticalPadding,
          ),

          const SizedBox(height: 8),

          _buildIndexCard(
            title: 'SNOB 43',
            description:
                '많은 사람들이 방문하는 곳',
            icon:
                Icons.groups_outlined,
            isHigh: false,
            verticalPadding:
                cardVerticalPadding,
          ),

          SizedBox(
            height:
                isDesktop ? 12 : 18,
          ),

          const Text(
            '관광지 혼잡도 데이터를 바탕으로\n'
            '여행지의 여유로운 정도를 확인할 수 있어요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isHigh,
    required double verticalPadding,
  }) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(
        horizontal: 20,
        vertical: verticalPadding,
      ),
      decoration:
          BoxDecoration(
        color: isHigh
            ? snobLightGreen
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: isHigh
              ? const Color(
                  0xFFCDE2D4,
                )
              : const Color(
                  0xFFE3EAE5,
                ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: isHigh
                  ? Colors.white
                  : const Color(
                      0xFFF1F5F2,
                    ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: snobGreen,
              size: 23,
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
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),

          if (isHigh)
            const Icon(
              Icons
                  .check_circle_outline,
              color: snobGreen,
              size: 21,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. 심리테스트 / 여행 성향
  // ============================================================

  Widget _buildPersonalityPage({
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double visualHeight =
        isDesktop
            ? screenHeight < 760
                ? 120
                : 140
            : isTablet
                ? 145
                : 160;

    return _buildPageContainer(
      screenHeight: screenHeight,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildNatureVisual(
            icon:
                Icons.explore_outlined,
            label:
                '나만의 여행 성향',
            height: visualHeight,
          ),

          SizedBox(
            height:
                isDesktop ? 18 : 28,
          ),

          Text(
            '나의 여행 성향을 찾아보세요',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize:
                  isDesktop ? 27 : 30,
              fontWeight:
                  FontWeight.w800,
              color: primaryText,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '간단한 심리테스트를 통해\n'
            '나만의 여행 유형을 알아볼 수 있어요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
              height: 1.5,
            ),
          ),

          SizedBox(
            height:
                isDesktop ? 16 : 24,
          ),

          _buildAxisCard(
            icon:
                Icons.location_city_outlined,
            title: '도시 ↔ 자연',
            description:
                '도시의 활기찬 분위기부터\n자연 속의 여유까지',
            compact: isDesktop,
          ),

          const SizedBox(height: 8),

          _buildAxisCard(
            icon:
                Icons.explore_outlined,
            title: '유명 ↔ 숨은',
            description:
                '많이 알려진 명소부터\n나만 알고 싶은 장소까지',
            compact: isDesktop,
          ),

          const SizedBox(height: 8),

          _buildAxisCard(
            icon:
                Icons
                    .directions_walk_outlined,
            title: '활동 ↔ 힐링',
            description:
                '새로운 경험과 활동부터\n느긋한 휴식까지',
            compact: isDesktop,
          ),

          SizedBox(
            height:
                isDesktop ? 12 : 18,
          ),

          const Text(
            '3가지 여행 성향을 조합해\n'
            '27가지 여행 유형으로 나뉘어요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: primaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisCard({
    required IconData icon,
    required String title,
    required String description,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(
        horizontal: 17,
        vertical:
            compact ? 11 : 14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              const Color(0xFFE3EAE5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: snobLightGreen,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: snobGreen,
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
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                    height: 1.35,
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
  // 4. SNOB 사용 방법
  // ============================================================

  Widget _buildHowToUsePage({
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double visualHeight =
        isDesktop
            ? screenHeight < 760
                ? 115
                : 135
            : isTablet
                ? 145
                : 160;

    return _buildPageContainer(
      screenHeight: screenHeight,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildNatureVisual(
            icon:
                Icons.route_outlined,
            label:
                '나만의 여행을 만들어보세요',
            height: visualHeight,
          ),

          SizedBox(
            height:
                isDesktop ? 16 : 28,
          ),

          Text(
            'SNOB은 이렇게 사용해요',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize:
                  isDesktop ? 27 : 30,
              fontWeight:
                  FontWeight.w800,
              color: primaryText,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '나에게 맞는 여행지를 발견하고\n'
            '여유로운 여행을 시작해보세요.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
              height: 1.5,
            ),
          ),

          SizedBox(
            height:
                isDesktop ? 18 : 26,
          ),

          _buildStep(
            number: '01',
            title: '여행 성향 테스트',
            description:
                '간단한 질문으로 나의 여행 성향을 알아봐요.',
            compact: isDesktop,
          ),

          _buildStep(
            number: '02',
            title: '여행 유형 확인',
            description:
                '27가지 유형 중 나에게 맞는 유형을 찾아요.',
            compact: isDesktop,
          ),

          _buildStep(
            number: '03',
            title: '여행지 추천',
            description:
                '나의 성향과 SNOB 지수를 고려해 여행지를 추천받아요.',
            compact: isDesktop,
          ),

          _buildStep(
            number: '04',
            title: '나만의 여행 기록',
            description:
                '다녀온 여행을 기록하고 나만의 여행을 만들어가요.',
            compact: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required bool compact,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(
          horizontal: 16,
          vertical:
              compact ? 9 : 12,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
                const Color(0xFFE3EAE5),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(
                color: snobGreen,
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
              child: Center(
                child: Text(
                  number,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
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
                    title,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color: primaryText,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    description,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 5. 로그인 화면
  // ============================================================

  Widget _buildLoginPage({
    required double screenHeight,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final double cardHorizontalPadding =
        isDesktop
            ? 48
            : isTablet
                ? 38
                : 24;

    final double cardVerticalPadding =
        isDesktop
            ? 34
            : isTablet
                ? 30
                : 26;

    final double visualHeight =
        isDesktop
            ? screenHeight < 760
                ? 150
                : 175
            : isTablet
                ? 170
                : 155;

    final Widget content = Center(
        child: Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal:
                isMobile
                    ? 16
                    : isTablet
                        ? 30
                        : 40,
            vertical:
                isDesktop
                    ? 18
                    : 20,
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: Container(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    cardHorizontalPadding,
                vertical:
                    cardVerticalPadding,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFE1E9E3,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 30,
                    offset:
                        const Offset(
                      0,
                      12,
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // ==================================================
                  // SNOB 로고
                  // ==================================================

                  Text(
                    'SNOB',
                    style: TextStyle(
                      fontSize:
                          isDesktop
                              ? 30
                              : 29,
                      fontWeight:
                          FontWeight.w900,
                      color: snobGreen,
                      letterSpacing: -1.8,
                    ),
                  ),

                  SizedBox(
                    height:
                        isDesktop ? 16 : 20,
                  ),

                  // ==================================================
                  // 자연 / 여행 이미지 영역
                  // ==================================================

                  Container(
                    width: double.infinity,
                    height: visualHeight,
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        begin:
                            Alignment.topLeft,
                        end:
                            Alignment
                                .bottomRight,
                        colors: [
                          Color(
                            0xFFEAF5EE,
                          ),
                          Color(
                            0xFFCFE5D7,
                          ),
                        ],
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        22,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 18,
                          right: 22,
                          child: Icon(
                            Icons
                                .wb_sunny_outlined,
                            size: 30,
                            color:
                                const Color(
                              0xFF79A88B,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: -25,
                          left: -5,
                          child: Icon(
                            Icons
                                .landscape_outlined,
                            size: 150,
                            color:
                                const Color(
                              0xFFAFCDBA,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: -12,
                          right: 25,
                          child: Icon(
                            Icons
                                .forest_outlined,
                            size: 105,
                            color:
                                const Color(
                              0xFF7FAE91,
                            ),
                          ),
                        ),

                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withOpacity(
                                0.92,
                              ),
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .travel_explore_outlined,
                              size: 36,
                              color:
                                  snobGreen,
                            ),
                          ),
                        ),

                        Positioned(
                          left: 18,
                          bottom: 16,
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withOpacity(
                                0.9,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                999,
                              ),
                            ),
                            child:
                                const Text(
                              '나만의 여행을 찾아보세요',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    snobGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height:
                        isDesktop ? 22 : 26,
                  ),

                  // ==================================================
                  // 소개 문구
                  // ==================================================

                  Text(
                    '모두의 여행에서,\n'
                    '오직 나만의 여행으로',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          isDesktop
                              ? 27
                              : 28,
                      fontWeight:
                          FontWeight.w800,
                      color: primaryText,
                      letterSpacing: -1.1,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    '나의 여행 성향에 맞는 여행지를 발견하고\n'
                    'SNOB과 함께 특별한 여행을 시작해보세요.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          secondaryText,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(
                    height:
                        isDesktop ? 22 : 26,
                  ),

                  // ==================================================
                  // 카카오 로그인
                  // 기존 kakaoLogin() 그대로 호출
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : kakaoLogin,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFFEE500,
                        ),
                        foregroundColor:
                            const Color(
                          0xFF191919,
                        ),
                        disabledBackgroundColor:
                            const Color(
                          0xFFF2E9A0,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Color(
                                  0xFF191919,
                                ),
                              ),
                            )
                          : const Text(
                              '카카오로 시작하기',
                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // Apple 로그인
                  // 기존 동작 유지
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        print(
                          "Apple 로그인 준비",
                        );

                        Navigator
                            .pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BottomNavigation(),
                          ),
                        );
                      },
                      style:
                          OutlinedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            primaryText,
                        elevation: 0,
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFFD7E0DA,
                          ),
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
                      child:
                          const Text(
                        'Apple로 시작하기',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    '로그인하면 나에게 맞는 여행을 시작할 수 있어요.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );

    if (isMobile) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}