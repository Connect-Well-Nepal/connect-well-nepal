import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AgoraTokenService - Handles token generation for Agora RTC
///
/// For Production:
/// - Tokens should be generated on your backend server (RECOMMENDED)
/// - Never expose App Certificate in client code
/// - Tokens expire after 24 hours (configurable)
///
/// For Development:
/// - Can use temporary tokens from Agora Console
/// - Or disable token authentication in console
class AgoraTokenService {
  
  // Agora App ID
  static const String appId = "0f3b01a62b1e4644b1ae017327c3be69";
  
  // App Certificate (ONLY use this for client-side generation in development)
  // In production, this should be stored on your backend server
  // TODO: Remove this and use backend token generation in production
  static const String appCertificate = "ab688d5698be422988659ecc8973f8f1"; // Add your App Certificate here if needed
  
  // Backend token server URL (for production)
  // Set this to your backend endpoint that generates tokens
  static const String? tokenServerUrl = null; // e.g., "https://your-api.com/agora/token"
  
  // Temporary token for testing (from Agora Console)
  // IMPORTANT: Temp tokens are tied to a specific channel name!
  // When generating a temp token in Agora Console, use the EXACT channel name your app will use
  // Or set this to null/empty and disable token authentication in Agora Console for development
  // Replace with your temp token from Agora Console > Security > Generate Temp Token
  // Set to null or empty string to use token-less mode
  static const String? testToken = null; // Set your token here or use null for token-less mode
  
  // Force token-less mode (set to true if token authentication is disabled in Agora Console)
  // This will always return empty token regardless of other settings
  static const bool forceTokenLessMode = false; // Set to true for development without tokens
  
  // Enable client-side token generation (DEVELOPMENT ONLY)
  // Set to true to generate tokens using App Certificate
  static const bool enableClientSideTokenGeneration = true;
  
  /// Generate or fetch a token for joining a channel
  /// 
  /// In production, this should call your backend server to generate tokens
  /// Backend should use your App Certificate to sign tokens securely
  /// 
  /// Parameters:
  /// - channelId: The channel name to join
  /// - uid: User ID (0 for auto-assign)
  /// - role: Publisher or Subscriber (default: Publisher)
  /// - expireTime: Token expiration in seconds (default: 24 hours)
  /// 
  /// Returns: Token string, or empty string for token-less mode
  static Future<String> getToken({
    required String channelId,
    int uid = 0,
    int role = 1, // 1 = Publisher, 2 = Subscriber
    int expireTime = 86400, // 24 hours in seconds
  }) async {
    // Force token-less mode (if token authentication is disabled in Agora Console)
    if (forceTokenLessMode) {
      debugPrint('ℹ️ Token-less mode enabled. Using empty token.');
      debugPrint('   Channel: $channelId, UID: $uid');
      debugPrint('   Ensure token authentication is DISABLED in Agora Console.');
      return '';
    }
    
    // If token server is configured, fetch from backend (PRODUCTION)
    if (tokenServerUrl != null && tokenServerUrl!.isNotEmpty) {
      return await _fetchTokenFromServer(
        channelId: channelId,
        uid: uid,
        role: role,
        expireTime: expireTime,
      );
    }
    
    // If test token is configured, use it for testing
    // WARNING: Temp tokens are tied to a specific channel name!
    // For dynamic channel names (like appointment-based), use client-side generation instead
    if (testToken != null && testToken!.isNotEmpty) {
      debugPrint('⚠️ Test token configured, but channel names are dynamic.');
      debugPrint('   Channel: $channelId, UID: $uid');
      debugPrint('   ⚠️ Temp tokens are tied to a specific channel name.');
      debugPrint('   ⚠️ Since your channel name is dynamic, falling back to client-side token generation.');
      debugPrint('   💡 To use testToken: Generate it for a fixed channel name, or use client-side generation.');
      // Fall through to client-side generation for dynamic channels
    }
    
    // If App Certificate is set and client-side generation is enabled, generate token
    if (appCertificate.isNotEmpty && enableClientSideTokenGeneration) {
      debugPrint('⚠️ Generating token client-side using App Certificate.');
      debugPrint('   Channel: $channelId, UID: $uid, Role: ${role == 1 ? "Publisher" : "Subscriber"}');
      debugPrint('   ⚠️ WARNING: This exposes your App Certificate in client code!');
      debugPrint('   ⚠️ This is OK for development, but use backend token generation for production.');
      return _generateTokenClientSide(
        channelId: channelId,
        uid: uid,
        role: role,
        expireTime: expireTime,
      );
    }
    
    // No token configured - return empty for token-less mode (DEVELOPMENT)
    debugPrint('ℹ️ No token server, test token, or certificate configured. Using token-less mode.');
    debugPrint('   For production, set tokenServerUrl or implement backend token generation.');
    debugPrint('   For testing, set testToken with a temp token from Agora Console.');
    return '';
  }
  
  /// Fetch token from backend server (PRODUCTION METHOD)
  static Future<String> _fetchTokenFromServer({
    required String channelId,
    required int uid,
    required int role,
    required int expireTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(tokenServerUrl!),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'channelName': channelId,
          'uid': uid,
          'role': role,
          'expireTime': expireTime,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'] as String? ?? '';
      } else {
        debugPrint('❌ Token server error: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch token from server: $e');
      return '';
    }
  }
  
