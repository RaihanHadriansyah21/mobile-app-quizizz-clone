import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import '../../data/providers/gameplay_provider.dart';
import '../../data/models/question_model.dart';
import '../../data/models/powerup_model.dart';
import '../../core/theme/app_theme.dart';
import 'result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final _openAnswerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    _openAnswerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playQuestionAudio(String path) async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
      } else {
        if (path.startsWith('http')) {
          await _audioPlayer.play(UrlSource(path));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔊 Memutar klip suara kuis dari server...'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (path.endsWith('.mp3')) {
          if (await File(path).exists()) {
            await _audioPlayer.play(DeviceFileSource(path));
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔊 Memutar klip suara kuis...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        setState(() => _isPlayingAudio = true);
      }
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameplay = context.watch<GameplayProvider>();
    final question = gameplay.currentQuestion;

    if (gameplay.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuizResultScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (question == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Pertanyaan kosong")),
      );
    }

    final audioPathToPlay = question.audioUrl ?? question.audioPath;
    final displayImageUrl = question.imageUrl ?? question.memeUrl ?? question.imagePath;

    double timerPercentage = 1.0;
    if (question.timeLimitSeconds > 0 && gameplay.timeLeft < 900) {
      timerPercentage = gameplay.timeLeft / question.timeLimitSeconds;
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Soal ${gameplay.currentQuestionIndex + 1} dari ${gameplay.activeQuiz?.questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Skor: ${gameplay.score} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (gameplay.activeQuiz!.isTimerEnabled &&
                      question.timeLimitSeconds > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: timerPercentage,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timerPercentage > 0.3
                              ? AppTheme.primary
                              : AppTheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: Card(
                      color: AppTheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${question.points} XP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              question.text,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            if (audioPathToPlay != null && audioPathToPlay.isNotEmpty) ...[
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _playQuestionAudio(audioPathToPlay),
                                  icon: Icon(
                                    _isPlayingAudio
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    _isPlayingAudio
                                        ? 'Jeda Audio'
                                        : 'Putar Audio Soal',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            if (displayImageUrl != null && displayImageUrl.isNotEmpty) ...[
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: displayImageUrl.startsWith('http')
                                      ? Image.network(
                                          displayImageUrl,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppTheme.surfaceLight,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                size: 50,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : (File(displayImageUrl).existsSync()
                                          ? Image.file(
                                              File(displayImageUrl),
                                              fit: BoxFit.contain,
                                            )
                                          : Container(
                                              color: AppTheme.surfaceLight,
                                              child: const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_outlined,
                                                    size: 50,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    '[Image Attachment]',
                                                    style: TextStyle(
                                                      color: AppTheme.textSecondary,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildAnswersInput(question, gameplay),
                  const SizedBox(height: 28),

                  Text(
                    'Item Power-Up / Booster',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: gameplay.powerUps.length,
                      itemBuilder: (context, index) {
                        final powerup = gameplay.powerUps[index];
                        final isEnabled = powerup.count > 0;
                        return _buildPowerupButton(
                          gameplay,
                          powerup,
                          isEnabled,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (gameplay.showFeedback) _buildFeedbackOverlay(gameplay),
        ],
      ),
    );
  }

  Widget _buildPowerupButton(
    GameplayProvider gameplay,
    PowerUpModel powerup,
    bool isEnabled,
  ) {
    return GestureDetector(
      onTap: isEnabled ? () => gameplay.usePowerUp(powerup) : null,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.surfaceLight
              : AppTheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppTheme.accent.withOpacity(0.5)
                : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              powerup.type == PowerUpType.doubleScore
                  ? '🚀'
                  : powerup.type == PowerUpType.freezeTimer
                  ? '❄️'
                  : powerup.type == PowerUpType.fiftyFifty
                  ? '✂️'
                  : '🛡️',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    powerup.type == PowerUpType.doubleScore
                        ? 'Double'
                        : powerup.type == PowerUpType.freezeTimer
                        ? 'Beku'
                        : powerup.type == PowerUpType.fiftyFifty
                        ? '50:50'
                        : 'Perisai',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isEnabled ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Tersedia: ${powerup.count}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersInput(QuestionModel question, GameplayProvider gameplay) {
    if (question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.trueFalse) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: question.options.map((option) {
          final isPruned = gameplay.prunedOptions.contains(option);

          return ElevatedButton(
            onPressed: isPruned ? null : () => gameplay.answerQuestion(option),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPruned
                  ? Colors.white10
                  : AppTheme.surfaceLight,
              side: isPruned
                  ? BorderSide.none
                  : const BorderSide(color: Colors.white10),
            ),
            child: Text(
              isPruned ? '' : option,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Card(
        color: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openAnswerController,
                  decoration: const InputDecoration(
                    hintText: 'Ketik jawaban Anda disini...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  gameplay.answerQuestion(_openAnswerController.text);
                  _openAnswerController.clear();
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildFeedbackOverlay(GameplayProvider gameplay) {
    final isCorrect = gameplay.isAnswerCorrect;

    return Container(
      color: Colors.black.withOpacity(0.9),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isCorrect ? AppTheme.success : AppTheme.error,
            size: 100,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'JAWABAN BENAR! 🎉' : 'JAWABAN SALAH 😭',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isCorrect ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCorrect ? '+${gameplay.currentQuestion?.points} XP' : '+0 XP',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCorrect
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.error.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  gameplay.memeText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Reaction meme card. Shows your real media from assets/memes/.
                // Supports images (.jpeg/.jpg/.png/.gif) AND videos (.mp4).
                // Keyed by path so a fresh video controller is built per meme.
                // Falls back to a built-in emoji card if a file is missing.
                MemeMediaCard(
                  key: ValueKey(gameplay.memeImage),
                  path: gameplay.memeImage,
                  fallback: _buildEmojiMeme(gameplay, isCorrect),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),

          ElevatedButton(
            onPressed: () {
              gameplay.dismissFeedback();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCorrect ? AppTheme.success : AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('Ketuk untuk Melanjutkan'),
          ),
        ],
      ),
    );
  }

  // Default reaction card: a colored gradient with a big reaction emoji.
  // Works without any image assets.
  Widget _buildEmojiMeme(GameplayProvider gameplay, bool isCorrect) {
    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [
                  AppTheme.success.withOpacity(0.30),
                  AppTheme.primary.withOpacity(0.30),
                ]
              : [
                  AppTheme.error.withOpacity(0.30),
                  AppTheme.secondary.withOpacity(0.30),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppTheme.success.withOpacity(0.4)
              : AppTheme.error.withOpacity(0.4),
        ),
      ),
      child: Text(
        gameplay.memeEmoji.isNotEmpty ? gameplay.memeEmoji : '🎯',
        style: const TextStyle(fontSize: 72),
      ),
    );
  }

  // Shows your real media from assets/memes/ when available, gracefully
  // falling back to the emoji card if a file is missing.
}

// Reaction meme card that supports BOTH images and short videos.
//   - .mp4  -> played muted, looping, via video_player
//   - other -> shown with Image.asset (.jpeg/.jpg/.png/.gif; GIFs animate)
// While a video initializes (or if any file is missing/unsupported), the
// provided [fallback] widget (an emoji card) is shown instead.
class MemeMediaCard extends StatefulWidget {
  final String path;
  final Widget fallback;

  const MemeMediaCard({super.key, required this.path, required this.fallback});

  @override
  State<MemeMediaCard> createState() => _MemeMediaCardState();
}

class _MemeMediaCardState extends State<MemeMediaCard> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoFailed = false;

  bool get _isVideo => widget.path.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.path);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // keep quiz audio clean
      await controller.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      if (_videoFailed) return widget.fallback;
      if (!_videoReady || _controller == null) {
        return widget.fallback; // shown briefly while the video loads
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    // Image path (jpeg/jpg/png/gif).
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        widget.path,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => widget.fallback,
      ),
    );
  }
}
