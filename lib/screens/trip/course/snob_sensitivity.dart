import 'dart:convert';

import 'package:flutter/services.dart';

class SnobSensitivityResult {
  final Map<String, dynamic> spot;
  final bool isProtected;
  final double sensitivityScore;

  const SnobSensitivityResult({
    required this.spot,
    required this.isProtected,
    required this.sensitivityScore,
  });

  @override
  String toString() {
    final name = spot['hubTatsNm'] ?? '이름 없음';

    return '$name | '
        '보호 여부: $isProtected | '
        'Sensitivity: ${sensitivityScore.toStringAsFixed(0)}';
  }
}

class SnobSensitivity {
  static const String csvPath =
      'assets/data/tourism_spots_protected.csv';

  static const double protectedScore = 0;
  static const double normalScore = 20;

  /// Center50에서 전달받은 관광지 50개를 대상으로
  /// 보호 여부를 판단하고 Sensitivity 점수만 계산한다.
  static Future<List<SnobSensitivityResult>> calculate(
    List<Map<String, dynamic>> center50Spots,
  ) async {
    print('');
    print('========================================');
    print('SNOB SENSITIVITY 시작');
    print('대상 관광지 수: ${center50Spots.length}');
    print('========================================');

    // -----------------------------------------
    // 1. 보호 관광지 CSV 읽기
    // -----------------------------------------

    final csvText =
    await rootBundle.loadString(csvPath);

    final lines = const LineSplitter().convert(csvText);

    if (lines.isEmpty) {
      throw Exception('보호 관광지 CSV가 비어 있습니다.');
    }

    // -----------------------------------------
    // 2. CSV 헤더 확인
    // -----------------------------------------

    final headers = _parseCsvLine(lines.first);

    final titleIndex = headers.indexOf('title');
    final protectedIndex = headers.indexOf('is_protected');

    if (titleIndex == -1) {
      throw Exception(
        'CSV에 title 컬럼이 없습니다.',
      );
    }

    if (protectedIndex == -1) {
      throw Exception(
        'CSV에 is_protected 컬럼이 없습니다.',
      );
    }

    // -----------------------------------------
    // 3. 보호 여부를 빠르게 찾기 위한 Map 생성
    // -----------------------------------------

    final Map<String, bool> protectedMap = {};

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final row = _parseCsvLine(lines[i]);

      if (row.length <= titleIndex ||
          row.length <= protectedIndex) {
        continue;
      }

      final title = row[titleIndex].trim();

      final isProtected =
          row[protectedIndex].trim().toLowerCase() == 'true';

      if (title.isEmpty) continue;

      protectedMap[title] = isProtected;
    }

    print('');
    print('보호 관광지 데이터');
    print('총 관광지 수: ${protectedMap.length}');

    // -----------------------------------------
    // 4. Center50 관광지별 Sensitivity 계산
    // -----------------------------------------

    final List<SnobSensitivityResult> results = [];

    for (int i = 0; i < center50Spots.length; i++) {
      final spot = center50Spots[i];

      final name =
          spot['hubTatsNm']?.toString().trim() ?? '';

      final isProtected =
          protectedMap[name] ?? false;

      final score =
          isProtected ? protectedScore : normalScore;

      final result = SnobSensitivityResult(
        spot: spot,
        isProtected: isProtected,
        sensitivityScore: score,
      );

      results.add(result);

      print(
        '[${i + 1}/${center50Spots.length}] '
        '$name | '
        '보호: $isProtected | '
        'Sensitivity: ${score.toStringAsFixed(0)}',
      );
    }

    print('');
    print('========================================');
    print('SNOB SENSITIVITY 종료');
    print('========================================');

    return results;
  }

  // -----------------------------------------
  // 간단한 CSV 파싱
  // -----------------------------------------

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();

    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (insideQuotes &&
            i + 1 < line.length &&
            line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }

    result.add(current.toString());

    return result;
  }
}