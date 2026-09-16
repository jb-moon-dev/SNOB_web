import 'user_vector.dart';
import 'region_vector.dart';


class SnobScore {



  // ============================
  // 성향 유사도 점수 계산
  // ============================
  static double calculateSimilarity(

      UserVector user,

      RegionVector region,

      ){

    double natureDiff =
        user.nature - region.nature;


    double hiddenDiff =
        user.hidden - region.hidden;


    double healingDiff =
        user.healing - region.healing;



    // 거리 계산
    double distance =

        (natureDiff * natureDiff) +

        (hiddenDiff * hiddenDiff) +

        (healingDiff * healingDiff);



    /*
      최대 거리:
      3개 축 모두 100 차이일 때

      sqrt(30000) ≈ 173

      거리 → 점수 변환
    */

    double similarity =

        100 - ((distance / 30000) * 100);



    return similarity.clamp(0, 100);

  }





  // ============================
  // 혼잡도 점수
  // ============================
  static double calculateCongestionScore(

      double congestion,

      ){

    return (100 - congestion)
        .clamp(0, 100);

  }





  // ============================
  // 최종 SNOB 점수
  // ============================
  static double calculateSnobScore({

    required double similarity,

    required double congestion,

    double similarityWeight = 0.5,

    double congestionWeight = 0.5,

  }){


    double congestionScore =
        calculateCongestionScore(
            congestion
        );



    return

        (similarity * similarityWeight)

            +

        (congestionScore * congestionWeight);

  }


}