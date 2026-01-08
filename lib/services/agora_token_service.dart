import 'dart:convert';
import 'dart:math';
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
  static const String appCertificate = ""; // Add your App Certificate here if needed
  
  // Backend token server URL (for production)
  // Set this to your backend endpoint that generates tokens
  static const String? tokenServerUrl = null; // e.g., "https://your-api.com/agora/token"
  
  // Temporary token for testing (from Agora Console)
  // Replace with your temp token from Agora Console > Security > Generate Temp Token
  // Set to null or empty string to use token-less mode
  static const String? testToken = "007eJxTYBAPdavwrO71mnnII06ozG6D6AFbgwdKqz7I2s9oli7K71VgMEgzTjIwTDQzSjJMNTEzMUkyTEw1MDQ3NjJPNk5KNbPUUYjPbAhkZNCVaGRlZIBAEF+CISU1Nz8+OSMxLy81Jz4lP7kkvyg+OTEnh4EBALztIzQ=";
  
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
    if (testToken != null && testToken!.isNotEmpty) {
      debugPrint('ℹ️ Using test token from Agora Console for testing.');
      debugPrint('   Note: Test tokens expire after the set duration. Generate a new one if expired.');
      return testToken!;
    }
    
    // If App Certificate is set, generate client-side (DEVELOPMENT ONLY)
    if (appCertificate.isNotEmpty) {
      debugPrint('⚠️ Generating token client-side. This is NOT recommended for production!');
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
  static String _generateTokenClientSide({
    required String channelId,
    required int uid,
    required int role,
    required int expireTime,
  }) {
    // This is a simplified example. In practice, you need to:
    // 1. Generate a random 32-byte salt
    // 2. Create message with channel, uid, role, expireTime
    // 3. Sign with HMAC-SHA256 using App Certificate
    // 4. Encode as base64
    
    // For now, return empty - implement proper token generation or use backend
    debugPrint('⚠️ Client-side token generation not fully implemented.');
    debugPrint('   Use backend token generation or Agora Console temp tokens for testing.');
    return '';
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

