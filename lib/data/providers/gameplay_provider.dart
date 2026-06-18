import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/attempt_model.dart';
import '../models/powerup_model.dart';
import '../services/db_service.dart';

class GameplayProvider extends ChangeNotifier {
  QuizModel? _activeQuiz;
  String? _activeClassId;
  DateTime? _startTime;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _timeLeft = 30;
  bool _isTimerActive = false;
  Timer? _timer;

  // Answers Map
  final Map<String, String> _studentAnswers = {};

  // Power Up state
  List<PowerUpModel> _powerUps = PowerUpModel.defaultList;
  bool _doubleScoreActive = false;
  bool _secondChanceActive = false;
  bool _secondChanceUsed = false;
  List<String> _prunedOptions = []; // For 50:50 powerup

  // Badge tracking (recorded into the AttemptModel on submit)
  int _powerUpsUsed = 0;
  int _fastestCorrectSeconds = 9999; // smallest time-to-answer among correct

  // Answer feedback overlay state
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;
  String _memeText = "";
  String _memeImage = ""; // Optional asset/file path (used if real PNGs exist)
  String _memeEmoji = ""; // Reaction emoji shown on the feedback card

  // Getters
  QuizModel? get activeQuiz => _activeQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctCount => _correctCount;
  int get timeLeft => _timeLeft;
  bool get isTimerActive => _isTimerActive;
  QuestionModel? get currentQuestion =>
      (_activeQuiz != null &&
          _currentQuestionIndex < _activeQuiz!.questions.length)
      ? _activeQuiz!.questions[_currentQuestionIndex]
      : null;
  bool get isFinished =>
      _activeQuiz == null ||
      _currentQuestionIndex >= _activeQuiz!.questions.length;
  List<PowerUpModel> get powerUps => _powerUps;
  List<String> get prunedOptions => _prunedOptions;
  bool get showFeedback => _showFeedback;
  bool get isAnswerCorrect => _isAnswerCorrect;
  String get memeText => _memeText;
  String get memeImage => _memeImage;
  String get memeEmoji => _memeEmoji;
  Map<String, String> get studentAnswers => _studentAnswers;

  // Memes Database
  // Captions (text + emoji) are picked independently from the media file, so
  // the number of media files does not have to match the number of captions.
  final List<Map<String, String>> _correctMemes = [
    {'text': 'Big Brain Time! 🧠', 'emoji': '🧠'},
    {'text': 'Stonks! 📈', 'emoji': '📈'},
    {'text': 'Outstanding Move! 😎', 'emoji': '😎'},
    {'text': 'IQ 200! 🌟', 'emoji': '🌟'},
  ];

  final List<Map<String, String>> _incorrectMemes = [
    {'text': 'Are you sure about that? 🤔', 'emoji': '🤔'},
    {'text': 'Not Stonks! 📉', 'emoji': '📉'},
    {'text': 'Excuse me, what? 🤨', 'emoji': '🤨'},
    {'text': 'Adios, Points! 🥲', 'emoji': '🥲'},
  ];

  // Real media files in assets/memes/. Images (.jpeg) and videos (.mp4) are
  // both supported by the feedback overlay. A random one is shown each time.
  final List<String> _correctMedia = [
    'assets/memes/true1.mp4',
    'assets/memes/true2.mp4',
    'assets/memes/true3.jpeg',
    'assets/memes/true4.mp4',
    'assets/memes/true5.jpeg',
  ];

  final List<String> _incorrectMedia = [
    'assets/memes/false1.jpeg',
    'assets/memes/false2.jpeg',
    'assets/memes/false3.jpeg',
    'assets/memes/false5.jpeg',
    'assets/memes/false6.jpeg',
    'assets/memes/false7.jpeg',
    'assets/memes/false8.jpeg',
  ];

  void startQuiz(QuizModel quiz, {String? classId}) {
    _activeQuiz = quiz;
    _activeClassId = classId;
    _startTime = DateTime.now();
    _currentQuestionIndex = 0;
    _score = 0;
    _correctCount = 0;
    _studentAnswers.clear();
    _powerUps = PowerUpModel.defaultList;
    _doubleScoreActive = false;
    _secondChanceActive = false;
    _secondChanceUsed = false;
    _prunedOptions.clear();
    _showFeedback = false;
    _powerUpsUsed = 0;
    _fastestCorrectSeconds = 9999;
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _cancelTimer();
    _prunedOptions.clear();
    _secondChanceUsed = false;

    if (currentQuestion == null) return;

    if (!_activeQuiz!.isTimerEnabled ||
        currentQuestion!.timeLimitSeconds <= 0) {
      _timeLeft = 999; // Represents infinite/flexible
      _isTimerActive = false;
      notifyListeners();
      return;
    }

    _timeLeft = currentQuestion!.timeLimitSeconds;
    _isTimerActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timeLeft = 0;
        _cancelTimer();
        answerQuestion("");
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerActive = false;
  }

  void pauseQuestionTimer() {
    if (_isTimerActive && _timer != null) {
      _timer?.cancel();
      _timer = null;
      _isTimerActive = false;
      notifyListeners();
      debugPrint("Timer paused. Time left: $_timeLeft seconds.");
    }
  }

