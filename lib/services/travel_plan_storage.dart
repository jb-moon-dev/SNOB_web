import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_plan.dart';

class TravelPlanStorage {
  static const String _key = 'current_travel_plan';

  // ============================================================
  // 현재 여행 저장
  // ============================================================

  static Future<void> saveTravelPlan(
    TravelPlan plan,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      plan.toJsonString(),
    );
  }

  // ============================================================
  // 현재 여행 불러오기
  // ============================================================

  static Future<TravelPlan?> loadTravelPlan() async {
    final prefs = await SharedPreferences.getInstance();

    final source = prefs.getString(_key);

    if (source == null || source.isEmpty) {
      return null;
    }

    try {
      return TravelPlan.fromJsonString(source);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // 현재 여행 삭제
  // ============================================================

  static Future<void> deleteTravelPlan() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}