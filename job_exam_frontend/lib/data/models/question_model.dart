class QuestionModel {
  final int id;
  final int examId;
  final String examTitle;
  final String positionTitle;
  final String questionText;
  final int questionMarks;
  final String? questionImageUrl;
  final List<ChoiceModel> choices;
  final int choiceCount;
  final String createdAt;

  QuestionModel({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.positionTitle,
    required this.questionText,
    required this.questionMarks,
    this.questionImageUrl,
    required this.choices,
    required this.choiceCount,
    required this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: int.parse(json['id'].toString()),
      examId: int.parse(json['exam_id'].toString()),
      examTitle: json['exam_title'] ?? '',
      positionTitle: json['position_title'] ?? '',
      questionText: json['question_text'] ?? '',
      questionMarks: int.parse((json['question_marks'] ?? '1').toString()),
      questionImageUrl: json['questionImageUrl'],
      choices: (json['choices'] as List<dynamic>?)
              ?.map((choice) => ChoiceModel.fromJson(choice))
              .toList() ??
          [],
      choiceCount: int.parse((json['choice_count'] ?? '0').toString()),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'exam_title': examTitle,
      'position_title': positionTitle,
      'question_text': questionText,
      'question_marks': questionMarks,
      'questionImageUrl': questionImageUrl,
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'choice_count': choiceCount,
      'created_at': createdAt,
    };
  }
}

class ChoiceModel {
  final int id;
  final String choiceText;
  final bool isCorrect;

  ChoiceModel({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
  });

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      id: int.parse(json['id'].toString()),
      choiceText: json['choice_text'] ?? '',
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choice_text': choiceText,
      'is_correct': isCorrect,
    };
  }
}
