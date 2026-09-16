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

  final List<Widget> _pages = [
    const HomeScreen(),
    const RecordScreen(),
    const MapScreen(),
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type:
            BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '기록',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}