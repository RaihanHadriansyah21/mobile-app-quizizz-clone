import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import '../models/class_model.dart';
import '../models/attempt_model.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import '../services/google_classroom_service.dart';

class DosenProvider extends ChangeNotifier {
  List<QuizModel> _quizzes = [];
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  StreamSubscription<String>? _realtimeSubscription;

  DosenProvider() {
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _realtimeSubscription = DbService.realtimeChangeStream.stream.listen((table) {
      debugPrint('DosenProvider received realtime change: $table');
      _quizzes = DbService.getQuizzes();
      _classes = DbService.getClasses();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  List<QuizModel> get quizzes => _quizzes;
  List<ClassModel> get classes => _classes;
  bool get isLoading => _isLoading;

  Future<void> refreshData({bool syncWithSupabase = true}) async {
    _isLoading = true;
    notifyListeners();

    _quizzes = DbService.getQuizzes();
    _classes = DbService.getClasses();

    _isLoading = false;
    notifyListeners();

    if (syncWithSupabase && DbService.isSupabaseEnabled) {
      await DbService.syncFromSupabase();
      _quizzes = DbService.getQuizzes();
      _classes = DbService.getClasses();
      notifyListeners();
    }
  }

  // --- QUIZ BANK CRUD ---
  Future<void> saveQuiz(QuizModel quiz) async {
    await DbService.saveQuiz(quiz);
    await refreshData(syncWithSupabase: false);
  }

  Future<void> deleteQuiz(String quizId) async {
    // Clean up quizId from all classes that assigned it
    final allRelatedClasses = _classes
        .where((c) => c.quizIds.contains(quizId))
        .toList();
    for (var classObj in allRelatedClasses) {
      List<String> updatedQuizzes = List.from(classObj.quizIds)..remove(quizId);
      await DbService.saveClass(classObj.copyWith(quizIds: updatedQuizzes));
    }

    await DbService.deleteQuiz(quizId);
    await refreshData(syncWithSupabase: false);
  }

  // --- CLASS CRUD ---
  Future<void> saveClass(String className, String teacherId) async {
    Random rand = Random();
    String code = '';
    bool codeExists = true;

    while (codeExists) {
      code = (100000 + rand.nextInt(900000)).toString();
      final localExists = DbService.getClasses().any((c) => c.code == code);
      if (!localExists) {
        if (DbService.isSupabaseEnabled) {
          try {
            final res = await Supabase.instance.client
                .from('classes')
                .select('id')
                .eq('code', code)
                .maybeSingle();
            if (res == null) {
              codeExists = false;
            }
          } catch (e) {
            debugPrint('Error checking class code uniqueness in Supabase: $e');
            codeExists = false;
          }
        } else {
          codeExists = false;
        }
      }
    }

    ClassModel newClass = ClassModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      className: className,
      code: code,
      teacherId: teacherId,
    );

    await DbService.saveClass(newClass);
    await refreshData(syncWithSupabase: false);
  }

  Future<void> deleteClass(String classId) async {
    await DbService.deleteClass(classId);
    await refreshData(syncWithSupabase: false);
  }

  // --- ASSIGN QUIZ ---
  Future<void> assignQuizToClass(String classId, String quizId) async {
    ClassModel? classObj = DbService.getClassById(classId);
    if (classObj != null) {
      List<String> updatedQuizzes = List.from(classObj.quizIds);
      if (!updatedQuizzes.contains(quizId)) {
        updatedQuizzes.add(quizId);
      }
      ClassModel updated = classObj.copyWith(quizIds: updatedQuizzes);
      await DbService.saveClass(updated);
      await refreshData(syncWithSupabase: false);
    }
  }

  Future<void> unassignQuizFromClass(String classId, String quizId) async {
    ClassModel? classObj = DbService.getClassById(classId);
    if (classObj != null) {
      List<String> updatedQuizzes = List.from(classObj.quizIds);
      updatedQuizzes.remove(quizId);
      ClassModel updated = classObj.copyWith(quizIds: updatedQuizzes);
      await DbService.saveClass(updated);
      await refreshData(syncWithSupabase: false);
    }
  }

  // --- ANALYTICS ---
  List<AttemptModel> getAttemptsForQuiz(String quizId) {
    return DbService.getAttemptsForQuiz(quizId);
  }

  // --- GOOGLE CLASSROOM (real integration) ---

  bool get isClassroomSignedIn => GoogleClassroomService.isSignedIn;

  /// Login Google + otorisasi scope Classroom.
  Future<bool> classroomSignIn() async {
    _isLoading = true;
    notifyListeners();
    final ok = await GoogleClassroomService.signIn();
    _isLoading = false;
    notifyListeners();
    return ok;
  }

  Future<void> classroomSignOut() async {
    await GoogleClassroomService.signOut();
    notifyListeners();
  }

  /// Ambil daftar kelas Google Classroom milik dosen.
  Future<List<GoogleClassroomCourse>> classroomCourses() {
    return GoogleClassroomService.fetchCourses();
  }

  /// Impor roster dari sebuah Google Course ke kelas lokal [classId].
  /// Mahasiswa yang belum ada dibuatkan akun, lalu ditambahkan ke kelas.
  /// Mengembalikan jumlah mahasiswa baru yang ditambahkan.
  Future<int> importRosterFromClassroom(
    String classId,
    String googleCourseId,
  ) async {
    _isLoading = true;
    notifyListeners();

    int added = 0;
    try {
      final roster = await GoogleClassroomService.fetchRoster(googleCourseId);
      final classObj = DbService.getClassById(classId);
      if (classObj != null) {
        final studentIds = List<String>.from(classObj.studentIds);
        for (final s in roster) {
          final email = (s['email'] ?? '').trim();
          if (email.isEmpty) continue;

          // Reuse an existing account by email, otherwise create one.
          UserModel? user = DbService.getUserByEmail(email);
          user ??= UserModel(
            id: 'u_gc_${s['id']?.isNotEmpty == true ? s['id'] : DateTime.now().microsecondsSinceEpoch}',
            name: s['name'] ?? 'Mahasiswa',
            email: email,
            role: UserRole.mahasiswa,
          );
          await DbService.saveUser(user);

          if (!studentIds.contains(user.id)) {
            studentIds.add(user.id);
            added++;
          }
        }
        await DbService.saveClass(classObj.copyWith(studentIds: studentIds));
      }
    } catch (e) {
      debugPrint('importRosterFromClassroom error: $e');
    }

    await refreshData(syncWithSupabase: false);
    _isLoading = false;
    notifyListeners();
    return added;
  }

  /// Kirim nilai satu kuis ke Gradebook Google Classroom.
  /// Membuat satu tugas, lalu mengisi nilai tiap mahasiswa yang emailnya cocok
  /// dengan roster Google. Mengembalikan jumlah nilai yang berhasil dikirim.
  Future<int> postClassGradesToClassroom({
    required String googleCourseId,
    required QuizModel quiz,
    required List<AttemptModel> attempts,
  }) async {
    _isLoading = true;
    notifyListeners();

    int posted = 0;
    try {
      final courseWorkId = await GoogleClassroomService.createAssignment(
        googleCourseId,
        quiz.title,
      );
      if (courseWorkId != null) {
        // Map email -> Google userId from the live roster.
        final roster = await GoogleClassroomService.fetchRoster(googleCourseId);
        final emailToId = {
          for (final r in roster)
            (r['email'] ?? '').toLowerCase(): r['id'] ?? '',
        };

        // Best score per student for this quiz.
        final Map<String, AttemptModel> bestByStudent = {};
        for (final a in attempts.where((a) => a.quizId == quiz.id)) {
          final existing = bestByStudent[a.studentId];
          if (existing == null || a.score > existing.score) {
            bestByStudent[a.studentId] = a;
          }
        }

        for (final attempt in bestByStudent.values) {
          final student = DbService.getUserById(attempt.studentId);
          final userId = emailToId[(student?.email ?? '').toLowerCase()];
          if (userId == null || userId.isEmpty) continue;

          final total = quiz.questions.length;
          final grade = total > 0
              ? (attempt.correctAnswersCount / total) * 100.0
              : 0.0;

          final ok = await GoogleClassroomService.postStudentGrade(
            courseId: googleCourseId,
            courseWorkId: courseWorkId,
            studentUserId: userId,
            grade: grade,
          );
          if (ok) posted++;
        }
      }
    } catch (e) {
      debugPrint('postClassGradesToClassroom error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return posted;
  }

  // --- SELECTION STATES FOR QUICK NAVIGATION ---
  ClassModel? _selectedClassForAnalytics;
  ClassModel? get selectedClassForAnalytics => _selectedClassForAnalytics;
  void setSelectedClassForAnalytics(ClassModel? c) {
    _selectedClassForAnalytics = c;
    notifyListeners();
  }

  QuizModel? _selectedQuizForAssignment;
  QuizModel? get selectedQuizForAssignment => _selectedQuizForAssignment;
  void setSelectedQuizForAssignment(QuizModel? q) {
    _selectedQuizForAssignment = q;
    notifyListeners();
  }
}
