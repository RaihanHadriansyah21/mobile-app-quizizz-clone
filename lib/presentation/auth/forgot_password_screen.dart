import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';

// Steps of the password-reset flow.
enum _ResetStep { email, password, done }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Step 1: verify the email belongs to a registered account.
  void _handleVerifyEmail() {
    if (!_emailFormKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exists = auth.emailExists(_emailController.text.trim());

    if (!exists) {
      HapticFeedback.heavyImpact();
      AppTheme.showPremiumSnackBar(
        context,
        'Email tidak terdaftar. Periksa kembali.',
        SnackBarType.error,
      );
      return;
    }

    setState(() => _step = _ResetStep.password);
  }

  // Step 2: write the new password to the account.
  Future<void> _handleSetNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      setState(() => _step = _ResetStep.done);
    } else {
      HapticFeedback.heavyImpact();
      AppTheme.showPremiumSnackBar(
        context,
        auth.errorMessage ?? 'Gagal mengatur ulang password.',
        SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, Color(0xFF130F26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: SingleChildScrollView(child: _buildStep(isLoading)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isLoading) {
    switch (_step) {
      case _ResetStep.email:
        return _buildEmailStep(isLoading);
      case _ResetStep.password:
        return _buildPasswordStep(isLoading);
      case _ResetStep.done:
        return _buildDoneStep();
    }
  }

  // --- STEP 1: EMAIL ---
  Widget _buildEmailStep(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 80, color: AppTheme.secondary),
          const SizedBox(height: 24),
          Text(
            'Lupa Password?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan email terdaftar Anda untuk mengatur ulang kata sandi.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Terdaftar',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppTheme.textSecondary,
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleVerifyEmail,
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: NEW PASSWORD ---
  Widget _buildPasswordStep(bool isLoading) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.password, size: 80, color: AppTheme.accent),
          const SizedBox(height: 24),
          Text(
            'Buat Password Baru',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Untuk akun ${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              prefixIcon: const Icon(
                Icons.lock_outlined,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password Baru',
              prefixIcon: const Icon(
                Icons.lock_clock_outlined,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
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
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : _handleSetNewPassword,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Simpan Password Baru'),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: DONE ---
  Widget _buildDoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 90,
          color: AppTheme.success,
        ),
        const SizedBox(height: 24),
        Text(
          'Password Berhasil Diubah!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Silakan login kembali menggunakan password baru Anda.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }
}
