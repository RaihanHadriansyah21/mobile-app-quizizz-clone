import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/models/user_model.dart';

class AdminClassManagementScreen extends StatelessWidget {
  const AdminClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final classes = provider.classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: classes.isEmpty
          ? Center(
              child: Text(
                'Belum ada kelas yang dibuat oleh Dosen.',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classObj = classes[index];
                
                // Find Dosen name
                final lecturer = provider.users.firstWhere(
                  (u) => u.id == classObj.teacherId,
                  orElse: () => provider.users.firstWhere((u) => u.role == UserRole.dosen),
                );

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
                            Text(
                              classObj.className,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kode: ${classObj.code}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: AppTheme.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Dosen: ${lecturer.name}',
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.school, size: 16, color: AppTheme.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Jumlah Mahasiswa: ${classObj.studentIds.length}',
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
                            ),
                          ],
                        ),
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
                                    title: const Text('Hapus Kelas', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('Apakah Anda yakin ingin menghapus kelas ${classObj.className}? Tindakan ini permanen.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                        onPressed: () async {
                                          await provider.deleteClass(classObj.id);
                                          if (context.mounted) Navigator.pop(ctx);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Hapus Kelas', style: TextStyle(fontSize: 12)),
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
