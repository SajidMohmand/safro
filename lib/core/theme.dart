import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const red = Color(0xFFE5383B);
  static const redDark = Color(0xFFD62828);
  static const redSoft = Color(0xFFFDECEC);
  static const green = Color(0xFF1B9E5A);
  static const greenSoft = Color(0xFFE3F5EB);
  static const ink = Color(0xFF14151A);
  static const grey = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const bg = Color(0xFFF6F6F8);
  static const yellow = Color(0xFFFFB400);
  static const milk = Color(0xFFFFF1E6);
}

TextStyle ts(double size,
        {FontWeight w = FontWeight.w500,
        Color c = AppColors.ink,
        double? h,
        double? ls}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.red, primary: AppColors.red),
      scaffoldBackgroundColor: Colors.white,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.redSoft,
        labelTextStyle: WidgetStatePropertyAll(ts(12, w: FontWeight.w600)),
      ),
    );
  }
}
