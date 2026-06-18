import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../admin/admin_main_navigation.dart';
import '../dosen/dosen_main_navigation.dart';
import '../mahasiswa/mahasiswa_main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _routeToDashboard(UserRole role) {
    Widget target;
    switch (role) {
      case UserRole.admin:
        target = const AdminMainNavigation();
        break;
      case UserRole.dosen:
        target = const DosenMainNavigation();
        break;
      case UserRole.mahasiswa:
        target = const MahasiswaMainNavigation();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => target),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _routeToDashboard(authProvider.currentUser!.role);
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      AppTheme.showPremiumSnackBar(
        context,
        authProvider.errorMessage ?? "Login gagal",
        SnackBarType.error,
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.loginWithBiometrics();

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _routeToDashboard(authProvider.currentUser!.role);
    } else if (mounted && authProvider.errorMessage != null) {
      HapticFeedback.heavyImpact();
      AppTheme.showPremiumSnackBar(
        context,
        authProvider.errorMessage!,
        SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.background : const Color(0xFFF8FAFC),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppTheme.premiumShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Hero(
                            tag: 'app_logo',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Quizizz',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = AppTheme.doubleGradient.createShader(
                            const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                          ),
                      ),
                    ).animate().fade(delay: 100.ms, duration: 300.ms),
                    
                    const SizedBox(height: 8),
                    Text(
                      'Continue Learning Anywhere',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.getTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fade(delay: 150.ms, duration: 300.ms),
                    
                    const SizedBox(height: 32),

                    // Main form card
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Silakan Masuk',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
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
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.doubleGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.secondary.withOpacity(0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _handleLogin,
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
                                              'Masuk',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceLight(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: IconButton(
                                    iconSize: 30,
                                    padding: const EdgeInsets.all(12),
                                    icon: const Icon(
                                      Icons.fingerprint,
                                      color: AppTheme.secondary,
                                    ),
                                    onPressed: isLoading ? null : _handleBiometricLogin,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 200.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mahasiswa baru? ',
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar Akun',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 250.ms, duration: 300.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Trial Account hints
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceLight(context).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.getBorderColor(context),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Akun Percobaan (Sandi: password123)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.getTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.6,
                                color: AppTheme.getTextSecondary(context),
                              ),
                              children: [
                                const TextSpan(
                                  text: '• Dosen: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                ),
                                const TextSpan(text: 'dosen@quizizz.com\n'),
                                const TextSpan(
                                  text: '• Mahasiswa: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                const TextSpan(text: 'mahasiswa@quizizz.com\n'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 300.ms, duration: 300.ms),
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
