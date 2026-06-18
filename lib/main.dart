import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/db_service.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/providers/dosen_provider.dart';
import 'data/providers/mahasiswa_provider.dart';
import 'data/providers/gameplay_provider.dart';
import 'data/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/splash_screen.dart';

// CONFIGURATION: Replace these with your actual Supabase credentials.
// You can find these in your Supabase project settings under API.
const String supabaseUrl = 'https://svendvsdlxucpswmwnaw.supabase.co';
const String supabaseAnonKey = 'sb_publishable_LWXX758R6GZJ7nSL7t9Iqg_7wBKc5Qt';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if credentials are provided
  if (supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  } else {
    debugPrint('Supabase credentials not set. Running in offline/cached mode.');
  }

  // Initialize Shared Preferences & Local Mock Database
  await DbService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DosenProvider()),
        ChangeNotifierProvider(create: (_) => MahasiswaProvider()),
        ChangeNotifierProvider(create: (_) => GameplayProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const QuizizzApp(),
    ),
  );
}

class QuizizzApp extends StatelessWidget {
  const QuizizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Quizizz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
