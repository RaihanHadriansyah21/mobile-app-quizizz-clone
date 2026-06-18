import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/*
================================================================================
        SET-UP GOOGLE CLASSROOM API (ringkas — detail di chat)
================================================================================
1. Google Cloud Console > buat Project.
2. APIs & Services > Library > aktifkan "Google Classroom API".
3. "Google Auth Platform" (dulu: OAuth consent screen):
   - User type External, isi App info, tambahkan 3 scope di bawah,
     daftarkan akun Google-mu sebagai Test user.
4. Credentials > Create OAuth client ID:
   - Buat client tipe ANDROID  (package name + SHA-1 debug).
   - Buat client tipe WEB      -> Client ID-nya dipakai sebagai
     serverClientId di bawah (kGoogleServerClientId).
5. pubspec: jalankan
     flutter pub add google_sign_in googleapis extension_google_sign_in_as_googleapis_auth
   (biarkan pub memilih versi terbaru yang kompatibel)
================================================================================
*/

/// Ganti dengan Client ID dari OAuth client tipe **Web** milikmu.
const String kGoogleServerClientId =
    '381416966272-bdegaevfh0f19lrfhj8ts53gg6ouuig1.apps.googleusercontent.com';

/// Scope yang dibutuhkan untuk membaca kelas/roster dan menulis nilai.
const List<String> kClassroomScopes = <String>[
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.rosters.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.students',
];

/// Model ringan untuk satu kelas (Course) Google Classroom.
class GoogleClassroomCourse {
  final String id;
  final String name;
  final String? section;
  final String? description;

  GoogleClassroomCourse({
    required this.id,
    required this.name,
    this.section,
    this.description,
  });
}

/// Service integrasi nyata dengan Google Classroom API (google_sign_in v7).
class GoogleClassroomService {
  static bool _initialized = false;
  static GoogleSignInAccount? _account;
  static ClassroomApi? _classroom;

  static bool get isSignedIn => _classroom != null;

  /// Inisialisasi singleton GoogleSignIn (wajib dipanggil sekali sebelum login).
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: kGoogleServerClientId,
    );
    _initialized = true;
  }

  /// Login Google + minta otorisasi scope Classroom, lalu siapkan ClassroomApi.
  /// Harus dipanggil dari aksi pengguna (mis. tombol), karena bisa memunculkan
  /// dialog otorisasi.
  static Future<bool> signIn() async {
    try {
      await _ensureInitialized();

      // 1. Autentikasi (interaktif).
      _account = await GoogleSignIn.instance.authenticate();

      // 2. Otorisasi scope. Coba tanpa interaksi dulu, lalu minta jika perlu.
      GoogleSignInClientAuthorization? authz = await _account!
          .authorizationClient
          .authorizationForScopes(kClassroomScopes);
      authz ??= await _account!.authorizationClient.authorizeScopes(
        kClassroomScopes,
      );

      // 3. Jembatani ke googleapis -> client terautentikasi -> ClassroomApi.
      final client = authz.authClient(scopes: kClassroomScopes);
      _classroom = ClassroomApi(client);
      return true;
    } catch (e) {
      debugPrint('Google Classroom signIn error: $e');
      _account = null;
      _classroom = null;
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _account = null;
    _classroom = null;
  }

  /// Ambil daftar kelas (Course) milik dosen yang login.
  static Future<List<GoogleClassroomCourse>> fetchCourses() async {
    if (_classroom == null) return [];
    try {
      final ListCoursesResponse resp = await _classroom!.courses.list(
        courseStates: ['ACTIVE'],
      );
      final courses = resp.courses ?? [];
      return courses
          .map(
            (c) => GoogleClassroomCourse(
              id: c.id ?? '',
              name: c.name ?? 'Tanpa Nama',
              section: c.section,
              description: c.description,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('fetchCourses error: $e');
      return [];
    }
  }

  /// Ambil daftar mahasiswa (roster) dari sebuah kelas Google Classroom.
  /// Mengembalikan list map berisi 'id' (userId Google), 'name', 'email'.
  static Future<List<Map<String, String>>> fetchRoster(String courseId) async {
    if (_classroom == null) return [];
    try {
      final List<Map<String, String>> result = [];
      String? pageToken;
      do {
        final ListStudentsResponse resp = await _classroom!.courses.students
            .list(courseId, pageToken: pageToken);
        for (final s in resp.students ?? <Student>[]) {
          result.add({
            'id': s.userId ?? '',
            'name': s.profile?.name?.fullName ?? 'Mahasiswa',
            'email': s.profile?.emailAddress ?? '',
          });
        }
        pageToken = resp.nextPageToken;
      } while (pageToken != null);
      return result;
    } catch (e) {
      debugPrint('fetchRoster error: $e');
      return [];
    }
  }

  /// Buat satu tugas (CourseWork) di kelas; kembalikan id-nya untuk dipakai
  /// saat mengisi nilai tiap siswa. Panggil SEKALI per kuis (bukan per siswa).
  static Future<String?> createAssignment(
    String courseId,
    String title, {
    int maxPoints = 100,
  }) async {
    if (_classroom == null) return null;
    try {
      final created = await _classroom!.courses.courseWork.create(
        CourseWork(
          title: title,
          workType: 'ASSIGNMENT',
          maxPoints: maxPoints.toDouble(),
          state: 'PUBLISHED',
        ),
        courseId,
      );
      return created.id;
    } catch (e) {
      debugPrint('createAssignment error: $e');
      return null;
    }
  }

  /// Isi nilai satu siswa pada sebuah tugas. [studentUserId] adalah userId
  /// Google (dari fetchRoster), [grade] dalam skala maxPoints (mis. 0-100).
  static Future<bool> postStudentGrade({
    required String courseId,
    required String courseWorkId,
    required String studentUserId,
    required double grade,
  }) async {
    if (_classroom == null) return false;
    try {
      final subsResp = await _classroom!.courses.courseWork.studentSubmissions
          .list(courseId, courseWorkId, userId: studentUserId);
      final submissions = subsResp.studentSubmissions ?? [];
      for (final sub in submissions) {
        sub.assignedGrade = grade;
        sub.draftGrade = grade;
        await _classroom!.courses.courseWork.studentSubmissions.patch(
          sub,
          courseId,
          courseWorkId,
          sub.id!,
          updateMask: 'assignedGrade,draftGrade',
        );
      }
      return submissions.isNotEmpty;
    } catch (e) {
      debugPrint('postStudentGrade error: $e');
      return false;
    }
  }
}
