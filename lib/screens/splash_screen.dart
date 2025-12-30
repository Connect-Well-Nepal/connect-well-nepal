import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/screens/auth_screen.dart';
import 'package:connect_well_nepal/screens/main_screen.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';

/// SplashScreen - Initial loading screen with logo
/// 
/// Displays the Connect Well Nepal logo and branding
/// Auto-navigates to AuthScreen or MainScreen based on login status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Navigate to appropriate screen after delay
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final appProvider = context.read<AppProvider>();

      // Check if user is already logged in
      if (appProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0D1B2A),
                    const Color(0xFF1B263B),
                  ]
                : [
                    AppColors.backgroundWhite,
                    AppColors.backgroundOffWhite,
                  ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Connect Well Nepal Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryNavyBlue
                                  .withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
              'assets/logos/logo.png',
                          width: 150,
                          height: 150,
                        ),
            ),
            
                      const SizedBox(height: 32),
            
            // App Name
                      Text(
              'Connect Well',
              style: TextStyle(
                          fontSize: 36,
                fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.primaryNavyBlue,
                          letterSpacing: 1.2,
              ),
            ),
            
            const Text(
              'Nepal',
              style: TextStyle(
                          fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryCrimsonRed,
                          letterSpacing: 1.2,
              ),
            ),
            
                      const SizedBox(height: 12),
            
                      Text(
                        'Your Health, Our Priority',
              style: TextStyle(
                fontSize: 16,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                          letterSpacing: 0.5,
              ),
            ),
            
                      const SizedBox(height: 60),
            
            // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryCrimsonRed,
                          strokeWidth: 3,
                          backgroundColor: isDark
                              ? Colors.white12
                              : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                        ),
            ),
          ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
