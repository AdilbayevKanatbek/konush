import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konush/src/core/ui/app_motion.dart';

abstract final class AppTheme {
  static ThemeData get light => build();

  static ThemeData build({TextTheme? textTheme}) => ThemeData(
    useMaterial3: true,
    textTheme: (textTheme ?? GoogleFonts.onestTextTheme()).apply(
      bodyColor: const Color(0xFF12211F),
      displayColor: const Color(0xFF12211F),
    ),
    primaryTextTheme: textTheme ?? GoogleFonts.onestTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7A6E),
      primary: const Color(0xFF0E7A6E),
      surface: const Color(0xFFFBFAF7),
    ),
    scaffoldBackgroundColor: Colors.white,
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: Color(0xFF0E7A6E),
      scaffoldBackgroundColor: Colors.white,
      barBackgroundColor: Colors.white,
      textTheme: CupertinoTextThemeData(primaryColor: Color(0xFF12211F)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF12211F),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 60,
      titleTextStyle: TextStyle(
        fontFamily: 'Onest',
        color: Color(0xFF12211F),
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF0E7A6E), size: 23),
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(
          fontFamily: 'Onest',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: const BorderSide(color: Color(0xFFE2E8E4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      iconColor: Color(0xFF7A8884),
    ),
    dividerColor: const Color(0xFFE9EEEB),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF5F7F5),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: TextStyle(color: Color(0xFF7A8884), fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(11)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(11)),
        borderSide: BorderSide(color: Color(0xFF0E7A6E)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFDFE4DE)),
      ),
    ),
  );
}
