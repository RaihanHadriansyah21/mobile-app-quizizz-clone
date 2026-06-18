import 'dart:convert';

class AttemptModel {
  final String id;
  final String studentId;
  final String studentName;
  final String quizId;
  final String? classId;
  final int score;
  final int totalQuestions;
  final int correctAnswersCount;
  final DateTime completedAt;
  final Map<String, String> answers; // questionId -> chosenAnswer
  final int fastestCorrectSeconds; // fastest correct answer in seconds (9999 = none/untimed)
  final int powerUpsUsed; // number of power-ups used during this attempt
  final int timeTaken; // total time taken in seconds to complete the quiz

  AttemptModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.quizId,
    this.classId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswersCount,
    required this.completedAt,
    required this.answers,
    this.fastestCorrectSeconds = 9999,
    this.powerUpsUsed = 0,
    this.timeTaken = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'attempt_id': id,
      'user_id': studentId,
      'student_name': studentName,
      'quiz_id': quizId,
      'class_id': classId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswersCount,
      'submitted_at': completedAt.toIso8601String(),
      'answers': answers,
      'fastest_correct_seconds': fastestCorrectSeconds,
      'power_ups_used': powerUpsUsed,
      'time_taken': timeTaken,
    };
  }

  factory AttemptModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedAnswers = {};
    if (json['answers'] != null) {
      var rawAnswers = json['answers'];
      Map<String, dynamic> decoded;
      if (rawAnswers is String) {
        decoded = jsonDecode(rawAnswers) as Map<String, dynamic>;
      } else if (rawAnswers is Map) {
        decoded = Map<String, dynamic>.from(rawAnswers);
      } else {
        decoded = {};
      }
      decoded.forEach((key, value) {
        parsedAnswers[key] = value.toString();
      });
    }

    return AttemptModel(
      id: (json['attempt_id'] ?? json['id']) as String,
      studentId: (json['user_id'] ?? json['studentId']) as String,
      studentName: (json['student_name'] ?? json['studentName']) as String,
      quizId: (json['quiz_id'] ?? json['quizId']) as String,
      classId: (json['class_id'] ?? json['classId']) as String?,
      score: json['score'] as int,
      totalQuestions: (json['total_questions'] ?? json['totalQuestions']) as int,
      correctAnswersCount: (json['correct_answers'] ?? json['correctAnswersCount']) as int,
      completedAt: DateTime.parse((json['submitted_at'] ?? json['completedAt']) as String),
      answers: parsedAnswers,
      fastestCorrectSeconds: (json['fastest_correct_seconds'] ?? json['fastestCorrectSeconds']) as int? ?? 9999,
      powerUpsUsed: (json['power_ups_used'] ?? json['powerUpsUsed']) as int? ?? 0,
      timeTaken: (json['time_taken'] ?? json['timeTaken']) as int? ?? 0,
    );
  }
}
