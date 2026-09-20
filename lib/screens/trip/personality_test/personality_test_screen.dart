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
  // ============================================================
  // 기존 테스트 상태
  // ============================================================

  int currentQuestion = 0;

  final ScoreManager scoreManager = ScoreManager();

  late List<Question> shuffledQuestions;

  late List<Answer> shuffledAnswers;

  // ============================================================
  // SNOB Web 디자인
  // ============================================================

  static const Color snobGreen =
      Color(0xFF5B8C68);

  static const Color backgroundColor =
      Color(0xFFF6F7F3);

  static const Color textColor =
      Color(0xFF1F2A24);

  @override
  void initState() {
    super.initState();

    // ============================================================
    // 기존 질문 준비
    // ============================================================

    shuffledQuestions =
        List<Question>.from(questions);

    // ============================================================
    // 기존 첫 번째 질문 답변 랜덤 섞기
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
  // 기존 로직 그대로 유지
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
      // ==========================================================

      final recommendedRegion =
          await RecommendationEngine
              .recommendRandomRegion(
        userVector,
        regions,
      );

      // ==========================================================
      // 6. 현재 여행 성향 저장
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
      // 기존 오류 처리 그대로 유지
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
  // 답변 선택
  //
  // 점수 계산 및 기존 질문 진행 로직 그대로 유지
  // ============================================================

  void selectAnswer(Answer answer) {
    // ------------------------------------------------------------
    // 기존 점수 추가
    // ------------------------------------------------------------

    scoreManager.addScore(answer);

    // ------------------------------------------------------------
    // 기존 마지막 질문 확인
    // ------------------------------------------------------------

    if (currentQuestion ==
        shuffledQuestions.length - 1) {
      // 마지막 질문이면 기존 결과 계산
      finishTest();
    } else {
      // 다음 질문
      nextQuestion();
    }
  }

  // ============================================================
  // 웹 헤더
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
            child: Row(
              children: [
                // ------------------------------------------------
                // SNOB 로고
                // ------------------------------------------------

                const Text(
                  'SNOB',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: snobGreen,
                  ),
                ),

                const Spacer(),

                // ------------------------------------------------
                // 테스트 표시
                // ------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                        backgroundColor,
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'TRAVEL TEST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 1.2,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 진행률 영역
  // ============================================================

  Widget _buildProgressSection() {
    final total =
        shuffledQuestions.length;

    final progress =
        (currentQuestion + 1) / total;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TRAVEL PERSONALITY TEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),

            const Spacer(),

            Text(
              '${currentQuestion + 1} / $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor:
                Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<
                    Color>(
              snobGreen,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 질문 영역
  // ============================================================

  Widget _buildQuestion(
    Question question,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Q${currentQuestion + 1}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: snobGreen,
          ),
        ),

        const SizedBox(height: 18),

        Text(
          question.question,
          style: const TextStyle(
            fontSize: 32,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          '나에게 더 가까운 여행 방식을 선택해주세요.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 답변 카드
  // ============================================================

  Widget _buildAnswerCard(
    Answer answer,
    int index,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          selectAnswer(answer);
        },
        child: Ink(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.035),
                blurRadius: 15,
                offset:
                    const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // --------------------------------------------------
              // 선택지 번호
              // --------------------------------------------------

              Container(
                width: 38,
                height: 38,
                alignment:
                    Alignment.center,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // --------------------------------------------------
              // 답변 텍스트
              // --------------------------------------------------

              Expanded(
                child: Text(
                  answer.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // --------------------------------------------------
              // 화살표
              // --------------------------------------------------

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 테스트 카드
  // ============================================================

  Widget _buildTestCard(
    Question question,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.045),
            blurRadius: 35,
            offset:
                const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // 진행률
          // ------------------------------------------------------

          _buildProgressSection(),

          const SizedBox(height: 46),

          // ------------------------------------------------------
          // 질문
          // ------------------------------------------------------

          _buildQuestion(question),

          const SizedBox(height: 40),

          // ------------------------------------------------------
          // 답변
          // ------------------------------------------------------

          Column(
            children:
                shuffledAnswers
                    .asMap()
                    .entries
                    .map(
                      (entry) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _buildAnswerCard(
                            entry.value,
                            entry.key,
                          ),
                        );
                      },
                    )
                    .toList(),
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // 하단 안내
          // ------------------------------------------------------

          Center(
            child: Text(
              '선택하면 다음 질문으로 이동합니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Question question =
        shuffledQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // 웹 헤더
            // ======================================================

            _buildHeader(),

            // ======================================================
            // 본문
            // ======================================================

            Expanded(
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final isMobile =
                      constraints.maxWidth < 700;

                  final horizontalPadding =
                      isMobile ? 18.0 : 32.0;

                  final verticalPadding =
                      isMobile ? 24.0 : 48.0;

                  return SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal:
                          horizontalPadding,
                      vertical:
                          verticalPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 760,
                        ),
                        child: _buildTestCard(
                          question,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}