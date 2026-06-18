import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/services/db_service.dart';
import '../../data/providers/admin_provider.dart';
import '../../core/widgets/loading_skeleton.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Function(int)? onTabChanged;

  const AdminDashboardScreen({super.key, this.onTabChanged});

  void _showAddUserDialog(BuildContext context, AdminProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(
      text: 'password123',
    ); // prefill default
    final nimController = TextEditingController();
    UserRole selectedRole = UserRole.mahasiswa;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
              ),
              title: const Text(
                'Tambah Pengguna Baru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        dropdownColor: AppTheme.getSurface(context),
                        decoration: const InputDecoration(
                          labelText: 'Peran / Role',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.mahasiswa,
                            child: Text('Mahasiswa (Student)'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.dosen,
                            child: Text('Dosen (Lecturer)'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text('Admin (Administrator)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          hintText: 'Misal: Budi Santoso',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nama tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nimController,
                        decoration: const InputDecoration(
                          labelText: 'NIM / NIP',
                          hintText: 'Min. 7 digit angka',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'NIM/NIP wajib diisi';
                          }
                          if (!RegExp(r'^\d+$').hasMatch(val)) {
                            return 'NIM/NIP harus berupa angka';
                          }
                          if (val.trim().length < 7) {
                            return 'NIM/NIP minimal 7 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Misal: budi@quizizz.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!val.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Awal',
                          helperText:
                              'Kata sandi default untuk masuk pertama kali.',
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Sandi tidak boleh kosong'
                            : null,
                      ),
                    ],
                  ),
                ),
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
                    if (!formKey.currentState!.validate()) return;

                    final newUser = UserModel(
                      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      role: selectedRole,
                      password: passwordController.text,
                      nim: nimController.text.trim(),
                    );

                    if (selectedRole == UserRole.dosen) {
                      await provider.saveDosen(newUser);
                    } else if (selectedRole == UserRole.mahasiswa) {
                      await provider.saveMahasiswa(newUser);
                    } else {
                      await DbService.saveUser(newUser);
                      await provider.refreshData(syncWithSupabase: false);
                    }

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      HapticFeedback.mediumImpact();
                      AppTheme.showPremiumSnackBar(
                        context,
                        'Akun ${selectedRole.name.toUpperCase()} berhasil dibuat!',
                        SnackBarType.success,
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: () => provider.refreshData(),
          ),
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
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang, Admin! 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kelola pengguna, monitoring kelas, dan awasi perkembangan kuis secara global.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Text(
                'Statistik Sistem',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                      'Total Dosen',
                      provider.dosenList.length.toString(),
                      Icons.supervised_user_circle,
                      AppTheme.primary,
                      onTap: () => onTabChanged?.call(1),
                    ),
                    _buildStatCard(
                      context,
                      'Total Mahasiswa',
                      provider.mahasiswaList.length.toString(),
                      Icons.school,
                      AppTheme.secondary,
                      onTap: () => onTabChanged?.call(1),
                    ),
                    _buildStatCard(
                      context,
                      'Total Kelas',
                      provider.classes.length.toString(),
                      Icons.class_,
                      AppTheme.accent,
                      onTap: () => onTabChanged?.call(2),
                    ),
                    _buildStatCard(
                      context,
                      'Total Kuis',
                      provider.quizzes.length.toString(),
                      Icons.quiz,
                      AppTheme.success,
                      onTap: () => onTabChanged?.call(3),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),

              // Quick Actions Bar
              Text(
                'Aksi Cepat Admin',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    'Kelola User',
                    Icons.people,
                    AppTheme.primary,
                    onTap: () => onTabChanged?.call(1),
                  ),
                  _buildQuickActionItem(
                    context,
                    'Monitoring',
                    Icons.school,
                    AppTheme.accent,
                    onTap: () => onTabChanged?.call(2),
                  ),
                  _buildQuickActionItem(
                    context,
                    'Statistik',
                    Icons.query_stats,
                    AppTheme.success,
                    onTap: () => onTabChanged?.call(3),
                  ),
                  _buildQuickActionItem(
                    context,
                    'Tambah User',
                    Icons.person_add,
                    AppTheme.secondary,
                    onTap: () => _showAddUserDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Activity Monitoring
              Text(
                'Aktivitas Kuis Terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isLoading) ...[
                const LoadingSkeleton(
                  width: double.infinity,
                  height: 100,
                  borderRadius: 16,
                ),
              ] else if (provider.attempts.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Text(
                    'Belum ada pengerjaan kuis terbaru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.getTextSecondary(context)),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.attempts.length > 5
                      ? 5
                      : provider.attempts.length,
                  itemBuilder: (context, index) {
                    final attempt = provider.attempts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppTheme.getSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.getBorderColor(context),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          attempt.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Skor: ${attempt.score} | Soal Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}',
                        ),
                        trailing: Text(
                          attempt.completedAt.toString().substring(0, 10),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextSecondary(context),
                          ),
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
            Row(
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppTheme.getTextSecondary(context).withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 26,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
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
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 16),
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: 16),
      ],
    );
  }
}
