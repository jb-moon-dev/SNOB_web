import 'dart:convert';
import 'package:http/http.dart' as http;

class RelatedSpotService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TarRlteTarService1';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  // ------------------------------------------------------------
  // 지역 기반 관광지별 연관 관광지
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRelatedSpots({
    required int pageNo,
    required int numOfRows,
    required String mobileOS,
    required String mobileApp,
    required String baseYm,
    required String areaCd,
    required String signguCd,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/areaBasedList1',
    ).replace(
      queryParameters: {
        'serviceKey': serviceKey,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
        'MobileOS': mobileOS,
        'MobileApp': mobileApp,
        'baseYm': baseYm,
        'areaCd': areaCd,
        'signguCd': signguCd,
        '_type': 'json',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '연관 관광지 API 호출 실패: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    final items =
        decoded['response']?['body']?['items']?['item'];

    if (items == null) {
      return [];
    }

    if (items is List) {
      return List<Map<String, dynamic>>.from(items);
    }

    if (items is Map) {
      return [Map<String, dynamic>.from(items)];
    }

    return [];
  }


  // ------------------------------------------------------------
  // 키워드 검색 관광지별 연관 관광지
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchRelatedSpots({
    required int pageNo,
    required int numOfRows,
    required String mobileOS,
    required String mobileApp,
    required String baseYm,
    required String keyword,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/searchKeyword1',
    ).replace(
      queryParameters: {
        'serviceKey': serviceKey,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
        'MobileOS': mobileOS,
        'MobileApp': mobileApp,
        'baseYm': baseYm,
        'keyword': keyword,
        '_type': 'json',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '연관 관광지 키워드 API 호출 실패: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    final items =
        decoded['response']?['body']?['items']?['item'];

    if (items == null) {
      return [];
    }

    if (items is List) {
      return List<Map<String, dynamic>>.from(items);
    }

    if (items is Map) {
      return [Map<String, dynamic>.from(items)];
    }

    return [];
  }
}