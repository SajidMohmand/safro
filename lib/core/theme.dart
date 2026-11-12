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
  static const splashBg = Color(0xFF2A163F);
  static const creamBg = Color(0xFFF8F3EE);
  static const lilacBg = Color(0xFFEFE8F6);
  static const numberDark = Color(0xFF261838);
  static const verifyRed = Color(0xFFC93924);
  static const navSelected = Color(0xFFCA4E3D);
  static const searchBg = Color(0xFFEFE9F4);
  static const chipBg = Color(0xFFEBE2F4);
  static const safeGuardBg = Color(0xFF30887D);
  static const avatarBg = Color(0xFF413052);
  static const planTextDark = Color(0xFF2E2234);
  static const planCardDark = Color(0xFF2A163F);
  static const planSelectedDay = Color(0xFF2B173F);
  static const planUnselectedDay = Color(0xFFF2E9F7);
  static const planActiveBtn = Color(0xFF117770);
  static const tripsTextDark = Color(0xFF211527);
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
        indicatorColor: AppColors.navSelected.withOpacity(0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navSelected);
          }
          return const IconThemeData(color: AppColors.grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ts(12, w: FontWeight.w700, c: AppColors.navSelected);
          }
          return ts(12, w: FontWeight.w600, c: AppColors.grey);
        }),
      ),
    );
  }
}
