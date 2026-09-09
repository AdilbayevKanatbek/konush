import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konush/src/core/ui/app_motion.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.onestTextTheme().apply(
      bodyColor: const Color(0xFF12211F),
      displayColor: const Color(0xFF12211F),
    ),
    primaryTextTheme: GoogleFonts.onestTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7A6E),
      primary: const Color(0xFF0E7A6E),
      surface: const Color(0xFFFBFAF7),
    ),
    scaffoldBackgroundColor: const Color(0xFFFBFAF7),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: Color(0xFF0E7A6E),
      scaffoldBackgroundColor: Color(0xFFFBFAF7),
      barBackgroundColor: Color(0xFFFBFAF7),
      textTheme: CupertinoTextThemeData(primaryColor: Color(0xFF12211F)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFBFAF7),
      foregroundColor: Color(0xFF12211F),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: Color(0xFFE9EBE7)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFE7F3F1),
      surfaceTintColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF0E7A6E),
      linearTrackColor: Color(0xFFE7F3F1),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: AppMotion.fast,
      showDuration: const Duration(seconds: 2),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFDFE4DE)),
      ),
    ),
  );
}
