import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/mypage_screen.dart';
import '../screens/record_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
  });

  @override
  State<BottomNavigation> createState() =>
      _BottomNavigationState();
}

class _BottomNavigationState
    extends State<BottomNavigation> {
  int _selectedIndex = 0;

  final GlobalKey<RecordScreenState> _recordScreenKey =
      GlobalKey<RecordScreenState>();

  late final List<Widget> _pages = [
    const HomeScreen(),
    RecordScreen(key: _recordScreenKey),
    const MapScreen(),
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 기록 탭을 열 때마다 최신 기록을 다시 불러오기
    if (index == 1) {
      _recordScreenKey.currentState?.loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ==========================================================
        // PC / Web
        // ==========================================================

        if (constraints.maxWidth >= 900) {
          return Scaffold(
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor,
            body: Column(
              children: [
                _buildWebNavigation(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          );
        }

        // ==========================================================
        // Mobile / Small Tablet
        // 기존 하단 네비게이션 유지
        // ==========================================================

        return Scaffold(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor,
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar:
              BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: '기록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: '지도',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '마이',
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // Web Navigation
  // ================================================================

  Widget _buildWebNavigation() {
    return Container(
      height: 72,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE3EAE5),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1320,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Row(
              children: [
                // ==================================================
                // SNOB Logo
                // ==================================================

                _buildLogo(),

                const Spacer(),

                // ==================================================
                // Navigation
                // ==================================================

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWebNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      label: '홈',
                    ),
                    _buildWebNavItem(
                      index: 1,
                      icon: Icons.book_outlined,
                      label: '여행기록',
                    ),
                    _buildWebNavItem(
                      index: 2,
                      icon: Icons.map_outlined,
                      label: '지도',
                    ),
                    _buildWebNavItem(
                      index: 3,
                      icon: Icons.person_outline,
                      label: '마이페이지',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SNOB Logo
  // ================================================================

  Widget _buildLogo() {
    return GestureDetector(
      onTap: () {
        _onItemTapped(0);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          'SNOB',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF21624B),
            letterSpacing: -1.5,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // Web Navigation Item
  // ================================================================

  Widget _buildWebNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(
        left: 6,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _onItemTapped(index);
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF1F6F3),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isSelected
                        ? const Color(0xFF21624B)
                        : const Color(0xFF68756E),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF21624B)
                          : const Color(0xFF68756E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 2,
                    width: isSelected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF21624B),
                      borderRadius:
                          BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}