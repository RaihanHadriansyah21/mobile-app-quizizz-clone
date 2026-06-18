import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
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

    try {
      await gameplay.submitQuizAttempt(studentId, studentName);
      if (mounted) {
        await Provider.of<MahasiswaProvider>(context, listen: false).refreshData(studentId, syncWithSupabase: false);
      }
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      if (mounted) {
        HapticFeedback.heavyImpact();
        AppTheme.showPremiumSnackBar(
          context,
          'Gagal menyimpan hasil: $e',
          SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.background : AppTheme.backgroundL,
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
                    height: 130,
                    width: 130,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 3),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: const Hero(
                      tag: 'result_trophy',
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 75,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
                
                Text(
                  'Kuis Selesai! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ).animate().fade(delay: 150.ms, duration: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Kerja bagus! Performa Anda telah dicatat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 15),
                ).animate().fade(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                    boxShadow: AppTheme.premiumShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Skor Akhir:',
                              style: TextStyle(
                                color: AppTheme.getTextSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$finalScore XP',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 32, color: AppTheme.getBorderColor(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Akurasi Jawaban:',
                              style: TextStyle(
                                color: AppTheme.getTextSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(accuracy * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Benar / Total:',
                              style: TextStyle(
                                color: AppTheme.getTextSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$correctAnswers dari $totalQuestions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 250.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const Spacer(),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleBackToDashboard,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Kembali ke Dashboard'),
                  ),
                ).animate().fade(delay: 350.ms, duration: 300.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
