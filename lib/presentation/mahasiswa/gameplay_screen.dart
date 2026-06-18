import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
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
  StreamSubscription<PlayerState>? _audioStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final gameplay = Provider.of<GameplayProvider>(context, listen: false);
      if (state == PlayerState.playing) {
        setState(() => _isPlayingAudio = true);
        gameplay.pauseQuestionTimer();
      } else {
        setState(() => _isPlayingAudio = false);
        gameplay.resumeQuestionTimer();
      }
    });
  }

  @override
  void dispose() {
    _audioStateSubscription?.cancel();
    _openAnswerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playQuestionAudio(String path) async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        if (path.startsWith('http')) {
          await _audioPlayer.play(UrlSource(path));
          if (!mounted) return;
          HapticFeedback.lightImpact();
          AppTheme.showPremiumSnackBar(
            context,
            'Memutar klip suara kuis dari server...',
            SnackBarType.info,
          );
        } else if (path.endsWith('.mp3')) {
          if (await File(path).exists()) {
            await _audioPlayer.play(DeviceFileSource(path));
          } else {
            if (!mounted) return;
            HapticFeedback.lightImpact();
            AppTheme.showPremiumSnackBar(
              context,
              'Memutar klip suara kuis...',
              SnackBarType.info,
            );
          }
        }
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

    if (gameplay.showFeedback && _isPlayingAudio) {
      Future.microtask(() => _audioPlayer.stop());
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Skor: ${gameplay.score} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (gameplay.activeQuiz!.isTimerEnabled &&
                      question.timeLimitSeconds > 0)
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceLight(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                      ),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: constraints.maxWidth * timerPercentage,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: timerPercentage > 0.3
                                      ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF10B981)])
                                      : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                        boxShadow: AppTheme.premiumShadow,
                      ),
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
                                  color: AppTheme.primary.withOpacity(0.15),
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: AppTheme.accentGradient,
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _playQuestionAudio(audioPathToPlay),
                                    icon: Icon(
                                      _isPlayingAudio
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      _isPlayingAudio
                                          ? 'Jeda Audio'
                                          : 'Putar Audio Soal',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            if (displayImageUrl != null && displayImageUrl.isNotEmpty) ...[
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
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
                                            color: AppTheme.getSurfaceLight(context),
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
                                              color: AppTheme.getSurfaceLight(context),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_outlined,
                                                    size: 50,
                                                    color: AppTheme.getTextSecondary(context),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '[Image Attachment]',
                                                    style: TextStyle(
                                                      color: AppTheme.getTextSecondary(context),
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
                    ).animate(key: ValueKey(gameplay.currentQuestionIndex))
                     .fade(duration: 300.ms)
                     .slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad),
                  ),
                  const SizedBox(height: 24),

                  _buildAnswersInput(question, gameplay),
                  const SizedBox(height: 28),

                  Text(
                    'Item Power-Up / Booster',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
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
    final emoji = powerup.type == PowerUpType.doubleScore
        ? '🚀'
        : powerup.type == PowerUpType.freezeTimer
        ? '❄️'
        : powerup.type == PowerUpType.fiftyFifty
        ? '✂️'
        : '🛡️';
        
    final name = powerup.type == PowerUpType.doubleScore
        ? 'Double'
        : powerup.type == PowerUpType.freezeTimer
        ? 'Beku'
        : powerup.type == PowerUpType.fiftyFifty
        ? '50:50'
        : 'Perisai';

    return GestureDetector(
      onTap: isEnabled ? () {
        HapticFeedback.mediumImpact();
        gameplay.usePowerUp(powerup);
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.getSurfaceLight(context)
              : AppTheme.getSurface(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? AppTheme.accent.withOpacity(0.6)
                : AppTheme.getBorderColor(context),
            width: 2,
          ),
          boxShadow: isEnabled ? AppTheme.premiumShadow : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isEnabled ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isEnabled
                          ? AppTheme.getTextPrimary(context)
                          : AppTheme.getTextSecondary(context),
                    ),
                  ),
                  Text(
                    'Tersedia: ${powerup.count}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.getTextSecondary(context),
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
      
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        itemCount: question.options.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final option = question.options[index];
          final isPruned = gameplay.prunedOptions.contains(option);

          return GestureDetector(
            onTap: isPruned ? null : () {
              HapticFeedback.mediumImpact();
              _audioPlayer.stop();
              gameplay.answerQuestion(option);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isPruned ? 0.3 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.getBorderColor(context),
                    width: 1.5,
                  ),
                  boxShadow: isPruned ? [] : AppTheme.premiumShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 6,
                        child: Container(
                          color: isPruned 
                              ? AppTheme.getBorderColor(context) 
                              : AppTheme.primary.withOpacity(0.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Center(
                          child: Text(
                            isPruned ? '' : option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPruned 
                                  ? AppTheme.getTextSecondary(context)
                                  : AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(key: ValueKey('${gameplay.currentQuestionIndex}_$index'))
           .scale(delay: (index * 50).ms, duration: 300.ms, curve: Curves.easeOutBack);
        },
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.getBorderColor(context)),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                    filled: false,
                  ),
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.doubleGradient,
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _audioPlayer.stop();
                    gameplay.answerQuestion(_openAnswerController.text);
                    _openAnswerController.clear();
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0);
    }
  }

  Widget _buildFeedbackOverlay(GameplayProvider gameplay) {
    final isCorrect = gameplay.isAnswerCorrect;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isCorrect ? AppTheme.success : AppTheme.error,
                size: 100,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'JAWABAN BENAR! 🎉' : 'JAWABAN SALAH 😭',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppTheme.success : AppTheme.error,
                ),
              ).animate().fade(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 8),
              Text(
                isCorrect ? '+${gameplay.currentQuestion?.points} XP' : '+0 XP',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fade(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isCorrect
                        ? AppTheme.success.withOpacity(0.4)
                        : AppTheme.error.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      gameplay.memeText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    MemeMediaCard(
                      key: ValueKey(gameplay.memeImage),
                      path: gameplay.memeImage,
                      fallback: _buildEmojiMeme(gameplay, isCorrect),
                    ),
                  ],
                ),
              ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isCorrect
                      ? AppTheme.successGradient
                      : const LinearGradient(colors: [AppTheme.error, AppTheme.secondary]),
                  boxShadow: [
                    BoxShadow(
                      color: (isCorrect ? AppTheme.success : AppTheme.error).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    gameplay.dismissFeedback();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ketuk untuk Melanjutkan'),
                ),
              ).animate().fade(delay: 400.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

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
        child: Container(
          height: 200,
          width: double.infinity,
          color: Colors.black.withOpacity(0.15),
          child: FittedBox(
            fit: BoxFit.contain,
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
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.black.withOpacity(0.15),
        child: Image.asset(
          widget.path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => widget.fallback,
        ),
      ),
    );
  }
}
