import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocialFeedApp());
}

class SocialFeedApp extends StatefulWidget {
  const SocialFeedApp({super.key});

  @override
  State<SocialFeedApp> createState() => _SocialFeedAppState();
}

class _SocialFeedAppState extends State<SocialFeedApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('sf_theme_mode') ?? 0;
    if (mounted) {
      setState(() {
        _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
      });
    }
  }

  Future<void> _changeTheme(ThemeMode next) async {
    setState(() => _themeMode = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sf_theme_mode', next.index);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6C5CE7);

    return MaterialApp(
      title: 'SocialFeed',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5FA),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0D14),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161922).withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: MainScreen(
        currentTheme: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}
