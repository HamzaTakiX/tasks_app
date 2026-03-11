import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final appState = AppState();
  await appState.initHive(); // Ensure offline storage is ready before UI loads

  runApp(
    ChangeNotifierProvider.value(value: appState, child: const FocusDayApp()),
  );
}

class FocusDayApp extends StatelessWidget {
  const FocusDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusDay',
      debugShowCheckedModeBanner: false,
      // ── Arabic / RTL support ──
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(
          0xFFF8F9FE,
        ), // Modern soft background
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6C63FF), // Vibrant modern purple
          secondary: Color(0xFF00B4D8), // Vibrant cyan touch
          surface: Colors.white,
          onSurface: Color(0xFF2D3142),
          error: Color(0xFFFF6B6B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: const Color(0xFF2D3142),
              displayColor: const Color(0xFF1E2135),
            ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FE),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF6C63FF)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E2135),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF6C63FF),
          unselectedItemColor: Color(0xFFB0B3C6),
          elevation: 20,
        ),
        useMaterial3: true,
      ),

      // Beautiful Dark Theme optimized for OLED and Modern Aesthetics
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0B10), // Deep cinematic dark
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8C85FF), // Lighter purple for dark mode
          secondary: Color(0xFF00E5FF), // Neon cyan accent
          surface: Color(0xFF161823), // Slightly elevated dark surface
          onSurface: Color(0xFFE2E4ED),
          error: Color(0xFFFF8787),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: const Color(0xFFE2E4ED), displayColor: Colors.white),
        cardTheme: CardThemeData(
          color: const Color(0xFF161823),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF232536), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0B10),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF8C85FF)),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161823),
          selectedItemColor: Color(0xFF8C85FF),
          unselectedItemColor: Color(0xFF5B5E75),
          elevation: 20,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
