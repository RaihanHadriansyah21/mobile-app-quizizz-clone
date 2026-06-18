import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';
import '../../core/widgets/loading_skeleton.dart';

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kelas baru berhasil dibuat! 🏫'),
                      backgroundColor: AppTheme.success,
                    ),
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
      appBar: AppBar(
        title: const Text('Dosen Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondary),
            onPressed: () => provider.refreshData(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card Dosen
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, Color(0xFFD63031)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, ${user.name}! 📚',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIP/NIDN: ${user.nim ?? "-"}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kelola kelas Anda, buat bank soal interaktif, dan pantau nilai tugas mahasiswa secara realtime.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Stats Cards
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
                      onTap: () => onTabChanged?.call(1), // Go to Kelas tab
                    ),
                    _buildStatCard(
                      context,
                      'Jumlah Kuis',
                      provider.quizzes.length.toString(),
                      Icons.quiz,
                      AppTheme.accent,
                      onTap: () => onTabChanged?.call(2), // Go to Bank Soal tab
                    ),
                  ],
                ),
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
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
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
                    AppTheme.accent,
                    onTap: () => onTabChanged?.call(2),
                  ),
                  _buildQuickActionItem(
                    context,
                    'Tugaskan',
                    Icons.assignment_turned_in,
                    AppTheme.secondary,
                    onTap: () => onTabChanged?.call(3),
                  ),
                  _buildQuickActionItem(
                    context,
                    'Analitik',
                    Icons.bar_chart,
                    Colors.green,
                    onTap: () => onTabChanged?.call(4),
                  ),
                ],
              ),
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
                const LoadingSkeleton(width: double.infinity, height: 100, borderRadius: 16),
              ] else if (myClasses.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
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
                    return Card(
                      color: AppTheme.getSurface(context),
                      margin: const EdgeInsets.only(bottom: 12),
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
                                    classObj.className,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: classObj.code));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Kode kelas disalin ke clipboard! 📋')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.people, size: 14, color: AppTheme.getTextSecondary(context)),
                                const SizedBox(width: 4),
                                Text(
                                  '${classObj.studentIds.length} Mahasiswa bergabung',
                                  style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.quiz, size: 14, color: AppTheme.getTextSecondary(context)),
                                const SizedBox(width: 4),
                                Text(
                                  '${classObj.quizIds.length} Kuis ditugaskan',
                                  style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    onTabChanged?.call(3); // Go to assignment tab
                                  },
                                  icon: const Icon(Icons.assignment, size: 14),
                                  label: const Text('Tugaskan Kuis', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: const BorderSide(color: AppTheme.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    provider.setSelectedClassForAnalytics(classObj);
                                    onTabChanged?.call(4); // Go to analytics tab
                                  },
                                  icon: const Icon(Icons.analytics, size: 14),
                                  label: const Text('Analitik', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context))),
            Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppTheme.getTextPrimary(context))),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 16),
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 16),
      ],
    );
  }
}