  /// Generate token client-side (DEVELOPMENT ONLY - NOT SECURE FOR PRODUCTION)
  /// 
  /// WARNING: This method requires App Certificate in client code.
  /// This is a security risk in production. Use backend token generation instead.
  /// 
  /// This implements Agora RTC Token v2 format:
  /// - Version: 007 (for RTC tokens)
  /// - App ID
  /// - Channel name
  /// - UID
  /// - Expiration timestamp
  /// - HMAC-SHA256 signature
  static String _generateTokenClientSide({
    required String channelId,
    required int uid,
    required int role,
    required int expireTime,
  }) {
    try {
      // Calculate expiration timestamp
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final privilegeExpiredTs = currentTimestamp + expireTime;
      
      // Agora token version (version 007 for RTC)
      const version = '007';
      
      // UID as string (0 becomes "0")
      final uidStr = uid.toString();
      
      // Privilege flags (timestamps when each privilege expires)
      // For Publisher role: enable publish privileges
      // For Subscriber role: enable subscribe privileges  
      final publishAudioTs = (role == 1) ? privilegeExpiredTs : 0; // 1 = Publisher
      final publishVideoTs = (role == 1) ? privilegeExpiredTs : 0;
      final subscribeAudioTs = privilegeExpiredTs; // Always allow subscribing
      final subscribeVideoTs = privilegeExpiredTs;
      
      // Create message content to sign
      // Format: appId:channelName:uid:publishAudioTs:publishVideoTs:subscribeAudioTs:subscribeVideoTs
      final message = '$appId:$channelId:$uidStr:$publishAudioTs:$publishVideoTs:$subscribeAudioTs:$subscribeVideoTs';
      
      // Generate HMAC-SHA256 signature
      final key = utf8.encode(appCertificate);
      final bytes = utf8.encode(message);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);
      final signatureHex = digest.toString();
      
      // Generate random salt (32 bytes = 64 hex characters)
      final random = Random.secure();
      final salt = List<int>.generate(32, (_) => random.nextInt(256));
      final saltHex = salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      
      // Build token: version:appId:channelId:uid:salt:publishAudioTs:publishVideoTs:subscribeAudioTs:subscribeVideoTs:signature
      final tokenContent = '$version:$appId:$channelId:$uidStr:$saltHex:$publishAudioTs:$publishVideoTs:$subscribeAudioTs:$subscribeVideoTs:$signatureHex';
      
      // Encode to base64 (standard base64 encoding)
      final tokenBytes = utf8.encode(tokenContent);
      final token = base64.encode(tokenBytes);
      
      debugPrint('✅ Token generated successfully');
      debugPrint('   Role: ${role == 1 ? "Publisher" : "Subscriber"}');
      debugPrint('   Expires in: $expireTime seconds (${expireTime ~/ 3600} hours)');
      debugPrint('   Expires at: ${DateTime.fromMillisecondsSinceEpoch(privilegeExpiredTs * 1000)}');
      
      return token;
    } catch (e) {
      debugPrint('❌ Failed to generate token: $e');
      debugPrint('   Falling back to empty token');
      return '';
    }
  }
  
  /// Check if token is expired (basic check)
  /// Tokens contain expiration timestamp, but parsing requires token structure knowledge
  static bool isTokenExpired(String token) {
    // In production, your backend should handle token expiration
    // and automatically refresh tokens before they expire
    return false; // Simplified - implement proper token parsing if needed
  }
}

/// Backend Token Server Example (Node.js/Express)
/// 
/// Install: npm install agora-access-token
/// 
/// ```javascript
/// const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
/// 
/// app.post('/agora/token', async (req, res) => {
///   const { channelName, uid, role, expireTime } = req.body;
///   
///   const appId = '0f3b01a62b1e4644b1ae017327c3be69';
///   const appCertificate = 'YOUR_APP_CERTIFICATE'; // From Agora Console
///   const currentTimestamp = Math.floor(Date.now() / 1000);
///   const privilegeExpiredTs = currentTimestamp + (expireTime || 86400);
///   
///   const rtcRole = role === 2 ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
///   
///   const token = RtcTokenBuilder.buildTokenWithUid(
///     appId,
///     appCertificate,
///     channelName,
///     uid,
///     rtcRole,
///     privilegeExpiredTs
///   );
///   
///   res.json({ token });
/// });
/// ```
/// 
/// Python Example (Flask):
/// 
/// ```python
/// from agora_token_builder import RtcTokenBuilder
/// 
/// @app.route('/agora/token', methods=['POST'])
/// def get_token():
///     data = request.json
///     app_id = '0f3b01a62b1e4644b1ae017327c3be69'
///     app_certificate = 'YOUR_APP_CERTIFICATE'
///     channel_name = data['channelName']
///     uid = data['uid']
///     expire_time = data.get('expireTime', 86400)
///     
///     current_timestamp = int(time.time())
///     privilege_expired_ts = current_timestamp + expire_time
///     
///     token = RtcTokenBuilder.buildTokenWithUid(
///         app_id, app_certificate, channel_name, uid,
///         RtcTokenBuilder.Role.Role_Publisher, privilege_expired_ts
///     )
///     
///     return jsonify({'token': token})
/// ```

