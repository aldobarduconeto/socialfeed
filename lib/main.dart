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
    const primaryColor = Color(0xFF635BFF);

    return MaterialApp(
      title: 'SocialFeed',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        dividerTheme: DividerThemeData(
          color: Colors.black.withValues(alpha: 0.06),
          thickness: 1,
          space: 1,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.88),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: const Color(0xFF7C74FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF12151E),
        ),
        scaffoldBackgroundColor: const Color(0xFF090B10),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.07),
          thickness: 1,
          space: 1,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12151E).withValues(alpha: 0.88),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
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
