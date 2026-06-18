import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/class_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';

class DosenClassCrudScreen extends StatelessWidget {
  const DosenClassCrudScreen({super.key});

  void _showAddClassDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final classNameController = TextEditingController();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          title: const Text(
            'Buat Kelas Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: classNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'Misal: Kalkulus 1 - TI A',
              ),
              validator: (val) => val == null || val.isEmpty
                  ? 'Nama kelas tidak boleh kosong'
                  : null,
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
                await Provider.of<DosenProvider>(
                  context,
                  listen: false,
                ).saveClass(classNameController.text.trim(), user.id);
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showQrDialog(BuildContext context, ClassModel classObj) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          title: Text(
            'QR Code Kelas: ${classObj.className}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mahasiswa dapat memindai QR ini untuk masuk otomatis.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                height: 220,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: classObj.code,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    errorStateBuilder: (context, error) => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Text(
                          'QR gagal dibuat',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KODE KELAS: ${classObj.code}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final classes = provider.classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Kelas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showAddClassDialog(context),
      ),
      body: classes.isEmpty
          ? Center(
              child: Text(
                'Belum ada kelas yang dibuat. Terapkan kelas pertama Anda!',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classObj = classes[index];
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.qr_code,
                                color: AppTheme.accent,
                              ),
                              onPressed: () => _showQrDialog(context, classObj),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kode Join: ${classObj.code}',
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${classObj.studentIds.length} Mahasiswa',
                              style: TextStyle(
                                color: AppTheme.getTextSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppTheme.getBorderColor(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.getSurface(
                                      context,
                                    ),
                                    title: const Text(
                                      'Hapus Kelas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Apakah Anda yakin ingin menghapus kelas ${classObj.className}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(
                                          'Batal',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.error,
                                        ),
                                        onPressed: () async {
                                          await provider.deleteClass(
                                            classObj.id,
                                          );
                                          if (context.mounted)
                                            Navigator.pop(ctx);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
