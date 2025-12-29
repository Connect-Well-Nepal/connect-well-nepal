import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/models/user_model.dart';
import 'package:connect_well_nepal/screens/verification_screen.dart';
import 'package:connect_well_nepal/screens/doctor_registration_screen.dart';
import 'package:connect_well_nepal/screens/main_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// AuthScreen - Login and Signup screen
///
/// Features:
/// - Role selection (Patient/Doctor/Care Provider)
/// - Toggle between Login and Signup modes
/// - Google Sign-In
/// - Email verification for signup
/// - Guest access option
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.patient;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final appProvider = context.read<AppProvider>();

    if (_isLogin) {
      // Login flow
      final success = await appProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else if (mounted) {
        _showErrorSnackBar('Login failed. Please check your credentials.');
      }
    } else {
      // Signup flow - initiate verification
      final success = await appProvider.initiateSignUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (mounted && success) {
        // Navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              email: _emailController.text.trim(),
              role: _selectedRole,
            ),
          ),
        );
      } else if (mounted) {
        _showErrorSnackBar('Failed to send verification code. Please try again.');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final appProvider = context.read<AppProvider>();
    final result = await appProvider.signInWithGoogle();

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['needsRoleSelection'] == true) {
        // Show role selection dialog for new users
        _showRoleSelectionDialog(
          email: result['email'],
          name: result['name'],
          photoUrl: result['photoUrl'],
        );
      } else {
        // Existing user, go to main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      _showErrorSnackBar(result['error'] ?? 'Google Sign-In failed');
    }
  }

  void _showRoleSelectionDialog({
    required String email,
    String? name,
    String? photoUrl,
  }) {
    UserRole selectedRole = UserRole.patient;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Welcome!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'I am a...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Role options
                  _buildRoleOptionTile(
                    role: UserRole.patient,
                    selectedRole: selectedRole,
                    icon: Icons.person,
                    title: 'Patient',
                    subtitle: 'Looking for healthcare services',
                    onTap: () {
                      setModalState(() {
                        selectedRole = UserRole.patient;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildRoleOptionTile(
                    role: UserRole.doctor,
                    selectedRole: selectedRole,
                    icon: Icons.medical_services,
                    title: 'Doctor',
                    subtitle: 'Licensed medical practitioner',
                    onTap: () {
                      setModalState(() {
                        selectedRole = UserRole.doctor;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildRoleOptionTile(
                    role: UserRole.careProvider,
                    selectedRole: selectedRole,
                    icon: Icons.health_and_safety,
                    title: 'Care Provider',
                    subtitle: 'Nurse, therapist, or other healthcare worker',
                    onTap: () {
                      setModalState(() {
                        selectedRole = UserRole.careProvider;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Capture references before popping dialog
                        final navigator = Navigator.of(this.context);
                        final appProvider = this.context.read<AppProvider>();
                        final role = selectedRole;
                        
                        Navigator.pop(context);

                        if (role == UserRole.patient) {
                          // Direct registration for patients
                          final success = await appProvider.completeGoogleSignIn(role: role);

                          if (mounted && success) {
                            navigator.pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                            );
                          }
                        } else {
                          // Doctor/Care Provider needs additional info
                          await appProvider.sendVerificationCode(email);

                          if (mounted) {
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => DoctorRegistrationScreen(
                                  verificationCode: '', // Google users skip code
                                  role: role,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryCrimsonRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleOptionTile({
    required UserRole role,
    required UserRole selectedRole,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = role == selectedRole;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryCrimsonRed.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.backgroundOffWhite),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryCrimsonRed
                : (isDark ? Colors.white12 : AppColors.dividerGray),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryCrimsonRed.withValues(alpha: 0.2)
                    : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.secondaryCrimsonRed
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.secondaryCrimsonRed,
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondaryCrimsonRed,
      ),
    );
  }

  void _continueAsGuest() {
    context.read<AppProvider>().continueAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0D1B2A),
                    const Color(0xFF1B263B),
                    const Color(0xFF415A77),
                  ]
                : [
                    AppColors.primaryNavyBlue,
                    const Color(0xFF2A4A7F),
                    const Color(0xFF3D5A9E),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Logo and App Name
                _buildHeader(),

                const SizedBox(height: 30),

                // Form Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            _isLogin ? 'Welcome Back!' : 'Create Account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.primaryNavyBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLogin
                                ? 'Sign in to continue your health journey'
                                : 'Join Connect Well Nepal today',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Role Selection (Signup only)
                          if (!_isLogin) ...[
                            Text(
                              'I am a...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRoleSelector(),
                            const SizedBox(height: 20),
                          ],

                          // Name field (Signup only)
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Phone field (Signup only)
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone (Optional)',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Password field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Confirm Password (Signup only)
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],

                          // Forgot Password (Login only)
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Password reset feature coming soon!'),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.secondaryCrimsonRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Submit Button
                          Consumer<AppProvider>(
                            builder: (context, provider, child) {
                              return ElevatedButton(
                                onPressed:
                                    provider.isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryCrimsonRed,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: provider.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'Sign In'
                                            : 'Create Account',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark ? Colors.white24 : AppColors.dividerGray,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark ? Colors.white24 : AppColors.dividerGray,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Google Sign-In Button
                          OutlinedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.g_mobiledata, size: 24);
                              },
                            ),
                            label: Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : AppColors.dividerGray,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Toggle Login/Signup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? "Don't have an account? "
                                    : 'Already have an account? ',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleMode,
                                child: Text(
                                  _isLogin ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(
                                    color: AppColors.secondaryCrimsonRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Continue as Guest
                TextButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/logos/logo_icon.png',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connect Well Nepal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your Health, Our Priority',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleChip(
            role: UserRole.patient,
            icon: Icons.person,
            label: 'Patient',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleChip(
            role: UserRole.doctor,
            icon: Icons.medical_services,
            label: 'Doctor',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleChip(
            role: UserRole.careProvider,
            icon: Icons.health_and_safety,
            label: 'Care\nProvider',
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryCrimsonRed.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.backgroundOffWhite),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryCrimsonRed
                : (isDark ? Colors.white12 : AppColors.dividerGray),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.secondaryCrimsonRed
                  : (isDark ? Colors.white54 : AppColors.textSecondary),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.secondaryCrimsonRed
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.backgroundOffWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : AppColors.dividerGray,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.secondaryCrimsonRed,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.secondaryCrimsonRed,
          ),
        ),
      ),
    );
  }
}
