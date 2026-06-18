import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/quiz_model.dart';
import '../models/attempt_model.dart';
import '../services/db_service.dart';

class AdminProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  List<ClassModel> _classes = [];
  List<QuizModel> _quizzes = [];
  List<AttemptModel> _attempts = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  List<UserModel> get dosenList =>
      _users.where((u) => u.role == UserRole.dosen).toList();
  List<UserModel> get mahasiswaList =>
      _users.where((u) => u.role == UserRole.mahasiswa).toList();
  List<ClassModel> get classes => _classes;
  List<QuizModel> get quizzes => _quizzes;
  List<AttemptModel> get attempts => _attempts;
  bool get isLoading => _isLoading;

  Future<void> refreshData({bool syncWithSupabase = true}) async {
    _isLoading = true;
    notifyListeners();

    _loadLocal();
    _isLoading = false;
    notifyListeners();

    if (syncWithSupabase && DbService.isSupabaseEnabled) {
      await DbService.syncFromSupabase();
      _loadLocal();
      notifyListeners();
    }
  }

  void _loadLocal() {
    _users = DbService.getUsers();
    _classes = DbService.getClasses();
    _quizzes = DbService.getQuizzes();
    _attempts = DbService.getAttempts();
  }

  // --- CRUD DOSEN ---
  Future<void> saveDosen(UserModel dosen) async {
    await DbService.saveUser(dosen);
    await refreshData(syncWithSupabase: false);
  }

  Future<void> deleteDosen(String id) async {
    await DbService.deleteUser(id);
    await refreshData(syncWithSupabase: false);
  }

  // --- CRUD MAHASISWA ---
  Future<void> saveMahasiswa(UserModel mahasiswa) async {
    await DbService.saveUser(mahasiswa);
    await refreshData(syncWithSupabase: false);
  }

  Future<void> deleteMahasiswa(String id) async {
    await DbService.deleteUser(id);
    await refreshData(syncWithSupabase: false);
  }

  // --- CLASS MONITORING ---
  Future<void> deleteClass(String id) async {
    await DbService.deleteClass(id);
    await refreshData(syncWithSupabase: false);
  }

  // --- QUIZ MONITORING ---
  Future<void> deleteQuiz(String id) async {
    // Clean up quizId from all classes that assigned it
    final allRelatedClasses = _classes.where((c) => c.quizIds.contains(id)).toList();
    for (var classObj in allRelatedClasses) {
      List<String> updatedQuizzes = List.from(classObj.quizIds)..remove(id);
      await DbService.saveClass(classObj.copyWith(quizIds: updatedQuizzes));
    }

    await DbService.deleteQuiz(id);
    await refreshData(syncWithSupabase: false);
  }
}
