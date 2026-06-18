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
    final navItems = [
      _NavModel(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Beranda'),
      _NavModel(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Gabung'),
      _NavModel(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Peringkat'),
      _NavModel(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
    ];

    return Scaffold(
      extendBody: true, // Let the scaffold content flow behind the floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
