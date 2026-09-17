import 'package:flutter/material.dart';
import '../services/kakao_auth_service.dart';
import '../widgets/bottom_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isLoading = false;
  final PageController _pageController = PageController();

  int currentPage = 0;

  // 총 온보딩 페이지 수
  final int totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ================================
  // 카카오 로그인
  // ================================

  Future<void> kakaoLogin() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print("카카오 버튼 클릭");

    final user = await KakaoAuthService.login(context);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (user != null) {
      print("카카오 로그인 성공 (사용자 ID: ${user.id})");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNavigation(),
        ),
      );
    } else {
      print("카카오 로그인 실패");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("카카오 로그인에 실패했습니다."),
        ),
      );
    }
  }

  // ================================
  // 다음 페이지
  // ================================

  void nextPage() {
    if (currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ================================
  // 건너뛰기
  // ================================

  void skipOnboarding() {
    _pageController.animateToPage(
      totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ================================
            // 건너뛰기 버튼
            // ================================

            SizedBox(
              height: 50,
              child: Align(
                alignment: Alignment.centerRight,
                child: currentPage < totalPages - 1
                    ? TextButton(
                        onPressed: skipOnboarding,
                        child: const Text(
                          "건너뛰기",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),

            // ================================
            // 페이지 영역
            // ================================

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: [
                  _buildSnobIntroPage(),
                  _buildSnobIndexPage(),
                  _buildPersonalityPage(),
                  _buildHowToUsePage(),
                  _buildLoginPage(),
                ],
              ),
            ),

            // ================================
            // 페이지 인디케이터
            // ================================

            if (currentPage < totalPages - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages - 1,
                    (index) {
                      final isSelected = currentPage == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ================================
            // 다음 버튼
            // ================================

            if (currentPage < totalPages - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentPage == totalPages - 2
                          ? "SNOB 시작하기"
                          : "다음",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  // ============================================================
  // 1. SNOB 소개
  // ============================================================

  Widget _buildSnobIntroPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로고 영역
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                "SNOB",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 45),

          const Text(
            "SNOB",
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "모두의 여행에서,\n오직 나만의 여행으로",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            "사람들이 몰리는 유명 관광지만이 아닌\n"
            "나에게 맞는 새로운 여행지를 찾아보세요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
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

  Widget _buildSnobIndexPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "SNOB 지수",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            "덜 붐비는 여행지일수록\n더 높은 SNOB 지수를 받아요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // 지수 예시
          _buildIndexCard(
            title: "SNOB 92",
            description: "여유롭게 여행하기 좋은 곳",
            icon: Icons.eco_outlined,
          ),

          const SizedBox(height: 14),

          _buildIndexCard(
            title: "SNOB 76",
            description: "비교적 여유로운 관광지",
            icon: Icons.park_outlined,
          ),

          const SizedBox(height: 14),

          _buildIndexCard(
            title: "SNOB 43",
            description: "많은 사람들이 방문하는 곳",
            icon: Icons.groups_outlined,
          ),

          const SizedBox(height: 25),

          Text(
            "관광지 혼잡도 데이터를 바탕으로\n"
            "여행지의 여유로운 정도를 확인할 수 있어요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.6,
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
  // 3. 심리테스트 / 여행 성향
  // ============================================================

  Widget _buildPersonalityPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "나의 여행 성향을 찾아보세요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "간단한 심리테스트를 통해\n"
            "나만의 여행 유형을 알아볼 수 있어요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 45),

          _buildAxisCard(
            icon: Icons.location_city_outlined,
            title: "도시 ↔ 자연",
            description: "도시의 활기찬 분위기부터\n자연 속의 여유까지",
          ),

          const SizedBox(height: 14),

          _buildAxisCard(
            icon: Icons.explore_outlined,
            title: "유명 ↔ 숨은",
            description: "많이 알려진 명소부터\n나만 알고 싶은 장소까지",
          ),

          const SizedBox(height: 14),

          _buildAxisCard(
            icon: Icons.directions_walk_outlined,
            title: "활동 ↔ 힐링",
            description: "새로운 경험과 활동부터\n느긋한 휴식까지",
          ),

          const SizedBox(height: 30),

          const Text(
            "3가지 여행 성향을 조합해\n27가지 여행 유형으로 나뉘어요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: Colors.black,
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
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

  Widget _buildHowToUsePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "SNOB은 이렇게 사용해요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            "나에게 맞는 여행지를 발견하고\n"
            "여유로운 여행을 시작해보세요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 45),

          _buildStep(
            number: "01",
            title: "여행 성향 테스트",
            description: "간단한 질문으로 나의 여행 성향을 알아봐요.",
          ),

          _buildStep(
            number: "02",
            title: "여행 유형 확인",
            description: "27가지 유형 중 나에게 맞는 유형을 찾아요.",
          ),

          _buildStep(
            number: "03",
            title: "여행지 추천",
            description: "나의 성향과 SNOB 지수를 고려해 여행지를 추천받아요.",
          ),

          _buildStep(
            number: "04",
            title: "나만의 여행 기록",
            description: "다녀온 여행을 기록하고 나만의 여행을 만들어가요.",
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
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
  // 5. 기존 로그인 화면
  // ============================================================

  Widget _buildLoginPage() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              const Text(
                "SNOB",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "모두의 여행에서,\n오직 나만의 여행으로",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 60),

              // ================================
              // 카카오 로그인
              // ================================

              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : kakaoLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("카카오로 시작하기"),
                ),
              ),

              const SizedBox(height: 15),

              // ================================
              // Apple 로그인
              // ================================

              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    print("Apple 로그인 준비");

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BottomNavigation(),
                      ),
                    );
                  },
                  child: const Text("Apple로 시작하기"),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}