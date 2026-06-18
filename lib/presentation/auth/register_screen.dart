import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../mahasiswa/mahasiswa_main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nimController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Register role is strictly mahasiswa
    bool success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      UserRole.mahasiswa,
      _nimController.text.trim(),
    );

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      AppTheme.showPremiumSnackBar(
        context,
        "Pendaftaran berhasil! Selamat datang.",
        SnackBarType.success,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MahasiswaMainNavigation(),
        ),
      );
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      AppTheme.showPremiumSnackBar(
        context,
        authProvider.errorMessage ?? "Pendaftaran gagal",
        SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppTheme.getTextPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.background : const Color(0xFFF8FAFC),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Daftar Mahasiswa',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = AppTheme.doubleGradient.createShader(
                                const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                              ),
                          ),
                    ).animate().scale(duration: 350.ms, curve: Curves.easeOut),
                    const SizedBox(height: 6),
                    Text(
                      'Buat akun mahasiswa Anda untuk memulai kuis interaktif',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ).animate().fade(delay: 100.ms, duration: 300.ms),
                    const SizedBox(height: 32),
                    
                    // Main Form Card
                    Card(
                      color: AppTheme.getSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: AppTheme.getBorderColor(context),
                          width: 1,
                        ),
                      ),
                      shadowColor: Colors.black.withOpacity(0.05),
                      elevation: isDark ? 0 : 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nimController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'NIM (Min. 7 Digit Angka)',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'NIM tidak boleh kosong';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'NIM harus berupa angka';
                                }
                                if (value.trim().length < 7) {
                                  return 'NIM minimal 7 digit';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Kampus',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@')) return 'Email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outlined,
                                  color: AppTheme.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Password',
                                prefixIcon: const Icon(
                                  Icons.lock_clock_outlined,
                                  color: AppTheme.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password tidak boleh kosong';
                                }
                                if (value != _passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: AppTheme.doubleGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Daftar Sekarang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 150.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 28),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 200.ms, duration: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
