import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Validate credentials and return user if success
  static Future<UserModel?> login(String email, String password) async {
    if (DbService.isSupabaseEnabled) {
      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          // Fetch user details from Supabase 'users' table
          final userData = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (userData != null) {
            final Map<String, dynamic> mergedData = Map.from(userData);
            mergedData['password'] = password;
            UserModel user = UserModel.fromJson(mergedData);
            await DbService.saveUser(user);
            return user;
          } else {
            // Fallback: If profile doesn't exist in 'users' table but exists in Auth, create it
            UserModel newUser = UserModel(
              id: response.user!.id,
              name: response.user!.userMetadata?['name'] ?? email.split('@')[0],
              email: email,
              role: UserRole.mahasiswa,
              password: password,
            );
            await DbService.saveUser(newUser);
            return newUser;
          }
        }
      } catch (e) {
        print("Supabase login failed, trying local DB fallback: $e");
      }
    }

    // Fallback: Check local database
    UserModel? user = DbService.getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  // Register a new user (only Mahasiswa can self-register)
  static Future<UserModel?> register(
    String name,
    String email,
    String password,
    UserRole role,
    String? nim,
  ) async {
    // If someone tries to register as Admin or Dosen, reject
    if (role != UserRole.mahasiswa) {
      return null;
    }

    String userId = 'u_${DateTime.now().millisecondsSinceEpoch}';

    // Always block duplicate local accounts
    if (DbService.getUserByEmail(email) != null) {
      throw Exception("Email sudah terdaftar.");
    }

    if (DbService.isSupabaseEnabled) {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (authResponse.user != null) {
        userId = authResponse.user!.id;
      }
    }

    UserModel newUser = UserModel(
      id: userId,
      name: name,
      email: email,
      role: role,
      password: password,
      nim: nim,
    );
    await DbService.saveUser(newUser);
    return newUser;
  }

  // Send a real Supabase password-reset email (best-effort).
  // The app's login validates against the locally-stored password, so this
  // email is supplementary — the functional reset happens in AuthProvider.
  static Future<void> sendResetEmail(String email) async {
    if (!DbService.isSupabaseEnabled) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      print("Reset email error: $e");
    }
  }

  // Biometric Capabilities Check
  static Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // List enrolled biometrics
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // Authenticate user using Biometrics
  static Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // fallback to pin/passcode if fingerprint fails/is absent
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
