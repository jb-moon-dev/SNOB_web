import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_plan.dart';

class SavedPlaceStorage {
  static const String _key =
      'saved_places';

  static Future<List<TravelSpot>>
      loadPlaces() async {
    final prefs =
        await SharedPreferences.getInstance();

    final source =
        prefs.getString(_key);

    if (source == null || source.isEmpty) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(source);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (e) => TravelSpot.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePlace(
    TravelSpot spot,
  ) async {
    final places = await loadPlaces();

    final alreadyExists =
        places.any(
      (item) {
        if (spot.kakaoPlaceId != null &&
            item.kakaoPlaceId != null) {
          return spot.kakaoPlaceId ==
              item.kakaoPlaceId;
        }

        return item.name == spot.name;
      },
    );

    if (alreadyExists) {
      return;
    }

    places.insert(0, spot);

    await _save(places);
  }

  static Future<void> removePlace(
    TravelSpot spot,
  ) async {
    final places = await loadPlaces();

    places.removeWhere(
      (item) {
        if (spot.kakaoPlaceId != null &&
            item.kakaoPlaceId != null) {
          return spot.kakaoPlaceId ==
              item.kakaoPlaceId;
        }

        return item.name == spot.name;
      },
    );

    await _save(places);
  }

  static Future<bool> isSaved(
    TravelSpot spot,
  ) async {
    final places = await loadPlaces();

    return places.any(
      (item) {
        if (spot.kakaoPlaceId != null &&
            item.kakaoPlaceId != null) {
          return spot.kakaoPlaceId ==
              item.kakaoPlaceId;
        }

        return item.name == spot.name;
      },
    );
  }

  static Future<void> clear() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }

  static Future<void> _save(
    List<TravelSpot> places,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        places.map(
          (e) => e.toJson(),
        ).toList(),
      ),
    );
  }
}