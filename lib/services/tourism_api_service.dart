import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snob/snob/tourism_spot.dart';

class TourismApiService {
  static const String serviceKey =
      "22cfa7aa1cefdd4fe98e0e9dad0415b994b125c08a2da84a8757d7ac5aa09af5";

  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";

  // ============================================================
  // API 응답 item 추출
  // ============================================================

  static List<dynamic> _extractItems(dynamic data) {
    if (data is! Map) {
      return [];
    }

    final response = data["response"];

    if (response is! Map) {
      return [];
    }

    final body = response["body"];

    if (body is! Map) {
      return [];
    }

    final items = body["items"];

    if (items is! Map) {
      return [];
    }

    final item = items["item"];

    if (item == null) {
      return [];
    }

    if (item is String) {
      return [];
    }

    if (item is Map) {
      return [item];
    }

    if (item is List) {
      return item;
    }

    return [];
  }

  // ============================================================
  // 시도 코드 + 이름 조회
  // ============================================================

  static Future<List<Map<String, String>>> getRegions() async {
    final List<Map<String, String>> regions = [];

    final Uri url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100"
      "&pageNo=1",
    );

    try {
      print("시도 코드 조회 중...");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "시도 코드 API 오류 : ${response.statusCode}",
        );
        return [];
      }

      final dynamic data = json.decode(response.body);

      final List<dynamic> items = _extractItems(data);

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final String code =
            item["code"]?.toString().trim() ?? "";

        final String name =
            item["name"]?.toString().trim() ?? "";

        if (code.isEmpty || name.isEmpty) {
          continue;
        }

        regions.add({
          "code": code,
          "name": name,
        });
      }
    } catch (e) {
      print("시도 코드 조회 실패 : $e");
    }

    return regions;
  }

  // ============================================================
  // 시군구 코드 + 이름 조회
  // ============================================================

  static Future<List<Map<String, String>>> getSigungus(
    String regionCode,
  ) async {
    final List<Map<String, String>> sigungus = [];

    final Uri url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100"
      "&pageNo=1"
      "&lDongRegnCd=$regionCode",
    );

    try {
      print(
        "  시군구 코드 조회 : $regionCode",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "  시군구 코드 API 오류 : "
          "${response.statusCode}",
        );
        return [];
      }

      final dynamic data = json.decode(response.body);

      final List<dynamic> items = _extractItems(data);

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final String code =
            item["code"]?.toString().trim() ?? "";

        final String name =
            item["name"]?.toString().trim() ?? "";

        if (code.isEmpty || name.isEmpty) {
          continue;
        }

        sigungus.add({
          "code": code,
          "name": name,
        });
      }
    } catch (e) {
      print(
        "  시군구 코드 조회 실패 : "
        "$regionCode / $e",
      );
    }

    return sigungus;
  }

  // ============================================================
  // 관광지 조회
  // ============================================================

  static Future<List<TourismSpot>> getTourismSpotsByLegalDong(
    String regionCode,
    String sigunguCode,
    String regionName,
  ) async {
    final List<TourismSpot> spots = [];

    int pageNo = 1;

    while (true) {
      final Uri url = Uri.parse(
        "$baseUrl/areaBasedList2"
        "?serviceKey=$serviceKey"
        "&MobileOS=AND"
        "&MobileApp=SNOB"
        "&_type=json"
        "&numOfRows=100"
        "&pageNo=$pageNo"
        "&contentTypeId=12"
        "&lDongRegnCd=$regionCode"
        "&lDongSignguCd=$sigunguCode",
      );

      try {
        print(
          "    관광지 조회 : "
          "$regionCode / $sigunguCode "
          "(page $pageNo)",
        );

        final response = await http.get(url);

        if (response.statusCode != 200) {
          print(
            "    API HTTP 오류 : "
            "${response.statusCode}",
          );
          break;
        }

        final dynamic data =
            json.decode(response.body);

        final List<dynamic> items =
            _extractItems(data);

        if (items.isEmpty) {
          break;
        }

        int addedCount = 0;

        for (final item in items) {
          if (item is! Map) {
            continue;
          }

          final String title =
              item["title"]?.toString() ?? "";

          if (title.trim().isEmpty) {
            continue;
          }

          // ======================================================
          // ⭐ 관광지 좌표
          //
          // API:
          // mapy = 위도(latitude)
          // mapx = 경도(longitude)
          // ======================================================

          final double? latitude =
              double.tryParse(
            item["mapy"]?.toString() ?? "",
          );

          final double? longitude =
              double.tryParse(
            item["mapx"]?.toString() ?? "",
          );

          final TourismSpot spot = TourismSpot(
            contentId:
                item["contentid"]?.toString() ?? "",

            title: title,

            address:
                item["addr1"]?.toString() ?? "",

            contentTypeId:
                item["contenttypeid"]?.toString() ?? "",

            lDongRegnCd:
                item["lDongRegnCd"]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? item["lDongRegnCd"].toString()
                    : regionCode,

            lDongSignguCd:
                item["lDongSignguCd"]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? item["lDongSignguCd"].toString()
                    : sigunguCode,

            // ⭐ API의 시군구 정보를 기준으로 결정한 정확한 지역명
            regionName: regionName,

            lclsSystm1:
                item["lclsSystm1"]?.toString() ?? "",

            lclsSystm2:
                item["lclsSystm2"]?.toString() ?? "",

            lclsSystm3:
                item["lclsSystm3"]?.toString() ?? "",

            modifiedTime:
                item["modifiedtime"]?.toString() ?? "",

            // ⭐ 좌표 추가
            latitude: latitude,
            longitude: longitude,
          );

          spots.add(spot);
          addedCount++;
        }

        print("      → $addedCount개");

        if (items.length < 100) {
          break;
        }

        pageNo++;
      } catch (e) {
        print(
          "    관광지 API 데이터 처리 실패 : $e",
        );
        break;
      }
    }

    print(
      "    관광지 합계 : ${spots.length}개",
    );

    return spots;
  }
    // ============================================================
  // 관광지 상세 이미지 조회
  // ============================================================
  //
  // contentId를 이용해서 detailImage2 API 호출
  //
  // 반환:
  // 이미지 URL 목록
  //
  // 가장 첫 번째 이미지를 대표 이미지로 사용할 수 있다.
  // ============================================================

  static Future<List<String>> getTourismImages(
    String contentId,
  ) async {
    if (contentId.trim().isEmpty) {
      print(
        "    이미지 조회 생략 : contentId 없음",
      );

      return [];
    }

    final Uri url = Uri.parse(
      "$baseUrl/detailImage2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&contentId=$contentId"
      "&imageYN=Y"
      "&numOfRows=10"
      "&pageNo=1",
    );

    try {
      print(
        "    관광지 이미지 조회 : "
        "$contentId",
      );

      final response =
          await http.get(url);

      if (response.statusCode != 200) {
        print(
          "    이미지 API HTTP 오류 : "
          "${response.statusCode}",
        );

        return [];
      }

      final dynamic data =
          json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      if (items.isEmpty) {
        print(
          "      → 이미지 없음",
        );

        return [];
      }

      final List<String> imageUrls = [];

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        // 원본 이미지 URL
        final String originUrl =
            item["originimgurl"]
                    ?.toString()
                    .trim() ??
                "";

        // 썸네일 이미지 URL
        final String smallUrl =
            item["smallimageurl"]
                    ?.toString()
                    .trim() ??
                "";

        // 원본 이미지 우선
        final String imageUrl =
            originUrl.isNotEmpty
                ? originUrl
                : smallUrl;

        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }

      print(
        "      → ${imageUrls.length}개",
      );

      return imageUrls;
    } catch (e) {
      print(
        "    관광지 이미지 조회 실패 : "
        "$contentId / $e",
      );

      return [];
    }
  }

  // ============================================================
  // 전국 관광지 조회
  // ============================================================

  static Future<List<TourismSpot>>
      getAllTourismSpots() async {
    final List<TourismSpot> allSpots = [];

    print("");
    print(
      "==================================================",
    );
    print(
      "SNOB 전국 관광지 데이터 수집 시작",
    );
    print(
      "==================================================",
    );

    // ----------------------------------------------------------
    // 1. 시도
    // ----------------------------------------------------------

    final List<Map<String, String>> regions =
        await getRegions();

    print("");
    print(
      "전체 시도 : ${regions.length}개",
    );

    if (regions.isEmpty) {
      print("❌ 시도 데이터를 가져오지 못했습니다.");
      return [];
    }

    // ----------------------------------------------------------
    // 2. 시도 → 시군구 → 관광지
    // ----------------------------------------------------------

    for (int i = 0; i < regions.length; i++) {
      final String regionCode =
          regions[i]["code"]!;

      final String sidoName =
          regions[i]["name"]!;

      print("");
      print(
        "[시도 ${i + 1}/${regions.length}] "
        "$regionCode / $sidoName",
      );

      final List<Map<String, String>> sigungus =
          await getSigungus(regionCode);

      print(
        "시군구 : ${sigungus.length}개",
      );

      if (sigungus.isEmpty) {
        print(
          "  ⚠️ 시군구 데이터가 없습니다.",
        );
        continue;
      }

      for (int j = 0; j < sigungus.length; j++) {
        final String sigunguCode =
            sigungus[j]["code"]!;

        final String sigunguName =
            sigungus[j]["name"]!;

        // ------------------------------------------------------
        // ⭐ 지역명 결정
        //
        // 시도 + 시군구
        //
        // 세종의 경우:
        // 36 + 110
        // → 36110
        // → 세종특별자치시
        // ------------------------------------------------------

        String fullRegionName;

        if (regionCode == "36" &&
            sigunguCode == "110") {
          fullRegionName = "세종특별자치시";
        } else {
          fullRegionName =
              "$sidoName $sigunguName";
        }

        print(
          "  [${j + 1}/${sigungus.length}] "
          "$fullRegionName",
        );

        final List<TourismSpot> spots =
            await getTourismSpotsByLegalDong(
          regionCode,
          sigunguCode,
          fullRegionName,
        );

        allSpots.addAll(spots);
      }
    }

    // ==========================================================
    // 3. contentId 기준 중복 제거
    // ==========================================================

    final Map<String, TourismSpot> uniqueSpots = {};

    for (final TourismSpot spot in allSpots) {
      if (spot.contentId.trim().isEmpty) {
        continue;
      }

      uniqueSpots[spot.contentId] = spot;
    }

    final List<TourismSpot> result =
        uniqueSpots.values.toList();

    print("");
    print(
      "==================================================",
    );
    print(
      "SNOB 전국 관광지 데이터 수집 완료",
    );
    print(
      "==================================================",
    );

    print(
      "API 관광지 : ${allSpots.length}개",
    );

    print(
      "중복 제거 후 : ${result.length}개",
    );

    // ⭐ 좌표가 있는 관광지 수 확인
    final int spotsWithCoordinates =
        result.where(
      (spot) =>
          spot.latitude != null &&
          spot.longitude != null,
    ).length;

    print(
      "좌표 보유 관광지 : "
      "$spotsWithCoordinates개",
    );

    print(
      "좌표 없는 관광지 : "
      "${result.length - spotsWithCoordinates}개",
    );

    return result;
  }
}