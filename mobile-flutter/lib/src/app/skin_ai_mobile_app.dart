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
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF98128),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFF9F5),
            side: const BorderSide(color: Color(0xFFFFB98D)),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: const SkinAnalysisScreen(),
    );
  }
}
