import 'user_vector.dart';
import 'region_vector.dart';
import 'snob_score.dart';



class SnobService {



  // =================================
  // 최종 추천 지역
  // =================================

  static List<RegionVector> recommendRegions({

    required UserVector user,

    required List<RegionVector> regions,

  }){


    if(regions.isEmpty){

      return [];

    }



    List<Map<String,dynamic>> results = [];





    for(var region in regions){



      // 성향 유사도

      double similarity =

      SnobScore.calculateSimilarity(

        user,

        region,

      );





      // 최종 SNOB 점수

      double score =

      SnobScore.calculateSnobScore(

        similarity: similarity,

        congestion: region.congestion,

      );





      results.add({

        "region": region,

        "score": score,

      });



    }





    // 높은 점수 순 정렬

    results.sort(

          (a,b) =>

          b["score"]

              .compareTo(

              a["score"]

          ),

    );







    // 상위 3개 반환

    return results

        .take(3)

        .map(

            (e)=>

        e["region"] as RegionVector

    )

        .toList();



  }



}