import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/dosen_speed_dial.dart';
import '../../data/services/db_service.dart';
import 'question_bank_crud.dart';

class DosenDashboardScreen extends StatelessWidget {
  final Function(int)? onTabChanged;

  const DosenDashboardScreen({super.key, this.onTabChanged});

  void _showCreateClassDialog(BuildContext context, String teacherId, DosenProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        title: const Text('Buat Kelas Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Kelas',
            hintText: 'Misal: Kelas XI IPA 1',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                // Tunggu saveClass selesai sebelum menutup dialog
                // agar list kelas ter-refresh dan QR code bisa langsung diakses
                await provider.saveClass(controller.text.trim(), teacherId);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  HapticFeedback.mediumImpact();
                  AppTheme.showPremiumSnackBar(
                    context,
                    'Kelas baru berhasil dibuat!',
                    SnackBarType.success,
                  );
                }
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<DosenProvider>();
    final isLoading = provider.isLoading;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Tidak ada user")));
    }

    final myClasses = provider.classes;

    return Scaffold(
      floatingActionButton: DosenSpeedDial(
        onCreateClass: () => _showCreateClassDialog(context, user.id, provider),
        onCreateQuiz: () => Navigator.push(
          context,
          AppTheme.pageRoute(const QuizEditorScreen(quiz: null)),
        ),
        onCreateQuestion: () {
          showDialog(
            context: context,
            builder: (ctx) => QuestionFormDialog(
              question: null,
              onSave: (newQuestion) async {
                await DbService.saveQuestion(newQuestion);
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  AppTheme.showPremiumSnackBar(
                    context,
                    'Soal baru berhasil ditambahkan ke bank soal!',
                    SnackBarType.success,
                  );
                }
              },
            ),
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // extra padding for bottom navigation bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom App Bar Greeting Panel
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
                          user.name,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.secondary.withOpacity(0.12),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'D',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 16),
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

                // Welcome Card Dosen (Pink-Teal Gradient Card)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIP/NIDN: ${user.nim ?? "-"}',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kelola kelas Anda, buat bank kuis, dan pantau nilai tugas mahasiswa secara realtime.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), height: 1.5),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 150.ms, duration: 350.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),

                Text(
                  'Ikhtisar Anda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (isLoading) ...[
                  const _StatsGridSkeleton(),
                ] else ...[
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        context,
                        'Jumlah Kelas',
                        provider.classes.length.toString(),
                        Icons.school,
                        AppTheme.primary,
                        onTap: () => onTabChanged?.call(1),
                      ),
                      _buildStatCard(
                        context,
                        'Jumlah Kuis',
                        provider.quizzes.length.toString(),
                        Icons.quiz,
                        AppTheme.secondary,
                        onTap: () => onTabChanged?.call(2),
                      ),
                    ],
                  ).animate().fade(delay: 200.ms, duration: 300.ms),
                ],
                const SizedBox(height: 28),

                // Quick Actions Bar
                Text(
                  'Aksi Cepat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.95,
                  children: [
                    _buildQuickActionItem(
                      context,
                      'Buat Kelas',
                      Icons.add_home_work,
                      AppTheme.primary,
                      onTap: () => _showCreateClassDialog(context, user.id, provider),
                    ),
                    _buildQuickActionItem(
                      context,
                      'Bank Soal',
                      Icons.question_answer,
                      AppTheme.secondary,
                      onTap: () => onTabChanged?.call(2),
                    ),
                    _buildQuickActionItem(
                      context,
                      'Tugaskan',
                      Icons.assignment_turned_in,
                      AppTheme.accent,
                      onTap: () => onTabChanged?.call(3),
                    ),
                    _buildQuickActionItem(
                      context,
                      'Analitik',
                      Icons.bar_chart,
                      AppTheme.success,
                      onTap: () => onTabChanged?.call(4),
                    ),
                  ],
                ).animate().fade(delay: 250.ms, duration: 300.ms),
                const SizedBox(height: 28),

                // Classes List Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Kelas Anda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => onTabChanged?.call(1),
                      icon: const Icon(Icons.edit, size: 14, color: AppTheme.secondary),
                      label: const Text('Kelola', style: TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (isLoading) ...[
                  const LoadingSkeleton(width: double.infinity, height: 100, borderRadius: 24),
                ] else if (myClasses.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.school_outlined, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada kelas yang dibuat.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gunakan menu "Buat Kelas" di atas untuk memulai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myClasses.length,
                    itemBuilder: (context, index) {
                      final classObj = myClasses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.getSurface(context),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.premiumShadow,
                          border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      classObj.className,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.getTextPrimary(context),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: classObj.code));
                                      HapticFeedback.lightImpact();
                                      AppTheme.showPremiumSnackBar(
                                        context,
                                        'Kode kelas disalin ke clipboard!',
                                        SnackBarType.success,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Kode: ${classObj.code}',
                                            style: const TextStyle(
                                              color: AppTheme.secondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.copy, size: 12, color: AppTheme.secondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 14, color: AppTheme.getTextSecondary(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${classObj.studentIds.length} Siswa',
                                    style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.quiz, size: 14, color: AppTheme.getTextSecondary(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${classObj.quizIds.length} Kuis',
                                    style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: AppTheme.getBorderColor(context), height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      onTabChanged?.call(3);
                                    },
                                    icon: const Icon(Icons.assignment, size: 14),
                                    label: const Text('Tugaskan Kuis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      provider.setSelectedClassForAnalytics(classObj);
                                      onTabChanged?.call(4);
                                    },
                                    icon: const Icon(Icons.analytics, size: 14),
                                    label: const Text('Analitik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: (300 + index * 50).ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.premiumShadow,
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w500)),
            Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28, color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.premiumShadow,
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 24),
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 24),
      ],
    );
  }
}
