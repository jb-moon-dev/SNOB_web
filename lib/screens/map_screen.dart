import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';


// ============================================================
// 혼잡도 데이터
// ============================================================

class CongestionData {
  final String cd;
  final String nm;
  final double currentVisitor;
  final double normalVisitor;
  final double normalCompare;
  final double absoluteScore;
  final String levelStr;

  CongestionData({
    required this.cd,
    required this.nm,
    required this.currentVisitor,
    required this.normalVisitor,
    required this.normalCompare,
    required this.absoluteScore,
    required this.levelStr,
  });
}


// ============================================================
// GeoJSON 지역 데이터
// ============================================================

class PolygonRegion {
  final String cd;
  final String nm;
  final List<List<LatLng>> polygons;

  PolygonRegion({
    required this.cd,
    required this.nm,
    required this.polygons,
  });
}


// ============================================================
// 백그라운드 파싱용 파라미터
// ============================================================

class ParseParams {
  final String csvString;
  final String jsonString;
  final bool onlySeoul;

  ParseParams(
    this.csvString,
    this.jsonString, {
    this.onlySeoul = false,
  });
}


// ============================================================
// 파싱 결과
// ============================================================

class ParseResult {
  final Map<String, CongestionData> congestionMapByNm;
  final Map<String, CongestionData> congestionMapByCd;
  final List<PolygonRegion> regions;

  ParseResult(
    this.congestionMapByNm,
    this.congestionMapByCd,
    this.regions,
  );
}


// ============================================================
// 지역명 정규화
// ============================================================

String _normalizeName(String name) {
  String clean = name.replaceAll(' ', '').trim();

  if (clean == '세종' ||
      clean == '세종시' ||
      clean == '세종특별자치시') {
    return '세종';
  }

  clean = clean
      .replaceAll('특별시', '')
      .replaceAll('광역시', '')
      .replaceAll('특별자치시', '')
      .replaceAll('특별자치도', '');

  return clean;
}


// ============================================================
// CSV + GeoJSON 백그라운드 파싱
// ============================================================

