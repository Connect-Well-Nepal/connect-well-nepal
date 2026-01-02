import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connect_well_nepal/models/user_model.dart';

/// DatabaseService - Handles all Firestore database operations
///
/// Collections:
/// - users: User profiles (patients, doctors, care providers)
/// - appointments: Appointment records
/// - consultations: Consultation history
/// - reviews: Doctor reviews and ratings
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _appointmentsCollection => _db.collection('appointments');
  CollectionReference get _consultationsCollection => _db.collection('consultations');
  CollectionReference get _reviewsCollection => _db.collection('reviews');

  // ============== USER OPERATIONS ==============

  /// Create a new user document
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
      debugPrint('✅ User created in Firestore: ${user.id} (${user.email})');
      debugPrint('   Role: ${user.role}, Verified: ${user.isEmailVerified}');
    } catch (e) {
      debugPrint('❌ Error creating user in Firestore: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user document
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
      debugPrint('User updated: $userId');
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user document
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      debugPrint('User deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Store verification code for OTP email sending (via Cloud Function)
  Future<void> storeVerificationCode({
    required String userId,
    required String code,
    required String email,
    required DateTime expiresAt,
  }) async {
    try {
      await _db.collection('verification_codes').doc(userId).set({
        'code': code,
        'email': email,
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Verification code stored for: $email');
    } catch (e) {
      debugPrint('Error storing verification code: $e');
      rethrow;
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // ============== DOCTOR OPERATIONS ==============

  /// Get all verified doctors
  Future<List<UserModel>> getVerifiedDoctors() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('isVerifiedDoctor', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctors: $e');
      return [];
    }
  }

  /// Get doctors by specialty
  Future<List<UserModel>> getDoctorsBySpecialty(String specialty) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('isVerifiedDoctor', isEqualTo: true)
          .where('specialty', isEqualTo: specialty)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');
      return [];
    }
  }

  /// Get pending doctor verifications (for admin)
  Future<List<UserModel>> getPendingDoctorVerifications() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', whereIn: ['doctor', 'careProvider'])
          .where('isVerifiedDoctor', isEqualTo: false)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending verifications: $e');
      return [];
    }
  }

  /// Verify a doctor (admin action)
  Future<void> verifyDoctor(String doctorId) async {
    try {
      await _usersCollection.doc(doctorId).update({
        'isVerifiedDoctor': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Doctor verified: $doctorId');
    } catch (e) {
      debugPrint('Error verifying doctor: $e');
      rethrow;
    }
  }

  // ============== APPOINTMENT OPERATIONS ==============

  /// Create appointment
  Future<String> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final docRef = await _appointmentsCollection.add({
        ...appointmentData,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      debugPrint('Appointment created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      rethrow;
    }
  }

  /// Get appointments for a user (patient or doctor)
  Future<List<Map<String, dynamic>>> getUserAppointments(
    String userId, {
    bool isDoctor = false,
  }) async {
    try {
      final field = isDoctor ? 'doctorId' : 'patientId';
      final querySnapshot = await _appointmentsCollection
          .where(field, isEqualTo: userId)
          .orderBy('appointmentTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('Error getting appointments: $e');
      return [];
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Appointment updated: $appointmentId -> $status');
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // ============== CONSULTATION OPERATIONS ==============

  /// Save consultation record
  Future<String> saveConsultation(Map<String, dynamic> consultationData) async {
    try {
      final docRef = await _consultationsCollection.add({
        ...consultationData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving consultation: $e');
      rethrow;
    }
  }

  /// Get consultation history
  Future<List<Map<String, dynamic>>> getConsultationHistory(
    String userId, {
    bool isDoctor = false,
  }) async {
    try {
      final field = isDoctor ? 'doctorId' : 'patientId';
      final querySnapshot = await _consultationsCollection
          .where(field, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('Error getting consultations: $e');
      return [];
    }
  }

  // ============== REVIEW OPERATIONS ==============

  /// Add a review for a doctor
  Future<void> addReview({
    required String doctorId,
    required String patientId,
    required String patientName,
    required double rating,
    required String comment,
  }) async {
    try {
      await _reviewsCollection.add({
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update doctor's average rating
      await _updateDoctorRating(doctorId);
    } catch (e) {
      debugPrint('Error adding review: $e');
      rethrow;
    }
  }

  /// Get reviews for a doctor
  Future<List<Map<String, dynamic>>> getDoctorReviews(String doctorId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      return [];
    }
  }

  /// Update doctor's average rating
  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final reviews = await getDoctorReviews(doctorId);
      if (reviews.isEmpty) return;

      final totalRating = reviews.fold<double>(
        0,
        (sum, review) => sum + (review['rating'] as double),
      );
      final averageRating = totalRating / reviews.length;

      await _usersCollection.doc(doctorId).update({
        'rating': averageRating,
        'totalReviews': reviews.length,
      });
    } catch (e) {
      debugPrint('Error updating doctor rating: $e');
    }
  }

  // ============== SEARCH OPERATIONS ==============

  /// Search doctors by name
  Future<List<UserModel>> searchDoctors(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // For production, consider using Algolia or similar
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('isVerifiedDoctor', isEqualTo: true)
          .get();

      final allDoctors = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Client-side filtering
      return allDoctors
          .where((doctor) =>
              doctor.name.toLowerCase().contains(query.toLowerCase()) ||
              (doctor.specialty?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    } catch (e) {
      debugPrint('Error searching doctors: $e');
      return [];
    }
  }
}
