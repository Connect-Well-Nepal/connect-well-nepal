import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connect_well_nepal/models/user_model.dart';

/// AppProvider - Central state management for Connect Well Nepal
///
/// Manages:
/// - User authentication state
/// - User roles (patient/doctor)
/// - Email verification
/// - Google Sign-In
/// - Theme mode (dark/light)
/// - App settings
class AppProvider extends ChangeNotifier {
  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // User state
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Email verification
  String? _verificationCode;
  String? _pendingEmail;
  UserRole? _pendingRole;
  String? _pendingName;
  String? _pendingPhone;
  DateTime? _codeExpiry;

  // Theme state
  ThemeMode _themeMode = ThemeMode.light;

  // Settings
  bool _notificationsEnabled = true;
  String _language = 'English';

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  String? get pendingEmail => _pendingEmail;

  // Role-based getters
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isCareProvider => _currentUser?.isCareProvider ?? false;
  bool get isHealthcareProfessional =>
      _currentUser?.isHealthcareProfessional ?? false;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get isEmailVerified => _currentUser?.isEmailVerified ?? false;

  /// Get user's display name or default
  String get displayName {
    if (_currentUser != null) {
      return _currentUser!.firstName;
    }
    return 'Guest';
  }

  /// Get user's full name or default
  String get fullName {
    if (_currentUser != null) {
      return _currentUser!.name;
    }
    return 'Guest User';
  }

  /// Generate a 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Getter for verification code (for testing/demo only - remove in production)
  String? get testVerificationCode => _verificationCode;

  /// Send verification code to email
  Future<bool> sendVerificationCode(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate code
      _verificationCode = _generateVerificationCode();
      _pendingEmail = email;
      _codeExpiry = DateTime.now().add(const Duration(minutes: 10));

      // TODO: Integrate with actual email service (Firebase, SendGrid, etc.)
      // For now, we'll simulate sending and show the code in debug
      await Future.delayed(const Duration(seconds: 1));

      debugPrint('🔐 Verification code for $email: $_verificationCode');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending verification code: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify the code entered by user
  bool verifyCode(String code) {
    if (_verificationCode == null || _codeExpiry == null) {
      return false;
    }

    if (DateTime.now().isAfter(_codeExpiry!)) {
      // Code expired
      _verificationCode = null;
      return false;
    }

    return code == _verificationCode;
  }

  /// Resend verification code
  Future<bool> resendVerificationCode() async {
    if (_pendingEmail == null) return false;
    return sendVerificationCode(_pendingEmail!);
  }

  /// Sign up a new user (Step 1: Send verification)
  Future<bool> initiateSignUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    _pendingName = name;
    _pendingEmail = email;
    _pendingRole = role;
    _pendingPhone = phone;

    return sendVerificationCode(email);
  }

  /// Complete sign up after verification (Step 2)
  Future<bool> completeSignUp({
    required String verificationCode,
    // Doctor-specific fields
    String? specialty,
    String? licenseNumber,
    String? qualification,
    int? yearsOfExperience,
    String? hospitalAffiliation,
  }) async {
    if (!verifyCode(verificationCode)) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Integrate with Firebase Auth
      await Future.delayed(const Duration(seconds: 1));

      // Create new user based on role
      _currentUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _pendingName!,
        email: _pendingEmail!,
        phone: _pendingPhone,
        role: _pendingRole!,
        isEmailVerified: true,
        specialty: specialty,
        licenseNumber: licenseNumber,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        hospitalAffiliation: hospitalAffiliation,
      );

      _isLoggedIn = true;

      // Clear pending data
      _clearPendingData();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Sign in cancelled'};
      }

      // Get user details
      _pendingEmail = googleUser.email;
      _pendingName = googleUser.displayName ?? 'User';

      _isLoading = false;
      notifyListeners();

      // Return success with need for role selection
      return {
        'success': true,
        'needsRoleSelection': true,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      };
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Complete Google Sign-In with role selection
  Future<bool> completeGoogleSignIn({
    required UserRole role,
    String? phone,
    // Doctor fields
    String? specialty,
    String? licenseNumber,
    String? qualification,
    int? yearsOfExperience,
    String? hospitalAffiliation,
  }) async {
    if (_pendingEmail == null || _pendingName == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Integrate with Firebase Auth
      await Future.delayed(const Duration(seconds: 1));

      final googleUser = _googleSignIn.currentUser;

      _currentUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _pendingName!,
        email: _pendingEmail!,
        phone: phone,
        profileImageUrl: googleUser?.photoUrl,
        role: role,
        isEmailVerified: true, // Google accounts are pre-verified
        specialty: specialty,
        licenseNumber: licenseNumber,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        hospitalAffiliation: hospitalAffiliation,
      );

      _isLoggedIn = true;
      _clearPendingData();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Integrate with Firebase Auth
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, create a user
      _currentUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'User',
        email: email,
        role: UserRole.patient, // Default role, would be fetched from DB
        isEmailVerified: true,
      );
      _isLoggedIn = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Google (for existing users)
  Future<bool> loginWithGoogle() async {
    final result = await signInWithGoogle();

    if (result['success'] == true) {
      // For existing users, we'd fetch their role from the database
      // For now, assume they need to select if not found
      return result['needsRoleSelection'] != true;
    }
    return false;
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }

    // TODO: Firebase signOut
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    _isLoggedIn = false;
    _clearPendingData();
    _isLoading = false;
    notifyListeners();
  }

  /// Clear pending signup data
  void _clearPendingData() {
    _verificationCode = null;
    _pendingEmail = null;
    _pendingRole = null;
    _pendingName = null;
    _pendingPhone = null;
    _codeExpiry = null;
  }

  /// Update user profile
  void updateUserProfile({
    String? name,
    String? phone,
    String? medicalHistory,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? allergies,
    String? emergencyContact,
    // Doctor fields
    String? specialty,
    String? qualification,
    String? hospitalAffiliation,
    String? bio,
    double? consultationFee,
    List<String>? availableDays,
    String? availableTimeStart,
    String? availableTimeEnd,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        medicalHistory: medicalHistory,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodType: bloodType,
        allergies: allergies,
        emergencyContact: emergencyContact,
        specialty: specialty,
        qualification: qualification,
        hospitalAffiliation: hospitalAffiliation,
        bio: bio,
        consultationFee: consultationFee,
        availableDays: availableDays,
        availableTimeStart: availableTimeStart,
        availableTimeEnd: availableTimeEnd,
      );
      notifyListeners();
    }
  }

  /// Update profile image
  Future<void> updateProfileImage(String imagePath) async {
    if (_currentUser == null) return;

    // TODO: Upload to Firebase Storage and get download URL
    // For now, use the local file path (works for demo)
    // In production, upload to Firebase Storage:
    // final storageService = StorageService();
    // final downloadUrl = await storageService.uploadProfileImage(
    //   userId: _currentUser!.id,
    //   imageFile: File(imagePath),
    // );
    
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo, use a file:// URL (in production, use Firebase Storage URL)
    _currentUser = _currentUser!.copyWith(
      profileImageUrl: 'file://$imagePath',
    );
    notifyListeners();
  }

  /// Toggle dark mode
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggle notifications
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  /// Set language
  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  /// Continue as guest
  void continueAsGuest() {
    _currentUser = UserModel(
      id: 'guest',
      name: 'Guest User',
      email: 'guest@connectwell.np',
      role: UserRole.guest,
    );
    _isLoggedIn = true;
    notifyListeners();
  }
}