ParseResult _parseInBackground(ParseParams params) {

  // ----------------------------------------------------------
  // CSV
  // ----------------------------------------------------------

  List<String> lines =
      const LineSplitter().convert(params.csvString);

  Map<String, CongestionData> tempCsvMapByNm = {};
  Map<String, CongestionData> tempCsvMapByCd = {};

  for (int i = 1; i < lines.length; i++) {

    if (lines[i].trim().isEmpty) {
      continue;
    }

    List<String> cols =
        lines[i].split(',');

    if (cols.length < 8) {
      continue;
    }

    String cd =
        cols[0].trim();

    String rawNm =
        cols[1].trim();

    String normalizedNm =
        _normalizeName(rawNm);

    double currentVisitor =
        double.tryParse(
          cols[2].trim(),
        ) ??
        0;

    double normalVisitor =
        double.tryParse(
          cols[3].trim(),
        ) ??
        0;

    double normalCompare =
        double.tryParse(
          cols[4].trim(),
        ) ??
        0;

    double absoluteScore =
        double.tryParse(
          cols[6].trim(),
        ) ??
        0;

    String levelStr =
        cols[7].trim();

    CongestionData data =
        CongestionData(
      cd: cd,
      nm: rawNm,
      currentVisitor: currentVisitor,
      normalVisitor: normalVisitor,
      normalCompare: normalCompare,
      absoluteScore: absoluteScore,
      levelStr: levelStr,
    );

    // 지역명 기준
    tempCsvMapByNm[rawNm] =
        data;

    tempCsvMapByNm[normalizedNm] =
        data;

    // 시군구 코드 기준
    if (cd.isNotEmpty) {
      tempCsvMapByCd[cd] =
          data;
    }
  }


  // ----------------------------------------------------------
  // GeoJSON
  // ----------------------------------------------------------

  Map<String, dynamic> geojson =
      jsonDecode(
    params.jsonString,
  );

  List features =
      geojson['features'] ?? [];

  List<PolygonRegion> tempRegions =
      [];


  // ----------------------------------------------------------
  // 지역별 Polygon
  // ----------------------------------------------------------

  for (var feature in features) {

    var geometry =
        feature['geometry'];

    var properties =
        feature['properties'];

    if (geometry == null ||
        properties == null) {
      continue;
    }

    String cd =
        (properties['SIGUNGU_CD'] ?? '')
            .toString()
            .trim();

    String rawNm =
        (properties['SIGUNGU_NM'] ?? '')
            .toString()
            .trim();

    if (rawNm.isEmpty) {
      continue;
    }

    if (params.onlySeoul &&
        !cd.startsWith('11')) {
      continue;
    }

    String type =
        (geometry['type'] ?? '')
            .toString();

    List<List<LatLng>>
        multiPolygons = [];


    try {

      // --------------------------------------------------------
      // Polygon
      // --------------------------------------------------------

      if (type == 'Polygon') {

        List rawRings =
            geometry['coordinates'];

        if (rawRings.isNotEmpty) {

          List<LatLng> points =
              _downsampleCoordinates(
            rawRings[0],
            params.onlySeoul,
          );

          if (points.length >= 3) {
            multiPolygons.add(
              points,
            );
          }
        }
      }


      // --------------------------------------------------------
      // MultiPolygon
      // --------------------------------------------------------

      else if (type == 'MultiPolygon') {

        List rawPolygons =
            geometry['coordinates'];

        for (var poly in rawPolygons) {

          if (poly.isEmpty) {
            continue;
          }

          List<LatLng> points =
              _downsampleCoordinates(
            poly[0],
            params.onlySeoul,
          );

          if (points.length >= 3) {
            multiPolygons.add(
              points,
            );
          }
        }
      }

    } catch (e) {

      debugPrint(
        "GeoJSON Polygon 파싱 오류 [$rawNm]: $e",
      );

      continue;
    }


    if (multiPolygons.isNotEmpty) {

      tempRegions.add(
        PolygonRegion(
          cd: cd,
          nm: rawNm,
          polygons: multiPolygons,
        ),
      );
    }
  }


  return ParseResult(
    tempCsvMapByNm,
    tempCsvMapByCd,
    tempRegions,
  );
}


// ============================================================
// GeoJSON 정점 처리
//
// ★ 중요
//
// 기존에는 step = 5 / 10 / 20 / 35 로
// 좌표를 강제로 많이 제거했음.
//
// 작은 시군구에서는 이 때문에
// 경계가 각지고 빈틈처럼 보일 수 있음.
//
// 현재는 step = 1
// → GeoJSON에 남아있는 좌표를 모두 사용.
// ============================================================

List<LatLng> _downsampleCoordinates(
  List rawCoordinates,
  bool onlySeoul,
) {

  List<LatLng> points = [];

  int totalPoints =
      rawCoordinates.length;

  // ----------------------------------------------------------
  // ★ 경계 보존
  //
  // 좌표를 추가로 삭제하지 않는다.
  // ----------------------------------------------------------

  const int step = 1;


  // ----------------------------------------------------------
  // 좌표 변환
  // ----------------------------------------------------------

  for (
    int i = 0;
    i < totalPoints;
    i += step
  ) {

    var c =
        rawCoordinates[i];

    if (c is! List ||
        c.length < 2) {
      continue;
    }

    points.add(
      LatLng(
        (c[1] as num)
            .toDouble(),

        (c[0] as num)
            .toDouble(),
      ),
    );
  }


  // ----------------------------------------------------------
  // 마지막 점 포함
  // ----------------------------------------------------------

  if (totalPoints > 0) {

    var last =
        rawCoordinates.last;

    if (last is List &&
        last.length >= 2) {

      LatLng lastPoint =
          LatLng(
        (last[1] as num)
            .toDouble(),

        (last[0] as num)
            .toDouble(),
      );

      if (
        points.isEmpty ||
        points.last.latitude !=
            lastPoint.latitude ||
        points.last.longitude !=
            lastPoint.longitude
      ) {

        points.add(
          lastPoint,
        );
      }
    }
  }


  return points;
}


