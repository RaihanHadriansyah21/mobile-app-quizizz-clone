import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/class_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/providers/dosen_provider.dart';
import '../../data/services/google_classroom_service.dart';
import '../../core/theme/app_theme.dart';

class ClassroomSyncScreen extends StatefulWidget {
  final ClassModel classObj;
  const ClassroomSyncScreen({super.key, required this.classObj});

  @override
  State<ClassroomSyncScreen> createState() => _ClassroomSyncScreenState();
}

class _ClassroomSyncScreenState extends State<ClassroomSyncScreen> {
  bool _busy = false;
  List<GoogleClassroomCourse> _courses = [];
  GoogleClassroomCourse? _selectedCourse;
  QuizModel? _selectedQuiz;

  DosenProvider get _provider =>
      Provider.of<DosenProvider>(context, listen: false);

  Future<void> _connect() async {
    setState(() => _busy = true);
    final ok = await _provider.classroomSignIn();
    if (ok) {
      _courses = await _provider.classroomCourses();
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      _snack('Gagal terhubung ke Google Classroom.', AppTheme.error);
    } else if (_courses.isEmpty) {
      _snack(
        'Terhubung, tapi tidak ada kelas aktif ditemukan.',
        AppTheme.warning,
      );
    }
  }

  Future<void> _importRoster() async {
    if (_selectedCourse == null) {
      _snack('Pilih kelas Google Classroom dulu.', AppTheme.warning);
      return;
    }
    setState(() => _busy = true);
    final added = await _provider.importRosterFromClassroom(
      widget.classObj.id,
      _selectedCourse!.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('$added mahasiswa baru ditambahkan ke kelas. 🎓', AppTheme.success);
  }

  Future<void> _postGrades() async {
    if (_selectedCourse == null) {
      _snack('Pilih kelas Google Classroom dulu.', AppTheme.warning);
      return;
    }
    if (_selectedQuiz == null) {
      _snack('Pilih kuis yang nilainya akan dikirim.', AppTheme.warning);
      return;
    }
    setState(() => _busy = true);
    final attempts = _provider.getAttemptsForQuiz(_selectedQuiz!.id);
    final posted = await _provider.postClassGradesToClassroom(
      googleCourseId: _selectedCourse!.id,
      quiz: _selectedQuiz!,
      attempts: attempts,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('$posted nilai dikirim ke Google Classroom. 📝', AppTheme.success);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _provider.isClassroomSignedIn;

    // Quizzes assigned to this class (for grade posting).
    final classQuizzes = _provider.quizzes
        .where((q) => widget.classObj.quizIds.contains(q.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Google Classroom Sync',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection banner
            Card(
              color: signedIn
                  ? const Color(0xFF1B4F3A)
                  : AppTheme.getSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 56,
                      color: signedIn ? Colors.white : AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      signedIn
                          ? 'Google Classroom Terhubung'
                          : 'Belum Terhubung',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: signedIn ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mengintegrasikan kelas "${widget.classObj.className}".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: signedIn
                            ? Colors.white70
                            : AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (!signedIn) ...[
              ElevatedButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: const Text('Hubungkan Google Classroom'),
              ),
            ] else ...[
              // Course selector
              Text(
                'Pilih Kelas Google Classroom',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<GoogleClassroomCourse>(
                initialValue: _selectedCourse,
                dropdownColor: AppTheme.getSurface(context),
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                hint: const Text('— pilih kelas —'),
                items: _courses
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCourse = v),
              ),
              const SizedBox(height: 24),

              // Roster import
              _actionCard(
                icon: Icons.group_add,
                color: AppTheme.primary,
                title: 'Impor Roster Siswa',
                subtitle:
                    'Tambahkan mahasiswa dari Google Classroom ke kelas ini.',
                buttonLabel: 'Impor Roster',
                onPressed: _busy ? null : _importRoster,
              ),
              const SizedBox(height: 16),

              // Grade export
              Text(
                'Kirim Nilai Kuis',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<QuizModel>(
                initialValue: _selectedQuiz,
                dropdownColor: AppTheme.getSurface(context),
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                hint: const Text('— pilih kuis —'),
                items: classQuizzes
                    .map(
                      (q) => DropdownMenuItem(
                        value: q,
                        child: Text(q.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedQuiz = v),
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.grade_outlined,
                color: AppTheme.secondary,
                title: 'Ekspor Nilai ke Gradebook',
                subtitle:
                    'Membuat tugas dan mengisi nilai mahasiswa di Classroom.',
                buttonLabel: 'Kirim Nilai',
                onPressed: _busy ? null : _postGrades,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        await _provider.classroomSignOut();
                        if (mounted) setState(() => _courses = []);
                      },
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text(
                  'Putuskan Koneksi',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],

            const SizedBox(height: 20),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Text(
                'Catatan: butuh setup OAuth di Google Cloud & dijalankan di '
                'perangkat Android yang login akun Google guru.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getTextSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback? onPressed,
  }) {
    return Card(
      color: AppTheme.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
