import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// Kakao 장소 검색 결과
/// ============================================================

class KakaoPlace {
  final String id;
  final String name;

  final String? categoryName;

  final String? addressName;
  final String? roadAddressName;

  final String? phone;
  final String? placeUrl;

  final double latitude;
  final double longitude;

  final String? distance;

  const KakaoPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.categoryName,
    this.addressName,
    this.roadAddressName,
    this.phone,
    this.placeUrl,
    this.distance,
  });

  /// 표시할 주소
  String get displayAddress {
    if (roadAddressName != null &&
        roadAddressName!.isNotEmpty) {
      return roadAddressName!;
    }

    return addressName ?? '';
  }

  factory KakaoPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    return KakaoPlace(
      id:
          json['id']?.toString() ?? '',

      name:
          json['place_name']
                  ?.toString() ??
              '',

      categoryName:
          json['category_name']
              ?.toString(),

      addressName:
          json['address_name']
              ?.toString(),

      roadAddressName:
          json['road_address_name']
              ?.toString(),

      phone:
          json['phone']?.toString(),

      placeUrl:
          json['place_url']
              ?.toString(),

      // Kakao Local API
      // x = longitude
      // y = latitude
      longitude:
          double.tryParse(
                json['x']?.toString() ??
                    '',
              ) ??
              0.0,

      latitude:
          double.tryParse(
                json['y']?.toString() ??
                    '',
              ) ??
              0.0,

      distance:
          json['distance']
              ?.toString(),
    );
  }

  @override
  String toString() {
    return 'KakaoPlace('
        'id: $id, '
        'name: $name, '
        'latitude: $latitude, '
        'longitude: $longitude'
        ')';
  }
}

/// ============================================================
/// Kakao Local Service
/// ============================================================

class KakaoLocalService {
  KakaoLocalService({
    String? restApiKey,
    http.Client? client,
  })  : _restApiKey =
            restApiKey ??
                const String.fromEnvironment(
                  'KAKAO_MOBILITY_REST_KEY',
                ),
        _client =
            client ?? http.Client();

  /// ============================================================
  /// 코드에 직접 넣을 REST API KEY
  /// ============================================================
  ///
  /// 실제 키는 아래 문자열에 입력하면 된다.
  ///
  /// 보안을 위해 여기서는 실제 키를 다시 노출하지 않는다.
  /// ============================================================

  static const String hardcodedRestApiKey =
      'YOUR_KAKAO_REST_KEY';

  final String _restApiKey;

  final http.Client _client;

  static const String _baseUrl =
      'https://dapi.kakao.com';

  /// ============================================================
  /// 실제 사용할 API KEY
  /// ============================================================

  String get apiKey {
    if (_restApiKey.trim().isNotEmpty) {
      return _restApiKey;
    }

    return hardcodedRestApiKey;
  }

  bool get hasApiKey {
    return apiKey.trim().isNotEmpty &&
        apiKey != 'YOUR_KAKAO_REST_KEY';
  }

  /// ============================================================
  /// API Key 확인
  /// ============================================================

  void _validateKey() {
    if (!hasApiKey) {
      throw Exception(
        'Kakao REST API Key가 설정되지 않았습니다.',
      );
    }
  }

  /// ============================================================
  /// 장소 키워드 검색
  /// ============================================================

