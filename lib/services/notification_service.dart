import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService - Handles Firebase Cloud Messaging (FCM)
///
/// Features:
/// - Push notification setup
/// - Topic subscriptions
/// - Token management
/// - Notification handling
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Storage keys
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Topic names
  static const String topicAllUsers = 'all_users';
  static const String topicPatients = 'patients';
  static const String topicDoctors = 'doctors';
  static const String topicHealthTips = 'health_tips';
  static const String topicEmergency = 'emergency';

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get and save FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background/terminated messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

        // Handle notification tap when app is opened from terminated state
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        debugPrint('Notification service initialized');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Get and save FCM token
  Future<String?> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      debugPrint('FCM token saved: ${token.substring(0, 20)}...');

      // TODO: Also save token to Firestore for the current user
      // This allows sending targeted notifications
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get stored FCM token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe user based on role
  Future<void> subscribeUserTopics({
    required bool isDoctor,
    bool healthTips = true,
    bool emergency = true,
  }) async {
    // Subscribe to common topics
    await subscribeToTopic(topicAllUsers);

    // Role-specific topics
    if (isDoctor) {
      await subscribeToTopic(topicDoctors);
      await unsubscribeFromTopic(topicPatients);
    } else {
      await subscribeToTopic(topicPatients);
      await unsubscribeFromTopic(topicDoctors);
    }

    // Optional topics
    if (healthTips) {
      await subscribeToTopic(topicHealthTips);
    } else {
      await unsubscribeFromTopic(topicHealthTips);
    }

    if (emergency) {
      await subscribeToTopic(topicEmergency);
    } else {
      await unsubscribeFromTopic(topicEmergency);
    }
  }

  /// Unsubscribe from all topics (on logout)
  Future<void> unsubscribeAll() async {
    await unsubscribeFromTopic(topicAllUsers);
    await unsubscribeFromTopic(topicPatients);
    await unsubscribeFromTopic(topicDoctors);
    await unsubscribeFromTopic(topicHealthTips);
    await unsubscribeFromTopic(topicEmergency);
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // TODO: Show local notification or in-app notification
    // You can use flutter_local_notifications package for this
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Handle navigation based on notification data
    final type = message.data['type'];
    final id = message.data['id'];

    switch (type) {
      case 'appointment':
        // Navigate to appointment details
        debugPrint('Navigate to appointment: $id');
        break;
      case 'consultation':
        // Navigate to consultation
        debugPrint('Navigate to consultation: $id');
        break;
      case 'message':
        // Navigate to chat
        debugPrint('Navigate to chat: $id');
        break;
      default:
        // Navigate to home
        debugPrint('Navigate to home');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsEnabledKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, enabled);

      if (!enabled) {
        await unsubscribeAll();
      }
    } catch (e) {
      debugPrint('Error setting notifications: $e');
    }
  }

  /// Delete FCM token (on logout/account deletion)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
  // Handle background message if needed
}
