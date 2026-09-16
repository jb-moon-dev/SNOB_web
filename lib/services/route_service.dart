import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// ============================================================
/// 이동수단
/// ============================================================

enum TransportMode {
  walking,
  car,
  publicTransit,
}

/// ============================================================
/// 이동수단 이름
/// ============================================================

extension TransportModeExtension on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.walking:
        return '도보';

      case TransportMode.car:
        return '자동차';

      case TransportMode.publicTransit:
        return '대중교통';
    }
  }

  String get shortLabel {
    switch (this) {
      case TransportMode.walking:
        return '도보';

      case TransportMode.car:
        return '차';

      case TransportMode.publicTransit:
        return '대중교통';
    }
  }

  String get iconName {
    switch (this) {
      case TransportMode.walking:
        return 'walking';

      case TransportMode.car:
        return 'car';

      case TransportMode.publicTransit:
        return 'transit';
    }
  }
}

/// ============================================================
/// 경로 결과
/// ============================================================

class RouteResult {
  final int durationMinutes;
  final int durationSeconds;

  final int distanceMeters;

  /// 실제 API에서 가져왔는지 여부
  final bool fromApi;

  /// 어떤 이동수단으로 계산했는지
  final TransportMode mode;

  const RouteResult({
    required this.durationMinutes,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.fromApi,
    required this.mode,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    }

    final km = distanceMeters / 1000;

    return '${km.toStringAsFixed(1)}km';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes분';
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (minutes == 0) {
      return '$hours시간';
    }

    return '$hours시간 $minutes분';
  }
}

/// ============================================================
/// Kakao Route Service
/// ============================================================

class RouteService {
  RouteService({
    String? restApiKey,
    http.Client? client,
  })  : _restApiKey = restApiKey ?? '',
        _client = client ?? http.Client();

  /// ============================================================
  /// API KEY
  /// ============================================================
  ///
  /// 여기에 기존에 사용하던 Kakao REST API Key를 그대로 넣으면 된다.
  /// ============================================================

  static const String hardcodedRestApiKey =
      '3bc005218347f7b0f3c023554bbfe13e';

  final String _restApiKey;

  final http.Client _client;

  static const String _routeBaseUrl =
      'https://apis-navi.kakaomobility.com';

  /// ============================================================
  /// 실제 사용할 API Key
  /// ============================================================

  String get apiKey {
    if (_restApiKey.trim().isNotEmpty) {
      return _restApiKey;
    }

    return hardcodedRestApiKey;
  }

  /// ============================================================
  /// API Key 확인
  /// ============================================================

  void _validateKey() {
    if (apiKey.trim().isEmpty ||
        apiKey == '3bc005218347f7b0f3c023554bbfe13e') {
      throw Exception(
        'Kakao REST API Key가 설정되지 않았습니다.',
      );
    }
  }

  /// ============================================================
  /// 이동시간 계산
  /// ============================================================

