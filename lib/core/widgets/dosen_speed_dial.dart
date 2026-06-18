import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class DosenSpeedDial extends StatefulWidget {
  final VoidCallback onCreateClass;
  final VoidCallback onCreateQuiz;
  final VoidCallback onCreateQuestion;

  const DosenSpeedDial({
    super.key,
    required this.onCreateClass,
    required this.onCreateQuiz,
    required this.onCreateQuestion,
  });

  @override
  State<DosenSpeedDial> createState() => _DosenSpeedDialState();
}

class _DosenSpeedDialState extends State<DosenSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildChildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Card
        ScaleTransition(
          scale: _expandAnimation,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.getBorderColor(context)),
                boxShadow: AppTheme.premiumShadow,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(context),
                ),
              ),
            ),
          ),
        ),
        // Mini FAB
        ScaleTransition(
          scale: _expandAnimation,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _toggle();
                  onTap();
                },
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Backdrop Overlay when open
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ),

        // Floating menu items above main FAB
        Positioned(
          right: 4,
          bottom: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChildButton(
                icon: Icons.school_outlined,
                label: 'Buat Kelas',
                onTap: widget.onCreateClass,
              ),
              const SizedBox(height: 14),
              _buildChildButton(
                icon: Icons.quiz_outlined,
                label: 'Buat Kuis',
                onTap: widget.onCreateQuiz,
              ),
              const SizedBox(height: 14),
              _buildChildButton(
                icon: Icons.add_comment_outlined,
                label: 'Tambah Soal',
                onTap: widget.onCreateQuestion,
              ),
            ],
          ),
        ),

        // Main FAB
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: RotationTransition(
                turns: _rotateAnimation,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
