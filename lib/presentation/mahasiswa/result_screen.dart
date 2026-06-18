import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/gameplay_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../core/theme/app_theme.dart';
import 'mahasiswa_main_navigation.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _submitting = false;

  Future<void> _handleBackToDashboard() async {
    setState(() => _submitting = true);

    final gameplay = Provider.of<GameplayProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.currentUser!.id;
    final studentName = auth.currentUser!.name;

    await gameplay.submitQuizAttempt(studentId, studentName);
    
    if (mounted) {
      await Provider.of<MahasiswaProvider>(context, listen: false).refreshData(studentId, syncWithSupabase: false);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MahasiswaMainNavigation()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameplay = context.watch<GameplayProvider>();
    final totalQuestions = gameplay.activeQuiz?.questions.length ?? 0;
    final correctAnswers = gameplay.correctCount;
    final finalScore = gameplay.score;

    double accuracy = 0.0;
    if (totalQuestions > 0) {
      accuracy = correctAnswers / totalQuestions;
    }

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, Color(0xFF130F26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 70,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                const Text(
                  'Kuis Selesai! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kerja bagus! Performa Anda telah dicatat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),

                Card(
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Skor Akhir:', style: TextStyle(color: AppTheme.textSecondary)),
                            Text('$finalScore XP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Akurasi Jawaban:', style: TextStyle(color: AppTheme.textSecondary)),
                            Text('${(accuracy * 100).round()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Benar / Total:', style: TextStyle(color: AppTheme.textSecondary)),
                            Text('$correctAnswers dari $totalQuestions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                ElevatedButton(
                  onPressed: _submitting ? null : _handleBackToDashboard,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Kembali ke Dashboard'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
