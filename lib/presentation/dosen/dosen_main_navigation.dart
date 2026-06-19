import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/dosen_provider.dart';
import 'dosen_dashboard.dart';
import 'class_crud.dart';
import 'question_bank_crud.dart';
import 'quiz_assignment_crud.dart';
import 'dosen_analytics.dart';
import 'dosen_profile.dart';

class DosenMainNavigation extends StatefulWidget {
  const DosenMainNavigation({super.key});

  @override
  State<DosenMainNavigation> createState() => _DosenMainNavigationState();
}

class _DosenMainNavigationState extends State<DosenMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DosenProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DosenDashboardScreen(onTabChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const DosenClassCrudScreen(),
      const QuestionBankCrudScreen(),
      const QuizAssignmentCrudScreen(),
      const DosenAnalyticsScreen(),
      const DosenProfileScreen(),
    ];

    final navItems = [
      _NavModel(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dash'),
      _NavModel(icon: Icons.class_outlined, activeIcon: Icons.class_, label: 'Kelas'),
      _NavModel(icon: Icons.question_answer_outlined, activeIcon: Icons.question_answer, label: 'Soal'),
      _NavModel(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Tugas'),
      _NavModel(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analitik'),
      _NavModel(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
    ];

    return Scaffold(
      extendBody: true, // Let content scroll underneath the floating nav
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.premiumShadow,
            border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == idx;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.getTextSecondary(context),
                        size: 20,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavModel {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavModel({required this.icon, required this.activeIcon, required this.label});
}