  Future<List<KakaoPlace>> searchPlaces(
    String query, {
    int page = 1,
    int size = 15,
  }) async {
    _validateKey();

    final trimmed =
        query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    if (page < 1) {
      page = 1;
    }

    if (size < 1) {
      size = 15;
    }

    if (size > 15) {
      size = 15;
    }

    final uri = Uri.parse(
      '$_baseUrl/v2/local/search/keyword.json',
    ).replace(
      queryParameters: {
        'query': trimmed,
        'page':
            page.toString(),
        'size':
            size.toString(),
        'sort':
            'accuracy',
      },
    );

    debugPrint(
      '[Kakao Local] 검색 시작: $trimmed',
    );

    final response =
        await _client.get(
      uri,
      headers: {
        'Authorization':
            'KakaoAK $apiKey',

        'Content-Type':
            'application/json;charset=UTF-8',
      },
    );

    debugPrint(
      '[Kakao Local] status: '
      '${response.statusCode}',
    );

    /// ==========================================================
    /// 성공
    /// ==========================================================

    if (response.statusCode == 200) {
      dynamic decoded;

      try {
        decoded =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Kakao API 응답을 해석할 수 없습니다.',
        );
      }

      if (decoded
          is! Map<String, dynamic>) {
        throw Exception(
          'Kakao API 응답 형식이 올바르지 않습니다.',
        );
      }

      final documents =
          decoded['documents']
                  as List? ??
              [];

      debugPrint(
        '[Kakao Local] 검색 결과: '
        '${documents.length}개',
      );

      final places =
          <KakaoPlace>[];

      for (final item
          in documents) {
        if (item is! Map) {
          continue;
        }

        try {
          final place =
              KakaoPlace.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          );

          if (place.name.isEmpty) {
            continue;
          }

          if (place.latitude ==
                  0 ||
              place.longitude ==
                  0) {
            continue;
          }

          places.add(place);
        } catch (e) {
          debugPrint(
            '[Kakao Local] 결과 변환 실패: '
            '$e',
          );
        }
      }

      return places;
    }

    /// ==========================================================
    /// 인증 실패
    /// ==========================================================

    if (response.statusCode == 401) {
      throw Exception(
        'Kakao REST API Key가 올바르지 않거나\n'
        'Kakao Developers 설정을 확인해주세요.\n\n'
        'HTTP 401',
      );
    }

    /// ==========================================================
    /// 권한 없음
    /// ==========================================================

    if (response.statusCode == 403) {
      throw Exception(
        'Kakao API 사용 권한이 없습니다.\n'
        'Kakao Developers에서 Local API 사용 설정을 확인해주세요.\n\n'
        'HTTP 403',
      );
    }

    /// ==========================================================
    /// 요청 오류
    /// ==========================================================

    if (response.statusCode == 400) {
      String message =
          '잘못된 검색 요청입니다.';

      try {
        final data =
            jsonDecode(
          response.body,
        );

        if (data is Map &&
            data['msg'] != null) {
          message =
              data['msg'].toString();
        }
      } catch (_) {}

      throw Exception(
        '$message\n\nHTTP 400',
      );
    }

    /// ==========================================================
    /// 호출 제한
    /// ==========================================================

    if (response.statusCode == 429) {
      throw Exception(
        'Kakao API 호출량이 초과되었습니다.\n'
        '잠시 후 다시 시도해주세요.\n\n'
        'HTTP 429',
      );
    }

    /// ==========================================================
    /// 기타 오류
    /// ==========================================================

    String detail = '';

    try {
      final data =
          jsonDecode(
        response.body,
      );

      if (data is Map &&
          data['msg'] != null) {
        detail =
            '\n${data['msg']}';
      }
    } catch (_) {}

    throw Exception(
      '장소 검색에 실패했습니다.'
      '$detail\n\n'
      'HTTP ${response.statusCode}',
    );
  }

  /// ============================================================
  /// 장소명으로 검색
  /// ============================================================

  Future<List<KakaoPlace>>
      searchByKeyword(
    String keyword,
  ) async {
    return searchPlaces(
      keyword,
    );
  }

  /// ============================================================
  /// 여러 페이지 검색
  /// ============================================================

  Future<List<KakaoPlace>>
      searchPlacesMultiplePages(
    String query, {
    int maxPages = 3,
    int size = 15,
  }) async {
    _validateKey();

    final trimmed =
        query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    if (maxPages < 1) {
      maxPages = 1;
    }

    final allResults =
        <KakaoPlace>[];

    for (
      int page = 1;
      page <= maxPages;
      page++
    ) {
      final results =
          await searchPlaces(
        trimmed,
        page: page,
        size: size,
      );

      allResults.addAll(
        results,
      );

      if (results.length <
          size) {
        break;
      }
    }

    return allResults;
  }

  /// ============================================================
  /// 리소스 정리
  /// ============================================================

  void dispose() {
    _client.close();
  }
}