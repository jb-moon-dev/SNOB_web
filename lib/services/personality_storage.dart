import 'package:shared_preferences/shared_preferences.dart';

class PersonalityStorage {
  static const String _personalityTypeKey =
      'current_personality_type';

  static const String _recommendedRegionKey =
      'current_recommended_region';

  // ============================================================
  // 여행 성향 저장
  // ============================================================

  static Future<void> savePersonality({
    required String personalityType,
    required String recommendedRegion,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _personalityTypeKey,
      personalityType,
    );

    await prefs.setString(
      _recommendedRegionKey,
      recommendedRegion,
    );
  }

  // ============================================================
  // 저장된 여행 성향 불러오기
  // ============================================================

  static Future<Map<String, String>?> loadPersonality() async {
    final prefs =
        await SharedPreferences.getInstance();

    final personalityType =
        prefs.getString(_personalityTypeKey);

    final recommendedRegion =
        prefs.getString(_recommendedRegionKey);

    if (personalityType == null ||
        personalityType.isEmpty) {
      return null;
    }

    return {
      'personalityType': personalityType,
      'recommendedRegion':
          recommendedRegion ?? '',
    };
  }

  // ============================================================
  // 여행 성향 삭제
  // ============================================================

  static Future<void> deletePersonality() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_personalityTypeKey);
    await prefs.remove(_recommendedRegionKey);
  }
}