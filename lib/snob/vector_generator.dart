import 'region_vector.dart';
import 'spot_vector.dart';
import 'tourism_spot.dart';

class VectorGenerator {
  // ============================================================
  // TourismSpot → SpotVector
  // ============================================================

  static SpotVector generateSpotVector(
    TourismSpot spot,
  ) {
    double nature = 50;
    double hidden = 50;
    double healing = 50;

    // ============================================================
    // 1차 분류
    // ============================================================

    switch (spot.lclsSystm1) {
      case "NA":
        nature += 30;
        healing += 20;
        break;

      case "HS":
        hidden += 20;
        healing += 20;
        break;

      case "EX":
        hidden += 10;
        healing += 10;
        break;

      case "VE":
        nature += 20;
        healing -= 10;
        break;
    }

    // ============================================================
    // 2차 분류
    // ============================================================

    switch (spot.lclsSystm2) {
      case "NA01":
        nature += 20;
        healing += 20;
        hidden += 10;
        break;

      case "NA02":
        nature += 30;
        healing += 20;
        break;

      case "NA04":
        nature += 20;
        healing += 30;
        hidden += 10;
        break;

      case "HS01":
        hidden += 20;
        healing += 10;
        break;

      case "HS03":
        nature += 20;
        healing += 20;
        hidden += 20;
        break;

      case "EX07":
        hidden += 20;
        break;

      case "VE03":
        nature += 10;
        break;
    }

    // ============================================================
    // 3차 분류
    // ============================================================

    switch (spot.lclsSystm3) {
      case "NA010100":
        nature += 20;
        healing += 20;
        break;

      case "NA010300":
        nature += 20;
        healing += 20;
        break;

      case "NA010500":
        healing += 30;
        break;

      case "NA020700":
        nature += 20;
        break;

      case "NA020900":
        nature += 30;
        healing += 20;
        break;

      case "HS030100":
        healing += 40;
        break;

      case "HS010900":
        hidden += 20;
        healing += 10;
        break;
    }

    // ============================================================
    // 범위 제한
    // ============================================================

    nature = nature.clamp(0, 100).toDouble();
    hidden = hidden.clamp(0, 100).toDouble();
    healing = healing.clamp(0, 100).toDouble();

    // ============================================================
    // ⭐ 지역명은 TourismApiService에서 확정된 값을 사용
    // ============================================================

    return SpotVector(
      spotName: spot.title,
      regionName: spot.regionName,
      nature: nature,
      hidden: hidden,
      healing: healing,
      congestion: 0,
    );
  }

  // ============================================================
  // TourismSpot List → SpotVector List
  // ============================================================

  static List<SpotVector> generateSpotVectors(
    List<TourismSpot> spots,
  ) {
    return spots
        .map(generateSpotVector)
        .toList();
  }

  // ============================================================
  // SpotVector → RegionVector
  // ============================================================

  static List<RegionVector> generateRegions(
    List<SpotVector> spots,
  ) {
    final Map<String, List<SpotVector>> grouped = {};

    for (final SpotVector spot in spots) {
      final String region =
          spot.regionName.trim();

      if (region.isEmpty) {
        continue;
      }

      grouped.putIfAbsent(
        region,
        () => [],
      );

      grouped[region]!.add(spot);
    }

    final List<RegionVector> regions = [];

    grouped.forEach(
      (String regionName,
      List<SpotVector> spotList) {
        if (spotList.isEmpty) {
          return;
        }

        double nature = 0;
        double hidden = 0;
        double healing = 0;

        for (final SpotVector spot in spotList) {
          nature += spot.nature;
          hidden += spot.hidden;
          healing += spot.healing;
        }

        final double count =
            spotList.length.toDouble();

        regions.add(
          RegionVector(
            regionName: regionName,
            nature: nature / count,
            hidden: hidden / count,
            healing: healing / count,
            congestion: 0,
          ),
        );
      },
    );

    regions.sort(
      (a, b) => a.regionName.compareTo(
        b.regionName,
      ),
    );

    return regions;
  }

  // ============================================================
  // TourismSpot List → RegionVector List
  // ============================================================

  static List<RegionVector>
      generateRegionsFromTourismSpots(
    List<TourismSpot> spots,
  ) {
    final List<SpotVector> spotVectors =
        generateSpotVectors(spots);

    return generateRegions(
      spotVectors,
    );
  }
}