import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum EmptyIllustrationType { noQuiz, noClass, noAttempt, noAnalytics }

class VectorIllustration extends StatelessWidget {
  final EmptyIllustrationType type;
  final Color color;

  const VectorIllustration({
    super.key,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _IllustrationPainter(type: type, color: color),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final EmptyIllustrationType type;
  final Color color;

  _IllustrationPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (type) {
      case EmptyIllustrationType.noQuiz:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.15, w * 0.44, h * 0.65),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, paint);
        canvas.drawLine(Offset(w * 0.38, h * 0.32), Offset(w * 0.62, h * 0.32), paint);
        canvas.drawLine(Offset(w * 0.38, h * 0.45), Offset(w * 0.62, h * 0.45), paint);
        canvas.drawLine(Offset(w * 0.38, h * 0.58), Offset(w * 0.52, h * 0.58), paint);
        
        final badgeCenter = Offset(w * 0.72, h * 0.68);
        canvas.drawCircle(badgeCenter, 13, Paint()..color = color..style = PaintingStyle.fill);
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2));
        break;

      case EmptyIllustrationType.noClass:
        final boardRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.42),
          const Radius.circular(6),
        );
        canvas.drawRRect(boardRect, fillPaint);
        canvas.drawRRect(boardRect, paint);
        canvas.drawLine(Offset(w * 0.14, h * 0.64), Offset(w * 0.86, h * 0.64), paint);
        canvas.drawLine(Offset(w * 0.34, h * 0.64), Offset(w * 0.28, h * 0.85), paint);
        canvas.drawLine(Offset(w * 0.66, h * 0.64), Offset(w * 0.72, h * 0.85), paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.64), Offset(w * 0.5, h * 0.88), paint);
        
        final capPath = Path()
          ..moveTo(w * 0.5, h * 0.3)
          ..lineTo(w * 0.64, h * 0.36)
          ..lineTo(w * 0.5, h * 0.42)
          ..lineTo(w * 0.36, h * 0.36)
          ..close();
        canvas.drawPath(capPath, paint);
        break;

      case EmptyIllustrationType.noAttempt:
        final doc = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.15, w * 0.44, h * 0.65),
          const Radius.circular(8),
        );
        canvas.drawRRect(doc, fillPaint);
        canvas.drawRRect(doc, paint);
        for (var i = 0; i < 3; i++) {
          final y = h * (0.28 + i * 0.16);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.34, y, 10, 10), const Radius.circular(2)),
            paint,
          );
          canvas.drawLine(Offset(w * 0.48, y + 5), Offset(w * 0.64, y + 5), paint);
        }
        break;

      case EmptyIllustrationType.noAnalytics:
        canvas.drawLine(Offset(w * 0.2, h * 0.75), Offset(w * 0.8, h * 0.75), paint);
        canvas.drawLine(Offset(w * 0.2, h * 0.22), Offset(w * 0.2, h * 0.75), paint);
        final heights = [h * 0.26, h * 0.42, h * 0.22];
        for (var i = 0; i < 3; i++) {
          final x = w * (0.28 + i * 0.16);
          final rect = Rect.fromLTWH(x, h * 0.75 - heights[i], w * 0.11, heights[i]);
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, paint);
        }
        final trendPaint = Paint()
          ..color = AppTheme.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.32, h * 0.62), Offset(w * 0.48, h * 0.46), trendPaint);
        canvas.drawLine(Offset(w * 0.48, h * 0.46), Offset(w * 0.64, h * 0.34), trendPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final EmptyIllustrationType? illustrationType;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final List<Widget>? extraActions;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.illustrationType,
    this.actionLabel,
    this.onActionPressed,
    this.extraActions,
  });

  EmptyIllustrationType get _inferredType {
    if (illustrationType != null) return illustrationType!;
    if (icon == Icons.school || icon == Icons.class_ || icon == Icons.group || icon == Icons.people) {
      return EmptyIllustrationType.noClass;
    }
    if (icon == Icons.analytics || icon == Icons.bar_chart || icon == Icons.show_chart) {
      return EmptyIllustrationType.noAnalytics;
    }
    if (icon == Icons.history || icon == Icons.assignment || icon == Icons.check_circle || icon == Icons.assignment_turned_in) {
      return EmptyIllustrationType.noAttempt;
    }
    return EmptyIllustrationType.noQuiz;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VectorIllustration(
              type: _inferredType,
              color: AppTheme.primary,
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack)
                .rotate(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeInOut),
            const SizedBox(height: 28),
            
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.getTextPrimary(context),
                  ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 12),
            
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms, duration: 300.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 36),
            
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(actionLabel!),
                ),
              ).animate().fade(delay: 300.ms, duration: 300.ms).scaleXY(begin: 0.95, end: 1),
            ],
            if (extraActions != null) ...[
              const SizedBox(height: 8),
              ...extraActions!.asMap().entries.map((entry) {
                final idx = entry.key;
                final widget = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: widget,
                  ),
                ).animate().fade(delay: (300 + idx * 80).ms, duration: 300.ms).scaleXY(begin: 0.95, end: 1);
              }),
            ],
          ],
        ),
      ),
    );
  }
}
