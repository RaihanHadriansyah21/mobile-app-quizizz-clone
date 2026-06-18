import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/class_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_skeleton.dart';

class QuizAssignmentCrudScreen extends StatefulWidget {
  final QuizModel? quiz;
  const QuizAssignmentCrudScreen({super.key, this.quiz});

  @override
  State<QuizAssignmentCrudScreen> createState() =>
      _QuizAssignmentCrudScreenState();
}

class _QuizAssignmentCrudScreenState extends State<QuizAssignmentCrudScreen> {
  final _classController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  QuizModel? _selectedQuiz;

  @override
  void initState() {
    super.initState();
    _selectedQuiz = widget.quiz;
    if (_selectedQuiz == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<DosenProvider>(context, listen: false);
        if (provider.selectedQuizForAssignment != null &&
            provider.quizzes.contains(provider.selectedQuizForAssignment)) {
          setState(() {
            _selectedQuiz = provider.selectedQuizForAssignment;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          hintText: 'Cari nama kelas...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSkeletonClassesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          color: AppTheme.getSurface(context),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(width: 150, height: 18, borderRadius: 4),
                      const SizedBox(height: 8),
                      LoadingSkeleton(width: 200, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
                LoadingSkeleton(width: 32, height: 32, borderRadius: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createNewClass() async {
    if (_classController.text.trim().isEmpty) return;

    final provider = Provider.of<DosenProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;

    await provider.saveClass(_classController.text.trim(), user.id);
    _classController.clear();

    if (mounted) {
      AppTheme.showPremiumSnackBar(
        context,
        'Kelas baru berhasil dibuat! 🏫',
        SnackBarType.success,
      );
    }
  }

  void _showQrDialog(ClassModel classObj) {
    if (_selectedQuiz == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Text(
          'Gabung Kuis via QR',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedQuiz!.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kelas: ${classObj.className}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // QR Generator
            SizedBox(
              width: 220,
              height: 220,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: classObj.code,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (context, error) => const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Text(
                        'QR gagal dibuat',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KODE GABUNG: ${classObj.code}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Siswa dapat men-scan kode ini menggunakan fitur gabung kelas di aplikasi mereka.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final classes = provider.classes;
    final quizzes = provider.quizzes;

    // If _selectedQuiz is not in the list (e.g. deleted), reset it
    if (_selectedQuiz != null &&
        !quizzes.any((q) => q.id == _selectedQuiz!.id)) {
      _selectedQuiz = null;
    }

    final filteredClasses = classes
        .where((c) => c.className.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tugaskan Kuis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Quiz Selector (shown if not pre-selected or if loaded as a bottom tab)
            if (widget.quiz == null) ...[
              Text(
                'Pilih Kuis untuk Ditugaskan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<QuizModel>(
                initialValue: quizzes.contains(_selectedQuiz)
                    ? _selectedQuiz
                    : null,
                dropdownColor: AppTheme.getSurface(context),
                iconEnabledColor: AppTheme.secondary,
                decoration: const InputDecoration(hintText: 'Pilih Kuis'),
                items: quizzes.map((q) {
                  return DropdownMenuItem<QuizModel>(
                    value: q,
                    child: Text(q.title, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedQuiz = val;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            if (_selectedQuiz != null) ...[
              // Active Quiz Card
              Card(
                color: AppTheme.getSurfaceLight(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kuis yang Ditugaskan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedQuiz!.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedQuiz!.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Class Creation Row
              Text(
                'Buat Kelas Baru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _classController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kelas',
                        hintText: 'Misal: Kelas X-C Matematika',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _createNewClass,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Class Assignment List
              Text(
                'Daftar Kelas Dosen',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildSearchBar(),
              const SizedBox(height: 8),
              provider.isLoading
                  ? _buildSkeletonClassesList()
                  : filteredClasses.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Belum ada kelas. Silakan buat kelas baru di atas.'
                                : 'Tidak ada kelas dengan nama "$_searchQuery".',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredClasses.length,
                          itemBuilder: (context, index) {
                            final classObj = filteredClasses[index];
                        final isAssigned = classObj.quizIds.contains(
                          _selectedQuiz!.id,
                        );

                        return Card(
                          color: AppTheme.getSurface(context),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              classObj.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Kode Kelas: ${classObj.code} • ${classObj.studentIds.length} Mahasiswa',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.qr_code,
                                    color: AppTheme.accent,
                                  ),
                                  onPressed: () => _showQrDialog(classObj),
                                  tooltip: 'Tampilkan QR Code',
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    if (isAssigned) {
                                      provider.unassignQuizFromClass(
                                        classObj.id,
                                        _selectedQuiz!.id,
                                      );
                                      HapticFeedback.lightImpact();
                                      AppTheme.showPremiumSnackBar(
                                        context,
                                        'Kuis dilepas dari kelas.',
                                        SnackBarType.info,
                                      );
                                    } else {
                                      provider.assignQuizToClass(
                                        classObj.id,
                                        _selectedQuiz!.id,
                                      );
                                      HapticFeedback.mediumImpact();
                                      AppTheme.showPremiumSnackBar(
                                        context,
                                        'Berhasil ditugaskan ke ${classObj.className}!',
                                        SnackBarType.success,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAssigned
                                        ? AppTheme.getSurfaceLight(context)
                                        : AppTheme.secondary,
                                    foregroundColor: isAssigned
                                        ? AppTheme.getTextSecondary(context)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    isAssigned ? 'Lepas' : 'Tugaskan',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ] else ...[
              Card(
                color: AppTheme.getSurface(context),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Silakan pilih atau buat kuis terlebih dahulu untuk menugaskannya ke kelas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}
