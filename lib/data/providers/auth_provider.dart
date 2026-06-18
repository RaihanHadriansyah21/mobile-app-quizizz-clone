import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/file_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    UserModel? user = await AuthService.login(email, password);
    _isLoading = false;

    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Email atau password salah.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool isSupported = await AuthService.isBiometricsAvailable();
    if (!isSupported) {
      _errorMessage = "Perangkat Anda tidak mendukung login sidik jari.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    bool didAuth = await AuthService.authenticateWithBiometrics(
      "Autentikasi sidik jari untuk login Quizizz",
    );
    _isLoading = false;

    if (didAuth) {
      // Find the first user with biometrics enabled
      List<UserModel> users = DbService.getUsers();
      UserModel? bioUser;
      try {
        bioUser = users.firstWhere((u) => u.isBiometricEnabled);
      } catch (_) {
        bioUser = null;
      }

      if (bioUser == null) {
        _errorMessage = "Belum ada akun yang mengaktifkan login sidik jari.";
        notifyListeners();
        return false;
      }

      _currentUser = bioUser;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Autentikasi sidik jari gagal.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    UserRole role,
    String? nim,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      UserModel? user = await AuthService.register(
        name,
        email,
        password,
        role,
        nim,
      );
      _isLoading = false;

      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Pendaftaran gagal. Email mungkin sudah terdaftar.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Check whether an account with this email exists (used by reset flow).
  bool emailExists(String email) {
    return DbService.getUserByEmail(email) != null;
  }

  // Reset the password for the account tied to [email].
  // Updates the local DB (the source of truth for login) and syncs to
  // Supabase via saveUser. Also triggers a best-effort Supabase reset email.
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final user = DbService.getUserByEmail(email);
    if (user == null) {
      _isLoading = false;
      _errorMessage = "Email tidak terdaftar.";
      notifyListeners();
      return false;
    }

    // Supplementary: send a real reset email if Supabase is online.
    await AuthService.sendResetEmail(email);

    // Update the stored password — this is what login actually checks.
    final updated = user.copyWith(password: newPassword);
    await DbService.saveUser(updated);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? nim,
    String? photoPath,
  }) async {
    if (_currentUser == null) return;

    String? finalPhotoPath = photoPath;

    // If new photo is provided and is a local file path
    if (photoPath != null && !photoPath.startsWith('http')) {
      if (DbService.isSupabaseEnabled) {
        final String? uploadedUrl = await FileService.uploadToSupabase(
          photoPath,
          'avatars',
        );
        if (uploadedUrl != null) {
          finalPhotoPath = uploadedUrl;

          // Delete old photo from Supabase if it exists
          if (_currentUser!.photoPath != null &&
              _currentUser!.photoPath!.startsWith('http')) {
            await FileService.deleteFromSupabase(
              _currentUser!.photoPath!,
              'avatars',
            );
          }
        }
      }
    } else if (photoPath == null &&
        _currentUser!.photoPath != null &&
        _currentUser!.photoPath!.startsWith('http')) {
      // If photo is deleted, clean up Supabase storage
      if (DbService.isSupabaseEnabled) {
        await FileService.deleteFromSupabase(
          _currentUser!.photoPath!,
          'avatars',
        );
      }
    }

    UserModel updated = _currentUser!.copyWith(
      name: name,
      email: email,
      nim: nim ?? _currentUser!.nim,
      photoPath: finalPhotoPath,
    );

    await DbService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> toggleBiometricAuth(bool enabled) async {
    if (_currentUser == null) return;

    UserModel updated = _currentUser!.copyWith(isBiometricEnabled: enabled);
    await DbService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> addFingerprint(String name) async {
    if (_currentUser == null) return;

    List<String> list = List.from(_currentUser!.registeredFingerprints);
    if (!list.contains(name)) {
      list.add(name);
    }

    UserModel updated = _currentUser!.copyWith(registeredFingerprints: list);
    await DbService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> removeFingerprint(String name) async {
    if (_currentUser == null) return;

    List<String> list = List.from(_currentUser!.registeredFingerprints);
    list.remove(name);

    UserModel updated = _currentUser!.copyWith(registeredFingerprints: list);
    await DbService.saveUser(updated);
    _currentUser = updated;
    notifyListeners();
  }
}
