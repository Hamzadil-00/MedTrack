import 'package:flutter/material.dart';
import 'package:medtrack/utils/constants.dart';

final appTheme = ThemeData(
  primarySwatch: MaterialColor(
    AppConstants.primaryColorValue,
    const {
      50: Color(0xFFECEAFE),
      100: Color(0xFFD0CBFD),
      200: Color(0xFFB1A9FC),
      300: Color(0xFF9287FA),
      400: Color(0xFF7A6DF9),
      500: Color(AppConstants.primaryColorValue),
      600: Color(0xFF5F5BF6),
      700: Color(0xFF5451F5),
      800: Color(0xFF4A47F3),
      900: Color(0xFF3935F1),
    },
  ),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: MaterialColor(
      AppConstants.primaryColorValue,
      const {
        50: Color(0xFFECEAFE),
        100: Color(0xFFD0CBFD),
        200: Color(0xFFB1A9FC),
        300: Color(0xFF9287FA),
        400: Color(0xFF7A6DF9),
        500: Color(AppConstants.primaryColorValue),
        600: Color(0xFF5F5BF6),
        700: Color(0xFF5451F5),
        800: Color(0xFF4A47F3),
        900: Color(0xFF3935F1),
      },
    ),
  ).copyWith(
    secondary: Color(AppConstants.secondaryColorValue),
    background: Color(AppConstants.accentColorValue),
  ),
  scaffoldBackgroundColor: Color(AppConstants.accentColorValue),
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Color(AppConstants.primaryColorValue),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);