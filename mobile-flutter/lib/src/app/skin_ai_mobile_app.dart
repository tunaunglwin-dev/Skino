import 'package:flutter/material.dart';

import '../features/analysis/presentation/skin_analysis_screen.dart';

class SkinAiMobileApp extends StatelessWidget {
  const SkinAiMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skino',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFAF7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFF47C22),
          onPrimary: Colors.white,
          secondary: Color(0xFF174C45),
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF282420),
          error: Color(0xFFE5533C),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 26,
            height: 1.16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF282420),
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            height: 1.18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF282420),
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF282420),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: Color(0xFF282420),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF282420),
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: Color(0xFF282420),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.38,
            fontWeight: FontWeight.w400,
            color: Color(0xFF433D37),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.36,
            fontWeight: FontWeight.w400,
            color: Color(0xFF625B53),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            height: 1.32,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A7169),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF98128),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0E5C56),
            side: const BorderSide(color: Color(0xFFFFB98D)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: const SkinAnalysisScreen(),
    );
  }
}