  Future<RouteResult> getRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    TransportMode mode = TransportMode.walking,
  }) async {
    switch (mode) {
      case TransportMode.walking:
        return getWalkingRoute(
          startLatitude: startLatitude,
          startLongitude: startLongitude,
          endLatitude: endLatitude,
          endLongitude: endLongitude,
        );

      case TransportMode.car:
        return getDrivingRoute(
          startLatitude: startLatitude,
          startLongitude: startLongitude,
          endLatitude: endLatitude,
          endLongitude: endLongitude,
        );

      case TransportMode.publicTransit:
        return getPublicTransitRoute(
          startLatitude: startLatitude,
          startLongitude: startLongitude,
          endLatitude: endLatitude,
          endLongitude: endLongitude,
        );
    }
  }

  /// ============================================================
  /// 자동차 실제 경로
  /// ============================================================

  Future<RouteResult> getDrivingRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    try {
      // 여기로 이동
      _validateKey();

      final uri = Uri.parse(
        '$_routeBaseUrl/v1/directions',
      ).replace(
        queryParameters: {
          'origin':
              '$startLongitude,$startLatitude',

          'destination':
              '$endLongitude,$endLatitude',

          'priority': 'RECOMMEND',

          'summary': 'true',

          'alternatives': 'false',

          'road_details': 'false',
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'Authorization':
              'KakaoAK $apiKey',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode != 200) {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
          TransportMode.car,
        );
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final routes =
          data['routes'] as List?;

      if (routes == null ||
          routes.isEmpty) {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
          TransportMode.car,
        );
      }

      final firstRoute =
          routes.first as Map<String, dynamic>;

      final result =
          firstRoute['summary']
              as Map<String, dynamic>?;

      final distance =
          (result?['distance'] as num?)
              ?.toInt();

      final duration =
          (result?['duration'] as num?)
              ?.toInt();

      if (distance == null ||
          duration == null) {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
          TransportMode.car,
        );
      }

      return RouteResult(
        durationSeconds: duration,
        durationMinutes:
            math.max(
          1,
          (duration / 60).ceil(),
        ),
        distanceMeters: distance,
        fromApi: true,
        mode: TransportMode.car,
      );
    } catch (_) {
      return _fallback(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
        TransportMode.car,
      );
    }
  }

  /// ============================================================
  /// 도보 경로
  /// ============================================================

  Future<RouteResult> getWalkingRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final distanceMeters =
        _haversineDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    /// 평균 도보속도 약 4km/h
    const walkingSpeed =
        4000 / 3600;

    final seconds =
        (distanceMeters /
                walkingSpeed)
            .round();

    return RouteResult(
      durationSeconds: seconds,
      durationMinutes:
          math.max(
        1,
        (seconds / 60).ceil(),
      ),
      distanceMeters:
          distanceMeters.round(),
      fromApi: false,
      mode: TransportMode.walking,
    );
  }

  /// ============================================================
  /// 대중교통 경로
  /// ============================================================

  Future<RouteResult> getPublicTransitRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final distanceMeters =
        _haversineDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    const averageSpeedKmh = 22.0;

    final roadDistance =
        distanceMeters * 1.35;

    final seconds =
        (roadDistance /
                (averageSpeedKmh *
                    1000 /
                    3600))
            .round();

    final minimumSeconds =
        5 * 60;

    final finalSeconds =
        math.max(
      seconds,
      minimumSeconds,
    );

    return RouteResult(
      durationSeconds:
          finalSeconds,
      durationMinutes:
          math.max(
        1,
        (finalSeconds / 60)
            .ceil(),
      ),
      distanceMeters:
          distanceMeters.round(),
      fromApi: false,
      mode:
          TransportMode.publicTransit,
    );
  }

  /// ============================================================
  /// fallback
  /// ============================================================

  RouteResult _fallback(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
    TransportMode mode,
  ) {
    final distanceMeters =
        _haversineDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    double speedKmh;

    switch (mode) {
      case TransportMode.walking:
        speedKmh = 4.0;
        break;

      case TransportMode.car:
        speedKmh = 30.0;
        break;

      case TransportMode.publicTransit:
        speedKmh = 22.0;
        break;
    }

    final metersPerSecond =
        speedKmh * 1000 / 3600;

    final seconds =
        (distanceMeters /
                metersPerSecond)
            .round();

    return RouteResult(
      durationSeconds: seconds,
      durationMinutes:
          math.max(
        1,
        (seconds / 60).ceil(),
      ),
      distanceMeters:
          distanceMeters.round(),
      fromApi: false,
      mode: mode,
    );
  }

  /// ============================================================
  /// Haversine 거리
  /// ============================================================

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius =
        6371000.0;

    final dLat =
        _degreesToRadians(
      lat2 - lat1,
    );

    final dLon =
        _degreesToRadians(
      lon2 - lon1,
    );

    final a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  _degreesToRadians(
                    lat1,
                  ),
                ) *
                math.cos(
                  _degreesToRadians(
                    lat2,
                  ),
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return earthRadius * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }

  /// ============================================================
  /// dispose
  /// ============================================================

  void dispose() {
    _client.close();
  }
}