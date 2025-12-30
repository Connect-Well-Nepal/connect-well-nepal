import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/splash_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// Entry point of the Connect Well Nepal application
/// 
/// This file initializes the app:
/// - Provider for state management
/// - Material Design 3 theming with dark mode support
/// - Custom color scheme
/// - Global app configuration
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ConnectWellNepalApp(),
    ),
  );
}

/// Root widget of the application
class ConnectWellNepalApp extends StatelessWidget {
  const ConnectWellNepalApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
    return MaterialApp(
      // metadata
      title: 'Connect Well Nepal',
      debugShowCheckedModeBanner: false,
      
          // Theme mode from provider
          themeMode: appProvider.themeMode,

          // Light Theme configuration using Material 3
          theme: _buildLightTheme(),

          // Dark Theme configuration
          darkTheme: _buildDarkTheme(),

          // Set SplashScreen as the home screen (will navigate to AuthScreen or MainScreen)
          home: const SplashScreen(),
        );
      },
    );
  }

  /// Build light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
        // Enable Material Design 3
        useMaterial3: true,

      brightness: Brightness.light,
        
        // Color scheme based on AppColors
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavyBlue,
          primary: AppColors.primaryNavyBlue,
          secondary: AppColors.secondaryCrimsonRed,
          surface: AppColors.backgroundWhite,
          surfaceContainer: AppColors.backgroundOffWhite,
        brightness: Brightness.light,
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.primaryNavyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.backgroundWhite,
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundOffWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.dividerGray,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryNavyBlue,
              width: 2,
            ),
          ),
        ),
        
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryCrimsonRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        
        // Text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        
        // Scaffold background
        scaffoldBackgroundColor: AppColors.backgroundOffWhite,

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryNavyBlue,
        unselectedItemColor: AppColors.textSecondary,
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    const darkBackground = Color(0xFF0D1B2A);
    const darkSurface = Color(0xFF1B263B);
    const darkCard = Color(0xFF1E2A3A);

    return ThemeData(
      // Enable Material Design 3
      useMaterial3: true,

      brightness: Brightness.dark,

      // Color scheme for dark mode
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavyBlue,
        primary: const Color(0xFF5A7BC0),
        secondary: AppColors.secondaryCrimsonRed,
        surface: darkSurface,
        surfaceContainer: darkCard,
        brightness: Brightness.dark,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: darkCard,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryCrimsonRed,
            width: 2,
          ),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryCrimsonRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: darkBackground,

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: const Color(0xFF5A7BC0),
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}
