import 'package:flutter/material.dart';
import 'package:connect_well_nepal/screens/splash_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// Entry point of the Connect Well Nepal application
/// 
/// This file initializes the app:
/// - Material Design 3 theming
/// - Custom color scheme
/// - Global app configuration
void main() {
  runApp(const ConnectWellNepalApp());
}

/// Root widget of the application
class ConnectWellNepalApp extends StatelessWidget {
  const ConnectWellNepalApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // metadata
      title: 'Connect Well Nepal',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration using Material 3
      theme: ThemeData(
        // Enable Material Design 3
        useMaterial3: true,
        
        // Color scheme based on AppColors
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavyBlue,
          primary: AppColors.primaryNavyBlue,
          secondary: AppColors.secondaryCrimsonRed,
          surface: AppColors.backgroundWhite,
          surfaceContainer: AppColors.backgroundOffWhite,
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
      ),
      
      // Set SplashScreen as the home screen (will navigate to MainScreen)
      home: const SplashScreen(),
    );
  }
}
