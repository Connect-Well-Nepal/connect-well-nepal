import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:connect_well_nepal/models/user_model.dart';
import 'package:connect_well_nepal/services/database_service.dart';

/// AuthService - Handles all Firebase Authentication operations
///
/// Features:
/// - Email/Password authentication
/// - Google Sign-In
/// - Phone OTP verification
/// - Password reset
/// - User session management
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final DatabaseService _dbService = DatabaseService();

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    // Doctor fields
    String? specialty,
    String? licenseNumber,
    String? qualification,
    int? yearsOfExperience,
    String? hospitalAffiliation,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create account');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Create user model
      final userModel = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        isEmailVerified: false,
        specialty: specialty,
        licenseNumber: licenseNumber,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        hospitalAffiliation: hospitalAffiliation,
      );

      // Save user to Firestore (with error handling)
      try {
        await _dbService.createUser(userModel);
        debugPrint('✅ User saved to Firestore successfully');
      } catch (e) {
        debugPrint('⚠️ Failed to save user to Firestore: $e');
        // Still return success - user is created in Auth, Firestore can be synced later
      }

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('SignUp error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Sign in failed');
      }

      // Fetch user data from Firestore (with timeout for faster response)
      UserModel? userModel;
      try {
        userModel = await _dbService.getUser(credential.user!.uid)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('⚠️ Firestore fetch timeout or error: $e');
        // Continue with basic user model
      }

      if (userModel != null) {
        // Update email verification status asynchronously (don't wait)
        if (credential.user!.emailVerified && !userModel.isEmailVerified) {
          _dbService.updateUser(
            credential.user!.uid,
            {'isEmailVerified': true},
          ).catchError((e) => debugPrint('Failed to update verification status: $e'));
        }
        return AuthResult.success(userModel);
      } else {
        // User exists in Auth but not in Firestore (create basic profile)
        final newUser = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'User',
          email: email,
          isEmailVerified: credential.user!.emailVerified,
        );
        // Create user asynchronously (don't wait)
        _dbService.createUser(newUser)
            .catchError((e) => debugPrint('Failed to create user in Firestore: $e'));
        return AuthResult.success(newUser);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('SignIn error: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google sign in cancelled');
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure('Google sign in failed');
      }

      // Check if user exists in Firestore
      final existingUser = await _dbService.getUser(userCredential.user!.uid);

      if (existingUser != null) {
        return AuthResult.success(existingUser);
      } else {
        // New Google user - needs role selection
        return AuthResult.needsRoleSelection(
          email: googleUser.email,
          name: googleUser.displayName ?? 'User',
          photoUrl: googleUser.photoUrl,
          uid: userCredential.user!.uid,
        );
      }
    } catch (e) {
      debugPrint('Google SignIn error: $e');
      return AuthResult.failure('Google sign in failed');
    }
  }

  /// Complete Google sign-in with role selection
  Future<AuthResult> completeGoogleSignIn({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? photoUrl,
    String? phone,
    String? specialty,
    String? licenseNumber,
    String? qualification,
    int? yearsOfExperience,
    String? hospitalAffiliation,
  }) async {
    try {
      final userModel = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: photoUrl,
        role: role,
        isEmailVerified: true, // Google accounts are verified
        specialty: specialty,
        licenseNumber: licenseNumber,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        hospitalAffiliation: hospitalAffiliation,
      );

      await _dbService.createUser(userModel);
      return AuthResult.success(userModel);
    } catch (e) {
      debugPrint('Complete Google SignIn error: $e');
      return AuthResult.failure('Failed to complete registration');
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      return false;
    }
  }

  /// Change user password
  /// Requires re-authentication for security
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return AuthResult.failure('No user logged in');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      
      debugPrint('✅ Password changed successfully');
      return AuthResult.success(await _dbService.getUser(user.uid) ?? UserModel(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email!,
        isEmailVerified: user.emailVerified,
      ));
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      debugPrint('Change password error: $e');
      return AuthResult.failure('Failed to change password. Please try again.');
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      return true;
    } catch (e) {
      debugPrint('Email verification error: $e');
      return false;
    }
  }

  /// Check if email is verified
  Future<bool> checkEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }

  /// Phone number verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserModel user) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            final user = await _dbService.getUser(userCredential.user!.uid);
            if (user != null) {
              onAutoVerified(user);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_getErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Phone verification failed');
    }
  }

  /// Verify phone OTP
  Future<AuthResult> verifyPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure('Verification failed');
      }

      final user = await _dbService.getUser(userCredential.user!.uid);
      if (user != null) {
        return AuthResult.success(user);
      }

      return AuthResult.needsRoleSelection(
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? 'User',
        uid: userCredential.user!.uid,
      );
    } catch (e) {
      return AuthResult.failure('Invalid verification code');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      final uid = currentUser?.uid;
      if (uid != null) {
        await _dbService.deleteUser(uid);
        await currentUser?.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Verification expired. Please try again';
      default:
        debugPrint('Unhandled Firebase Auth error code: $code');
        return 'An error occurred. Please try again';
    }
  }
}

/// Result class for auth operations
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;
  final bool needsRoleSelection;
  final String? pendingEmail;
  final String? pendingName;
  final String? pendingPhotoUrl;
  final String? pendingUid;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
    this.needsRoleSelection = false,
    this.pendingEmail,
    this.pendingName,
    this.pendingPhotoUrl,
    this.pendingUid,
  });

  factory AuthResult.success(UserModel user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }

  factory AuthResult.needsRoleSelection({
    required String email,
    required String name,
    String? photoUrl,
    required String uid,
  }) {
    return AuthResult._(
      success: true,
      needsRoleSelection: true,
      pendingEmail: email,
      pendingName: name,
      pendingPhotoUrl: photoUrl,
      pendingUid: uid,
    );
  }
}
