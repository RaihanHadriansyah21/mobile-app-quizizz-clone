import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/services/update_service.dart';
import 'login_screen.dart';
import '../admin/admin_main_navigation.dart';
import '../dosen/dosen_main_navigation.dart';
import '../mahasiswa/mahasiswa_main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Check and apply updates in the background
    try {
      await UpdateService.checkAndApplyUpdate(context);
    } catch (e) {
      debugPrint('Error running Shorebird update check: $e');
    }

    // Hold for 2.8 seconds to display bridging animation completely
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      _navigateToDashboard(auth.currentUser!.role);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateToDashboard(UserRole role) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [AppTheme.surfaceLight, AppTheme.background],
            radius: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with bouncing scale animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'app_logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title and progress bar with fade-in animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Quizizz',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Self-Paced Edu Platform',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 54),
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
