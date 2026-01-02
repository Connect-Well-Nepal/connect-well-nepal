import 'dart:math';
import 'package:flutter/material.dart';
import 'package:connect_well_nepal/models/user_model.dart';
import 'package:connect_well_nepal/services/auth_service.dart';
import 'package:connect_well_nepal/services/database_service.dart';

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
  // Auth service
  final AuthService _authService = AuthService();

  // User state
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Email verification
  String? _verificationCode;
  String? _pendingEmail;
  String? _pendingPassword;
  String? _pendingUid; // For Google Sign-In
  UserRole? _pendingRole;
  String? _pendingName;
  String? _pendingPhone;
  DateTime? _codeExpiry;
  bool _emailSentSuccessfully = false; // Track if email was sent
  String? _lastError; // Store last error message

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
  
  // Getter for email send status
  bool get emailSentSuccessfully => _emailSentSuccessfully;
  String? get lastError => _lastError;

  /// Send verification code to email
  /// 
  /// Optimized: Creates account, saves to Firestore, and sends verification email
  Future<bool> sendVerificationCode(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate 6-digit code for verification screen
      _verificationCode = _generateVerificationCode();
      _pendingEmail = email;
      _codeExpiry = DateTime.now().add(const Duration(minutes: 10));

      // Create Firebase account first (but don't complete signup yet)
      if (_pendingPassword == null) {
        debugPrint('❌ Password not set - cannot create Firebase account');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Try to create Firebase account with email/password
      // This also saves user to Firestore automatically
      var authResult = await _authService.signUpWithEmail(
        email: email,
        password: _pendingPassword!,
        name: _pendingName ?? 'User',
        role: _pendingRole ?? UserRole.patient,
        phone: _pendingPhone,
      );

      // If account already exists, tell user to use login screen
      if (!authResult.success && 
          (authResult.error?.contains('already exists') == true ||
           authResult.error?.contains('email-already-in-use') == true)) {
        _lastError = 'This email is already registered. Please use the login screen to sign in.';
        debugPrint('❌ Email already registered: $email');
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (!authResult.success) {
        _lastError = authResult.error ?? 'Failed to create account';
        debugPrint('❌ Failed to create Firebase account: ${authResult.error}');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send Firebase verification email (this is fast, don't wait for Firestore operations)
      _emailSentSuccessfully = await _authService.sendEmailVerification();
      
      if (_emailSentSuccessfully) {
        debugPrint('✅ Firebase verification email sent to $email');
      } else {
        debugPrint('⚠️ Failed to send Firebase verification email');
      }

      // Store verification code in Firestore asynchronously (don't wait)
      _storeVerificationCodeAsync(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error sending verification code: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Store verification code asynchronously (non-blocking)
  void _storeVerificationCodeAsync(String email) {
    Future.microtask(() async {
      try {
        final dbService = DatabaseService();
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null && _verificationCode != null && _codeExpiry != null) {
          await dbService.storeVerificationCode(
            userId: firebaseUser.uid,
            code: _verificationCode!,
            email: email,
            expiresAt: _codeExpiry!,
          );
          debugPrint('✅ Verification code stored in Firestore');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to store verification code: $e');
      }
    });
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
    _pendingPassword = password; // Store password for later
    _pendingRole = role;
    _pendingPhone = phone;

    return sendVerificationCode(email);
  }

  /// Complete sign up after verification (Step 2)
  /// 
  /// Note: Firebase account is already created in sendVerificationCode()
  /// Here we just verify the code and update user profile with doctor fields if needed
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

    if (_pendingEmail == null || 
        _pendingName == null || 
        _pendingRole == null) {
      debugPrint('❌ Missing pending data for signup');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Firebase account was already created in sendVerificationCode()
      // Get the current Firebase user
      final firebaseUser = _authService.currentUser;
      
      if (firebaseUser == null) {
        debugPrint('❌ No Firebase user found');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if we need to update user with doctor fields
      if ((_pendingRole == UserRole.doctor || _pendingRole == UserRole.careProvider) &&
          (specialty != null || licenseNumber != null)) {
        // Update user in Firestore with doctor fields
        final userModel = UserModel(
          id: firebaseUser.uid,
          name: _pendingName!,
          email: _pendingEmail!,
          phone: _pendingPhone,
          role: _pendingRole!,
          isEmailVerified: false, // Will be true after email verification
          specialty: specialty,
          licenseNumber: licenseNumber,
          qualification: qualification,
          yearsOfExperience: yearsOfExperience,
          hospitalAffiliation: hospitalAffiliation,
        );
        
        // Update user in Firestore
        final dbService = DatabaseService();
        await dbService.updateUser(firebaseUser.uid, {
          'specialty': specialty,
          'licenseNumber': licenseNumber,
          'qualification': qualification,
          'yearsOfExperience': yearsOfExperience,
          'hospitalAffiliation': hospitalAffiliation,
        });
        
        _currentUser = userModel;
      } else {
        // Fetch user from Firestore
        final dbService = DatabaseService();
        final userModel = await dbService.getUser(firebaseUser.uid);
        _currentUser = userModel;
      }

      _isLoggedIn = true;
      _clearPendingData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Complete signup error: $e');
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
      final authResult = await _authService.signInWithGoogle();

      if (!authResult.success) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': authResult.error ?? 'Google sign in failed'};
      }

      if (authResult.user != null) {
        // Existing user - sign them in
        _currentUser = authResult.user;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'needsRoleSelection': false,
        };
      }

      if (authResult.needsRoleSelection) {
        // New user - needs role selection
        _pendingEmail = authResult.pendingEmail;
        _pendingName = authResult.pendingName;
        _pendingUid = authResult.pendingUid;
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'needsRoleSelection': true,
          'email': authResult.pendingEmail,
          'name': authResult.pendingName,
          'photoUrl': authResult.pendingPhotoUrl,
          'uid': authResult.pendingUid,
        };
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Unexpected error'};
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

    // Get UID from pending data or current Firebase user
    String? uid = _pendingUid;
    if (uid == null) {
      final currentFirebaseUser = _authService.currentUser;
      if (currentFirebaseUser == null) {
        debugPrint('❌ No Firebase user found and no pending UID');
        return false;
      }
      uid = currentFirebaseUser.uid;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final authResult = await _authService.completeGoogleSignIn(
        uid: uid,
        name: _pendingName!,
        email: _pendingEmail!,
        role: role,
        photoUrl: null, // Will be set from Firebase user
        phone: phone,
        specialty: specialty,
        licenseNumber: licenseNumber,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        hospitalAffiliation: hospitalAffiliation,
      );

      if (authResult.success && authResult.user != null) {
        _currentUser = authResult.user;
        _isLoggedIn = true;
        _clearPendingData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Complete Google signin failed: ${authResult.error}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Complete Google signin error: $e');
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
      final authResult = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (authResult.success && authResult.user != null) {
        _currentUser = authResult.user;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Login failed: ${authResult.error}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with Google (for existing users)
  Future<bool> loginWithGoogle() async {
    final result = await signInWithGoogle();
    return result['success'] == true && result['needsRoleSelection'] != true;
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

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
    _pendingPassword = null;
    _pendingUid = null;
    _pendingRole = null;
    _pendingName = null;
    _pendingPhone = null;
    _codeExpiry = null;
    _emailSentSuccessfully = false;
    _lastError = null;
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

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.sendPasswordResetEmail(email);
      
      if (success) {
        debugPrint('✅ Password reset email sent to $email');
        _lastError = null; // Clear any previous errors
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Failed to send password reset email. Please check if the email is registered.';
        debugPrint('❌ Failed to send password reset email');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'An error occurred. Please try again later.';
      debugPrint('❌ Error sending password reset email: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResult = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (authResult.success) {
        debugPrint('✅ Password changed successfully');
        _lastError = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _lastError = authResult.error ?? 'Failed to change password';
        debugPrint('❌ Failed to change password: ${authResult.error}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'An error occurred. Please try again.';
      debugPrint('❌ Error changing password: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
