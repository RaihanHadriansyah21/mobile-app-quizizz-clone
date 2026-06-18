import 'dart:convert';
import 'question_model.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final String creatorId;
  final bool isHomework;
  final DateTime? deadline;
  final bool isTimerEnabled;
  final List<String> allowedPowerUps;
  final int maxAttempts; // 0 means unlimited

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.creatorId,
    this.isHomework = false,
    this.deadline,
    this.isTimerEnabled = true,
    this.allowedPowerUps = const [
      'double_score',
      'freeze_timer',
      'fifty_fifty',
      'second_chance',
    ],
    this.maxAttempts = 0,
  });

  QuizModel copyWith({
    String? title,
    String? description,
    List<QuestionModel>? questions,
    bool? isHomework,
    DateTime? deadline,
    bool? isTimerEnabled,
    List<String>? allowedPowerUps,
    int? maxAttempts,
  }) {
    return QuizModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      creatorId: creatorId,
      isHomework: isHomework ?? this.isHomework,
      deadline: deadline ?? this.deadline,
      isTimerEnabled: isTimerEnabled ?? this.isTimerEnabled,
      allowedPowerUps: allowedPowerUps ?? this.allowedPowerUps,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'creatorId': creatorId,
      'isHomework': isHomework,
      'deadline': deadline?.toIso8601String(),
      'isTimerEnabled': isTimerEnabled,
      'allowedPowerUps': allowedPowerUps.join(','),
      'maxAttempts': maxAttempts,
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'];
    List decodedQuestions;
    if (rawQuestions is String) {
      decodedQuestions = jsonDecode(rawQuestions) as List;
    } else if (rawQuestions is List) {
      decodedQuestions = rawQuestions;
    } else {
      decodedQuestions = [];
    }

    List<QuestionModel> questionsList = decodedQuestions
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();

    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: questionsList,
      creatorId: json['creatorId'] as String,
      isHomework: json['isHomework'] == true || (json['isHomework'] ?? 0) == 1,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isTimerEnabled: json['isTimerEnabled'] == true || (json['isTimerEnabled'] ?? 0) == 1,
      allowedPowerUps:
          (json['allowedPowerUps'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      maxAttempts: json['maxAttempts'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
