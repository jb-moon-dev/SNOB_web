class TypeMatcher {


  static String match({
    required int city,
    required int nature,

    required int famous,
    required int hidden,

    required int active,
    required int healing,
  }) {


    String location =
        _matchLocation(city, nature);


    String place =
        _matchPlace(famous, hidden);


    String style =
        _matchStyle(active, healing);



    return "${location}_${place}_$style";

  }



  // =========================
  // 도시 ↔ 자연
  // =========================

  static String _matchLocation(
      int city,
      int nature,
      ) {


    int total = city + nature;


    if(total == 0){

      return "balance";

    }



    double natureRatio =
        nature / total;



    if(natureRatio < 0.333){

      return "city";

    }

    else if(natureRatio < 0.666){

      return "balance";

    }

    else{

      return "nature";

    }

  }





  // =========================
  // 유명 ↔ 숨은
  // =========================

  static String _matchPlace(
      int famous,
      int hidden,
      ) {


    int total =
        famous + hidden;



    if(total == 0){

      return "balance";

    }



    double hiddenRatio =
        hidden / total;



    if(hiddenRatio < 0.333){

      return "famous";

    }

    else if(hiddenRatio < 0.666){

      return "balance";

    }

    else{

      return "hidden";

    }

  }





  // =========================
  // 활동 ↔ 힐링
  // =========================

  static String _matchStyle(
    int active,
    int healing,
  ) {

    int total = active + healing;


    if(total == 0){
      return "balance";
    }


    double activeRatio = active / total;


    if(activeRatio < 0.333){

      return "healing";

    }
    else if(activeRatio < 0.666){

      return "balance";

    }
    else{

      return "active";

    }

  }


}