  void resumeQuestionTimer() {
    if (_activeQuiz != null &&
        _activeQuiz!.isTimerEnabled &&
        currentQuestion != null &&
        currentQuestion!.timeLimitSeconds > 0 &&
        !_isTimerActive &&
        _timer == null &&
        _timeLeft > 0 &&
        !_showFeedback) {
      _isTimerActive = true;
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 1) {
          _timeLeft--;
          notifyListeners();
        } else {
          _timeLeft = 0;
          _cancelTimer();
          answerQuestion("");
        }
      });
      debugPrint("Timer resumed. Time left: $_timeLeft seconds.");
    }
  }

  void answerQuestion(String answer) {
    _cancelTimer();
    if (currentQuestion == null) return;

    final question = currentQuestion!;
    bool isCorrect =
        answer.toLowerCase().trim() ==
        question.correctAnswer.toLowerCase().trim();

    if (!isCorrect && _secondChanceActive && !_secondChanceUsed) {
      _secondChanceUsed = true;
      _secondChanceActive = false;
      _timeLeft = 15;
      _isTimerActive = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 1) {
          _timeLeft--;
          notifyListeners();
        } else {
          _timeLeft = 0;
          _cancelTimer();
          _processAnswer(question, "");
        }
      });
      notifyListeners();
      return;
    }

    _processAnswer(question, answer);
  }

  void _processAnswer(QuestionModel question, String answer) {
    bool isCorrect =
        answer.toLowerCase().trim() ==
        question.correctAnswer.toLowerCase().trim();
    _studentAnswers[question.id] = answer;

    int pointsEarned = 0;
    if (isCorrect) {
      _correctCount++;
      pointsEarned = question.points;

      if (_activeQuiz!.isTimerEnabled && question.timeLimitSeconds > 0) {
        double timeRatio = _timeLeft / question.timeLimitSeconds;
        pointsEarned += (timeRatio * 50).round();

        // Track fastest correct answer (for the "Speed Runner" badge).
        // A non-empty answer means it wasn't a timeout.
        if (answer.trim().isNotEmpty) {
          final int timeTaken = question.timeLimitSeconds - _timeLeft;
          if (timeTaken >= 0 && timeTaken < _fastestCorrectSeconds) {
            _fastestCorrectSeconds = timeTaken;
          }
        }
      }

      if (_doubleScoreActive) {
        pointsEarned *= 2;
        _doubleScoreActive = false;
      }
      _score += pointsEarned;
    } else {
      _doubleScoreActive = false;
    }

    _isAnswerCorrect = isCorrect;
    final random = Random();
    if (isCorrect) {
      final meme = _correctMemes[random.nextInt(_correctMemes.length)];
      _memeText = meme['text']!;
      _memeEmoji = meme['emoji']!;
      _memeImage = _correctMedia[random.nextInt(_correctMedia.length)];
    } else {
      final meme = _incorrectMemes[random.nextInt(_incorrectMemes.length)];
      _memeText = meme['text']!;
      _memeEmoji = meme['emoji']!;
      _memeImage = _incorrectMedia[random.nextInt(_incorrectMedia.length)];
    }

    _showFeedback = true;
    _secondChanceActive = false;
    notifyListeners();
  }

  void dismissFeedback() {
    _showFeedback = false;
    _currentQuestionIndex++;
    if (!isFinished) {
      _startQuestionTimer();
    }
    notifyListeners();
  }

  void usePowerUp(PowerUpModel powerUp) {
    if (powerUp.count <= 0 || currentQuestion == null) return;

    _powerUpsUsed++; // for the "Booster User" badge

    _powerUps = _powerUps.map((p) {
      if (p.type == powerUp.type) {
        return p.copyWith(count: p.count - 1);
      }
      return p;
    }).toList();

    switch (powerUp.type) {
      case PowerUpType.doubleScore:
        _doubleScoreActive = true;
        break;
      case PowerUpType.freezeTimer:
        _cancelTimer();
        _timeLeft = currentQuestion!.timeLimitSeconds;
        _isTimerActive = false;
        break;
      case PowerUpType.fiftyFifty:
        if (currentQuestion!.type == QuestionType.multipleChoice) {
          final correct = currentQuestion!.correctAnswer;
          final incorrects = currentQuestion!.options
              .where((o) => o != correct)
              .toList();
          if (incorrects.length >= 2) {
            final random = Random();
            final o1 = incorrects[random.nextInt(incorrects.length)];
            incorrects.remove(o1);
            final o2 = incorrects[random.nextInt(incorrects.length)];
            _prunedOptions = [o1, o2];
          }
        }
        break;
      case PowerUpType.secondChance:
        _secondChanceActive = true;
        break;
    }
    notifyListeners();
  }

  Future<void> submitQuizAttempt(String studentId, String studentName) async {
    if (_activeQuiz == null) return;

    final elapsedSeconds = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    AttemptModel attempt = AttemptModel(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName,
      quizId: _activeQuiz!.id,
      classId: _activeClassId,
      score: _score,
      totalQuestions: _activeQuiz!.questions.length,
      correctAnswersCount: _correctCount,
      completedAt: DateTime.now(),
      answers: Map.from(_studentAnswers),
      fastestCorrectSeconds: _fastestCorrectSeconds,
      powerUpsUsed: _powerUpsUsed,
      timeTaken: elapsedSeconds,
    );

    try {
      await DbService.saveAttempt(attempt);
    } catch (e) {
      debugPrint('submitQuizAttempt: Failed to save attempt: $e');
      rethrow;
    } finally {
      _activeQuiz = null;
      _activeClassId = null;
      _startTime = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
