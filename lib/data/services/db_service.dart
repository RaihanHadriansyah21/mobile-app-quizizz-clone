import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/class_model.dart';
import '../models/attempt_model.dart';
import 'mock_data.dart';

class DbService {
  static SharedPreferences? _prefs;

  static List<UserModel>? _usersCached;
  static List<ClassModel>? _classesCached;
  static List<QuizModel>? _quizzesCached;
  static List<AttemptModel>? _attemptsCached;
  static List<QuestionModel>? _questionsCached;

  static final StreamController<String> realtimeChangeStream = StreamController<String>.broadcast();
  static RealtimeChannel? _realtimeChannel;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Seed initial mock data if this is the first run
    if (_prefs!.getString('users') == null) {
      await seedMockData();
    }

    // Perform background sync if Supabase is initialized
    if (isSupabaseEnabled) {
      await syncFromSupabase().catchError((e) {
        debugPrint('Initial Supabase sync error: $e');
      });
      subscribeToRealtime();
    }
  }

  static void subscribeToRealtime() {
    if (!isSupabaseEnabled) return;
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel('db-sync-channel');

      _realtimeChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'quizzes',
        callback: (payload) async {
          debugPrint('Realtime change: quizzes');
          try {
            await syncFromSupabase();
            realtimeChangeStream.add('quizzes');
          } catch (e) {
            debugPrint('Error syncing quizzes on realtime event: $e');
          }
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'classes',
        callback: (payload) async {
          debugPrint('Realtime change: classes');
          try {
            await syncFromSupabase();
            realtimeChangeStream.add('classes');
          } catch (e) {
            debugPrint('Error syncing classes on realtime event: $e');
          }
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'questions',
        callback: (payload) async {
          debugPrint('Realtime change: questions');
          try {
            await syncFromSupabase();
            realtimeChangeStream.add('questions');
          } catch (e) {
            debugPrint('Error syncing questions on realtime event: $e');
          }
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'attempts',
        callback: (payload) async {
          debugPrint('Realtime change: attempts');
          try {
            await syncFromSupabase();
            realtimeChangeStream.add('attempts');
          } catch (e) {
            debugPrint('Error syncing attempts on realtime event: $e');
          }
        },
      );

      _realtimeChannel!.subscribe();
      debugPrint('Subscribed to Supabase Realtime.');
    } catch (e) {
      debugPrint('Failed to subscribe to Realtime: $e');
    }
  }

  // Check if Supabase client is initialized and accessible
  static bool get isSupabaseEnabled {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Generic SharedPreferences helpers
  static List<Map<String, dynamic>> _getList(String key) {
    String? raw = _prefs?.getString(key);
    if (raw == null) return [];
    try {
      List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    await _prefs?.setString(key, jsonEncode(list));
  }

  // Seed Initial Data
  static Future<void> seedMockData() async {
    await _saveList(
      'users',
      MockData.initialUsers.map((u) => u.toJson()).toList(),
    );
    await _saveList(
      'quizzes',
      MockData.initialQuizzes.map((q) => q.toJson()).toList(),
    );
    await _saveList(
      'classes',
      MockData.initialClasses.map((c) => c.toJson()).toList(),
    );
    await _saveList(
      'attempts',
      MockData.initialAttempts.map((a) => a.toJson()).toList(),
    );
    await _saveList(
      'questions',
      MockData.initialQuestions.map((q) => q.toJson()).toList(),
    );
  }

  // --- SUPABASE SYNCING ---
  static Map<String, dynamic> _cleanRecordForSupabase(String table, Map<String, dynamic> json) {
    final Map<String, dynamic> cleaned = Map.from(json);
    if (table == 'users') {
      cleaned.remove('password');
    } else if (table == 'attempts') {
      cleaned.remove('fastest_correct_seconds');
      cleaned.remove('power_ups_used');
    }
    return cleaned;
  }

  static Future<void> syncFromSupabase() async {
    if (!isSupabaseEnabled) return;
    final client = Supabase.instance.client;
    try {
      // 1. Fetch remote users
      final List<dynamic> remoteUsersRaw = await client.from('users').select();
      final List<UserModel> remoteUsers = remoteUsersRaw
          .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u)))
          .toList();
      
      // Preserve passwords from local cache or local SharedPreferences
      final localUsers = _usersCached ?? _getList('users').map((u) => UserModel.fromJson(u)).toList();
      final Map<String, String> localPasswords = {
        for (var u in localUsers) u.id: u.password
      };

      _usersCached = remoteUsers.map((ru) {
        final pass = localPasswords[ru.id] ?? 'password123';
        return ru.copyWith(password: pass);
      }).toList();

      // 2. Fetch remote classes
      final List<dynamic> remoteClassesRaw = await client.from('classes').select();
      _classesCached = remoteClassesRaw
          .map((c) => ClassModel.fromJson(Map<String, dynamic>.from(c)))
          .toList();

      // 3. Fetch remote quizzes
      final List<dynamic> remoteQuizzesRaw = await client.from('quizzes').select();
      _quizzesCached = remoteQuizzesRaw
          .map((q) => QuizModel.fromJson(Map<String, dynamic>.from(q)))
          .toList();

      // 4. Fetch remote attempts
      final List<dynamic> remoteAttemptsRaw = await client.from('attempts').select();
      _attemptsCached = remoteAttemptsRaw
          .map((a) => AttemptModel.fromJson(Map<String, dynamic>.from(a)))
          .toList();

      // 5. Fetch remote questions
      final List<dynamic> remoteQuestionsRaw = await client.from('questions').select();
      _questionsCached = remoteQuestionsRaw
          .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q)))
          .toList();

      debugPrint('Supabase syncing completed (in-memory).');
    } catch (e) {
      debugPrint('Sync from Supabase failed: $e');
      rethrow;
    }
  }

  // --- USER CRUD ---
  static List<UserModel> getUsers() {
    if (isSupabaseEnabled && _usersCached != null) {
      return _usersCached!;
    }
    final local = _getList('users').map((u) => UserModel.fromJson(u)).toList();
    if (isSupabaseEnabled) {
      _usersCached = local;
    }
    return local;
  }

  static Future<void> saveUser(UserModel user) async {
    if (isSupabaseEnabled) {
      _usersCached ??= getUsers();
      _usersCached!.removeWhere((u) => u.id == user.id);
      _usersCached!.add(user);

      final userJson = _cleanRecordForSupabase('users', user.toJson());
      try {
        await Supabase.instance.client
            .from('users')
            .upsert(userJson);
      } catch (e) {
        debugPrint('Error uploading user to Supabase: $e');
        rethrow;
      }
    } else {
      List<UserModel> users = getUsers();
      users.removeWhere((u) => u.id == user.id);
      users.add(user);
      await _saveList('users', users.map((u) => u.toJson()).toList());
    }
  }

  static Future<void> deleteUser(String userId) async {
    if (isSupabaseEnabled) {
      _usersCached ??= getUsers();
      _usersCached!.removeWhere((u) => u.id == userId);

      try {
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('id', userId);
      } catch (e) {
        debugPrint('Error deleting user from Supabase: $e');
        rethrow;
      }
    } else {
      List<UserModel> users = getUsers();
      users.removeWhere((u) => u.id == userId);
      await _saveList('users', users.map((u) => u.toJson()).toList());
    }
  }

  static UserModel? getUserById(String id) {
    try {
      return getUsers().firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  static UserModel? getUserByEmail(String email) {
    try {
      return getUsers().firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // --- QUIZ CRUD ---
  static List<QuizModel> getQuizzes() {
    if (isSupabaseEnabled && _quizzesCached != null) {
      return _quizzesCached!;
    }
    final local = _getList('quizzes').map((q) => QuizModel.fromJson(q)).toList();
    if (isSupabaseEnabled) {
      _quizzesCached = local;
    }
    return local;
  }

  static Future<void> saveQuiz(QuizModel quiz) async {
    if (isSupabaseEnabled) {
      _quizzesCached ??= getQuizzes();
      _quizzesCached!.removeWhere((q) => q.id == quiz.id);
      _quizzesCached!.add(quiz);

      final quizJson = _cleanRecordForSupabase('quizzes', quiz.toJson());
      try {
        await Supabase.instance.client
            .from('quizzes')
            .upsert(quizJson);
      } catch (e) {
        debugPrint('Error uploading quiz to Supabase: $e');
        rethrow;
      }
    } else {
      List<QuizModel> quizzes = getQuizzes();
      quizzes.removeWhere((q) => q.id == quiz.id);
      quizzes.add(quiz);
      await _saveList('quizzes', quizzes.map((q) => q.toJson()).toList());
    }
  }

  static Future<void> deleteQuiz(String quizId) async {
    if (isSupabaseEnabled) {
      _quizzesCached ??= getQuizzes();
      _quizzesCached!.removeWhere((q) => q.id == quizId);

      try {
        await Supabase.instance.client
            .from('quizzes')
            .delete()
            .eq('id', quizId);
      } catch (e) {
        debugPrint('Error deleting quiz from Supabase: $e');
        rethrow;
      }
    } else {
      List<QuizModel> quizzes = getQuizzes();
      quizzes.removeWhere((q) => q.id == quizId);
      await _saveList('quizzes', quizzes.map((q) => q.toJson()).toList());
    }
  }

  static QuizModel? getQuizById(String id) {
    try {
      return getQuizzes().firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- CLASS CRUD ---
  static List<ClassModel> getClasses() {
    if (isSupabaseEnabled && _classesCached != null) {
      return _classesCached!;
    }
    final local = _getList('classes').map((c) => ClassModel.fromJson(c)).toList();
    if (isSupabaseEnabled) {
      _classesCached = local;
    }
    return local;
  }

  static Future<void> saveClass(ClassModel classObj) async {
    if (isSupabaseEnabled) {
      _classesCached ??= getClasses();
      _classesCached!.removeWhere((c) => c.id == classObj.id);
      _classesCached!.add(classObj);

      try {
        await Supabase.instance.client
            .from('classes')
            .upsert(classObj.toJson());
      } catch (e) {
        debugPrint('Error uploading class to Supabase: $e');
        rethrow;
      }
    } else {
      List<ClassModel> classes = getClasses();
      classes.removeWhere((c) => c.id == classObj.id);
      classes.add(classObj);
      await _saveList('classes', classes.map((c) => c.toJson()).toList());
    }
  }

  static Future<void> deleteClass(String classId) async {
    if (isSupabaseEnabled) {
      _classesCached ??= getClasses();
      _classesCached!.removeWhere((c) => c.id == classId);

      try {
        await Supabase.instance.client
            .from('classes')
            .delete()
            .eq('id', classId);
      } catch (e) {
        debugPrint('Error deleting class from Supabase: $e');
        rethrow;
      }
    } else {
      List<ClassModel> classes = getClasses();
      classes.removeWhere((c) => c.id == classId);
      await _saveList('classes', classes.map((c) => c.toJson()).toList());
    }
  }

  static ClassModel? getClassByCode(String code) {
    try {
      return getClasses().firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  static ClassModel? getClassById(String id) {
    try {
      return getClasses().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- ATTEMPT CRUD ---
  static List<AttemptModel> getAttempts() {
    if (isSupabaseEnabled && _attemptsCached != null) {
      return _attemptsCached!;
    }
    final local = _getList('attempts').map((a) => AttemptModel.fromJson(a)).toList();
    if (isSupabaseEnabled) {
      _attemptsCached = local;
    }
    return local;
  }

  static Future<void> saveAttempt(AttemptModel attempt) async {
    if (isSupabaseEnabled) {
      _attemptsCached ??= getAttempts();
      _attemptsCached!.removeWhere((a) => a.id == attempt.id);
      _attemptsCached!.add(attempt);

      final attemptJson = _cleanRecordForSupabase('attempts', attempt.toJson());
      try {
        await Supabase.instance.client
            .from('attempts')
            .upsert(attemptJson);
      } catch (e) {
        debugPrint('Error uploading attempt to Supabase: $e');
        rethrow;
      }
    } else {
      List<AttemptModel> attempts = getAttempts();
      attempts.removeWhere((a) => a.id == attempt.id);
      attempts.add(attempt);
      await _saveList('attempts', attempts.map((a) => a.toJson()).toList());
    }
  }

  static List<AttemptModel> getAttemptsForQuiz(String quizId) {
    return getAttempts().where((a) => a.quizId == quizId).toList();
  }

  // --- QUESTION BANK CRUD ---
  // Reusable pool of standalone questions. Stored locally; quizzes take a
  // *copy* (snapshot) when a bank question is added, so the bank never affects
  // quizzes/attempts that already exist.
  static List<QuestionModel> getQuestions() {
    if (isSupabaseEnabled && _questionsCached != null) {
      return _questionsCached!;
    }
    final local = _getList('questions').map((q) => QuestionModel.fromJson(q)).toList();
    if (isSupabaseEnabled) {
      _questionsCached = local;
    }
    return local;
  }

  static Future<void> saveQuestion(QuestionModel question) async {
    if (isSupabaseEnabled) {
      _questionsCached ??= getQuestions();
      _questionsCached!.removeWhere((q) => q.id == question.id);
      _questionsCached!.add(question);

      try {
        await Supabase.instance.client
            .from('questions')
            .upsert(question.toJson());
      } catch (e) {
        debugPrint('Error uploading question to Supabase: $e');
        rethrow;
      }
    } else {
      List<QuestionModel> questions = getQuestions();
      questions.removeWhere((q) => q.id == question.id);
      questions.add(question);
      await _saveList('questions', questions.map((q) => q.toJson()).toList());
    }
  }

  static Future<void> deleteQuestion(String questionId) async {
    if (isSupabaseEnabled) {
      _questionsCached ??= getQuestions();
      _questionsCached!.removeWhere((q) => q.id == questionId);

      try {
        await Supabase.instance.client
            .from('questions')
            .delete()
            .eq('id', questionId);
      } catch (e) {
        debugPrint('Error deleting question from Supabase: $e');
        rethrow;
      }
    } else {
      List<QuestionModel> questions = getQuestions();
      questions.removeWhere((q) => q.id == questionId);
      await _saveList('questions', questions.map((q) => q.toJson()).toList());
    }
  }

  static QuestionModel? getQuestionById(String id) {
    try {
      return getQuestions().firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Distinct categories present in the bank (for filter chips/dropdowns).
  static List<String> getQuestionCategories() {
    final set = getQuestions().map((q) => q.category).toSet().toList();
    set.sort();
    return set;
  }
}
