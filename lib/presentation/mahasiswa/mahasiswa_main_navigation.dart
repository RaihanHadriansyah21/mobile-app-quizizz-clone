import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/mahasiswa_provider.dart';
import 'mahasiswa_dashboard.dart';
import 'join_class.dart';
import 'mahasiswa_leaderboard.dart';
import 'mahasiswa_profile.dart';

class MahasiswaMainNavigation extends StatefulWidget {
  const MahasiswaMainNavigation({super.key});

  @override
  State<MahasiswaMainNavigation> createState() => _MahasiswaMainNavigationState();
}

class _MahasiswaMainNavigationState extends State<MahasiswaMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MahasiswaDashboardScreen(),
    JoinClassScreen(),
    MahasiswaLeaderboardScreen(),
    MahasiswaProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<MahasiswaProvider>(context, listen: false)
            .refreshData(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
          selectedItemColor: AppTheme.primary, // Deep Neon Purple for Mahasiswa Theme
          unselectedItemColor: AppTheme.getTextSecondary(context),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Gabung Kelas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard),
              label: 'Peringkat',
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
