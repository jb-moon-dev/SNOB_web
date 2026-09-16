import 'tourism_spot.dart';
import 'spot_vector.dart';



class SpotVectorGenerator {



  static SpotVector generate(
      TourismSpot spot,
      ) {



    double nature = 50;
    double hidden = 50;
    double healing = 50;





    // ==========================
    // 🌿 자연 점수
    // ==========================


    final lcls1 =
        spot.lclsSystm1;


    final lcls2 =
        spot.lclsSystm2;


    final lcls3 =
        spot.lclsSystm3;





    // 자연 계열

    if(lcls1 == "NA") {

      nature += 30;

    }



    // 자연 세부

    if(
    lcls2.startsWith("NA01")
    ){

      nature += 20;

    }



    // 문화/역사 계열

    if(
    lcls1 == "HS"
    ){

      nature -= 10;

    }






    // ==========================
    // 🔍 숨은 점수
    // ==========================



    // 세부 코드가 구체적일수록 숨은 관광지 취급

    if(
    lcls3.isNotEmpty &&
        lcls3.endsWith("00")
    ){

      hidden += 10;

    }





    final title =
        spot.title;





    if(
    title.contains("공원") ||
        title.contains("산") ||
        title.contains("숲") ||
        title.contains("계곡") ||
        title.contains("길")
    ){

      hidden += 10;

    }







    // ==========================
    // 🌙 힐링 점수
    // ==========================



    if(
    title.contains("온천") ||
        title.contains("휴양") ||
        title.contains("힐링") ||
        title.contains("치유") ||
        title.contains("정원")
    ){

      healing += 30;

    }





    // 체험/레포츠 계열

    if(
    lcls1 == "VE"
    ){

      healing -= 10;

    }






    // ==========================
    // 범위 제한
    // ==========================


    nature =
        nature.clamp(0,100);


    hidden =
        hidden.clamp(0,100);


    healing =
        healing.clamp(0,100);







    return SpotVector(


      spotName:
      spot.title,


      regionName:
      spot.address,



      nature:
      nature,



      hidden:
      hidden,



      healing:
      healing,



      congestion:
      50,

    );


  }


}