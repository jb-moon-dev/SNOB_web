class Question {
  final String question;
  final List<Answer> answers;

  const Question({
    required this.question,
    required this.answers,
  });
}

class Answer {
  final String text;

  // 도시 성향
  final int city;
  final int nature;

  // 유명도
  final int famous;
  final int hidden;

  // 활동성
  final int active;
  final int healing;

  const Answer({
    required this.text,

    this.city = 0,
    this.nature = 0,

    this.famous = 0,
    this.hidden = 0,

    this.active = 0,
    this.healing = 0,
  });
}