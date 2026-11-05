

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color navy = Color(0xFF0B1220);
  static const Color navyCard = Color(0xFF151F32);
  static const Color gold = Color(0xFFF2C46D);
  static const Color goldDark = Color(0xFF8B651B);

  // Dark theme
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF151F32);
  static const Color darkText = Color(0xFFF4F6FA);
  static const Color darkTextSecondary = Color(0xFFAAB5C8);
  static const Color darkBorder = Color(0xFF2A3850);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF192235);
  static const Color lightTextSecondary = Color(0xFF526078);
  static const Color lightBorder = Color(0xFFDCE3ED);

  // Ludo player colors — independent from app theme
  static const Color playerGreen = Color(0xFF38B879);
  static const Color playerYellow = Color(0xFFF5C542);
  static const Color playerBlue = Color(0xFF4D91F7);
  static const Color playerRed = Color(0xFFF06464);
}
