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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.getBorderColor(context), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.getSurface(context),
          selectedItemColor: AppTheme.secondary, // Electric Pink for Dosen Theme
          unselectedItemColor: AppTheme.getTextSecondary(context),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.class_outlined),
              activeIcon: Icon(Icons.class_),
              label: 'Kelas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer_outlined),
              activeIcon: Icon(Icons.question_answer),
              label: 'Bank Soal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Tugas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analitik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
