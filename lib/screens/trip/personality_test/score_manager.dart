import 'question_model.dart';
import '../../../snob/user_vector.dart';



class ScoreManager {


  // =========================
  // 도시 ↔ 자연
  // =========================

  int city = 0;
  int nature = 0;



  // =========================
  // 유명 ↔ 숨은
  // =========================

  int famous = 0;
  int hidden = 0;



  // =========================
  // 활동 ↔ 힐링
  // =========================

  int active = 0;
  int healing = 0;





  // =========================
  // 점수 추가
  // =========================

  void addScore(
    Answer answer,
  ) {


    city += answer.city;
    nature += answer.nature;


    famous += answer.famous;
    hidden += answer.hidden;


    active += answer.active;
    healing += answer.healing;


  }







  // =========================
  // 테스트 초기화
  // =========================

  void reset(){

    city = 0;
    nature = 0;


    famous = 0;
    hidden = 0;


    active = 0;
    healing = 0;


  }







  // =========================
  // 추천 시스템용 Vector 변환
  // =========================

  UserVector getUserVector(){



    return UserVector.fromScore(


      cityScore: city,

      natureScore: nature,



      famousScore: famous,

      hiddenScore: hidden,



      activeScore: active,

      healingScore: healing,


    );


  }







  // =========================
  // 디버깅용
  // =========================

  void printScore(){


    print("===== User Score =====");


    print(
      "🌆 도시 : $city"
    );


    print(
      "🌿 자연 : $nature"
    );


    print(
      "⭐ 유명 : $famous"
    );


    print(
      "🔍 숨은 : $hidden"
    );


    print(
      "🔥 활동 : $active"
    );


    print(
      "🌙 힐링 : $healing"
    );


    print("=====================");


  }


}