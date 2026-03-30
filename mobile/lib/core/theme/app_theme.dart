import 'package:flutter/material.dart';

/// NGỮ CẢNH (CONTEXT):
/// Bộ màu sắc này được trích xuất từ cấu hình Tailwind CSS của file `code.html`.
/// Yêu cầu AI (hoặc tự bạn) sử dụng `AppTheme.lightTheme` trong ứng dụng Flutter,
/// sau đó bất kể HTML gọi màu gì (ví dụ "bg-surface"), bạn sẽ mapping sang `Theme.of(context).colorScheme.surface`.
class AppTheme {
  const AppTheme._();

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary
    primary: Color(0xFF3525CD), // primary
    onPrimary: Color(0xFFFFFFFF), // on-primary
    primaryContainer: Color(0xFF4F46E5), // primary-container
    onPrimaryContainer: Color(0xFFDAD7FF), // on-primary-container
    
    // Secondary
    secondary: Color(0xFF00687A), // secondary
    onSecondary: Color(0xFFFFFFFF), // on-secondary
    secondaryContainer: Color(0xFF57DFFE), // secondary-container
    onSecondaryContainer: Color(0xFF006172), // on-secondary-container
    
    // Tertiary
    tertiary: Color(0xFF005338), // tertiary
    onTertiary: Color(0xFFFFFFFF), // on-tertiary
    tertiaryContainer: Color(0xFF006E4B), // tertiary-container
    onTertiaryContainer: Color(0xFF67F4B7), // on-tertiary-container
    
    // Error
    error: Color(0xFFBA1A1A), // error
    onError: Color(0xFFFFFFFF), // on-error
    errorContainer: Color(0xFFFFDAD6), // error-container
    onErrorContainer: Color(0xFF93000A), // on-error-container
    
    // Surface & Background
    surface: Color(0xFFF8F9FA), // surface
    onSurface: Color(0xFF191C1D), // on-surface
    surfaceContainerHighest: Color(0xFFE1E3E4), // surface-container-highest
    
    // Outline
    outline: Color(0xFF777587), // outline
    outlineVariant: Color(0xFFC7C4D8), // outline-variant
    
    // Inverse
    inverseSurface: Color(0xFF2E3132), // inverse-surface
    onInverseSurface: Color(0xFFF0F1F2), // inverse-on-surface
    inversePrimary: Color(0xFFC3C0FF), // inverse-primary
    
    // Các màu bổ sung M3 (không có param trực tiếp trong ColorScheme,
    // nhưng có thể truy cập thông qua theme extension hoặc gọi trực tiếp)
    // - surfaceContainer: #edeeef
    // - surfaceContainerLowest: #ffffff
    // - surfaceContainerLow: #f3f4f5
    // - surfaceContainerHigh: #e7e8e9
    // - surfaceDim: #d9dadb
    // - surfaceBright: #f8f9fa
    surfaceTint: Color(0xFF4D44E3), // surface-tint
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      // Mapping font
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // Ánh xạ cho 'font-headline' vs 'text-lg'
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        // Ánh xạ cho 'font-body'
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        // Ánh xạ cho 'font-label'
        labelSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0), // ứng với 'tracking-widest'
      ),
    );
  }
}
