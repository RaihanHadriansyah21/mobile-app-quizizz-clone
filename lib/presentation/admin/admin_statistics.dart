import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/models/user_model.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final quizzes = provider.quizzes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: quizzes.isEmpty
          ? Center(
              child: Text(
                'Belum ada kuis yang dibuat oleh Dosen.',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                
                // Find Dosen name
                final lecturer = provider.users.firstWhere(
                  (u) => u.id == quiz.creatorId,
                  orElse: () => provider.users.firstWhere((u) => u.role == UserRole.dosen),
                );

                // Find attempts count
                final quizAttempts = provider.attempts.where((a) => a.quizId == quiz.id).toList();

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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: quiz.isHomework ? AppTheme.accent.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                quiz.isHomework ? 'Mode PR' : 'Mode Live',
                                style: TextStyle(
                                  color: quiz.isHomework ? AppTheme.accent : AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quiz.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: AppTheme.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Pembuat: ${lecturer.name}',
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.question_answer_outlined, size: 16, color: AppTheme.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Jumlah Pertanyaan: ${quiz.questions.length}',
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: AppTheme.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Pengerjaan Mahasiswa: ${quizAttempts.length} Percobaan',
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                            ),
                          ],
                        ),
                        if (quiz.deadline != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppTheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                'Tenggat: ${quiz.deadline.toString().substring(0, 16)}',
                                style: const TextStyle(color: AppTheme.secondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(color: AppTheme.getBorderColor(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.getSurface(context),
                                    title: const Text('Hapus Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('Apakah Anda yakin ingin menghapus kuis ${quiz.title}? Tindakan ini permanen.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                        onPressed: () async {
                                          await provider.deleteQuiz(quiz.id);
                                          if (context.mounted) Navigator.pop(ctx);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Hapus Kuis', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
