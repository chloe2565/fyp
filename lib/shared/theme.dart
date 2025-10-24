import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData customAppTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFEFEFEF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFD722E), // Orange
    onPrimary: Colors.white,
    secondary: Color(0xFF969696), // Cancel grey
    onSecondary: Colors.white,
    tertiary: Color(0xFF1CB870), // Success logo green
    onTertiary: Color(0xFF056137), // Success text dark green
    error: Color(0xFFFF0014), // Error, Fail red
    onError: Colors.black,
    errorContainer: Colors.white,
    surface: Colors.white, // Card bg color
    onSurface: Color(0xFF404042),
    surfaceDim: Color(0xFFB5B5B5),
    brightness: Brightness.light,
    primaryContainer: Color(0xFFFD722E), // Focused icon color (orange)
    onSurfaceVariant: Color(0xFF565656), // Unfocused icon color (grey)
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      color: Colors.black,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 30,
    ),
    headlineSmall: TextStyle(
      color: Color(0xFF5C5F62),
      fontFamily: 'Poppins',
      fontSize: 16,
    ),
    labelMedium: TextStyle(
      color: Colors.black,
      fontFamily: 'Poppins',
      fontSize: 20,
    ),
    labelSmall: TextStyle(
      color: Color(0xFF5C5F62),
      fontSize: 14,
      fontFamily: 'Poppins',
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Color(0xFFFD722E),
    ),
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Color(0xFFFD722E),
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 12,
      color: Colors.black,
    ),
    displayMedium: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: 'Plus Jakarta Sans',
      fontWeight: FontWeight.w600,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFD722E),
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    centerTitle: true,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      textStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.normal,
            fontSize: 14,
            color: Color(0xFFE6E6E6), // Disabled light grey
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFE6E6E6),
          );
        }
        return const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: Colors.black, // Normal text
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFFFD722E),
        );
      }),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.fromLTRB(0, 20, 0, 20)
      ),
      minimumSize: const WidgetStatePropertyAll(
          Size(double.infinity, double.minPositive)
      ),
      side: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: Color(0xFFE6E6E6)); // Light grey
        }
        if (states.contains(WidgetState.pressed)) {
          return const BorderSide(color: Color(0xFFFD722E)); // Orange border
        }
        return const BorderSide(color: Color(0xFFCCCCCC)); // Default grey
      }),
      foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFE6E6E6); // Disabled light grey
        }
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFFFD722E); // Orange on press
        }
        return const Color(0xFF666666); // Default grey
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.fromLTRB(0, 20, 0, 20)
      ),
      minimumSize: const WidgetStatePropertyAll(
          Size(double.infinity, double.minPositive)
      ),
      foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white; // White text for disabled for contrast
        }
        return Colors.white; // White text for normal state
      }),
      backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFE6E6E6); // Disabled light grey
        }
        return const Color(0xFFFD722E); // Orange background
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.fromLTRB(0, 20, 0, 20)
      ),
      minimumSize: const WidgetStatePropertyAll(
          Size(double.infinity, double.minPositive)
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFE6E6E6); // Disabled light grey
        }
        return const Color(0xFF969696); // Grey for cancellation
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCACACA)), // Grey border
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCACACA)), // Grey border
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFFD722E), // Orange border
        width: 2,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)), // Disabled light grey
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF5C5F62),
      fontSize: 14,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.normal,
    ),
  ),
);