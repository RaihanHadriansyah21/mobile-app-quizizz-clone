import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/mahasiswa_provider.dart';
import '../../data/services/db_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: AppTheme.error),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Berhasil bergabung ke kelas! 🎓"),
                                  backgroundColor: AppTheme.success,
                                ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: AppTheme.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Berhasil bergabung ke kelas! 🎓"),
                    backgroundColor: AppTheme.success,
                  ),
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
        appBar: AppBar(
          title: const Text('Dashboard Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: EmptyState(
          title: 'Belum ada kelas yang diikuti',
          description: 'Silakan bergabung dengan kelas menggunakan kode kelas atau memindai QR Code dari Dosen Anda.',
          icon: Icons.school_outlined,
          extraActions: [
            ElevatedButton.icon(
              onPressed: () => _showJoinCodeDialog(context),
              icon: const Icon(Icons.pin),
              label: const Text('Gabung dengan Kode Kelas'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent, width: 1.5),
              ),
              onPressed: () => _startQrScanner(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code Kelas'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.refreshData(student.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Quick Stats Card
              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.getBorderColor(context))),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.school, size: 30, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, ${student.name}!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('NIM: ${student.nim ?? "-"}', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Skor Kumulatif: $totalScore XP 🔥', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Join buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showJoinCodeDialog(context),
                      icon: const Icon(Icons.pin, size: 18),
                      label: const Text('Gabung Kode', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _startQrScanner(context),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan QR', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

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

                  return Card(
                    color: AppTheme.getSurface(context),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.getBorderColor(context)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MahasiswaClassDetailScreen(classObj: classObj),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dosen: $lecturerName',
                                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kode: ${classObj.code} • ${classObj.quizIds.length} Kuis Tersedia',
                                    style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppTheme.getSurface(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.getBorderColor(context))),
                          child: ListTile(
                            leading: const Icon(Icons.stars, color: AppTheme.warning),
                            title: Text(quizTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Skor: ${attempt.score} XP • Benar: ${attempt.correctAnswersCount}/${attempt.totalQuestions}'),
                            trailing: Text(
                              attempt.completedAt.toString().substring(0, 10),
                              style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
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

  Widget _buildEmptyState(String text) {
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
}
