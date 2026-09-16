import 'dart:convert';

import 'package:http/http.dart' as http;

class CongestionService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  static const String serviceKey = '22cfa7aa1cefdd4fe98e0e9dad0415b994b125c08a2da84a8757d7ac5aa09af5';

  // ============================================================
  // 집중률 API 전체 페이지 조회
  //
  // signguCd를 넣으면
  //   → 특정 시군구 조회
  //
  // signguCd를 넣지 않으면
  //   → 해당 시도 전체 조회
  //
  // 예)
  //
  // 특정 지역:
  // getAllCongestion(
  //   areaCd: '23',
  //   signguCd: '11',
  // )
  //
  // 인천 전체:
  // getAllCongestion(
  //   areaCd: '23',
  // )
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllCongestion({
    required String areaCd,
    String? signguCd,
    int numOfRows = 100,
  }) async {
    final List<Map<String, dynamic>> allResults = [];

    int pageNo = 1;
    int totalCount = 0;

    // ============================================================
    // signguCd 정리
    // ============================================================

    final String? normalizedSignguCd =
        signguCd?.trim().isEmpty == true
            ? null
            : signguCd?.trim();

    while (true) {
      // ==========================================================
      // API 요청 파라미터
      // ==========================================================

      final queryParameters = <String, String>{
        'serviceKey': serviceKey,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
        'MobileOS': 'ETC',
        'MobileApp': 'SNOB',
        'areaCd': areaCd,
        '_type': 'json',
      };

      // signguCd가 있을 때만 추가
      if (normalizedSignguCd != null) {
        queryParameters['signguCd'] = normalizedSignguCd;
      }

      final uri = Uri.parse(
        '$baseUrl/tatsCnctrRatedList',
      ).replace(
        queryParameters: queryParameters,
      );

      try {
        print('');
        print('==========================================');
        print('집중률 API 조회');
        print('==========================================');
        print('areaCd   : $areaCd');
        print(
          'signguCd : '
          '${normalizedSignguCd ?? '전체 시군구'}',
        );
        print('페이지   : $pageNo');
        print('==========================================');

        // ========================================================
        // API 호출
        // ========================================================

        final response = await http.get(uri);

        print('HTTP 상태 : ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception(
            '집중률 API HTTP 오류 : ${response.statusCode}',
          );
        }

        // ========================================================
        // JSON 파싱
        // ========================================================

        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          print('응답 데이터가 Map 형식이 아닙니다.');
          break;
        }

        final dynamic responseData = decoded['response'];

        if (responseData is! Map) {
          print('response 데이터가 없습니다.');
          break;
        }

        final dynamic body = responseData['body'];

        if (body is! Map) {
          print('body 데이터가 없습니다.');
          break;
        }

        // ========================================================
        // 전체 데이터 개수
        // ========================================================

        totalCount =
            int.tryParse(
              body['totalCount']?.toString() ?? '0',
            ) ??
            0;

        print('전체 데이터 수 : $totalCount');

        // ========================================================
        // items 확인
        // ========================================================

        final dynamic items = body['items'];

        if (items == null || items == '') {
          print('items가 비어 있습니다.');
          break;
        }

        if (items is! Map) {
          print('items 형식이 올바르지 않습니다.');
          break;
        }

        // ========================================================
        // item 확인
        // ========================================================

        final dynamic itemData = items['item'];

        if (itemData == null || itemData == '') {
          print('item이 없습니다.');
          break;
        }

        List<Map<String, dynamic>> pageResults = [];

        // --------------------------------------------------------
        // item이 여러 개일 경우
        // --------------------------------------------------------

        if (itemData is List) {
          pageResults = itemData
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }

        // --------------------------------------------------------
        // item이 하나일 경우
        // --------------------------------------------------------

        else if (itemData is Map) {
          pageResults = [
            Map<String, dynamic>.from(itemData),
          ];
        }

        // ========================================================
        // 이번 페이지 데이터 확인
        // ========================================================

        if (pageResults.isEmpty) {
          print('이번 페이지에 데이터가 없습니다.');
          break;
        }

        allResults.addAll(pageResults);

        print(
          '이번 페이지 : ${pageResults.length}개',
        );

        print(
          '현재까지 : ${allResults.length}개',
        );

        // ========================================================
        // 마지막 페이지 확인
        // ========================================================

        // 전체 개수를 모두 가져온 경우
        if (totalCount > 0 &&
            allResults.length >= totalCount) {
          print('전체 페이지 조회 완료');
          break;
        }

        // numOfRows보다 적게 반환되면 마지막 페이지
        if (pageResults.length < numOfRows) {
          print('마지막 페이지 도달');
          break;
        }

        // 다음 페이지
        pageNo++;
      } catch (e) {
        print(
          '집중률 API 조회 실패 '
          '(page $pageNo) : $e',
        );

        break;
      }
    }

    // ============================================================
    // 최종 결과 출력
    // ============================================================

    print('');
    print('==========================================');
    print('집중률 API 최종 결과');
    print('==========================================');
    print('조회 areaCd   : $areaCd');
    print(
      '조회 signguCd : '
      '${normalizedSignguCd ?? '전체 시군구'}',
    );
    print('전체 데이터   : ${allResults.length}개');
    print('API totalCount: $totalCount');
    print('==========================================');

    return allResults;
  }

  // ============================================================
  // 특정 시군구 집중률 조회
  //
  // signguCd를 명확하게 넣어서 조회하고 싶을 때 사용
  // ============================================================

  Future<List<Map<String, dynamic>>> getCongestionBySigungu({
    required String areaCd,
    required String signguCd,
    int numOfRows = 100,
  }) async {
    return getAllCongestion(
      areaCd: areaCd,
      signguCd: signguCd,
      numOfRows: numOfRows,
    );
  }

  // ============================================================
  // 시도 전체 집중률 조회
  //
  // signguCd 없이 areaCd만 전달
  //
  // 예)
  //
  // getCongestionByArea(
  //   areaCd: '23',
  // )
  //
  // → 인천 전체
  // ============================================================

  Future<List<Map<String, dynamic>>> getCongestionByArea({
    required String areaCd,
    int numOfRows = 100,
  }) async {
    return getAllCongestion(
      areaCd: areaCd,
      numOfRows: numOfRows,
    );
  }
}