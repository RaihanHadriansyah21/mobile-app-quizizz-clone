import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/class_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../data/providers/gameplay_provider.dart';
import '../../data/services/db_service.dart';
import '../../core/theme/app_theme.dart';
import 'gameplay_screen.dart';

class MahasiswaClassDetailScreen extends StatelessWidget {
  final ClassModel classObj;
  const MahasiswaClassDetailScreen({super.key, required this.classObj});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();
    
    // Filter quizzes assigned to this class
    final classQuizzes = provider.availableQuizzes
        .where((q) => classObj.quizIds.contains(q.id))
        .toList();
    
    final homeworks = classQuizzes.where((q) => q.isHomework).toList();
    final liveQuizzes = classQuizzes.where((q) => !q.isHomework).toList();
    final pastAttempts = provider.pastAttempts;

    final lecturer = DbService.getUserById(classObj.teacherId);
    final lecturerName = lecturer?.name ?? 'Dosen Pengampu';

    return Scaffold(
      appBar: AppBar(
        title: Text(classObj.className, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Class Info Card
            Card(
              color: AppTheme.getSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
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
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classObj.className,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dosen: $lecturerName',
                                style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kode Join: ${classObj.code}',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${classObj.studentIds.length} Siswa Bergabung',
                          style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Active Live Quizzes
            _buildSectionTitle(context, 'Kuis Kelas (Live/Aktif)', Icons.bolt, AppTheme.accent),
            const SizedBox(height: 12),
            liveQuizzes.isEmpty
                ? _buildEmptyState(context, 'Tidak ada kuis kelas aktif saat ini.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = liveQuizzes[index];
                      return _buildQuizCard(context, quiz, false, pastAttempts);
                    },
                  ),
            const SizedBox(height: 28),

            // Homework Quizzes
            _buildSectionTitle(context, 'Pekerjaan Rumah (Homework)', Icons.menu_book, AppTheme.warning),
            const SizedBox(height: 12),
            homeworks.isEmpty
                ? _buildEmptyState(context, 'Bebas tugas! Semua PR kelas ini sudah selesai.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: homeworks.length,
                    itemBuilder: (context, index) {
                      final quiz = homeworks[index];
                      return _buildQuizCard(context, quiz, true, pastAttempts);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz, bool isHomework, List<dynamic> pastAttempts) {
    final now = DateTime.now();
    final isLocked = isHomework && quiz.deadline != null && now.isAfter(quiz.deadline!);

    return Card(
      color: AppTheme.getSurface(context),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isLocked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, size: 12, color: AppTheme.error),
                        SizedBox(width: 4),
                        Text('Terkunci', style: TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              quiz.description,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (isHomework && quiz.deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tenggat: ${quiz.deadline.toString().substring(0, 16)}',
                style: TextStyle(
                  color: isLocked ? AppTheme.error : AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${quiz.questions.length} Soal',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                ElevatedButton(
                  onPressed: isLocked
                      ? null
                      : () {
                          final attemptsForQuiz = pastAttempts.where((a) => a.quizId == quiz.id).length;
                          if (quiz.maxAttempts > 0 && attemptsForQuiz >= quiz.maxAttempts) {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: AppTheme.getSurface(context),
                                title: const Text('Batas Pengerjaan Tercapai', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Text('Anda telah mengerjakan kuis ini sebanyak $attemptsForQuiz kali dari batas maksimum ${quiz.maxAttempts} kali.'),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('Tutup'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          final gameplay = Provider.of<GameplayProvider>(context, listen: false);
                          gameplay.startQuiz(quiz, classId: classObj.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QuizPlayScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked
                        ? AppTheme.getSurfaceLight(context)
                        : isHomework
                            ? AppTheme.warning
                            : AppTheme.primary,
                    foregroundColor: isLocked ? Colors.white38 : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(isLocked ? 'Tenggat Lewat' : 'Mulai Kuis', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
