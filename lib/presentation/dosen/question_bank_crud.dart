import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/question_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/dosen_provider.dart';
import '../../data/services/file_service.dart';
import '../../data/services/db_service.dart';
import '../../core/theme/app_theme.dart';
import 'quiz_assignment_crud.dart';

class QuestionBankCrudScreen extends StatefulWidget {
  const QuestionBankCrudScreen({super.key});

  @override
  State<QuestionBankCrudScreen> createState() => _QuestionBankCrudScreenState();
}

class _QuestionBankCrudScreenState extends State<QuestionBankCrudScreen> {
  void _openQuizEditor(QuizModel? quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizEditorScreen(quiz: quiz)),
    );
  }

  void _confirmDelete(String quizId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Text(
          'Hapus Kuis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus kuis ini beserta semua soal didalamnya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Provider.of<DosenProvider>(
                context,
                listen: false,
              ).deleteQuiz(quizId);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final quizzes = provider.quizzes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bank Soal Dosen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondary),
            onPressed: () => provider.refreshData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _openQuizEditor(null),
      ),
      body: quizzes.isEmpty
          ? Center(
              child: Text(
                'Belum ada kuis. Klik tombol + untuk membuat baru.',
                style: TextStyle(color: AppTheme.getTextSecondary(context)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
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
                            Expanded(
                              child: Text(
                                quiz.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openQuizEditor(quiz);
                                } else if (value == 'assign') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          QuizAssignmentCrudScreen(quiz: quiz),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  _confirmDelete(quiz.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Kuis & Soal'),
                                ),
                                const PopupMenuItem(
                                  value: 'assign',
                                  child: Text('Tugaskan ke Kelas'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Hapus Kuis',
                                    style: TextStyle(color: AppTheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quiz.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${quiz.questions.length} Soal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: quiz.isHomework
                                    ? AppTheme.accent.withOpacity(0.1)
                                    : AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                quiz.isHomework ? 'Mode PR' : 'Mode Live',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: quiz.isHomework
                                      ? AppTheme.accent
                                      : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Full Quiz and Question Builder Screen
class QuizEditorScreen extends StatefulWidget {
  final QuizModel? quiz;
  const QuizEditorScreen({super.key, this.quiz});

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _quizId;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isHomework = false;
  bool _isTimerEnabled = true;
  List<QuestionModel> _questions = [];
  int _maxAttempts = 0;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _quizId = widget.quiz!.id;
      _titleController = TextEditingController(text: widget.quiz!.title);
      _descController = TextEditingController(text: widget.quiz!.description);
      _isHomework = widget.quiz!.isHomework;
      _isTimerEnabled = widget.quiz!.isTimerEnabled;
      _questions = List.from(widget.quiz!.questions);
      _maxAttempts = widget.quiz!.maxAttempts;
    } else {
      _quizId = 'q_${DateTime.now().millisecondsSinceEpoch}';
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _isHomework = false;
      _isTimerEnabled = true;
      _questions = [];
      _maxAttempts = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<DosenProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;

    QuizModel quiz = QuizModel(
      id: _quizId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      questions: _questions,
      creatorId: user.id,
      isHomework: _isHomework,
      isTimerEnabled: _isTimerEnabled,
      deadline: _isHomework
          ? DateTime.now().add(const Duration(days: 7))
          : null,
      maxAttempts: _maxAttempts,
    );

    await provider.saveQuiz(quiz);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuis berhasil disimpan! 🎉'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _openQuestionBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuestionBankSelectorDialog(
        onQuestionsSelected: (selectedQuestions) {
          setState(() {
            for (var q in selectedQuestions) {
              final copied = q.copyWith(
                id: 'q_copy_${DateTime.now().microsecondsSinceEpoch}_${q.id}',
              );
              _questions.add(copied);
            }
          });
        },
      ),
    );
  }

  void _addQuestion(QuestionModel? existing, int? index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuestionFormDialog(
        question: existing,
        onSave: (question) {
          setState(() {
            if (index != null) {
              _questions[index] = question;
            } else {
              _questions.add(question);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz == null ? 'Buat Kuis Baru' : 'Edit Kuis',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.success),
            onPressed: _saveQuiz,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Kuis'),
                validator: (val) => val == null || val.isEmpty
                    ? 'Judul kuis tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi Kuis'),
                validator: (val) => val == null || val.isEmpty
                    ? 'Deskripsi kuis tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mode PR',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _isHomework,
                      onChanged: (val) =>
                          setState(() => _isHomework = val ?? false),
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Aktifkan Timer',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _isTimerEnabled,
                      onChanged: (val) =>
                          setState(() => _isTimerEnabled = val ?? true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _maxAttempts,
                dropdownColor: AppTheme.getSurface(context),
                decoration: const InputDecoration(
                  labelText: 'Batas Percobaan Pengerjaan',
                  helperText:
                      'Tentukan berapa kali siswa boleh mengerjakan kuis ini.',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Tanpa Batas (Unlimited)'),
                  ),
                  DropdownMenuItem(value: 1, child: Text('1 Kali Pengerjaan')),
                  DropdownMenuItem(value: 2, child: Text('2 Kali Pengerjaan')),
                  DropdownMenuItem(value: 3, child: Text('3 Kali Pengerjaan')),
                  DropdownMenuItem(value: 5, child: Text('5 Kali Pengerjaan')),
                ],
                onChanged: (val) {
                  setState(() {
                    _maxAttempts = val ?? 0;
                  });
                },
              ),
              const Divider(height: 32, color: Colors.white10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Daftar Soal (${_questions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openQuestionBankSelector,
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text('Pilih Bank Soal', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _addQuestion(null, null),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Soal Baru', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _questions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        'Belum ada soal. Silakan tambah soal baru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return Card(
                          color: AppTheme.getSurfaceLight(context),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('${index + 1}. ${question.text}'),
                            subtitle: Text(
                              'Tipe: ${question.type == QuestionType.multipleChoice
                                  ? "Pilihan Ganda"
                                  : question.type == QuestionType.trueFalse
                                  ? "Benar/Salah"
                                  : "Jawaban Singkat"} • Waktu: ${question.timeLimitSeconds}s',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppTheme.accent,
                                  ),
                                  onPressed: () =>
                                      _addQuestion(question, index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _questions.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal dialog to Add/Edit individual questions
class QuestionFormDialog extends StatefulWidget {
  final QuestionModel? question;
  final Function(QuestionModel) onSave;
  const QuestionFormDialog({super.key, this.question, required this.onSave});

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late TextEditingController _textController;
  late TextEditingController _categoryController;
  String _difficulty = 'Sedang';
  QuestionType _type = QuestionType.multipleChoice;
  List<TextEditingController> _optionControllers = [];
  late TextEditingController _correctAnswerController;
  late int _points;
  late int _timeLimit;
  String? _audioPath;
  String? _imagePath;
  String? _imageUrl;
  String? _audioUrl;
  String? _memeUrl;
  String? _localAudioPath;
  String? _localImagePath;
  String? _localMemePath;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      final q = widget.question!;
      _id = q.id;
      _textController = TextEditingController(text: q.text);
      _categoryController = TextEditingController(text: q.category);
      _difficulty = q.difficulty;
      _type = q.type;
      _optionControllers = q.options
          .map((o) => TextEditingController(text: o))
          .toList();
      _correctAnswerController = TextEditingController(text: q.correctAnswer);
      _points = q.points;
      _timeLimit = q.timeLimitSeconds;
      _audioPath = q.audioPath;
      _imagePath = q.imagePath;
      _imageUrl = q.imageUrl;
      _audioUrl = q.audioUrl;
      _memeUrl = q.memeUrl;
    } else {
      _id = 'q_q_${DateTime.now().millisecondsSinceEpoch}';
      _textController = TextEditingController();
      _categoryController = TextEditingController(text: 'Umum');
      _difficulty = 'Sedang';
      _type = QuestionType.multipleChoice;
      _optionControllers = [
        TextEditingController(text: 'Opsi A'),
        TextEditingController(text: 'Opsi B'),
        TextEditingController(text: 'Opsi C'),
        TextEditingController(text: 'Opsi D'),
      ];
      _correctAnswerController = TextEditingController();
      _points = 100;
      _timeLimit = 30;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _categoryController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    _correctAnswerController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    String? path = await FileService.pickFile(type: FileType.audio);
    if (path != null) {
      setState(() {
        _localAudioPath = path;
      });
    }
  }

  Future<void> _pickImage() async {
    String? path = await FileService.pickFile(type: FileType.image);
    if (path != null) {
      setState(() {
        _localImagePath = path;
      });
    }
  }

  Future<void> _pickMeme() async {
    String? path = await FileService.pickFile(type: FileType.image);
    if (path != null) {
      setState(() {
        _localMemePath = path;
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploadingMedia = true);

    try {
      if (_localImagePath != null) {
        final url = await FileService.uploadImage(_localImagePath!);
        if (url != null) {
          _imageUrl = url;
        }
      }
      if (_localAudioPath != null) {
        final url = await FileService.uploadAudio(_localAudioPath!);
        if (url != null) {
          _audioUrl = url;
        }
      }
      if (_localMemePath != null) {
        final url = await FileService.uploadMeme(_localMemePath!);
        if (url != null) {
          _memeUrl = url;
        }
      }
    } catch (e) {
      debugPrint("Media upload failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunggah media: $e"), backgroundColor: AppTheme.error),
        );
        setState(() => _isUploadingMedia = false);
      }
      return;
    }

    List<String> options = [];
    if (_type == QuestionType.multipleChoice) {
      options = _optionControllers.map((c) => c.text.trim()).toList();
    } else if (_type == QuestionType.trueFalse) {
      options = ['Benar', 'Salah'];
    }

    QuestionModel newQuestion = QuestionModel(
      id: _id,
      text: _textController.text.trim(),
      type: _type,
      options: options,
      correctAnswer: _correctAnswerController.text.trim(),
      audioPath: _audioUrl ?? _localAudioPath ?? _audioPath,
      imagePath: _imageUrl ?? _localImagePath ?? _imagePath,
      points: _points,
      timeLimitSeconds: _timeLimit,
      category: _categoryController.text.trim(),
      difficulty: _difficulty,
      imageUrl: _imageUrl,
      audioUrl: _audioUrl,
      memeUrl: _memeUrl,
    );

    widget.onSave(newQuestion);
    try {
      await DbService.saveQuestion(newQuestion);
    } catch (e) {
      debugPrint('Sync question to bank failed: $e');
    }
    
    if (mounted) {
      setState(() => _isUploadingMedia = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.question == null ? 'Tambah Soal Baru' : 'Edit Soal',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<QuestionType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe Pertanyaan'),
                items: const [
                  DropdownMenuItem(
                    value: QuestionType.multipleChoice,
                    child: Text('Pilihan Ganda'),
                  ),
                  DropdownMenuItem(
                    value: QuestionType.trueFalse,
                    child: Text('Benar / Salah'),
                  ),
                  DropdownMenuItem(
                    value: QuestionType.openEnded,
                    child: Text('Jawaban Singkat'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                      if (_type == QuestionType.trueFalse) {
                        _correctAnswerController.text = 'Benar';
                      } else {
                        _correctAnswerController.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori (Bank Soal)',
                  hintText: 'Misal: Matematika, IPA, Umum',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Kategori tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Tingkat Kesulitan'),
                items: const [
                  DropdownMenuItem(value: 'Mudah', child: Text('Mudah')),
                  DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
                  DropdownMenuItem(value: 'Sulit', child: Text('Sulit')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _difficulty = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Pertanyaan / Soal',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Soal tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAudio,
                      icon: const Icon(Icons.music_note),
                      label: Text(
                        (_localAudioPath != null || _audioUrl != null || _audioPath != null)
                            ? 'Audio Terunggah'
                            : 'Klip Audio',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: (_localAudioPath == null && _audioUrl == null && _audioPath == null)
                            ? AppTheme.textSecondary
                            : AppTheme.accent,
                        side: BorderSide(
                          color: (_localAudioPath == null && _audioUrl == null && _audioPath == null)
                              ? Colors.white10
                              : AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(
                        (_localImagePath != null || _imageUrl != null || _imagePath != null)
                            ? 'Gambar Terunggah'
                            : 'Gambar Soal',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: (_localImagePath == null && _imageUrl == null && _imagePath == null)
                            ? AppTheme.textSecondary
                            : AppTheme.secondary,
                        side: BorderSide(
                          color: (_localImagePath == null && _imageUrl == null && _imagePath == null)
                              ? Colors.white10
                              : AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickMeme,
                icon: const Icon(Icons.sentiment_satisfied_alt),
                label: Text(
                  (_localMemePath != null || _memeUrl != null)
                      ? 'Meme Terunggah'
                      : 'Meme Soal (Opsional)',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: (_localMemePath == null && _memeUrl == null)
                      ? AppTheme.textSecondary
                      : AppTheme.warning,
                  side: BorderSide(
                    color: (_localMemePath == null && _memeUrl == null)
                        ? Colors.white10
                        : AppTheme.warning,
                  ),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
              if (_localImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_localImagePath!),
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _imageUrl!,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imagePath != null && _imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _imagePath!.startsWith('http')
                      ? Image.network(_imagePath!, height: 80, fit: BoxFit.cover)
                      : Image.file(File(_imagePath!), height: 80, fit: BoxFit.cover),
                ),
              if (_localMemePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_localMemePath!),
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_memeUrl != null && _memeUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _memeUrl!,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),

              if (_type == QuestionType.multipleChoice) ...[
                const Text(
                  'Pilihan Jawaban:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _optionControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Pilihan ${index + 1}',
                        hintText: 'Masukkan pilihan jawaban',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Pilihan tidak boleh kosong'
                          : null,
                    ),
                  );
                }),
              ],

              if (_type == QuestionType.trueFalse)
                DropdownButtonFormField<String>(
                  initialValue: _correctAnswerController.text.isEmpty
                      ? 'Benar'
                      : _correctAnswerController.text,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban yang Benar',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Benar', child: Text('Benar')),
                    DropdownMenuItem(value: 'Salah', child: Text('Salah')),
                  ],
                  onChanged: (val) {
                    if (val != null) _correctAnswerController.text = val;
                  },
                )
              else
                TextFormField(
                  controller: _correctAnswerController,
                  decoration: InputDecoration(
                    labelText: 'Jawaban yang Benar',
                    hintText: _type == QuestionType.multipleChoice
                        ? 'Harus persis sama dengan salah satu pilihan di atas'
                        : 'Masukkan jawaban singkat yang benar',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Jawaban benar tidak boleh kosong';
                    }
                    if (_type == QuestionType.multipleChoice) {
                      final matches = _optionControllers.any(
                        (c) =>
                            c.text.trim().toLowerCase() ==
                            val.trim().toLowerCase(),
                      );
                      if (!matches) {
                        return 'Jawaban benar harus sama dengan salah satu pilihan';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _points,
                      decoration: const InputDecoration(labelText: 'Poin Soal'),
                      items: const [
                        DropdownMenuItem(value: 50, child: Text('50 Poin')),
                        DropdownMenuItem(value: 100, child: Text('100 Poin')),
                        DropdownMenuItem(value: 150, child: Text('150 Poin')),
                        DropdownMenuItem(value: 200, child: Text('200 Poin')),
                      ],
                      onChanged: (val) => setState(() => _points = val ?? 100),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _timeLimit,
                      decoration: const InputDecoration(
                        labelText: 'Batas Waktu',
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Tanpa Batas')),
                        DropdownMenuItem(value: 10, child: Text('10 Detik')),
                        DropdownMenuItem(value: 20, child: Text('20 Detik')),
                        DropdownMenuItem(value: 30, child: Text('30 Detik')),
                        DropdownMenuItem(value: 60, child: Text('60 Detik')),
                        DropdownMenuItem(value: 120, child: Text('120 Detik')),
                      ],
                      onChanged: (val) =>
                          setState(() => _timeLimit = val ?? 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploadingMedia ? null : _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploadingMedia
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Simpan Soal'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionBankSelectorDialog extends StatefulWidget {
  final Function(List<QuestionModel>) onQuestionsSelected;
  const QuestionBankSelectorDialog({super.key, required this.onQuestionsSelected});

  @override
  State<QuestionBankSelectorDialog> createState() => _QuestionBankSelectorDialogState();
}

class _QuestionBankSelectorDialogState extends State<QuestionBankSelectorDialog> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _selectedDifficulty = 'Semua';
  final List<QuestionModel> _selectedQuestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allQuestions = DbService.getQuestions();
    final categories = ['Semua', ...DbService.getQuestionCategories()];

    // Filter questions
    final filtered = allQuestions.where((q) {
      final matchesSearch = q.text.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          q.category.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || q.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'Semua' || q.difficulty == _selectedDifficulty;
      return matchesSearch && matchesCategory && matchesDifficulty;
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih dari Bank Soal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_selectedQuestions.length} Terpilih',
                style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari soal...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Filters Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  dropdownColor: AppTheme.getSurface(context),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Kesulitan', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  dropdownColor: AppTheme.getSurface(context),
                  items: const [
                    DropdownMenuItem(value: 'Semua', child: Text('Semua', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Mudah', child: Text('Mudah', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Sedang', child: Text('Sedang', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Sulit', child: Text('Sulit', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDifficulty = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Questions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada soal yang cocok.',
                      style: TextStyle(color: AppTheme.getTextSecondary(context)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final q = filtered[index];
                      final isSelected = _selectedQuestions.any((sq) => sq.id == q.id);

                      return Card(
                        color: AppTheme.getSurfaceLight(context),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: CheckboxListTile(
                          activeColor: AppTheme.secondary,
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedQuestions.add(q);
                              } else {
                                _selectedQuestions.removeWhere((sq) => sq.id == q.id);
                              }
                            });
                          },
                          title: Text(q.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Kategori: ${q.category} • Kesulitan: ${q.difficulty} • Tipe: ${q.type == QuestionType.multipleChoice ? "Pilihan Ganda" : q.type == QuestionType.trueFalse ? "Benar/Salah" : "Singkat"}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedQuestions.isEmpty
                ? null
                : () {
                    widget.onQuestionsSelected(_selectedQuestions);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Masukkan Soal Terpilih'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
