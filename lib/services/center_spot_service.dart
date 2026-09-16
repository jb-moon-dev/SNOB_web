import 'dart:convert';
import 'package:http/http.dart' as http;

class CenterSpotService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/LocgoHubTarService1';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  Future<List<Map<String, dynamic>>> getCenterSpots({
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

    print('');
    print('========================================');
    print('CENTER SPOT API');
    print(uri);
    print('========================================');

    final response = await http.get(uri);

    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE:');
    print(response.body);
    print('========================================');

    if (response.statusCode != 200) {
      throw Exception(
        '중심 관광지 API 호출 실패: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    print('decoded type: ${decoded.runtimeType}');

    // response
    final responseData = decoded['response'];

    if (responseData is! Map) {
      print('response가 Map이 아닙니다.');
      return [];
    }

    // body
    final body = responseData['body'];

    if (body is! Map) {
      print('body가 Map이 아닙니다.');
      return [];
    }

    // items
    final itemsData = body['items'];

    print('items type: ${itemsData.runtimeType}');
    print('items: $itemsData');

    // 관광지가 없는 경우
    if (itemsData == null || itemsData == '') {
      return [];
    }

    if (itemsData is! Map) {
      print('items가 Map이 아닙니다.');
      return [];
    }

    // item
    final itemData = itemsData['item'];

    if (itemData == null || itemData == '') {
      return [];
    }

    // 여러 관광지
    if (itemData is List) {
      return itemData
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    // 관광지가 1개일 경우
    if (itemData is Map) {
      return [
        Map<String, dynamic>.from(itemData),
      ];
    }

    return [];
  }
}