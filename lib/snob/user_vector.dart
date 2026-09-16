class UserVector {


  /// 자연 정도 (0~100)
  final double nature;


  /// 숨은 정도 (0~100)
  final double hidden;


  /// 힐링 정도 (0~100)
  final double healing;



  const UserVector({

    required this.nature,

    required this.hidden,

    required this.healing,

  });






  // =====================================
  // ScoreManager 점수 변환
  // =====================================

  factory UserVector.fromScore({


    required int cityScore,

    required int natureScore,


    required int famousScore,

    required int hiddenScore,


    required int activeScore,

    required int healingScore,


  }) {



    final natureTotal =
        cityScore + natureScore;



    final hiddenTotal =
        famousScore + hiddenScore;



    final healingTotal =
        activeScore + healingScore;






    return UserVector(



      nature:

      natureTotal == 0

          ? 50

          : (natureScore / natureTotal) * 100,





      hidden:

      hiddenTotal == 0

          ? 50

          : (hiddenScore / hiddenTotal) * 100,






      healing:

      healingTotal == 0

          ? 50

          : (healingScore / healingTotal) * 100,



    );

  }







  @override
  String toString(){


    return """

===== User Vector =====

🌿 자연 : $nature

🔍 숨은 : $hidden

🌙 힐링 : $healing

=======================

""";


  }


}