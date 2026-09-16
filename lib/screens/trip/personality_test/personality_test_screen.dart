import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'questions.dart';
import 'question_model.dart';
import 'score_manager.dart';

import 'type_matcher.dart';
import 'result_data.dart';
import 'result_screen.dart';

import 'package:snob/snob/user_vector.dart';
import 'package:snob/snob/recommendation_engine.dart';
import 'package:snob/snob/region_vector.dart';

// 현재 여행 성향 저장
import '../../../services/personality_storage.dart';

class PersonalityTestScreen extends StatefulWidget {
  const PersonalityTestScreen({super.key});

  @override
  State<PersonalityTestScreen> createState() =>
      _PersonalityTestScreenState();
}

class _PersonalityTestScreenState
    extends State<PersonalityTestScreen> {
  int currentQuestion = 0;

  final ScoreManager scoreManager = ScoreManager();

  late List<Question> shuffledQuestions;

  late List<Answer> shuffledAnswers;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // 질문 준비
    // ============================================================

    shuffledQuestions = List<Question>.from(questions);

    // ============================================================
    // 첫 번째 질문의 답변 랜덤 섞기
    // ============================================================

    shuffledAnswers = List<Answer>.from(
      shuffledQuestions[currentQuestion].answers,
    )..shuffle(Random());
  }

  // ============================================================
  // 다음 질문
  // ============================================================

  void nextQuestion() {
    setState(() {
      currentQuestion++;

      shuffledAnswers = List<Answer>.from(
        shuffledQuestions[currentQuestion].answers,
      )..shuffle(Random());
    });
  }

  // ============================================================
  // 지역 데이터 불러오기
  // ============================================================
  //
  // region_vectors_canonical.json에는
  // snob_concentration.json의 canonical 210개 지역 중
  // 실제 성향 벡터가 존재하는 207개 지역만 들어 있다.
  //
  // 따라서 추천 후보는 처음부터
  // canonical 지역과 실제 성향 벡터가 모두 존재하는
  // 지역으로 제한한다.
  // ============================================================

  Future<List<RegionVector>> loadRegions() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/region_vectors_canonical.json',
    );

    final List<dynamic> jsonData =
        json.decode(jsonString);

    return jsonData
        .map(
          (json) => RegionVector.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // 테스트 완료
  // ============================================================

  Future<void> finishTest() async {
    try {
      // ==========================================================
      // 1. 27개 유형 key 생성
      // ==========================================================

      final type = TypeMatcher.match(
        city: scoreManager.city,
        nature: scoreManager.nature,
        famous: scoreManager.famous,
        hidden: scoreManager.hidden,
        active: scoreManager.active,
        healing: scoreManager.healing,
      );

      // ==========================================================
      // 2. 유형 데이터
      // ==========================================================

      final result =
          ResultRepository.getResult(type);

      // ==========================================================
      // 3. 사용자 성향 벡터 생성
      // ==========================================================

      final userVector =
          UserVector.fromScore(
        cityScore: scoreManager.city,
        natureScore: scoreManager.nature,
        famousScore: scoreManager.famous,
        hiddenScore: scoreManager.hidden,
        activeScore: scoreManager.active,
        healingScore: scoreManager.healing,
      );

      // ==========================================================
      // 4. 지역 데이터 불러오기
      //
      // region_vectors_canonical.json에는
      // canonical 210개 지역 중 실제 성향 벡터가 존재하는
      // 207개 지역만 들어 있다.
      //
      // 따라서 성향 벡터가 없는
      // 인천광역시 동구
      // 인천광역시 서구
      // 인천광역시 중구
      //
      // 3개 지역은 추천 후보에서 제외된다.
      // ==========================================================

      final regions = await loadRegions();

      if (regions.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '추천 가능한 지역 데이터가 없습니다.',
            ),
          ),
        );

        return;
      }

      // ==========================================================
      // 5. 지역 추천
      //
      // recommendRandomRegion()은 Future를 반환하므로
      // 반드시 await한다.
      //
      // RecommendationEngine에서
      // snob_concentration.json의 canonical 210개 지역과
      // 한 번 더 비교하여 최종 추천 지역을 검증한다.
      // ==========================================================

      final recommendedRegion =
          await RecommendationEngine
              .recommendRandomRegion(
        userVector,
        regions,
      );

      // ==========================================================
      // 6. 현재 여행 성향 저장
      //
      // recommendedRegion.regionName은
      // canonical 210개 중 하나이며,
      // 동시에 region_vectors_canonical.json에도
      // 존재하는 지역이다.
      // ==========================================================

      await PersonalityStorage.savePersonality(
        personalityType: result.title,
        recommendedRegion:
            recommendedRegion.regionName,
      );

      // ==========================================================
      // 7. 결과 화면으로 이동
      // ==========================================================

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            personalityType: result.title,
            recommendedRegion:
                recommendedRegion.regionName,
          ),
        ),
      );
    } catch (e, stackTrace) {
      // ==========================================================
      // 추천 과정에서 오류가 발생한 경우
      //
      // 앱이 그대로 죽지 않고 사용자에게 메시지를 보여준다.
      // ==========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint('여행 지역 추천 오류');
      debugPrint(
        '==========================================',
      );
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '여행 지역을 추천하지 못했습니다.\n$e',
          ),
          duration:
              const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Question question =
        shuffledQuestions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '여행 성향 테스트',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ======================================================
            // 진행도
            // ======================================================

            Text(
              '${currentQuestion + 1} / '
              '${shuffledQuestions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // ======================================================
            // 질문
            // ======================================================

            Text(
              question.question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // ======================================================
            // 답변
            // ======================================================

            Column(
              children:
                  shuffledAnswers.map((answer) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 15,
                  ),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () {
                        // ------------------------------------------
                        // 선택한 답변 점수 추가
                        // ------------------------------------------

                        scoreManager.addScore(
                          answer,
                        );

                        // ------------------------------------------
                        // 마지막 질문인지 확인
                        // ------------------------------------------

                        if (currentQuestion ==
                            shuffledQuestions
                                    .length -
                                1) {
                          // 마지막 질문이면
                          // 결과 계산
                          finishTest();
                        } else {
                          // 다음 질문
                          nextQuestion();
                        }
                      },

                      child: Text(
                        answer.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
