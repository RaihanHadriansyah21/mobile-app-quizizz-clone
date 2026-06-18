import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/class_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/attempt_model.dart';
import '../../data/providers/dosen_provider.dart';
import '../../data/services/file_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import 'classroom_sync.dart';

class DosenAnalyticsScreen extends StatefulWidget {
  const DosenAnalyticsScreen({super.key});

  @override
  State<DosenAnalyticsScreen> createState() => _DosenAnalyticsScreenState();
}

class _DosenAnalyticsScreenState extends State<DosenAnalyticsScreen> {
  ClassModel? _selectedClass;
  QuizModel? _selectedQuiz;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          hintText: 'Cari nama mahasiswa...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSkeletonBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(width: double.infinity, height: 48, borderRadius: 12),
        const SizedBox(height: 16),
        LoadingSkeleton(width: double.infinity, height: 48, borderRadius: 12),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
            const SizedBox(width: 16),
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
            const SizedBox(width: 16),
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 90, borderRadius: 16)),
          ],
        ),
      ],
    );
  }

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

    final filteredRankedStudents = rankedStudents
        .where((a) => a.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final filteredAttempts = attempts
        .where((a) => a.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
      body: RefreshIndicator(
        onRefresh: () => provider.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: provider.isLoading
              ? _buildSkeletonBody()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            DropdownButtonFormField<ClassModel>(
              initialValue: classes.contains(_selectedClass)
                  ? _selectedClass
                  : null,
              dropdownColor: AppTheme.getSurface(context),
              iconEnabledColor: AppTheme.secondary,
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
                dropdownColor: AppTheme.getSurface(context),
                iconEnabledColor: AppTheme.primary,
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
            if (_selectedQuiz != null) ...[
              const SizedBox(height: 16),
              _buildSearchBar(),
            ],
            const SizedBox(height: 20),

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
                      AppTheme.primary,
                    ),
                  ),
                ],
              ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Nilai Tertinggi',
                      '$highestScore XP',
                      Icons.emoji_events_outlined,
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Nilai Terendah',
                      '$lowestScore XP',
                      Icons.trending_down,
                      AppTheme.error,
                    ),
                  ),
                ],
              ).animate().fade(delay: 50.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _buildParticipationCard(jumlahPeserta, totalMahasiswa, jumlahAttempt, perfectScores)
                  .animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_outlined, color: AppTheme.error, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Soal Tersulit',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hardestQuestionText == "N/A"
                                  ? "N/A"
                                  : hardestQuestionText.length > 25
                                  ? '${hardestQuestionText.substring(0, 22)}... (${hardestQuestionAccuracy.round()}% Benar)'
                                  : '$hardestQuestionText (${hardestQuestionAccuracy.round()}% Benar)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 150.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppTheme.successGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppTheme.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.grid_on, color: Colors.white),
                        label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                  ),
                ],
              ).animate().fade(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.cloud_sync, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary),
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
              ).animate().fade(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribusi Nilai',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildDistributionRow('80 - 100 (Sangat Baik)', rangeA, attempts.length, AppTheme.success),
                      _buildDistributionRow('60 - 79 (Baik)', rangeB, attempts.length, AppTheme.primary),
                      _buildDistributionRow('40 - 59 (Cukup)', rangeC, attempts.length, AppTheme.warning),
                      _buildDistributionRow('0 - 39 (Kurang)', rangeD, attempts.length, AppTheme.error),
                    ],
                  ),
                ),
              ).animate().fade(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 32),
              
              Text(
                'Peringkat Mahasiswa (Nilai Terbaik)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              filteredRankedStudents.isEmpty
                  ? EmptyState(
                      title: _searchQuery.isEmpty ? 'Belum Ada Peringkat' : 'Hasil Tidak Ditemukan',
                      description: _searchQuery.isEmpty
                          ? 'Belum ada data peringkat untuk kuis ini.'
                          : 'Tidak ada mahasiswa dengan nama "$_searchQuery".',
                      icon: Icons.emoji_events_outlined,
                      illustrationType: EmptyIllustrationType.noAnalytics,
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRankedStudents.length,
                      itemBuilder: (context, index) {
                        final attempt = filteredRankedStudents[index];
                        final rank = index + 1;
                        Color medalColor = Colors.grey;
                        if (rank == 1) medalColor = AppTheme.warning;
                        else if (rank == 2) medalColor = const Color(0xFFBDC3C7);
                        else if (rank == 3) medalColor = const Color(0xFFCD7F32);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: rank <= 3 ? medalColor.withOpacity(0.15) : AppTheme.getSurfaceLight(context),
                                shape: BoxShape.circle,
                                border: rank <= 3 ? Border.all(color: medalColor, width: 1.5) : null,
                              ),
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rank <= 3 ? medalColor : AppTheme.getTextPrimary(context),
                                ),
                              ),
                            ),
                            title: Text(attempt.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Durasi: ${attempt.timeTaken}s • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '${attempt.score} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 15),
                            ),
                          ),
                        ).animate().fade(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.08, end: 0);
                      },
                    ),
              const SizedBox(height: 32),
              
              Text(
                'Analisis Akurasi per Soal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: _selectedQuiz!.questions.map((q) {
                      final correctCount = questionCorrectCount[q.id] ?? 0;
                      final totalAttempts = attempts.length;
                      final double pct = totalAttempts > 0 ? (correctCount / totalAttempts) * 100 : 0.0;
                      final int questionNumber = _selectedQuiz!.questions.indexOf(q) + 1;
                      
                      Color statColor = AppTheme.error;
                      if (pct >= 85) statColor = AppTheme.success;
                      else if (pct >= 50) statColor = AppTheme.warning;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: statColor.withOpacity(0.15),
                              child: Text(
                                '$questionNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Akurasi: ${pct.round()}% ($correctCount / $totalAttempts Siswa)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statColor,
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
              ).animate().fade(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 32),
              
              Text(
                'Detail Jawaban Mahasiswa',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              filteredAttempts.isEmpty
                  ? EmptyState(
                      title: _searchQuery.isEmpty ? 'Belum Ada Percobaan' : 'Hasil Tidak Ditemukan',
                      description: _searchQuery.isEmpty
                          ? 'Belum ada mahasiswa yang menyelesaikan kuis ini.'
                          : 'Tidak ada detail percobaan dengan nama "$_searchQuery".',
                      icon: Icons.assignment_outlined,
                      illustrationType: EmptyIllustrationType.noAttempt,
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAttempts.length,
                      itemBuilder: (context, index) {
                        final attempt = filteredAttempts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.getSurfaceLight(context),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextPrimary(context),
                                  ),
                                ),
                              ),
                              title: Text(
                                attempt.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Skor: ${attempt.score} • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rincian Jawaban:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                                      color: AppTheme.getTextPrimary(context),
                                                      fontSize: 13,
                                                      height: 1.4,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: 'Jawaban: $studentAnswer ',
                                                        style: TextStyle(
                                                          color: isCorrect
                                                              ? AppTheme.success
                                                              : AppTheme.error,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (!isCorrect)
                                                        TextSpan(
                                                          text: '(Kunci: ${question.correctAnswer})',
                                                          style: TextStyle(
                                                            color: AppTheme.getTextSecondary(context),
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
                          ),
                        ).animate().fade(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.08, end: 0);
                      },
                    ),
                  ],
                ],
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCard(
    int jumlahPeserta,
    int totalMahasiswa,
    int jumlahAttempt,
    int perfectScores,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_alt_outlined, color: AppTheme.warning, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partisipasi & Hasil Kelas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Detail statistik pengerjaan mahasiswa',
                        style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: AppTheme.getBorderColor(context)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubStat('Peserta', '$jumlahPeserta / $totalMahasiswa', AppTheme.primary),
                _buildSubStat('Percobaan', '$jumlahAttempt Kali', AppTheme.secondary),
                _buildSubStat('Sempurna', '$perfectScores Siswa', AppTheme.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color) {
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
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
