enum QuestionType { multipleChoice, trueFalse, openEnded }

class QuestionModel {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer; // For MC/TF it is the option text, for Open Ended it is matching criteria or empty.
  final String? audioPath; // local file path for audio clip questions
  final String? imagePath; // local file path for image/meme questions
  final int points;
  final int timeLimitSeconds;
  final String category; // e.g. "Matematika", "IPA" — for the question bank
  final String difficulty; // "Mudah" | "Sedang" | "Sulit"
  final String? imageUrl;
  final String? audioUrl;
  final String? memeUrl;

  QuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.audioPath,
    this.imagePath,
    this.points = 100,
    this.timeLimitSeconds = 30,
    this.category = 'Umum',
    this.difficulty = 'Sedang',
    this.imageUrl,
    this.audioUrl,
    this.memeUrl,
  });

  QuestionModel copyWith({
    String? id,
    String? text,
    QuestionType? type,
    List<String>? options,
    String? correctAnswer,
    String? audioPath,
    String? imagePath,
    int? points,
    int? timeLimitSeconds,
    String? category,
    String? difficulty,
    String? imageUrl,
    String? audioUrl,
    String? memeUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      audioPath: audioPath ?? this.audioPath,
      imagePath: imagePath ?? this.imagePath,
      points: points ?? this.points,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      memeUrl: memeUrl ?? this.memeUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'options': options.join('|||'),
      'correctAnswer': correctAnswer,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'points': points,
      'timeLimitSeconds': timeLimitSeconds,
      'category': category,
      'difficulty': difficulty,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'meme_url': memeUrl,
    };
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.byName(json['type'] as String),
      options: (json['options'] as String?)?.split('|||') ?? [],
      correctAnswer: json['correctAnswer'] as String,
      audioPath: json['audioPath'] as String?,
      imagePath: json['imagePath'] as String?,
      points: json['points'] as int? ?? 100,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 30,
      category: json['category'] as String? ?? 'Semua',
      difficulty: json['difficulty'] as String? ?? 'Sedang',
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      memeUrl: json['meme_url'] as String?,
    );
  }
}

