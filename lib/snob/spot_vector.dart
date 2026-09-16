class SpotVector {

  final String spotName;

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
  // 100 = 혼잡
  final double congestion;



  const SpotVector({

    required this.spotName,

    required this.regionName,

    required this.nature,

    required this.hidden,

    required this.healing,

    required this.congestion,

  });



    @override
  String toString(){

    return """

===== Spot Vector =====

관광지 : $spotName

지역 : $regionName

🌿 자연 : ${nature.toStringAsFixed(1)}

🔍 숨은 : ${hidden.toStringAsFixed(1)}

🌙 힐링 : ${healing.toStringAsFixed(1)}

🚶 혼잡도 : ${congestion.toStringAsFixed(1)}

=======================

""";

  }
}