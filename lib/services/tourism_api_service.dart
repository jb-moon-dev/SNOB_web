import 'dart:convert';

import 'package:http/http.dart' as http;

import '../snob/tourism_spot.dart';

class TourismApiService {
  static const String serviceKey =
      "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9";

  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";

  // ============================================================
  // 공통 응답 데이터 추출
  // ============================================================

  static List<dynamic> _extractItems(
    dynamic data,
  ) {
    try {
      final dynamic items =
          data["response"]["body"]["items"]["item"];

      if (items == null) {
        return [];
      }

      if (items is List) {
        return items;
      }

      return [items];
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 지역 목록 조회
  // ============================================================

  static Future<List<Map<String, String>>> getRegions() async {
    final Uri url = Uri.parse(
      "$baseUrl/areaCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100"
      "&pageNo=1",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "지역 조회 HTTP 오류 : "
          "${response.statusCode}",
        );

        return [];
      }

      final dynamic data =
          json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      final List<Map<String, String>> regions = [];

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

      return regions;
    } catch (e) {
      print(
        "지역 조회 실패 : $e",
      );

      return [];
    }
  }

  // ============================================================
  // 시군구 목록 조회
  // ============================================================

  static Future<List<Map<String, String>>> getSigungus(
    String areaCode,
  ) async {
    if (areaCode.trim().isEmpty) {
      return [];
    }

    final Uri url = Uri.parse(
      "$baseUrl/areaCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&areaCode=$areaCode"
      "&numOfRows=100"
      "&pageNo=1",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "시군구 조회 HTTP 오류 : "
          "${response.statusCode}",
        );

        return [];
      }

      final dynamic data =
          json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      final List<Map<String, String>> sigungus = [];

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

      return sigungus;
    } catch (e) {
      print(
        "시군구 조회 실패 : $e",
      );

      return [];
    }
  }

  // ============================================================
  // 법정동 기준 관광지 조회
  // ============================================================

  static Future<List<TourismSpot>>
      getTourismSpotsByLegalDong(
    String areaCode,
    String sigunguCode, [
    String? regionName,
  ]) async {
    if (areaCode.trim().isEmpty ||
        sigunguCode.trim().isEmpty) {
      return [];
    }

    final Uri url = Uri.parse(
      "$baseUrl/areaBasedList2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&areaCode=$areaCode"
      "&sigunguCode=$sigunguCode"
      "&contentTypeId=12"
      "&numOfRows=100"
      "&pageNo=1",
    );

    try {
      final response =
          await http.get(url);

      if (response.statusCode != 200) {
        print(
          "관광지 조회 HTTP 오류 : "
          "${response.statusCode}",
        );

        return [];
      }

      final dynamic data =
          json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      final List<TourismSpot> spots = [];

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final String contentId =
            item["contentid"]
                    ?.toString()
                    .trim() ??
                "";

        if (contentId.isEmpty) {
          continue;
        }

        spots.add(
          TourismSpot(
            contentId: contentId,
            title:
                item["title"]
                        ?.toString()
                        .trim() ??
                    "",
            address:
                item["addr1"]
                        ?.toString()
                        .trim() ??
                    "",
            contentTypeId:
                item["contenttypeid"]
                        ?.toString()
                        .trim() ??
                    "",
            lDongRegnCd:
                item["lDongRegnCd"]
                        ?.toString()
                        .trim() ??
                    areaCode,
            lDongSignguCd:
                item["lDongSignguCd"]
                        ?.toString()
                        .trim() ??
                    sigunguCode,
            regionName:
                item["addr1"]
                        ?.toString()
                        .trim() ??
                    regionName ??
                    "",
            lclsSystm1:
                item["lclsSystm1"]
                        ?.toString()
                        .trim() ??
                    "",
            lclsSystm2:
                item["lclsSystm2"]
                        ?.toString()
                        .trim() ??
                    "",
            lclsSystm3:
                item["lclsSystm3"]
                        ?.toString()
                        .trim() ??
                    "",
            modifiedTime:
                item["modifiedtime"]
                        ?.toString()
                        .trim() ??
                    "",
            latitude:
                double.tryParse(
                  item["mapy"]
                          ?.toString()
                          .trim() ??
                      "",
                ),
            longitude:
                double.tryParse(
                  item["mapx"]
                          ?.toString()
                          .trim() ??
                      "",
                ),
          ),
        );
      }

      print(
        "관광지 조회 : "
        "$areaCode / $sigunguCode"
        " → ${spots.length}개",
      );

      return spots;
    } catch (e) {
      print(
        "관광지 조회 실패 : "
        "$areaCode / $sigunguCode / $e",
      );

      return [];
    }
  }

  // ============================================================
  // 관광지 이미지 조회
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

        final String originUrl =
            item["originimgurl"]
                    ?.toString()
                    .trim() ??
                "";

        final String smallUrl =
            item["smallimageurl"]
                    ?.toString()
                    .trim() ??
                "";

        print(
          "      원본 이미지 : $originUrl",
        );

        print(
          "      썸네일 이미지 : $smallUrl",
        );

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
}
