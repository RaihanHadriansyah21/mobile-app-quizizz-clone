import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../data/services/db_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import 'join_class.dart';
import 'class_detail.dart';

class MahasiswaDashboardScreen extends StatefulWidget {
  const MahasiswaDashboardScreen({super.key});

  @override
  State<MahasiswaDashboardScreen> createState() => _MahasiswaDashboardScreenState();
}

class _MahasiswaDashboardScreenState extends State<MahasiswaDashboardScreen> {
  bool _isLoadingDialog = false;

  void _showJoinCodeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurface(context),
              title: const Text('Gabung dengan Kode', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    labelText: 'Kode Kelas 6-Digit',
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Masukkan 6 digit kode kelas' : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                ),
                ElevatedButton(
                  onPressed: _isLoadingDialog
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => _isLoadingDialog = true);

                          final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser!.id;
                          final mahProv = Provider.of<MahasiswaProvider>(context, listen: false);

                          String? error = await mahProv.joinClassWithCode(
                            codeController.text.trim(),
                            studentId,
                          );

                          setState(() => _isLoadingDialog = false);
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            if (error != null) {
                              HapticFeedback.heavyImpact();
                              AppTheme.showPremiumSnackBar(
                                context,
                                error,
                                SnackBarType.error,
                              );
                            } else {
                              HapticFeedback.mediumImpact();
                              AppTheme.showPremiumSnackBar(
                                context,
                                "Berhasil bergabung ke kelas!",
                                SnackBarType.success,
                              );
                            }
                          }
                        },
                  child: _isLoadingDialog
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gabung'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startQrScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          onCodeScanned: (code) async {
            Navigator.pop(context);
            
            final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser!.id;
            final mahProv = Provider.of<MahasiswaProvider>(context, listen: false);
            
            String? error = await mahProv.joinClassWithCode(code.trim(), studentId);
            
            if (context.mounted) {
              if (error != null) {
                HapticFeedback.heavyImpact();
                AppTheme.showPremiumSnackBar(
                  context,
                  error,
                  SnackBarType.error,
                );
              } else {
                HapticFeedback.mediumImpact();
                AppTheme.showPremiumSnackBar(
                  context,
                  "Berhasil bergabung ke kelas!",
                  SnackBarType.success,
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.currentUser;
    if (student == null) return const SizedBox();

    final provider = context.watch<MahasiswaProvider>();
    final pastAttempts = provider.pastAttempts;

    int totalScore = pastAttempts.isEmpty ? 0 : pastAttempts.map((a) => a.score).reduce((a, b) => a + b);

    // If student hasn't joined any classes, show the Empty State!
    if (provider.joinedClasses.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Minimal Greeting Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : 'M',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: EmptyState(
                  title: 'Belum ada kelas yang diikuti',
                  description: 'Silakan bergabung dengan kelas menggunakan kode kelas atau memindai QR Code dari Dosen Anda.',
                  icon: Icons.school_outlined,
                  extraActions: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.doubleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showJoinCodeDialog(context),
                        icon: const Icon(Icons.pin, color: Colors.white),
                        label: const Text('Gabung dengan Kode Kelas', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _startQrScanner(context),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSkeletonBody() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 100, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  LoadingSkeleton(width: 160, height: 26, borderRadius: 6),
                ],
              ),
              LoadingSkeleton(width: 52, height: 52, borderRadius: 26),
            ],
          ),
          const SizedBox(height: 24),
          LoadingSkeleton(width: double.infinity, height: 110, borderRadius: 24),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 48, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: LoadingSkeleton(width: double.infinity, height: 48, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 32),
          LoadingSkeleton(width: 180, height: 20, borderRadius: 4),
          const SizedBox(height: 12),
          LoadingSkeleton(width: double.infinity, height: 80, borderRadius: 20),
          const SizedBox(height: 12),
          LoadingSkeleton(width: double.infinity, height: 80, borderRadius: 20),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData(student.id);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: provider.isLoading
                ? buildSkeletonBody()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Custom Greeting AppBar Panel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          student.name,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    Hero(
                      tag: 'student_avatar',
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.secondary.withOpacity(0.12),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'M',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  'Ready to continue learning?',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ).animate().fade(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 24),

                // Cumulative Stats Card (Pink-Purple Gradient Card)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.doubleGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars, size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NIM: ${student.nim ?? "-"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Skor Kumulatif',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$totalScore XP 🔥',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 150.ms, duration: 350.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 20),

                // Quick Join Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showJoinCodeDialog(context),
                          icon: const Icon(Icons.pin, size: 18, color: Colors.white),
                          label: const Text('Gabung Kode', style: TextStyle(fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          side: const BorderSide(color: AppTheme.secondary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _startQrScanner(context),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Scan QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 32),

                // Classes List Section
                _buildSectionTitle('Kelas & Mata Kuliah Anda', Icons.class_outlined, AppTheme.primary),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.joinedClasses.length,
                  itemBuilder: (context, index) {
                    final classObj = provider.joinedClasses[index];
                    final lecturer = DbService.getUserById(classObj.teacherId);
                    final lecturerName = lecturer?.name ?? 'Dosen Pengampu';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(context),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MahasiswaClassDetailScreen(classObj: classObj),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.school, color: AppTheme.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classObj.className,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dosen: $lecturerName',
                                      style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kode: ${classObj.code} • ${classObj.quizIds.length} Kuis',
                                      style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: AppTheme.getTextSecondary(context)),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: (250 + index * 50).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
                  },
                ),
                const SizedBox(height: 28),

                // Past Attempts History
                _buildSectionTitle('Riwayat Kuis Selesai', Icons.history, AppTheme.success),
                const SizedBox(height: 12),
                pastAttempts.isEmpty
                    ? _buildEmptyState('Anda belum pernah mengerjakan kuis.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pastAttempts.length,
                        itemBuilder: (context, index) {
                          final attempt = pastAttempts[index];
                          final quiz = DbService.getQuizById(attempt.quizId);
                          final quizTitle = quiz?.title ?? 'Kuis Terhapus';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.getSurface(context),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppTheme.premiumShadow,
                              border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stars, color: AppTheme.warning, size: 24),
                              ),
                              title: Text(
                                quizTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextPrimary(context),
                                ),
                              ),
                              subtitle: Text(
                                'Skor: ${attempt.score} XP • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                attempt.completedAt.toString().substring(0, 10),
                                style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ).animate().fade(delay: (300 + index * 50).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLight(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.getTextSecondary(context), fontStyle: FontStyle.italic),
      ),
    );
  }
}