// ============================================================
// MapScreen
// ============================================================

class MapScreen
    extends StatefulWidget {

  const MapScreen({
    super.key,
  });

  @override
  State<MapScreen> createState() =>
      _MapScreenState();
}


class _MapScreenState
    extends State<MapScreen> {

  // ==========================================================
  // 지도
  // ==========================================================

  KakaoMapController?
      mapController;

  bool isDataLoaded =
      false;

  bool isMapReady =
      false;

  bool isAbsoluteMode =
      true;

  int currentMapLevel =
      12;


  // ==========================================================
  // 데이터
  // ==========================================================

  Map<String, CongestionData>
      congestionMapByNm = {};

  Map<String, CongestionData>
      congestionMapByCd = {};

  List<PolygonRegion>
      regions = [];


  // ==========================================================
  // Polygon
  // ==========================================================

  List<Polygon>
      renderedPolygons = [];


  // ==========================================================
  // 초기화
  // ==========================================================

  @override
  void initState() {

    super.initState();

    _loadData();
  }


  // ==========================================================
  // 데이터 로드
  // ==========================================================

  Future<void> _loadData() async {

    try {

      String csvString =
          await rootBundle.loadString(
        'congestion_final.csv',
      );


      String jsonString =
          await rootBundle.loadString(
        'assets/map/sigungu_congestion.geojson',
      );


      ParseResult result =
          await compute(
        _parseInBackground,
        ParseParams(
          csvString,
          jsonString,
          onlySeoul: false,
        ),
      );


      congestionMapByNm =
          result.congestionMapByNm;

      congestionMapByCd =
          result.congestionMapByCd;

      regions =
          result.regions;


      debugPrint(
        "혼잡도 데이터: "
        "${congestionMapByCd.length}개",
      );

      debugPrint(
        "GeoJSON 지역: "
        "${regions.length}개",
      );


      if (mounted) {

        setState(() {
          isDataLoaded =
              true;
        });
      }

    } catch (e) {

      debugPrint(
        "데이터 로드 오류: $e",
      );


      if (mounted) {

        setState(() {
          isDataLoaded =
              false;
        });
      }
    }
  }


  // ==========================================================
  // 혼잡도 데이터 찾기
  // ==========================================================

  CongestionData?
      _getCongestionData(
    String regionName, {
    String? regionCode,
  }) {

    // --------------------------------------------------------
    // 1. 코드
    // --------------------------------------------------------

    if (
      regionCode != null &&
      regionCode.isNotEmpty
    ) {

      CongestionData? data =
          congestionMapByCd[
            regionCode
          ];

      if (data != null) {
        return data;
      }
    }


    // --------------------------------------------------------
    // 2. 원본 지역명
    // --------------------------------------------------------

    CongestionData? byName =
        congestionMapByNm[
          regionName
        ];

    if (byName != null) {
      return byName;
    }


    // --------------------------------------------------------
    // 3. 정규화 지역명
    // --------------------------------------------------------

    String normalized =
        _normalizeName(
      regionName,
    );

    return congestionMapByNm[
      normalized
    ];
  }


  // ==========================================================
  // 혼잡도 색상
  // ==========================================================

  Color _getStageColor(
    CongestionData data,
  ) {

    // --------------------------------------------------------
    // 절대 혼잡도
    // --------------------------------------------------------

    if (isAbsoluteMode) {

      double score =
          data.absoluteScore;


      if (score < 20) {
        return const Color(
          0xFF16A085,
        );
      }


      if (score < 40) {
        return const Color(
          0xFF2ECC71,
        );
      }


      if (score < 60) {
        return const Color(
          0xFFF1C40F,
        );
      }


      if (score < 80) {
        return const Color(
          0xFFE67E22,
        );
      }


      return const Color(
        0xFFE74C3C,
      );
    }


    // --------------------------------------------------------
    // 평소 대비
    // --------------------------------------------------------

    double compare =
        data.normalCompare;


    if (compare <= -30) {
      return const Color(
        0xFF16A085,
      );
    }


    if (compare <= -10) {
      return const Color(
        0xFF2ECC71,
      );
    }


    if (compare <= 10) {
      return const Color(
        0xFFF1C40F,
      );
    }


    if (compare <= 40) {
      return const Color(
        0xFFE67E22,
      );
    }


    return const Color(
      0xFFE74C3C,
    );
  }


  // ==========================================================
  // 혼잡도 텍스트
  // ==========================================================

  String _getStageText(
    CongestionData data,
  ) {

    if (isAbsoluteMode) {

      double score =
          data.absoluteScore;


      if (score < 20) {
        return "매우 여유";
      }


      if (score < 40) {
        return "여유";
      }


      if (score < 60) {
        return "보통";
      }


      if (score < 80) {
        return "혼잡";
      }


      return "매우 혼잡";
    }


    double compare =
        data.normalCompare;


    if (compare <= -30) {
      return "대폭 감소";
    }


    if (compare <= -10) {
      return "소폭 감소";
    }


    if (compare <= 10) {
      return "평년 수준";
    }


    if (compare <= 40) {
      return "소폭 증가";
    }


    return "대폭 증가";
  }


  // ==========================================================
  // Polygon 렌더링
  // ==========================================================

  Future<void>
      _renderPolygonsInChunks() async {

    if (!mounted) {
      return;
    }


    setState(() {
      renderedPolygons.clear();
    });


    const int chunkSize =
        20;


    for (
      int i = 0;
      i < regions.length;
      i += chunkSize
    ) {

      if (!mounted) {
        return;
      }


      int end =
          (i + chunkSize <
                  regions.length)
              ? i + chunkSize
              : regions.length;


      List<PolygonRegion> chunk =
          regions.sublist(
        i,
        end,
      );


      List<Polygon>
          newChunkPolygons = [];


      for (
        PolygonRegion region
        in chunk
      ) {

        // ----------------------------------------------------
        // 코드 우선
        // ----------------------------------------------------

        CongestionData? data =
            _getCongestionData(
          region.nm,
          regionCode:
              region.cd,
        );


        // ----------------------------------------------------
        // 색상
        // ----------------------------------------------------

        Color fillColor;


        if (data != null) {

          fillColor =
              _getStageColor(
            data,
          );

        } else {

          fillColor =
              const Color(
            0xFFBDBDBD,
          );


          debugPrint(
            "혼잡도 데이터 없음: "
            "${region.nm} "
            "(${region.cd})",
          );
        }


        // ----------------------------------------------------
        // Polygon
        // ----------------------------------------------------

        int polyIndex =
            0;


        for (
          List<LatLng> points
          in region.polygons
        ) {

          if (points.length < 3) {
            continue;
          }

          debugPrint(
            'Polygon 생성 시-작: '
            '${region.nm} (${region.cd})',
          );


          newChunkPolygons.add(
            Polygon(

              polygonId:
                  "${region.cd}_"
                  "${region.nm}_"
                  "$polyIndex",

              points:
                  points,


              // 경계선
              strokeColor:
                  Colors.black38,

              strokeWidth:
                  2,


              // 혼잡도 색상
              fillColor:
                  fillColor,


              fillOpacity:
                  data != null
                      ? 0.10
                      : 0.10,
            ),
          );


          polyIndex++;
        }
      }


      if (!mounted) {
        return;
      }


      setState(() {

        renderedPolygons
            .addAll(
          newChunkPolygons,
        );
      });


      await Future.delayed(
        const Duration(
          milliseconds: 25,
        ),
      );
    }
  }


  // ==========================================================
  // Point in Polygon
  // ==========================================================

  bool _isPointInSinglePolygon(
    LatLng point,
    List<LatLng> polygon,
  ) {

    bool isInside =
        false;

    int j =
        polygon.length - 1;


    for (
      int i = 0;
      i < polygon.length;
      i++
    ) {

      if (
        (polygon[i].longitude >
                point.longitude) !=
            (polygon[j].longitude >
                point.longitude) &&

        (
          point.latitude <
              (polygon[j].latitude -
                      polygon[i].latitude) *
                  (point.longitude -
                      polygon[i].longitude) /
                  (polygon[j].longitude -
                      polygon[i].longitude) +
              polygon[i].latitude
        )
      ) {

        isInside =
            !isInside;
      }


      j = i;
    }


    return isInside;
  }


  // ==========================================================
  // 지도 클릭
  // ==========================================================

  void _handleMapTap(
    LatLng latLng,
  ) {

    for (
      PolygonRegion region
      in regions
    ) {

      for (
        List<LatLng> polygon
        in region.polygons
      ) {

        if (
          _isPointInSinglePolygon(
            latLng,
            polygon,
          )
        ) {

          _showRegionDetailCard(
            region.nm,
            region.cd,
          );

          return;
        }
      }
    }
  }


  // ==========================================================
  // 지역 상세 카드
  // ==========================================================

  void _showRegionDetailCard(
    String regionName,
    String regionCode,
  ) {

    CongestionData? data =
        _getCongestionData(
      regionName,
      regionCode:
          regionCode,
    );


    showModalBottomSheet(
      context: context,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),

      builder: (context) {

        // ----------------------------------------------------
        // 데이터 없음
        // ----------------------------------------------------

        if (data == null) {

          return Container(
            padding:
                const EdgeInsets.all(
              24,
            ),

            height: 180,

            child: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.info_outline,
                    size: 30,
                    color: Colors.grey,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    regionName,

                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    "현재 혼잡도 데이터가 없습니다.",

                    style:
                        TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }


        // ----------------------------------------------------
        // 데이터 있음
        // ----------------------------------------------------

        Color statusColor =
            _getStageColor(
          data,
        );

        String statusText =
            _getStageText(
          data,
        );


        return SafeArea(
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // 지역명 + 상태

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    Text(
                      data.nm,

                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            statusColor,

                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),

                      child: Text(
                        statusText,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),


                const Divider(
                  height: 30,
                ),


                // 통계

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [

                    _buildStatColumn(
                      "현재 방문자",

                      "${data.currentVisitor.toInt()}명",
                    ),

                    _buildStatColumn(
                      "평소 방문자",

                      "${data.normalVisitor.toInt()}명",
                    ),

                    _buildStatColumn(
                      "평소 대비",

                      "${data.normalCompare > 0 ? '+' : ''}"
                      "${data.normalCompare.toStringAsFixed(1)}%",

                      isHighlight:
                          true,
                    ),
                  ],
                ),


                const SizedBox(
                  height: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ==========================================================
  // 통계
  // ==========================================================

  Widget _buildStatColumn(
    String label,
    String value, {
    bool isHighlight =
        false,
  }) {

    return Column(
      children: [

        Text(
          label,

          style:
              const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          value,

          style:
              TextStyle(
            fontSize: 17,

            fontWeight:
                FontWeight.bold,

            color: isHighlight
                ? Colors.blueAccent
                : Colors.black87,
          ),
        ),
      ],
    );
  }


  // ==========================================================
  // 확대
  // ==========================================================

  void _zoomIn() {

    if (mapController ==
        null) {
      return;
    }


    if (currentMapLevel <= 1) {
      return;
    }


    currentMapLevel--;


    mapController!.setLevel(
      currentMapLevel,
    );


    if (mounted) {
      setState(() {});
    }
  }


  // ==========================================================
  // 축소
  // ==========================================================

  void _zoomOut() {

    if (mapController ==
        null) {
      return;
    }


    if (currentMapLevel >= 14) {
      return;
    }


    currentMapLevel++;


    mapController!.setLevel(
      currentMapLevel,
    );


    if (mounted) {
      setState(() {});
    }
  }


  // ==========================================================
  // 전국 보기
  // ==========================================================

  void _resetMap() {

    if (mapController ==
        null) {
      return;
    }


    currentMapLevel =
        12;


    mapController!.setCenter(
      LatLng(
        36.3,
        127.8,
      ),
    );


    mapController!.setLevel(
      currentMapLevel,
    );


    if (mounted) {
      setState(() {});
    }
  }


  // ==========================================================
  // 지도 컨트롤 버튼
  // ==========================================================

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return Material(
      color:
          Colors.white,

      elevation:
          4,

      shadowColor:
          Colors.black26,

      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child: InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        child: SizedBox(
          width: 46,
          height: 46,

          child: Icon(
            icon,

            color:
                Colors.black87,

            size:
                23,
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // 범례
  // ==========================================================

  Widget _buildLegend() {

    List<Map<String, dynamic>>
        items;


    if (isAbsoluteMode) {

      items = [

        {
          "color":
              const Color(
            0xFF16A085,
          ),

          "text":
              "매우 여유",
        },

        {
          "color":
              const Color(
            0xFF2ECC71,
          ),

          "text":
              "여유",
        },

        {
          "color":
              const Color(
            0xFFF1C40F,
          ),

          "text":
              "보통",
        },

        {
          "color":
              const Color(
            0xFFE67E22,
          ),

          "text":
              "혼잡",
        },

        {
          "color":
              const Color(
            0xFFE74C3C,
          ),

          "text":
              "매우 혼잡",
        },
      ];

    } else {

      items = [

        {
          "color":
              const Color(
            0xFF16A085,
          ),

          "text":
              "대폭 감소",
        },

        {
          "color":
              const Color(
            0xFF2ECC71,
          ),

          "text":
              "소폭 감소",
        },

        {
          "color":
              const Color(
            0xFFF1C40F,
          ),

          "text":
              "평년 수준",
        },

        {
          "color":
              const Color(
            0xFFE67E22,
          ),

          "text":
              "소폭 증가",
        },

        {
          "color":
              const Color(
            0xFFE74C3C,
          ),

          "text":
              "대폭 증가",
        },
      ];
    }


    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.94,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,

            blurRadius:
                6,

            offset:
                Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            isAbsoluteMode
                ? "절대 혼잡도"
                : "평소 대비",

            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),


          const SizedBox(
            height: 8,
          ),


          ...items.map(
            (item) {

              return Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 2,
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    Container(
                      width: 11,
                      height: 11,

                      decoration:
                          BoxDecoration(
                        color:
                            item["color"],

                        shape:
                            BoxShape.circle,
                      ),
                    ),


                    const SizedBox(
                      width: 7,
                    ),


                    Text(
                      item["text"],

                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // 모드 선택
  // ==========================================================

  Widget _buildModeSelector() {

    return Container(
      height: 45,

      decoration:
          BoxDecoration(
        color:
            Colors.grey[200],

        borderRadius:
            BorderRadius.circular(
          25,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,

            blurRadius:
                6,

            offset:
                Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Row(
        children: [

          // --------------------------------------------------
          // 절대 혼잡도
          // --------------------------------------------------

          Expanded(
            child:
                GestureDetector(

              onTap: () {

                if (!isAbsoluteMode) {

                  setState(() {
                    isAbsoluteMode =
                        true;
                  });

                  _renderPolygonsInChunks();
                }
              },

              child: Container(

                decoration:
                    BoxDecoration(
                  color:
                      isAbsoluteMode
                          ? Colors.blueAccent
                          : Colors.transparent,

                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),
                ),

                alignment:
                    Alignment.center,

                child: Text(
                  "절대 혼잡도",

                  style:
                      TextStyle(
                    color:
                        isAbsoluteMode
                            ? Colors.white
                            : Colors.black87,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),


          // --------------------------------------------------
          // 평소 대비
          // --------------------------------------------------

          Expanded(
            child:
                GestureDetector(

              onTap: () {

                if (isAbsoluteMode) {

                  setState(() {
                    isAbsoluteMode =
                        false;
                  });

                  _renderPolygonsInChunks();
                }
              },

              child: Container(

                decoration:
                    BoxDecoration(
                  color:
                      !isAbsoluteMode
                          ? Colors.blueAccent
                          : Colors.transparent,

                  borderRadius:
                      BorderRadius.circular(
                    25,
                  ),
                ),

                alignment:
                    Alignment.center,

                child: Text(
                  "평소 대비",

                  style:
                      TextStyle(
                    color:
                        !isAbsoluteMode
                            ? Colors.white
                            : Colors.black87,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "전국 혼잡도 지도",

          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle:
            true,
      ),


      body: Stack(

        children: [

          // ====================================================
          // 지도
          // ====================================================

          if (isDataLoaded)

            KakaoMap(

              // ------------------------------------------------
              // 지도 생성
              // ------------------------------------------------

              onMapCreated:
                  (controller) async {

                mapController =
                    controller;


                mapController!
                    .setZoomable(
                  true,
                );


                await Future.delayed(
                  const Duration(
                    milliseconds: 500,
                  ),
                );


                if (mounted) {

                  setState(() {
                    isMapReady =
                        true;
                  });


                  _renderPolygonsInChunks();
                }
              },


              // ------------------------------------------------
              // 지도 클릭
              // ------------------------------------------------

              onMapTap:
                  (latLng) {

                _handleMapTap(
                  latLng,
                );
              },


              // ------------------------------------------------
              // 기본 위치
              // ------------------------------------------------

              center:
                  LatLng(
                36.3,
                127.8,
              ),


              // ------------------------------------------------
              // 기본 확대
              // ------------------------------------------------

              currentLevel:
                  currentMapLevel,


              // ------------------------------------------------
              // Polygon
              // ------------------------------------------------

              polygons:
                  isMapReady
                      ? List.from(
                          renderedPolygons,
                        )
                      : [],
            )


          // ====================================================
          // 로딩
          // ====================================================

          else

            const Center(

              child: Column(

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  CircularProgressIndicator(),

                  SizedBox(
                    height: 16,
                  ),

                  Text(
                    "데이터를 불러오는 중입니다...",
                  ),
                ],
              ),
            ),


          // ====================================================
          // 상단 모드 선택
          // ====================================================

          if (
            isDataLoaded &&
            isMapReady
          )

            Positioned(
              top: 16,
              left: 20,
              right: 20,

              child:
                  _buildModeSelector(),
            ),


          // ====================================================
          // 범례
          // ====================================================

          if (
            isDataLoaded &&
            isMapReady
          )

            Positioned(
              left: 16,
              bottom: 100,

              child:
                  _buildLegend(),
            ),


          // ====================================================
          // 지도 컨트롤
          // ====================================================

          if (
            isDataLoaded &&
            isMapReady
          )

            Positioned(
              right: 16,
              bottom: 100,

              child: Column(

                children: [

                  // 확대

                  _buildMapControlButton(
                    icon:
                        Icons.add,

                    onTap:
                        _zoomIn,
                  ),


                  const SizedBox(
                    height: 8,
                  ),


                  // 축소

                  _buildMapControlButton(
                    icon:
                        Icons.remove,

                    onTap:
                        _zoomOut,
                  ),


                  const SizedBox(
                    height: 8,
                  ),


                  // 전국 보기

                  _buildMapControlButton(
                    icon:
                        Icons.public,

                    onTap:
                        _resetMap,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}