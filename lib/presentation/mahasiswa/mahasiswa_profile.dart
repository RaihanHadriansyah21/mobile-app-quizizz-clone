import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/services/file_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class MahasiswaProfileScreen extends StatefulWidget {
  const MahasiswaProfileScreen({super.key});

  @override
  State<MahasiswaProfileScreen> createState() => _MahasiswaProfileScreenState();
}

class _MahasiswaProfileScreenState extends State<MahasiswaProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _nimController;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _nimController = TextEditingController(text: user?.nim ?? '');
    _selectedPhotoPath = user?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    String? path = await FileService.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    if (path != null) {
      setState(() {
        _selectedPhotoPath = path;
      });
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          nim: _nimController.text.trim(),
          photoPath: path,
        );
        final updatedUser = authProvider.currentUser;
        if (mounted && updatedUser != null) {
          setState(() {
            _selectedPhotoPath = updatedUser.photoPath;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      nim: _nimController.text.trim(),
      photoPath: _selectedPhotoPath,
    );

    final updatedUser = authProvider.currentUser;
    if (mounted && updatedUser != null) {
      setState(() {
        _selectedPhotoPath = updatedUser.photoPath;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui! 🎉'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _addFingerprintPrompt() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Text('Daftarkan Sidik Jari', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sentuh sensor sidik jari Anda, dan beri nama sidik jari ini untuk memudahkan pengenalan.',
              style: TextStyle(fontSize: 13, color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Sidik Jari',
                hintText: 'Misal: Jempol Kanan, Telunjuk Kiri',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isEmpty) {
                name = 'Sidik Jari ${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.addFingerprint(name);
              await authProvider.toggleBiometricAuth(true);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sidik jari "$name" berhasil didaftarkan! 🔑'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final themeProvider = context.watch<ThemeProvider>();

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primary),
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.getSurfaceLight(context),
                      backgroundImage: _selectedPhotoPath != null
                          ? (_selectedPhotoPath!.startsWith('http')
                              ? NetworkImage(_selectedPhotoPath!) as ImageProvider
                              : FileImage(File(_selectedPhotoPath!)) as ImageProvider)
                          : null,
                      child: _selectedPhotoPath == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.getTextSecondary(context),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Mahasiswa • NIM: ${user.nim ?? "-"}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 36),

              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.getBorderColor(context))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Informasi Profil',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Nama tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nimController,
                        decoration: const InputDecoration(labelText: 'NIM (Nomor Induk Mahasiswa)', hintText: 'Min. 7 digit angka'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'NIM tidak boleh kosong';
                          if (!RegExp(r'^\d+$').hasMatch(value)) return 'NIM harus berupa angka';
                          if (value.trim().length < 7) return 'NIM minimal 7 digit';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Email tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text('Simpan Perubahan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.primary,
                        ),
                        title: const Text('Mode Gelap'),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          activeThumbColor: AppTheme.accent,
                          onChanged: (val) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                color: AppTheme.getSurface(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.getBorderColor(context))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Login Sidik Jari',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: user.isBiometricEnabled,
                            activeThumbColor: AppTheme.accent,
                            onChanged: (val) {
                              auth.toggleBiometricAuth(val);
                            },
                          ),
                        ],
                      ),
                      Text(
                        'Aktifkan opsi ini untuk login secara instan menggunakan sidik jari tanpa mengetik password.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      Divider(height: 32, color: AppTheme.getBorderColor(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Sidik Jari Terdaftar',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppTheme.accent,
                            ),
                            onPressed: _addFingerprintPrompt,
                          ),
                        ],
                      ),
                      if (user.registeredFingerprints.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Belum ada sidik jari terdaftar.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: user.registeredFingerprints.length,
                          itemBuilder: (context, index) {
                            final fingerprint = user.registeredFingerprints[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.fingerprint,
                                color: AppTheme.accent,
                              ),
                              title: Text(fingerprint),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                ),
                                onPressed: () {
                                  auth.removeFingerprint(fingerprint);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sidik jari "$fingerprint" dihapus.'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
