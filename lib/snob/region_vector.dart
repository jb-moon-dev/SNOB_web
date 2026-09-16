class RegionVector {


  // 지역명
  final String regionName;



  // 🌆 도시 ↔ 🌿 자연
  // 0 = 도시
  // 100 = 자연
  final double nature;



  // ⭐ 유명 ↔ 🔍 숨은
  // 0 = 유명
  // 100 = 숨은
  final double hidden;



  // ⚡ 활동 ↔ 🌙 힐링
  // 0 = 활동
  // 100 = 힐링
  final double healing;



  // 혼잡도
  // 0 = 한산
  // 100 = 매우 혼잡
  final double congestion;




  const RegionVector({

    required this.regionName,

    required this.nature,

    required this.hidden,

    required this.healing,

    required this.congestion,

  });





  factory RegionVector.fromJson(

      Map<String, dynamic> json

      ){

    return RegionVector(

      regionName: json['regionName'],

      nature:
      (json['nature'] as num)
          .toDouble(),

      hidden:
      (json['hidden'] as num)
          .toDouble(),

      healing:
      (json['healing'] as num)
          .toDouble(),

      congestion:
      (json['congestion'] as num)
          .toDouble(),

    );

  }





  Map<String, dynamic> toJson(){


    return {

      "regionName": regionName,

      "nature": nature,

      "hidden": hidden,

      "healing": healing,

      "congestion": congestion,

    };

  }





  @override
  String toString(){


    return """

===== Region Vector =====

지역 : $regionName

🌿 자연 : ${nature.toStringAsFixed(1)}

🔍 숨은 : ${hidden.toStringAsFixed(1)}

🌙 힐링 : ${healing.toStringAsFixed(1)}

🚶 혼잡도 : ${congestion.toStringAsFixed(1)}

""";


  }


}