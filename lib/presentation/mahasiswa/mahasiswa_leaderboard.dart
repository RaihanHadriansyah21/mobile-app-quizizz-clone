import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/services/db_service.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/class_model.dart';
import '../../data/models/attempt_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';

class MahasiswaLeaderboardScreen extends StatefulWidget {
  const MahasiswaLeaderboardScreen({super.key});

  @override
  State<MahasiswaLeaderboardScreen> createState() =>
      _MahasiswaLeaderboardScreenState();
}

class _MahasiswaLeaderboardScreenState
    extends State<MahasiswaLeaderboardScreen> {
  ClassModel? _selectedClass;
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          hintText: 'Cari nama siswa...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPodium(List<_LeaderboardEntry> entries) {
    if (entries.isEmpty) return const SizedBox();
    
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Second place (Silver)
        if (second != null)
          Expanded(
            child: _buildPodiumColumn(
              entry: second,
              rank: 2,
              height: 100,
              color: const Color(0xFF94A3B8),
              emoji: '🥈',
            ),
          ),
        const SizedBox(width: 12),
        // First place (Gold)
        if (first != null)
          Expanded(
            child: _buildPodiumColumn(
              entry: first,
              rank: 1,
              height: 135,
              color: AppTheme.warning,
              emoji: '👑',
            ),
          ),
        const SizedBox(width: 12),
        // Third place (Bronze)
        if (third != null)
          Expanded(
            child: _buildPodiumColumn(
              entry: third,
              rank: 3,
              height: 80,
              color: const Color(0xFFD97706),
              emoji: '🥉',
            ),
          ),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildPodiumColumn({
    required _LeaderboardEntry entry,
    required int rank,
    required double height,
    required Color color,
    required String emoji,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: rank == 1 ? 30 : 25,
            backgroundColor: AppTheme.getSurfaceLight(context),
            child: Text(
              entry.name.substring(0, min(2, entry.name.length)).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
                fontSize: rank == 1 ? 16 : 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          '${entry.score} XP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.35),
                color.withOpacity(0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(width: double.infinity, height: 160, borderRadius: 24),
        const SizedBox(height: 28),
        LoadingSkeleton(width: double.infinity, height: 48, borderRadius: 12),
        const SizedBox(height: 28),
        LoadingSkeleton(width: 140, height: 20, borderRadius: 4),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 140, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 180, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(child: LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 16)),
          ],
        ),
      ],
    );
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

    final student = context.watch<AuthProvider>().currentUser;
    final isLoading = provider.isLoading;

    final filteredList = list
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final remainingEntries = filteredList.length > 3 ? filteredList.sublist(3) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Papan Peringkat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshData(student?.id ?? ''),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: isLoading
              ? _buildSkeletonBody()
              : Column(
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
                    'Pahlawan Kuis Kelas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jawab kuis dengan cepat & tepat untuk meraih peringkat teratas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
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
              const SizedBox(height: 20),
              _buildSearchBar(),
            ],

            if (classes.isEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada kelas diikuti.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
              ).animate().fade(delay: 100.ms, duration: 300.ms),
            ] else if (filteredList.isEmpty) ...[
              EmptyState(
                title: _searchQuery.isEmpty ? 'Belum Ada Peringkat' : 'Hasil Tidak Ditemukan',
                description: _searchQuery.isEmpty
                    ? 'Belum ada skor tercatat di kelas ini. Selesaikan kuis pertama kelas Anda!'
                    : 'Tidak ada siswa dengan nama "$_searchQuery" di kelas ini.',
                icon: Icons.emoji_events_outlined,
                illustrationType: EmptyIllustrationType.noAttempt,
              ),
            ] else ...[
              Text(
                'Tiga Terbaik 👑',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPodium(filteredList),
              const SizedBox(height: 24),
              
              if (remainingEntries.isNotEmpty) ...[
                Text(
                  'Peringkat Lainnya',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: remainingEntries.length,
                  itemBuilder: (context, index) {
                    final entry = remainingEntries[index];
                    final rank = index + 4;

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
                            color: AppTheme.getSurfaceLight(context),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                        title: Text(
                          entry.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${entry.quizzesPlayed} Kuis Selesai', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${entry.score} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ).animate().fade(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
                  },
                ),
              ],
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
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildBadgeCard(
                  'Speed Runner ⚡',
                  'Jawab benar dalam < 5 detik.',
                  badgeSpeedRunner,
                  const Color(0xFFF59E0B),
                ),
                _buildBadgeCard(
                  'Perfect Score 💯',
                  'Nilai sempurna 100% kuis.',
                  badgePerfectScore,
                  const Color(0xFF10B981),
                ),
                _buildBadgeCard(
                  'Quiz Master 🧠',
                  'Selesaikan 5 kuis.',
                  badgeQuizMaster,
                  AppTheme.primary,
                ),
                _buildBadgeCard(
                  'Booster User 🚀',
                  'Gunakan total 3 item power-up.',
                  badgeBooster,
                  AppTheme.secondary,
                ),
              ],
            ).animate().fade(delay: 200.ms, duration: 400.ms),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(String name, String desc, bool unlocked, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.getSurface(context)
            : AppTheme.getSurface(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked
              ? accentColor.withOpacity(0.5)
              : AppTheme.getBorderColor(context),
          width: 2,
        ),
        boxShadow: unlocked ? AppTheme.premiumShadow : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (unlocked)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.stars,
                  size: 60,
                  color: accentColor.withOpacity(0.08),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: unlocked
                          ? AppTheme.getTextPrimary(context)
                          : AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? accentColor.withOpacity(0.15)
                          : AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unlocked ? 'Terbuka' : 'Terkunci',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? accentColor
                            : AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ),
                ],
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
