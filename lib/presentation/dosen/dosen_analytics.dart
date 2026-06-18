import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/class_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/attempt_model.dart';
import '../../data/providers/dosen_provider.dart';
import '../../data/services/file_service.dart';
import '../../core/theme/app_theme.dart';
import 'classroom_sync.dart';

class DosenAnalyticsScreen extends StatefulWidget {
  const DosenAnalyticsScreen({super.key});

  @override
  State<DosenAnalyticsScreen> createState() => _DosenAnalyticsScreenState();
}

class _DosenAnalyticsScreenState extends State<DosenAnalyticsScreen> {
  ClassModel? _selectedClass;
  QuizModel? _selectedQuiz;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DosenProvider>(context, listen: false);
      if (provider.selectedClassForAnalytics != null &&
          provider.classes.contains(provider.selectedClassForAnalytics)) {
        setState(() {
          _selectedClass = provider.selectedClassForAnalytics;
          _updateQuizSelection();
        });
      } else if (provider.classes.isNotEmpty) {
        setState(() {
          _selectedClass = provider.classes.first;
          _updateQuizSelection();
        });
      }
    });
  }

  void _updateQuizSelection() {
    if (_selectedClass == null) return;

    final quizzes = Provider.of<DosenProvider>(context, listen: false).quizzes;
    final assignedQuizzes = quizzes
        .where((q) => _selectedClass!.quizIds.contains(q.id))
        .toList();

    setState(() {
      _selectedQuiz = assignedQuizzes.isNotEmpty ? assignedQuizzes.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final classes = provider.classes;
    final quizzes = provider.quizzes;

    final assignedQuizzes = _selectedClass != null
        ? quizzes.where((q) => _selectedClass!.quizIds.contains(q.id)).toList()
        : <QuizModel>[];

    final attempts = _selectedQuiz != null && _selectedClass != null
        ? provider.getAttemptsForQuiz(_selectedQuiz!.id)
            .where((a) => a.classId == _selectedClass!.id)
            .toList()
        : <AttemptModel>[];

    double averageScore = 0;
    int perfectScores = 0;
    double classAccuracy = 0.0;
    String hardestQuestionText = "N/A";
    double hardestQuestionAccuracy = 100.0;

    int totalMahasiswa = _selectedClass?.studentIds.length ?? 0;
    int jumlahPeserta = attempts.map((a) => a.studentId).toSet().length;
    int jumlahAttempt = attempts.length;

    int highestScore = 0;
    int lowestScore = 0;
    if (attempts.isNotEmpty) {
      highestScore = attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
      lowestScore = attempts.map((a) => a.score).reduce((a, b) => a < b ? a : b);
    }

    int rangeA = 0; // 80 - 100
    int rangeB = 0; // 60 - 79
    int rangeC = 0; // 40 - 59
    int rangeD = 0; // 0 - 39
    for (var a in attempts) {
      if (a.score >= 80) rangeA++;
      else if (a.score >= 60) rangeB++;
      else if (a.score >= 40) rangeC++;
      else rangeD++;
    }

    final Map<String, AttemptModel> bestAttempts = {};
    for (var attempt in attempts) {
      final existing = bestAttempts[attempt.studentId];
      if (existing == null ||
          attempt.score > existing.score ||
          (attempt.score == existing.score && attempt.timeTaken < existing.timeTaken)) {
        bestAttempts[attempt.studentId] = attempt;
      }
    }
    final rankedStudents = bestAttempts.values.toList();
    rankedStudents.sort((a, b) {
      int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.timeTaken.compareTo(b.timeTaken); // time taken ASC
    });

    Map<String, int> questionCorrectCount = {};
    if (attempts.isNotEmpty && _selectedQuiz != null) {
      int totalCorrect = attempts
          .map((a) => a.correctAnswersCount)
          .reduce((a, b) => a + b);
      int totalQuestionsAnswered =
          attempts.length * _selectedQuiz!.questions.length;
      if (totalQuestionsAnswered > 0) {
        classAccuracy = (totalCorrect / totalQuestionsAnswered) * 100;
      }

      averageScore =
          attempts.map((a) => a.score).reduce((a, b) => a + b) /
          attempts.length;
      perfectScores = attempts
          .where(
            (a) => a.correctAnswersCount == _selectedQuiz!.questions.length,
          )
          .length;

      // Find hardest question
      for (var q in _selectedQuiz!.questions) {
        questionCorrectCount[q.id] = 0;
      }

      for (var attempt in attempts) {
        attempt.answers.forEach((qId, ans) {
          try {
            final q = _selectedQuiz!.questions.firstWhere(
              (question) => question.id == qId,
            );
            if (ans.toLowerCase().trim() ==
                q.correctAnswer.toLowerCase().trim()) {
              questionCorrectCount[qId] = (questionCorrectCount[qId] ?? 0) + 1;
            }
          } catch (_) {}
        });
      }

      String? hardestQId;
      double minAccuracy = 1.1; // initial greater than 1.0
      questionCorrectCount.forEach((qId, count) {
        double acc = count / attempts.length;
        if (acc < minAccuracy) {
          minAccuracy = acc;
          hardestQId = qId;
        }
      });

      if (hardestQId != null) {
        try {
          final hardestQ = _selectedQuiz!.questions.firstWhere(
            (q) => q.id == hardestQId,
          );
          hardestQuestionText = hardestQ.text;
          hardestQuestionAccuracy = minAccuracy * 100;
        } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analitik Kuis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ClassModel>(
              initialValue: classes.contains(_selectedClass)
                  ? _selectedClass
                  : null,
              decoration: const InputDecoration(labelText: 'Pilih Kelas'),
              items: classes.map((c) {
                return DropdownMenuItem<ClassModel>(
                  value: c,
                  child: Text(c.className),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClass = val;
                  _updateQuizSelection();
                });
              },
            ),
            const SizedBox(height: 16),

            if (_selectedClass != null)
              DropdownButtonFormField<QuizModel>(
                initialValue: assignedQuizzes.contains(_selectedQuiz)
                    ? _selectedQuiz
                    : null,
                decoration: const InputDecoration(labelText: 'Pilih Kuis'),
                items: assignedQuizzes.map((q) {
                  return DropdownMenuItem<QuizModel>(
                    value: q,
                    child: Text(q.title),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedQuiz = val;
                  });
                },
              ),
            const SizedBox(height: 28),

            if (_selectedClass == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text(
                    'Silakan buat kelas dan kuis terlebih dahulu.',
                    style: TextStyle(color: AppTheme.getTextSecondary(context)),
                  ),
                ),
              )
            else if (_selectedQuiz == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text(
                    'Kuis belum ditugaskan ke kelas ini.',
                    style: TextStyle(color: AppTheme.getTextSecondary(context)),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Rerata Nilai',
                      averageScore.toStringAsFixed(1),
                      Icons.star_outline,
                      AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Akurasi Kelas',
                      '${classAccuracy.round()}%',
                      Icons.insights,
                      AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Peserta & Attempt',
                      '$jumlahPeserta / $totalMahasiswa Siswa ($jumlahAttempt Attempt, $perfectScores Sempurna)',
                      Icons.people_alt_outlined,
                      AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Nilai Tertinggi / Terendah',
                      '$highestScore / $lowestScore',
                      Icons.height,
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Soal Tersulit',
                      hardestQuestionText == "N/A"
                          ? "N/A"
                          : hardestQuestionText.length > 18
                          ? '${hardestQuestionText.substring(0, 15)}... (${hardestQuestionAccuracy.round()}% Benar)'
                          : '$hardestQuestionText (${hardestQuestionAccuracy.round()}% Benar)',
                      Icons.warning_amber_outlined,
                      AppTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await FileService.exportAnalyticsPdf(
                          classObj: _selectedClass!,
                          quiz: _selectedQuiz!,
                          attempts: attempts,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await FileService.exportAnalyticsCsv(
                          classObj: _selectedClass!,
                          quiz: _selectedQuiz!,
                          attempts: attempts,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.cloud_sync, color: Colors.white),
                label: const Text('Sync Classroom'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassroomSyncScreen(classObj: _selectedClass!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 24),
              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.getBorderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribusi Nilai',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      _buildDistributionRow('80 - 100 (Sangat Baik)', rangeA, attempts.length),
                      _buildDistributionRow('60 - 79 (Baik)', rangeB, attempts.length),
                      _buildDistributionRow('40 - 59 (Cukup)', rangeC, attempts.length),
                      _buildDistributionRow('0 - 39 (Kurang)', rangeD, attempts.length),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Peringkat Mahasiswa (Nilai Terbaik)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              rankedStudents.isEmpty
                  ? Card(
                      color: AppTheme.getSurface(context),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Belum ada data peringkat.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rankedStudents.length,
                      itemBuilder: (context, index) {
                        final attempt = rankedStudents[index];
                        return Card(
                          color: AppTheme.getSurface(context),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.getBorderColor(context)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index == 0
                                  ? AppTheme.warning.withOpacity(0.2)
                                  : AppTheme.getSurfaceLight(context),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0 ? AppTheme.warning : null,
                                ),
                              ),
                            ),
                            title: Text(attempt.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Durasi: ${attempt.timeTaken} detik • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}'),
                            trailing: Text(
                              '${attempt.score} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
              Text(
                'Analisis Akurasi per Soal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.getBorderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _selectedQuiz!.questions.map((q) {
                      final correctCount = questionCorrectCount[q.id] ?? 0;
                      final totalAttempts = attempts.length;
                      final double pct = totalAttempts > 0 ? (correctCount / totalAttempts) * 100 : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: pct >= 80
                                  ? AppTheme.success.withOpacity(0.2)
                                  : (pct >= 50
                                      ? AppTheme.warning.withOpacity(0.2)
                                      : AppTheme.error.withOpacity(0.2)),
                              child: Text(
                                '${_selectedQuiz!.questions.indexOf(q) + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: pct >= 80
                                      ? AppTheme.success
                                      : (pct >= 50 ? AppTheme.warning : AppTheme.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.text, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Akurasi: ${pct.round()}% ($correctCount / $totalAttempts Siswa)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: pct >= 80
                                          ? AppTheme.success
                                          : (pct >= 50 ? AppTheme.warning : AppTheme.error),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Detail Jawaban Mahasiswa',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              attempts.isEmpty
                  ? Card(
                      color: AppTheme.getSurface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Belum ada mahasiswa yang menyelesaikan kuis ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = attempts[index];
                        return Card(
                          color: AppTheme.getSurface(context),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.getSurfaceLight(
                                context,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              attempt.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Skor: ${attempt.score} • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rincian Jawaban:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._selectedQuiz!.questions.map((question) {
                                      final studentAnswer =
                                          attempt.answers[question.id] ??
                                          "Tidak dijawab";
                                      final isCorrect =
                                          studentAnswer.toLowerCase().trim() ==
                                          question.correctAnswer
                                              .toLowerCase()
                                              .trim();
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              isCorrect
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: isCorrect
                                                  ? AppTheme.success
                                                  : AppTheme.error,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  text: '${question.text}\n',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.getTextPrimary(
                                                          context,
                                                        ),
                                                    fontSize: 13,
                                                    height: 1.4,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          'Jawaban: $studentAnswer ',
                                                      style: TextStyle(
                                                        color: isCorrect
                                                            ? AppTheme.success
                                                            : AppTheme.error,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (!isCorrect)
                                                      TextSpan(
                                                        text:
                                                            '(Kunci: ${question.correctAnswer})',
                                                        style: TextStyle(
                                                          color:
                                                              AppTheme.getTextSecondary(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total) {
    double pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                '$count attempt (${(pct * 100).round()}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.getBorderColor(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
