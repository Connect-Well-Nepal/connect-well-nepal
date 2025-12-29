import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// StorageService - Handles Firebase Storage operations
///
/// Features:
/// - Profile image upload
/// - Medical document upload
/// - Prescription upload
/// - File download URLs
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Storage paths
  static const String _profileImagesPath = 'profile_images';
  static const String _medicalDocumentsPath = 'medical_documents';
  static const String _prescriptionsPath = 'prescriptions';
  static const String _chatAttachmentsPath = 'chat_attachments';

  /// Upload profile image
  Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$_profileImagesPath/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Profile image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  /// Upload medical document
  Future<String?> uploadMedicalDocument({
    required String userId,
    required File file,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$_medicalDocumentsPath/$userId/${timestamp}_$fileName';
      final ref = _storage.ref().child(storagePath);

      // Determine content type
      final contentType = _getContentType(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Medical document uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading medical document: $e');
      return null;
    }
  }

  /// Upload prescription
  Future<String?> uploadPrescription({
    required String doctorId,
    required String patientId,
    required String appointmentId,
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'prescription_${appointmentId}_$timestamp.pdf';
      final storagePath = '$_prescriptionsPath/$patientId/$fileName';
      final ref = _storage.ref().child(storagePath);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'doctorId': doctorId,
            'patientId': patientId,
            'appointmentId': appointmentId,
          },
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Prescription uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading prescription: $e');
      return null;
    }
  }

  /// Upload chat attachment (image/file)
  Future<String?> uploadChatAttachment({
    required String chatId,
    required String senderId,
    required File file,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$_chatAttachmentsPath/$chatId/${timestamp}_$fileName';
      final ref = _storage.ref().child(storagePath);

      final contentType = _getContentType(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'senderId': senderId},
        ),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading chat attachment: $e');
      return null;
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted: $fileUrl');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Get all medical documents for a user
  Future<List<Map<String, dynamic>>> getUserMedicalDocuments(String userId) async {
    try {
      final ref = _storage.ref().child('$_medicalDocumentsPath/$userId');
      final result = await ref.listAll();

      final documents = <Map<String, dynamic>>[];
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        final downloadUrl = await item.getDownloadURL();
        documents.add({
          'name': item.name,
          'url': downloadUrl,
          'size': metadata.size,
          'contentType': metadata.contentType,
          'createdAt': metadata.timeCreated,
        });
      }

      return documents;
    } catch (e) {
      debugPrint('Error getting medical documents: $e');
      return [];
    }
  }

  /// Get all prescriptions for a patient
  Future<List<Map<String, dynamic>>> getPatientPrescriptions(String patientId) async {
    try {
      final ref = _storage.ref().child('$_prescriptionsPath/$patientId');
      final result = await ref.listAll();

      final prescriptions = <Map<String, dynamic>>[];
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        final downloadUrl = await item.getDownloadURL();
        prescriptions.add({
          'name': item.name,
          'url': downloadUrl,
          'size': metadata.size,
          'doctorId': metadata.customMetadata?['doctorId'],
          'appointmentId': metadata.customMetadata?['appointmentId'],
          'createdAt': metadata.timeCreated,
        });
      }

      return prescriptions;
    } catch (e) {
      debugPrint('Error getting prescriptions: $e');
      return [];
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
