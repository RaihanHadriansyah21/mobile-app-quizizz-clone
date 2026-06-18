import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import '../models/quiz_model.dart';
import '../models/attempt_model.dart';
import '../services/db_service.dart';

class MahasiswaProvider extends ChangeNotifier {
  List<ClassModel> _joinedClasses = [];
  List<QuizModel> _availableQuizzes = [];
  List<AttemptModel> _pastAttempts = [];
  bool _isLoading = false;
  String? _lastStudentId;
  StreamSubscription<String>? _realtimeSubscription;

  MahasiswaProvider() {
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    _realtimeSubscription = DbService.realtimeChangeStream.stream.listen((table) {
      if (_lastStudentId != null) {
        debugPrint('MahasiswaProvider received realtime change: $table');
        _loadLocalData(_lastStudentId!);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  List<ClassModel> get joinedClasses => _joinedClasses;
  List<QuizModel> get availableQuizzes => _availableQuizzes;
  List<AttemptModel> get pastAttempts => _pastAttempts;
  bool get isLoading => _isLoading;

  Future<void> refreshData(String studentId, {bool syncWithSupabase = true}) async {
    _lastStudentId = studentId;
    _isLoading = true;
    notifyListeners();

    _loadLocalData(studentId);

    _isLoading = false;
    notifyListeners();

    if (syncWithSupabase && DbService.isSupabaseEnabled) {
      await DbService.syncFromSupabase();
      _loadLocalData(studentId);
      notifyListeners();
    }
  }

  void _loadLocalData(String studentId) {
    List<ClassModel> allClasses = DbService.getClasses();
    _joinedClasses =
        allClasses.where((c) => c.studentIds.contains(studentId)).toList();

    List<String> quizIds = _joinedClasses.expand((c) => c.quizIds).toList();
    List<QuizModel> allQuizzes = DbService.getQuizzes();
    _availableQuizzes =
        allQuizzes.where((q) => quizIds.contains(q.id)).toList();

    List<AttemptModel> allAttempts = DbService.getAttempts();
    _pastAttempts =
        allAttempts.where((a) => a.studentId == studentId).toList();
  }

  // Join a class using 6-digit code or QR Code payload
  Future<String?> joinClassWithCode(String code, String studentId) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('joinClassWithCode: entering join flow with code="$code" and studentId="$studentId"');
    await Future.delayed(const Duration(milliseconds: 500));

    ClassModel? classObj;
    if (DbService.isSupabaseEnabled) {
      try {
        debugPrint('joinClassWithCode: querying Supabase classes table for code="$code"');
        final remoteClass = await Supabase.instance.client
            .from('classes')
            .select()
            .eq('code', code)
            .maybeSingle();
        debugPrint('joinClassWithCode: Supabase query result=$remoteClass');
        if (remoteClass != null) {
          classObj = ClassModel.fromJson(remoteClass);
          await DbService.saveClass(classObj); // cache/update locally
          debugPrint('joinClassWithCode: cached fresh class info for "${classObj.className}" locally');
        }
      } catch (e) {
        debugPrint('Error fetching class from Supabase: $e');
      }
    }

    // Fallback to local cache if offline or fetch failed
    if (classObj == null) {
      classObj = DbService.getClassByCode(code);
      debugPrint('joinClassWithCode: fallback to local cache check: classObj=$classObj');
    }
    
    _isLoading = false;

    if (classObj == null) {
      debugPrint('joinClassWithCode: class not found for code="$code"');
      notifyListeners();
      return "Kelas tidak ditemukan. Periksa kembali kode Anda.";
    }

    if (classObj.studentIds.contains(studentId)) {
      debugPrint('joinClassWithCode: studentId="$studentId" is already in class "${classObj.className}"');
      notifyListeners();
      return "Anda sudah bergabung dalam kelas ini.";
    }

    List<String> updatedStudents = List.from(classObj.studentIds);
    updatedStudents.add(studentId);
    debugPrint('joinClassWithCode: appending studentId. New student list: $updatedStudents');

    ClassModel updated = classObj.copyWith(studentIds: updatedStudents);
    await DbService.saveClass(updated);
    debugPrint('joinClassWithCode: successfully joined class and saved to Supabase/Cache');

    await refreshData(studentId, syncWithSupabase: false);
    return null; // Null means success
  }
}
