import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/class_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/dosen_speed_dial.dart';
import '../../data/services/db_service.dart';
import 'question_bank_crud.dart';

class DosenClassCrudScreen extends StatefulWidget {
  const DosenClassCrudScreen({super.key});

  @override
  State<DosenClassCrudScreen> createState() => _DosenClassCrudScreenState();
}

class _DosenClassCrudScreenState extends State<DosenClassCrudScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddClassDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final classNameController = TextEditingController();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
          title: const Text(
            'Buat Kelas Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: classNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'Misal: Kalkulus 1 - TI A',
              ),
              validator: (val) => val == null || val.isEmpty
                  ? 'Nama kelas tidak boleh kosong'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                HapticFeedback.mediumImpact();
                await Provider.of<DosenProvider>(
                  context,
                  listen: false,
                ).saveClass(classNameController.text.trim(), user.id);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  AppTheme.showPremiumSnackBar(
                    context,
                    'Kelas baru berhasil dibuat! 🏫',
                    SnackBarType.success,
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showQrDialog(BuildContext context, ClassModel classObj) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
          title: Text(
            'QR Code Kelas: ${classObj.className}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mahasiswa dapat memindai QR ini untuk masuk otomatis.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                height: 220,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 16),
              Text(
                'KODE KELAS: ${classObj.code}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          hintText: 'Cari kelas...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          color: AppTheme.getSurface(context),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.getBorderColor(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoadingSkeleton(width: 140, height: 18, borderRadius: 4),
                    LoadingSkeleton(width: 36, height: 36, borderRadius: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoadingSkeleton(width: 80, height: 14, borderRadius: 4),
                    LoadingSkeleton(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppTheme.getBorderColor(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LoadingSkeleton(width: 36, height: 36, borderRadius: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final classes = provider.classes;
    final isLoading = provider.isLoading;

    final filteredClasses = classes
        .where((c) => c.className.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Kelas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: DosenSpeedDial(
        onCreateClass: () => _showAddClassDialog(context),
        onCreateQuiz: () => Navigator.push(
          context,
          AppTheme.pageRoute(const QuizEditorScreen(quiz: null)),
        ),
        onCreateQuestion: () {
          showDialog(
            context: context,
            builder: (ctx) => QuestionFormDialog(
              question: null,
              onSave: (newQuestion) async {
                await DbService.saveQuestion(newQuestion);
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  AppTheme.showPremiumSnackBar(
                    context,
                    'Soal baru berhasil ditambahkan ke bank soal!',
                    SnackBarType.success,
                  );
                }
              },
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshData(),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: isLoading
                  ? _buildSkeletonList()
                  : filteredClasses.isEmpty
                      ? EmptyState(
                          title: _searchQuery.isEmpty ? 'Belum Ada Kelas' : 'Kelas Tidak Ditemukan',
                          description: _searchQuery.isEmpty
                              ? 'Belum ada kelas yang dibuat. Buat kelas pertama Anda sekarang!'
                              : 'Tidak ada kelas dengan nama "$_searchQuery".',
                          icon: Icons.school_outlined,
                          illustrationType: EmptyIllustrationType.noClass,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredClasses.length,
                          itemBuilder: (context, index) {
                            final classObj = filteredClasses[index];
                            return Card(
                              color: AppTheme.getSurface(context),
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppTheme.getBorderColor(context),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            classObj.className,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.qr_code,
                                            color: AppTheme.accent,
                                          ),
                                          onPressed: () =>
                                              _showQrDialog(context, classObj),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Kode Join: ${classObj.code}',
                                          style: const TextStyle(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          '${classObj.studentIds.length} Mahasiswa',
                                          style: TextStyle(
                                            color: AppTheme.getTextSecondary(context),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(color: AppTheme.getBorderColor(context)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.error,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.heavyImpact();
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor:
                                                    AppTheme.getSurface(context),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side: BorderSide(
                                                    color: AppTheme.getBorderColor(
                                                      context,
                                                    ),
                                                  ),
                                                ),
                                                title: const Text(
                                                  'Hapus Kelas',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Apakah Anda yakin ingin menghapus kelas ${classObj.className}?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: Text(
                                                      'Batal',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppTheme.error,
                                                    ),
                                                    onPressed: () async {
                                                      HapticFeedback
                                                          .mediumImpact();
                                                      await provider.deleteClass(
                                                        classObj.id,
                                                      );
                                                      if (context.mounted) {
                                                        Navigator.pop(ctx);
                                                        AppTheme.showPremiumSnackBar(
                                                          context,
                                                          'Kelas berhasil dihapus',
                                                          SnackBarType.success,
                                                        );
                                                      }
                                                    },
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
