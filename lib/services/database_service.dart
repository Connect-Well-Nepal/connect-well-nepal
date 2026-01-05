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

  FirebaseFirestore? _db;

  /// Get Firestore instance (lazy initialization with error handling)
  FirebaseFirestore? get _firestore {
    if (_db == null) {
      try {
        _db = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase not initialized: $e');
        return null;
      }
    }
    return _db;
  }

  // Collection references (lazy-loaded with error handling)
  CollectionReference get _usersCollection {
    final db = _firestore;
    if (db == null) {
      throw Exception('Firebase not initialized');
    }
    return db.collection('users');
  }
  
  CollectionReference get _appointmentsCollection {
    final db = _firestore;
    if (db == null) {
      throw Exception('Firebase not initialized');
    }
    return db.collection('appointments');
  }
  
  CollectionReference get _consultationsCollection {
    final db = _firestore;
    if (db == null) {
      throw Exception('Firebase not initialized');
    }
    return db.collection('consultations');
  }
  
  CollectionReference get _reviewsCollection {
    final db = _firestore;
    if (db == null) {
      throw Exception('Firebase not initialized');
    }
    return db.collection('reviews');
  }
  
  /// Check if Firebase is available
  bool get isFirebaseAvailable {
    return _firestore != null;
  }

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
      if (!isFirebaseAvailable) {
        throw Exception('Firebase not initialized');
      }
      final db = _firestore!;
      await db.collection('verification_codes').doc(userId).set({
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
  /// Get a single doctor by ID
  Future<Map<String, dynamic>?> getDoctor(String doctorId) async {
    try {
      if (!isFirebaseAvailable) {
        debugPrint('Firebase not available, cannot get doctor');
        return null;
      }

      final doc = await _usersCollection.doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting doctor: $e');
      return null;
    }
  }

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
      // Check if Firebase is available
      if (!isFirebaseAvailable) {
        throw Exception('Firebase is not initialized. Cannot create appointment.');
      }

      // Normalize dateTime field (use appointmentTime if provided, otherwise dateTime)
      final dateTime = appointmentData['appointmentTime'] ?? appointmentData['dateTime'];
      if (dateTime == null) {
        throw Exception('Missing appointmentTime or dateTime in appointment data');
      }

      // Convert to Timestamp for proper Firestore querying
      DateTime dateTimeObj;
      if (dateTime is DateTime) {
        dateTimeObj = dateTime;
      } else if (dateTime is String) {
        dateTimeObj = DateTime.parse(dateTime);
      } else {
        throw Exception('Invalid dateTime format');
      }

      final docRef = await _appointmentsCollection.add({
        ...appointmentData,
        'id': '', // Will be set after creation
        'dateTime': Timestamp.fromDate(dateTimeObj), // Store as Timestamp for proper querying
        'appointmentTime': Timestamp.fromDate(dateTimeObj), // Also store as appointmentTime for backward compatibility
        'createdAt': FieldValue.serverTimestamp(),
        'status': appointmentData['status'] ?? 'pending',
      });
      
      // Update with the document ID
      await docRef.update({'id': docRef.id});
      
      debugPrint('✅ Appointment created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating appointment: $e');
      rethrow;
    }
  }

  /// Get appointments for a user (patient or doctor)
  Future<List<Map<String, dynamic>>> getUserAppointments(
    String userId, {
    bool isDoctor = false,
  }) async {
    try {
      // Don't query Firebase for guest users
      if (userId == 'guest' || userId.isEmpty) {
        debugPrint('Skipping Firebase query for guest user');
        return [];
      }

      // Check if Firebase is available
      if (!isFirebaseAvailable) {
        debugPrint('Firebase not available, returning empty list');
        return [];
      }

      final field = isDoctor ? 'doctorId' : 'patientId';
      
      debugPrint('🔍 Querying appointments for $field: $userId');
      
      Query query = _appointmentsCollection.where(field, isEqualTo: userId);
      
      // Try to order by dateTime, but handle case where index might not exist
      try {
        query = query.orderBy('dateTime', descending: false);
      } catch (e) {
        debugPrint('⚠️ Could not order by dateTime (index may be missing): $e');
        // Continue without ordering - we'll sort in memory
      }
      
      final querySnapshot = await query.get();
      
      debugPrint('✅ Found ${querySnapshot.docs.length} appointments');

      final results = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Ensure both dateTime and appointmentTime are set for compatibility
            final dateTime = data['dateTime'] ?? data['appointmentTime'];
            return {
              ...data,
              'id': doc.id, // Ensure id is set
              'dateTime': dateTime, // Normalize to dateTime
              'appointmentTime': dateTime, // Also set appointmentTime for backward compatibility
            };
          })
          .toList();
      
      // Sort in memory if we couldn't order by dateTime
      try {
        results.sort((a, b) {
          final aTime = a['dateTime'];
          final bTime = b['dateTime'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return aTime.compareTo(bTime);
          } else if (aTime is String && bTime is String) {
            return DateTime.parse(aTime).compareTo(DateTime.parse(bTime));
          }
          return 0;
        });
      } catch (e) {
        debugPrint('⚠️ Error sorting appointments: $e');
      }
      
      return results;
    } catch (e) {
      debugPrint('Error getting appointments: $e');
      // Return empty list instead of throwing
      return [];
    }
  }
  
  /// Get appointment stream for real-time updates
  Stream<List<Map<String, dynamic>>> getUserAppointmentsStream(
    String userId, {
    bool isDoctor = false,
  }) {
    try {
      // Don't query Firebase for guest users
      if (userId == 'guest' || userId.isEmpty) {
        debugPrint('Skipping Firebase stream for guest user');
        return Stream.value([]);
      }

      // Check if Firebase is available
      if (!isFirebaseAvailable) {
        debugPrint('Firebase not available, returning empty stream');
        return Stream.value([]);
      }

      final field = isDoctor ? 'doctorId' : 'patientId';
      return _appointmentsCollection
          .where(field, isEqualTo: userId)
          .orderBy('dateTime', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Ensure both dateTime and appointmentTime are set for compatibility
                final dateTime = data['dateTime'] ?? data['appointmentTime'];
                return {
                  ...data,
                  'id': doc.id,
                  'dateTime': dateTime, // Normalize to dateTime
                  'appointmentTime': dateTime, // Also set appointmentTime for backward compatibility
                };
              })
              .toList());
    } catch (e) {
      debugPrint('Error getting appointments stream: $e');
      return Stream.value([]);
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      rethrow;
    }
  }
  
  /// Reschedule appointment
  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDateTime,
  ) async {
    try {
      final dateTimeStr = newDateTime.toIso8601String();
      await _appointmentsCollection.doc(appointmentId).update({
        'dateTime': dateTimeStr, // Primary field
        'appointmentTime': dateTimeStr, // Backward compatibility
        'status': 'pending', // Reset to pending for doctor confirmation
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Appointment rescheduled: $appointmentId');
    } catch (e) {
      debugPrint('❌ Error rescheduling appointment: $e');
      rethrow;
    }
  }
  
  /// Add rating and review to appointment
  Future<void> addAppointmentRating(
    String appointmentId,
    double rating,
    String? review,
  ) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'rating': rating,
        'review': review,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update doctor's rating in reviews collection
      final appointmentDoc = await _appointmentsCollection.doc(appointmentId).get();
      if (appointmentDoc.exists) {
        final data = appointmentDoc.data() as Map<String, dynamic>;
        final doctorId = data['doctorId'];
        final patientId = data['patientId'];
        final patientName = data['patientName'] ?? 'Anonymous';
        
        if (doctorId != null) {
          await addReview(
            doctorId: doctorId,
            patientId: patientId,
            patientName: patientName,
            rating: rating,
            comment: review ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding appointment rating: $e');
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
        (total, review) => total + (review['rating'] as double),
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
