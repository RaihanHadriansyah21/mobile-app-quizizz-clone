import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../data/services/db_service.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../data/models/class_model.dart';
import '../../data/models/attempt_model.dart';
import '../../core/theme/app_theme.dart';

class MahasiswaLeaderboardScreen extends StatefulWidget {
  const MahasiswaLeaderboardScreen({super.key});

  @override
  State<MahasiswaLeaderboardScreen> createState() =>
      _MahasiswaLeaderboardScreenState();
}

class _MahasiswaLeaderboardScreenState
    extends State<MahasiswaLeaderboardScreen> {
  ClassModel? _selectedClass;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MahasiswaProvider>(context, listen: false);
      if (provider.joinedClasses.isNotEmpty) {
        setState(() {
          _selectedClass = provider.joinedClasses.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();
    final classes = provider.joinedClasses;

    // --- BADGE COMPUTATION (from this student's real attempts) ---
    final myAttempts = provider.pastAttempts;
    final int quizzesCompleted = myAttempts.length;
    final bool hasPerfectScore = myAttempts.any(
      (a) => a.totalQuestions > 0 && a.correctAnswersCount == a.totalQuestions,
    );
    final int fastestCorrect = myAttempts.isEmpty
        ? 9999
        : myAttempts.map((a) => a.fastestCorrectSeconds).reduce(min);
    final int totalPowerUpsUsed = myAttempts.fold(
      0,
      (sum, a) => sum + a.powerUpsUsed,
    );

    final bool badgeSpeedRunner = fastestCorrect <= 5;
    final bool badgePerfectScore = hasPerfectScore;
    final bool badgeQuizMaster = quizzesCompleted >= 5;
    final bool badgeBooster = totalPowerUpsUsed >= 3;

    // Ensure selected class is valid
    final activeClass = classes.contains(_selectedClass)
        ? _selectedClass
        : (classes.isNotEmpty ? classes.first : null);

    final attempts = DbService.getAttempts();
    final List<_LeaderboardEntry> list = [];

    if (activeClass != null) {
      // 1. Group attempts by studentId and quizId, selecting the best attempt
      final Map<String, Map<String, AttemptModel>> studentBestAttemptsByQuiz = {}; // studentId -> {quizId -> Attempt}
      
      for (var attempt in attempts) {
        if (activeClass.studentIds.contains(attempt.studentId) &&
            activeClass.quizIds.contains(attempt.quizId)) {
          final studentId = attempt.studentId;
          final quizId = attempt.quizId;
          
          studentBestAttemptsByQuiz.putIfAbsent(studentId, () => {});
          final bestAttempts = studentBestAttemptsByQuiz[studentId]!;
          
          final existing = bestAttempts[quizId];
          if (existing == null || 
              attempt.score > existing.score || 
              (attempt.score == existing.score && attempt.timeTaken < existing.timeTaken)) {
            bestAttempts[quizId] = attempt;
          }
        }
      }
      
      // 2. Aggregate the best attempts per student
      final Map<String, _LeaderboardEntry> scoresMap = {};
      studentBestAttemptsByQuiz.forEach((studentId, quizzesMap) {
        for (var attempt in quizzesMap.values) {
          if (scoresMap.containsKey(studentId)) {
            scoresMap[studentId] = _LeaderboardEntry(
              name: attempt.studentName,
              score: scoresMap[studentId]!.score + attempt.score,
              quizzesPlayed: scoresMap[studentId]!.quizzesPlayed + 1,
              totalTimeSeconds: scoresMap[studentId]!.totalTimeSeconds + attempt.timeTaken,
            );
          } else {
            scoresMap[studentId] = _LeaderboardEntry(
              name: attempt.studentName,
              score: attempt.score,
              quizzesPlayed: 1,
              totalTimeSeconds: attempt.timeTaken,
            );
          }
        }
      });

      list.addAll(scoresMap.values);
      list.sort((a, b) {
        int scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.totalTimeSeconds.compareTo(b.totalTimeSeconds); // time ASC
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Papan Peringkat',
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
            // Header Trophy Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.emoji_events, size: 70, color: AppTheme.warning),
                  SizedBox(height: 12),
                  Text(
                    'Pahlawan Kuis Kelas 🏆',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jawab kuis dengan cepat & tepat untuk meraih peringkat teratas!',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Class Selector Dropdown
            if (classes.isNotEmpty) ...[
              Text(
                'Pilih Kelas untuk Peringkat',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ClassModel>(
                initialValue: activeClass,
                dropdownColor: AppTheme.getSurface(context),
                iconEnabledColor: AppTheme.secondary,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: classes.map((c) {
                  return DropdownMenuItem<ClassModel>(
                    value: c,
                    child: Text(
                      c.className,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = val;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            Text(
              activeClass != null
                  ? 'Peringkat Kelas: ${activeClass.className}'
                  : 'Rapor Peringkat Mahasiswa',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (classes.isEmpty) ...[
              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.getBorderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada kelas diikuti.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Silakan bergabung dengan kelas terlebih dahulu untuk melihat peringkat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (list.isEmpty) ...[
              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.getBorderColor(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Belum ada skor tercatat di kelas ini. Selesaikan kuis pertama kelas Anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final entry = list[index];
                  final rank = index + 1;

                  Color rankColor = AppTheme.textSecondary;
                  IconData? rankIcon;
                  if (rank == 1) {
                    rankColor = AppTheme.warning; // Gold
                    rankIcon = Icons.workspace_premium;
                  } else if (rank == 2) {
                    rankColor = const Color(0xFFBDC3C7); // Silver
                    rankIcon = Icons.workspace_premium;
                  } else if (rank == 3) {
                    rankColor = const Color(0xFFD35400); // Bronze
                    rankIcon = Icons.workspace_premium;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: rank <= 3
                        ? AppTheme.getSurfaceLight(context)
                        : AppTheme.getSurface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: rank == 1
                            ? AppTheme.warning.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: rankIcon != null
                            ? Icon(rankIcon, color: rankColor, size: 28)
                            : Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      title: Text(
                        entry.name,
                        style: TextStyle(
                          fontWeight: rank <= 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('${entry.quizzesPlayed} Kuis Selesai'),
                      trailing: Text(
                        '${entry.score} XP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? rankColor : AppTheme.accent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 28),

            Text(
              'Lencana Pencapaian (Badges)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildBadgeCard(
                  'Speed Runner ⚡',
                  'Jawab benar dalam < 5 detik.',
                  badgeSpeedRunner,
                ),
                _buildBadgeCard(
                  'Perfect Score 💯',
                  'Nilai sempurna 100% kuis.',
                  badgePerfectScore,
                ),
                _buildBadgeCard(
                  'Quiz Master 🧠',
                  'Selesaikan 5 kuis.',
                  badgeQuizMaster,
                ),
                _buildBadgeCard(
                  'Booster User 🚀',
                  'Gunakan total 3 item power-up.',
                  badgeBooster,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(String name, String desc, bool unlocked) {
    return Card(
      color: unlocked
          ? AppTheme.getSurfaceLight(context)
          : AppTheme.getSurface(context).withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: unlocked
                    ? AppTheme.getTextPrimary(context)
                    : AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.success.withOpacity(0.2)
                    : AppTheme.getBorderColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                unlocked ? 'Terbuka' : 'Terkunci',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: unlocked
                      ? AppTheme.success
                      : AppTheme.getTextSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  final String name;
  final int score;
  final int quizzesPlayed;
  final int totalTimeSeconds;

  _LeaderboardEntry({
    required this.name,
    required this.score,
    required this.quizzesPlayed,
    required this.totalTimeSeconds,
  });
}
