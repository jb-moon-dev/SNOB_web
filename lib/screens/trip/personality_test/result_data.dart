class ResultData {
  final String title;
  final String description;
  final String keyword;

  const ResultData({
    required this.title,
    required this.description,
    required this.keyword,
  });
}


class ResultRepository {

  static final Map<String, ResultData> results = {

    // =========================
    // 🌿 자연 중심 그룹
    // =========================

    "nature_hidden_healing": ResultData(
      title: "🍃 숲속 은둔 여행자",
      description: "아무도 모르는 조용한 곳에서 나만의 시간을 찾는 여행자",
      keyword: "자연 · 숨은 · 힐링",
    ),

    "nature_hidden_balance": ResultData(
      title: "🌱 비밀 정원 탐험가",
      description: "숨겨진 풍경과 작은 발견을 좋아하는 여행자",
      keyword: "자연 · 숨은 · 균형",
    ),

    "nature_hidden_active": ResultData(
      title: "🥾 오지 보물 사냥꾼",
      description: "지도 밖 새로운 장소를 찾아 떠나는 탐험가",
      keyword: "자연 · 숨은 · 활동",
    ),


    "nature_balance_healing": ResultData(
      title: "🌿 초록빛 휴식러",
      description: "자연 속에서 에너지를 충전하는 여행자",
      keyword: "자연 · 보통 · 힐링",
    ),

    "nature_balance_balance": ResultData(
      title: "🏕️ 느긋한 자연 탐방가",
      description: "풍경도 즐기고 가벼운 경험도 즐기는 여행자",
      keyword: "자연 · 보통 · 균형",
    ),

    "nature_balance_active": ResultData(
      title: "⛰️ 자연 액티비티 메이트",
      description: "자연 속 새로운 경험을 찾는 여행자",
      keyword: "자연 · 보통 · 활동",
    ),


    "nature_famous_healing": ResultData(
      title: "🌅 명소 속 힐링러",
      description: "유명한 풍경 속에서도 여유를 찾는 여행자",
      keyword: "자연 · 유명 · 힐링",
    ),

    "nature_famous_balance": ResultData(
      title: "🏞️ 풍경 수집가",
      description: "꼭 봐야 할 자연 명소를 찾아다니는 여행자",
      keyword: "자연 · 유명 · 균형",
    ),

    "nature_famous_active": ResultData(
      title: "🚵 랜드마크 어드벤처러",
      description: "자연 명소를 정복하는 여행자",
      keyword: "자연 · 유명 · 활동",
    ),


    // =========================
    // 🌆 도시 중심 그룹
    // =========================

    "city_hidden_healing": ResultData(
      title: "☕ 골목 감성 수집가",
      description: "조용한 카페와 작은 공간을 사랑하는 여행자",
      keyword: "도시 · 숨은 · 힐링",
    ),

    "city_hidden_balance": ResultData(
      title: "🏙️ 로컬 발견자",
      description: "도시 속 숨은 매력을 찾는 여행자",
      keyword: "도시 · 숨은 · 균형",
    ),

    "city_hidden_active": ResultData(
      title: "🔎 도시 보물 탐험가",
      description: "유명하지 않은 도시 경험을 찾아다니는 여행자",
      keyword: "도시 · 숨은 · 활동",
    ),


    "city_balance_healing": ResultData(
      title: "🌙 도시 느린 여행자",
      description: "도시에서도 여유를 즐기는 여행자",
      keyword: "도시 · 보통 · 힐링",
    ),

    "city_balance_balance": ResultData(
      title: "🎒 취향 밸런서",
      description: "어느 곳에서도 자신만의 재미를 찾는 여행자",
      keyword: "도시 · 보통 · 균형",
    ),

    "city_balance_active": ResultData(
      title: "🚶 도시 플레이어",
      description: "거리 곳곳을 경험하는 여행자",
      keyword: "도시 · 보통 · 활동",
    ),


    "city_famous_healing": ResultData(
      title: "🪟 감성 도시 산책러",
      description: "유명한 도시 속 여유로운 순간을 찾는 여행자",
      keyword: "도시 · 유명 · 힐링",
    ),

    "city_famous_balance": ResultData(
      title: "🌃 도시 큐레이터",
      description: "도시의 대표 매력을 골라 즐기는 여행자",
      keyword: "도시 · 유명 · 균형",
    ),

    "city_famous_active": ResultData(
      title: "🔥 핫플 콜렉터",
      description: "가장 뜨거운 장소를 빠르게 경험하는 여행자",
      keyword: "도시 · 유명 · 활동",
    ),


    // =========================
    // ⚖️ 균형형 그룹
    // =========================

    "balance_hidden_healing": ResultData(
      title: "🌾 쉼표 여행자",
      description: "조용한 발견과 휴식을 원하는 여행자",
      keyword: "균형 · 숨은 · 힐링",
    ),

    "balance_hidden_balance": ResultData(
      title: "🗺️ 취향 탐험가",
      description: "새로운 곳과 익숙한 곳 사이를 즐기는 여행자",
      keyword: "균형 · 숨은 · 균형",
    ),

    "balance_hidden_active": ResultData(
      title: "🧭 발견 모험가",
      description: "예상하지 못한 경험을 좋아하는 여행자",
      keyword: "균형 · 숨은 · 활동",
    ),

    "balance_balance_healing": ResultData(
      title: "☁️ 느린 여행자",
      description: "여행에서도 나만의 속도를 지키는 여행자",
      keyword: "균형 · 보통 · 힐링",
    ),

    "balance_balance_balance": ResultData(
      title: "✨ 자유로운 여행자",
      description: "어떤 여행이든 자연스럽게 즐기는 타입",
      keyword: "균형 · 보통 · 균형",
    ),

    "balance_balance_active": ResultData(
      title: "🎒 경험 수집가",
      description: "다양한 순간을 모으는 여행자",
      keyword: "균형 · 보통 · 활동",
    ),

    "balance_famous_healing": ResultData(
      title: "🌸 감성 명소 여행자",
      description: "유명한 장소에서도 특별한 순간을 찾는 여행자",
      keyword: "균형 · 유명 · 힐링",
    ),

    "balance_famous_balance": ResultData(
      title: "📸 여행 큐레이터",
      description: "좋은 장소를 골라 즐기는 여행자",
      keyword: "균형 · 유명 · 균형",
    ),

    "balance_famous_active": ResultData(
      title: "🌍 여행 정복자",
      description: "새로운 장소를 최대한 많이 경험하는 여행자",
      keyword: "균형 · 유명 · 활동",
    ),

  };


  static ResultData getResult(String key) {
    return results[key] ??
        const ResultData(
          title: "알 수 없는 여행자",
          description: "당신의 여행 성향을 분석할 수 없습니다.",
          keyword: "",
        );
  }
}