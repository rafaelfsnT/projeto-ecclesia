// Em: lib/theme_app.dart

import 'package:flutter/material.dart';

ThemeData themeApp() {
  const Color corMarrom = Color(0xFF5D4037);
  const Color corDourado = Color(0xFFD4AF37);
  const Color branco = Colors.white;
  const Color preto = Colors.black;
  final Color cinzaSuave = Colors.grey.shade400;

  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: corMarrom,
    brightness: Brightness.light,
    primary: corMarrom,
    onPrimary: branco,
    secondary: corDourado,
    onSecondary: preto,
    surface: const Color(0xFFF5F5F5), // Um branco um pouco mais suave para o fundo
    onSurface: preto,
    error: Colors.red.shade700,
    onError: branco,
  );

  final TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colorScheme.onSurface), // Título da AppBar
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
    bodyLarge: TextStyle(fontSize: 18, color: colorScheme.onSurface), // Texto principal
    bodyMedium: TextStyle(fontSize: 16, color: colorScheme.onSurface), // Texto secundário
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onPrimary), // Texto de botões
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: corMarrom,
      foregroundColor: branco,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: branco),
      iconTheme: const IconThemeData(color: branco, size: 28), // Ícones maiores
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corMarrom,
        foregroundColor: branco,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: corMarrom,
        textStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: const IconThemeData(color: corMarrom),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withAlpha(30),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: cinzaSuave),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: corDourado, width: 2.0),
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: TextStyle(color: corMarrom.withAlpha(200)),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
  );
}