import 'dart:convert';

enum UserRole { admin, dosen, mahasiswa }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String password;
  final String? photoPath;
  final bool isBiometricEnabled;
  final List<String> registeredFingerprints;
  final String? nim;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.password = 'password123',
    this.photoPath,
    this.isBiometricEnabled = false,
    this.registeredFingerprints = const [],
    this.nim,
  });

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? password,
    String? photoPath,
    bool? isBiometricEnabled,
    List<String>? registeredFingerprints,
    String? nim,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      password: password ?? this.password,
      photoPath: photoPath ?? this.photoPath,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      registeredFingerprints:
          registeredFingerprints ?? this.registeredFingerprints,
      nim: nim ?? this.nim,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'password': 'enc:' + _encryptPassword(password),
      'photoPath': photoPath,
      'isBiometricEnabled': isBiometricEnabled,
      'registeredFingerprints': registeredFingerprints.join(','),
      'nim': nim,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawPassword = json['password'] as String? ?? 'password123';
    final String parsedPassword = rawPassword.startsWith('enc:')
        ? _decryptPassword(rawPassword.substring(4))
        : rawPassword;

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      password: parsedPassword,
      photoPath: json['photoPath'] as String?,
      isBiometricEnabled: json['isBiometricEnabled'] == true || (json['isBiometricEnabled'] ?? 0) == 1,
      registeredFingerprints:
          (json['registeredFingerprints'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      nim: json['nim'] as String?,
    );
  }
}

String _encryptPassword(String password) {
  const key = 'quizizz_secret_key';
  final bytes = utf8.encode(password);
  final keyBytes = utf8.encode(key);
  final encrypted = List<int>.generate(
    bytes.length,
    (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
  );
  return base64.encode(encrypted);
}

String _decryptPassword(String encryptedBase64) {
  if (encryptedBase64.isEmpty) return 'password123';
  try {
    const key = 'quizizz_secret_key';
    final bytes = base64.decode(encryptedBase64);
    final keyBytes = utf8.encode(key);
    final decrypted = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  } catch (_) {
    return 'password123';
  }
}

