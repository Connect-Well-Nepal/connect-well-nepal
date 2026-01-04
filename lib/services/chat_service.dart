import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connect_well_nepal/models/chat_model.dart';

/// ChatService - Handles all chat-related Firebase operations
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _conversationsRef => 
      _firestore.collection('conversations');
  CollectionReference get _messagesRef => 
      _firestore.collection('messages');

  /// Create or get existing conversation between doctor and patient
  Future<ConversationModel> getOrCreateConversation({
    required String patientId,
    required String patientName,
    String? patientImage,
    required String doctorId,
    required String doctorName,
    String? doctorImage,
    String? doctorSpecialty,
  }) async {
    try {
      // Check if conversation already exists
      final existingQuery = await _conversationsRef
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: doctorId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return ConversationModel.fromFirestore(existingQuery.docs.first);
      }

      // Create new conversation
      final newConversation = ConversationModel(
        id: '',
        patientId: patientId,
        patientName: patientName,
        patientImage: patientImage,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorImage: doctorImage,
        doctorSpecialty: doctorSpecialty,
        createdAt: DateTime.now(),
      );

      final docRef = await _conversationsRef.add(newConversation.toFirestore());
      
      return ConversationModel(
        id: docRef.id,
        patientId: patientId,
        patientName: patientName,
        patientImage: patientImage,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorImage: doctorImage,
        doctorSpecialty: doctorSpecialty,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Get all conversations for a user (works for both doctors and patients)
  Stream<List<ConversationModel>> getConversations(String userId) {
    try {
      return _conversationsRef
          .where(Filter.or(
            Filter('patientId', isEqualTo: userId),
            Filter('doctorId', isEqualTo: userId),
          ))
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return ConversationModel.fromFirestore(doc);
                    } catch (e) {
                      debugPrint('Error parsing conversation ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<ConversationModel>()
                  .toList();
            } catch (e) {
              debugPrint('Error mapping conversations: $e');
              return <ConversationModel>[];
            }
          });
    } catch (e) {
      debugPrint('Error getting conversations stream: $e');
      return Stream.value(<ConversationModel>[]);
    }
  }

  /// Get messages for a conversation (real-time stream)
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        attachmentUrl: attachmentUrl,
        metadata: metadata,
      );

      // Add message
      final docRef = await _messagesRef.add(message.toFirestore());

      // Get conversation to update last message and increment unread count
      final conversationDoc = await _conversationsRef.doc(conversationId).get();
      if (conversationDoc.exists) {
        // Update conversation with last message and increment unread count for the other user
        await _conversationsRef.doc(conversationId).update({
          'lastMessage': content,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          // Increment unread count for the other participant
          'unreadCount': FieldValue.increment(1),
        });
      } else {
        // Fallback if conversation doesn't exist
        await _conversationsRef.doc(conversationId).update({
          'lastMessage': content,
          'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        });
      }

      return message.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String readerId) async {
    try {
      final unreadMessages = await _messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: readerId)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count for the reader
      final conversationDoc = await _conversationsRef.doc(conversationId).get();
      if (conversationDoc.exists) {
        await _conversationsRef.doc(conversationId).update({
          'unreadCount': 0,
        });
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messages = await _messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_conversationsRef.doc(conversationId));
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Send a prescription message
  Future<MessageModel> sendPrescription({
    required String conversationId,
    required String doctorId,
    required String doctorName,
    required String prescriptionDetails,
    String? attachmentUrl,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      senderId: doctorId,
      senderName: doctorName,
      content: '📋 Prescription: $prescriptionDetails',
      type: MessageType.prescription,
      attachmentUrl: attachmentUrl,
      metadata: {
        'prescriptionDetails': prescriptionDetails,
        'prescribedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send an appointment request/confirmation
  Future<MessageModel> sendAppointmentMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required DateTime appointmentTime,
    required String appointmentType,
    bool isConfirmation = false,
  }) async {
    final content = isConfirmation
        ? '✅ Appointment confirmed for ${_formatDateTime(appointmentTime)} ($appointmentType)'
        : '📅 Appointment request for ${_formatDateTime(appointmentTime)} ($appointmentType)';

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: MessageType.appointment,
      metadata: {
        'appointmentTime': appointmentTime.toIso8601String(),
        'appointmentType': appointmentType,
        'isConfirmation': isConfirmation,
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
