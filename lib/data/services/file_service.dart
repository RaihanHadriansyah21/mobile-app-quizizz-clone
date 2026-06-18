import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/class_model.dart';
import '../models/quiz_model.dart';
import '../models/attempt_model.dart';

class FileService {
  /// Upload a local file to Supabase Storage bucket and return public URL.
  /// If it fails or Supabase is not enabled/configured, returns null.
  static Future<String?> uploadToSupabase(
    String localPath,
    String bucketName,
  ) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${localPath.split(Platform.pathSeparator).last}';

      // Check if Supabase is initialized
      try {
        final supabase = Supabase.instance.client;

        // Upload the file
        await supabase.storage.from(bucketName).upload(fileName, file);

        // Get the public URL
        final String publicUrl = supabase.storage
            .from(bucketName)
            .getPublicUrl(fileName);
        return publicUrl;
      } catch (e) {
        debugPrint("Supabase storage error (using local path fallback): $e");
        return null;
      }
    } catch (e) {
      debugPrint("Error reading file for upload: $e");
      return null;
    }
  }

  /// Delete a file from Supabase Storage by its public URL.
  static Future<void> deleteFromSupabase(
    String publicUrl,
    String bucketName,
  ) async {
    try {
      if (!publicUrl.contains(bucketName)) return;
      final fileName = publicUrl.split('/').last;

      try {
        final supabase = Supabase.instance.client;
        await supabase.storage.from(bucketName).remove([fileName]);
        debugPrint("Deleted old file from Supabase storage: $fileName");
      } catch (e) {
        debugPrint("Error deleting from Supabase storage: $e");
      }
    } catch (e) {
      debugPrint("Error parsing url for delete: $e");
    }
  }

  // Pick a file (image, audio, or any)
  static Future<String?> pickFile({
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      debugPrint("Error picking file: $e");
      return null;
    }
  }

  // Generate and display PDF analytics report
  static Future<void> exportAnalyticsPdf({
    required ClassModel classObj,
    required QuizModel quiz,
    required List<AttemptModel> attempts,
  }) async {
    final pdf = pw.Document();

    // Calculate basic statistics
    double averageScore = 0;
    int totalQuestions = quiz.questions.length;
    int perfectScoresCount = 0;

    if (attempts.isNotEmpty) {
      int sum = attempts.map((a) => a.score).reduce((a, b) => a + b);
      averageScore = sum / attempts.length;
      perfectScoresCount = attempts
          .where((a) => a.correctAnswersCount == totalQuestions)
          .length;
    }

    // Sort attempts by score descending (leaderboard style)
    attempts.sort((a, b) => b.score.compareTo(a.score));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'QUIZIZZ ANALYTICS REPORT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 22,
                      color: PdfColors.purple800,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 10),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Class and Quiz details
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Class: ${classObj.className} (Code: ${classObj.code})',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Quiz: ${quiz.title}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Total Questions: $totalQuestions | Total Submissions: ${attempts.length}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary metrics cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfCard(
                  'Average Score',
                  averageScore.toStringAsFixed(1),
                  PdfColors.blue700,
                ),
                _buildPdfCard(
                  'Perfect Scores',
                  '$perfectScoresCount / ${attempts.length}',
                  PdfColors.green700,
                ),
                _buildPdfCard(
                  'Active Students',
                  classObj.studentIds.length.toString(),
                  PdfColors.orange700,
                ),
              ],
            ),
            pw.SizedBox(height: 25),

            // Roster / Student Results Table
            pw.Text(
              'Student Results Breakdowns',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'Rank',
                'Student Name',
                'Correct Answers',
                'Score',
                'Time Taken (s)',
                'Completed Date',
              ],
              data: List<List<dynamic>>.generate(attempts.length, (index) {
                var attempt = attempts[index];
                return [
                  (index + 1).toString(),
                  attempt.studentName,
                  '${attempt.correctAnswersCount} / $totalQuestions',
                  attempt.score.toString(),
                  '${attempt.timeTaken}s',
                  attempt.completedAt.toString().substring(0, 16),
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.purple900,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),

            // --- PER-STUDENT ANSWER DETAIL ---
            pw.SizedBox(height: 25),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Rincian Jawaban per Mahasiswa',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (attempts.isEmpty)
              pw.Text('Belum ada pengerjaan untuk kuis ini.'),
            ...attempts.expand(
              (attempt) => _buildStudentAnswerBlock(quiz, attempt),
            ),
          ];
        },
      ),
    );

    // Layout the PDF in the printing viewer (enables downloading, saving, printing on any device)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          '${classObj.className.replaceAll(' ', '_')}_${quiz.title.replaceAll(' ', '_')}_Report.pdf',
    );
  }

  // Builds the per-question answer breakdown for one student.
  static List<pw.Widget> _buildStudentAnswerBlock(
    QuizModel quiz,
    AttemptModel attempt,
  ) {
    final rows = List<List<dynamic>>.generate(quiz.questions.length, (i) {
      final q = quiz.questions[i];
      final given = (attempt.answers[q.id] ?? '').trim();
      final isCorrect =
          given.isNotEmpty &&
          given.toLowerCase() == q.correctAnswer.toLowerCase().trim();
      return [
        '${i + 1}',
        q.text,
        given.isEmpty ? '(tidak dijawab)' : given,
        q.correctAnswer,
        isCorrect ? 'Benar' : 'Salah',
      ];
    });

    return [
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              attempt.studentName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            pw.Text(
              'Benar ${attempt.correctAnswersCount}/${quiz.questions.length}   Skor ${attempt.score}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headers: ['No', 'Pertanyaan', 'Jawaban Siswa', 'Kunci', 'Status'],
        data: rows,
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          fontSize: 10,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
        cellStyle: const pw.TextStyle(fontSize: 9),
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        cellAlignment: pw.Alignment.centerLeft,
        cellAlignments: {0: pw.Alignment.center, 4: pw.Alignment.center},
        columnWidths: {
          0: const pw.FixedColumnWidth(28),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
          4: const pw.FixedColumnWidth(50),
        },
      ),
    ];
  }

  static pw.Widget _buildPdfCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Export CSV report of quiz analytics
  static Future<void> exportAnalyticsCsv({
    required ClassModel classObj,
    required QuizModel quiz,
    required List<AttemptModel> attempts,
  }) async {
    final buffer = StringBuffer();
    // Headers: Nama mahasiswa, Score, Correct answer, Total question, Time taken, Tanggal submit
    buffer.writeln('Nama Mahasiswa,Score,Correct Answer,Total Question,Time Taken (seconds),Tanggal Submit');
    
    // Sort attempts by score descending
    final sortedAttempts = List<AttemptModel>.from(attempts)
      ..sort((a, b) => b.score.compareTo(a.score));

    for (var attempt in sortedAttempts) {
      final name = attempt.studentName.replaceAll('"', '""');
      final dateStr = attempt.completedAt.toIso8601String();
      buffer.writeln('"$name",${attempt.score},${attempt.correctAnswersCount},${attempt.totalQuestions},${attempt.timeTaken},"$dateStr"');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${classObj.className.replaceAll(' ', '_')}_${quiz.title.replaceAll(' ', '_')}_Report.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], subject: 'Export CSV Analytics - ${quiz.title}');
    } catch (e) {
      debugPrint("Error exporting CSV: $e");
    }
  }

  // Upload an image to the 'images' bucket
  static Future<String?> uploadImage(String localPath) async {
    return uploadToSupabase(localPath, 'images');
  }

  // Upload an audio clip to the 'audio' bucket
  static Future<String?> uploadAudio(String localPath) async {
    return uploadToSupabase(localPath, 'audio');
  }

  // Upload a meme to the 'images' bucket
  static Future<String?> uploadMeme(String localPath) async {
    return uploadToSupabase(localPath, 'images');
  }
}
