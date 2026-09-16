import 'question_model.dart';

const List<Question> questions = [

  // Q1
  Question(
    question: "🌅 08:00 AM\n\n오늘 하루를 시작하고 싶은 풍경은?",
    answers: [
      Answer(
        text: "높은 건물 사이로 햇살이 들어오는 도시의 아침",
        city: 2,
      ),
      Answer(
        text: "오래된 골목길과 작은 가게들이 있는 동네",
        city: 1,
        hidden: 2,
      ),
      Answer(
        text: "창밖으로 바다와 산이 보이고 새소리가 들린다",
        nature: 2,
        healing: 1,
      ),
      Answer(
        text: "아무 소리도 들리지 않는 숲속 숙소",
        nature: 2,
        healing: 2,
      ),
    ],
  ),

  // Q2
  Question(
    question: "☕ 10:00 AM\n\n가장 먼저 눈에 들어오는 장소는?",
    answers: [
      Answer(
        text: "이 지역에 왔다면 반드시 가야 하는 대표 명소",
        famous: 2,
        active: 1,
      ),
      Answer(
        text: "현지인만 아는 숨겨진 카페와 골목",
        hidden: 2,
        city: 1,
      ),
      Answer(
        text: "아직 많이 알려지지 않은 자연 속 특별한 장소",
        nature: 1,
        hidden: 2,
      ),
      Answer(
        text: "풍경이 좋은 조용한 장소",
        nature: 2,
        healing: 1,
      ),
    ],
  ),

  // Q3
  Question(
    question: "🥐 12:00 PM\n\n어떤 점심이 가장 끌리는가?",
    answers: [
      Answer(
        text: "지역 대표 맛집",
        famous: 2,
        active: 1,
      ),
      Answer(
        text: "골목 안 작은 식당",
        hidden: 2,
      ),
      Answer(
        text: "풍경을 보며 천천히 즐기는 식사",
        nature: 1,
        healing: 2,
      ),
      Answer(
        text: "새로운 음식과 문화에 도전",
        active: 2,
      ),
    ],
  ),

  // Q4
  Question(
    question: "🚶 14:00 PM\n\n3시간의 자유 시간이 생긴다면?",
    answers: [
      Answer(
        text: "도시 곳곳을 돌아다닌다",
        city: 2,
        active: 2,
      ),
      Answer(
        text: "현지인이 추천하는 작은 마을과 시장",
        hidden: 2,
        active: 1,
      ),
      Answer(
        text: "바다·산·숲을 천천히 걷는다",
        nature: 2,
        healing: 2,
      ),
      Answer(
        text: "유명 관광지 체험 프로그램",
        famous: 2,
        active: 2,
      ),
    ],
  ),

  // Q5
  Question(
    question: "📸 16:00 PM\n\n가장 남기고 싶은 사진은?",
    answers: [
      Answer(
        text: "활기찬 도시 풍경",
        city: 2,
      ),
      Answer(
        text: "나만 알고 싶은 작은 장소",
        hidden: 2,
      ),
      Answer(
        text: "대표 명소 인증샷",
        famous: 2,
      ),
      Answer(
        text: "아무도 없는 자연",
        nature: 2,
        healing: 1,
      ),
    ],
  ),

  // Q6
  Question(
    question: "🌧 17:00 PM\n\n방문하려던 장소가 너무 붐빈다면?",
    answers: [
      Answer(
        text: "그래도 유명한 장소를 즐긴다",
        famous: 2,
      ),
      Answer(
        text: "사람 없는 새로운 장소를 찾아간다",
        hidden: 2,
        active: 1,
      ),
      Answer(
        text: "조용한 자연으로 이동한다",
        nature: 2,
      ),
      Answer(
        text: "카페나 숙소에서 쉰다",
        healing: 2,
      ),
    ],
  ),

  // Q7
  Question(
    question: "🌇 19:00 PM\n\n가장 행복한 저녁은?",
    answers: [
      Answer(
        text: "활기찬 거리와 맛집",
        city: 2,
        active: 1,
      ),
      Answer(
        text: "현지인 식당",
        hidden: 2,
      ),
      Answer(
        text: "노을이 보이는 자연",
        nature: 2,
        healing: 2,
      ),
      Answer(
        text: "유명 야경 명소",
        famous: 2,
      ),
    ],
  ),

  // Q8
  Question(
    question: "🌌 21:00 PM\n\n마지막 모험의 기회가 생긴다면?",
    answers: [
      Answer(
        text: "유명 장소를 하나 더 간다",
        famous: 2,
        active: 1,
      ),
      Answer(
        text: "지도에 없는 길을 걸어본다",
        hidden: 2,
      ),
      Answer(
        text: "조용한 밤 풍경을 바라본다",
        nature: 1,
        healing: 2,
      ),
      Answer(
        text: "새로운 사람들과 어울린다",
        city: 2,
        active: 2,
      ),
    ],
  ),

  // Q9
  Question(
    question: "🌙 23:00 PM\n\n오늘 가장 만족스러운 순간은?",
    answers: [
      Answer(
        text: "많은 것을 보고 경험했다",
        active: 2,
      ),
      Answer(
        text: "나만의 장소를 발견했다",
        hidden: 2,
      ),
      Answer(
        text: "일상에서 벗어나 쉬었다",
        healing: 2,
      ),
      Answer(
        text: "대표적인 장소를 경험했다",
        famous: 2,
      ),
    ],
  ),

  // Q10
  Question(
    question: "⭐ 24:00 AM\n\n오늘 하루가 영화였다면?",
    answers: [
      Answer(
        text: "도시의 새로운 장면을 찾아서",
        city: 2,
        active: 1,
      ),
      Answer(
        text: "아무도 몰랐던 나만의 발견",
        hidden: 2,
      ),
      Answer(
        text: "자연 속에서 다시 찾은 나",
        nature: 2,
        healing: 2,
      ),
      Answer(
        text: "꼭 한번 만나고 싶었던 장소와의 만남",
        famous: 2,
      ),
    ],
  ),
];