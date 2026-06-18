class ClassModel {
  final String id;
  final String className;
  final String code; // 6-digit join code, e.g. "489201"
  final String teacherId; // Maps to Dosen
  final List<String> studentIds; // Maps to Mahasiswa
  final List<String> quizIds; // Assigned quiz IDs

  ClassModel({
    required this.id,
    required this.className,
    required this.code,
    required this.teacherId,
    this.studentIds = const [],
    this.quizIds = const [],
  });

  ClassModel copyWith({
    String? className,
    List<String>? studentIds,
    List<String>? quizIds,
  }) {
    return ClassModel(
      id: id,
      className: className ?? this.className,
      code: code,
      teacherId: teacherId,
      studentIds: studentIds ?? this.studentIds,
      quizIds: quizIds ?? this.quizIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'code': code,
      'teacherId': teacherId,
      'studentIds': studentIds.join(','),
      'quizIds': quizIds.join(','),
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      className: json['className'] as String,
      code: json['code'] as String,
      teacherId: json['teacherId'] as String,
      studentIds:
          (json['studentIds'] as String?)
              ?.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      quizIds:
          (json['quizIds'] as String?)
              ?.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
