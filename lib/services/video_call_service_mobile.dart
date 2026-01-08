import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:permission_handler/permission_handler.dart';

import 'package:connect_well_nepal/services/video_call_service_base.dart'; // Import the base class
import 'package:connect_well_nepal/services/agora_token_service.dart'; // Token service for production

/// VideoCallServiceMobile - Manages video calling functionality using Agora RTC Engine for mobile platforms
///
/// Features:
/// - Initialize Agora RTC Engine
/// - Join/leave video call channels
/// - Audio/video controls (mute, camera toggle, speaker toggle)
/// - Camera switching (front/back)
/// - Call state management
/// - Event callbacks for UI updates
class VideoCallServiceMobile extends VideoCallServiceBase {
  // Agora RTC Engine instance
  RtcEngine? _engine;

  // Call state
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = true;
  bool _isFrontCamera = true;

  // Call info
  String? _channelId;
  int? _localUid;
  Timer? _callTimer;

  // Call duration tracking
  int _callDurationSeconds = 0;

  // Event streams for UI updates
  final StreamController<CallEvent> _callEventController = StreamController<CallEvent>.broadcast();
  final StreamController<RemoteUserEvent> _remoteUserController = StreamController<RemoteUserEvent>.broadcast();

  // Remote users in call
  final Set<int> _remoteUsers = {};

  // Agora App ID - In production, this should be stored securely
  // TODO: Move to environment variables or secure storage
  static const String _appId = "0f3b01a62b1e4644b1ae017327c3be69";
  
  // PRODUCTION SETUP:
  // 1. Enable token authentication in Agora Console (Security settings)
  // 2. Set up backend token server (see agora_token_service.dart for examples)
  // 3. Update tokenServerUrl in AgoraTokenService
  // 4. Never expose App Certificate in client code
  //
  // DEVELOPMENT SETUP:
  // 1. Option A: Disable token authentication in Agora Console (use empty tokens)
  // 2. Option B: Use "Generate Temp Token" in Agora Console for testing
  // 3. Option C: Set up local token server for development

  // Getters
  @override
  bool get isInitialized => _isInitialized;
  @override
  dynamic getEngine() => _engine; // Return the native engine
  @override
  bool get isJoined => _isJoined;
  @override
  bool get isMuted => _isMuted;
  @override
  bool get isVideoEnabled => _isVideoEnabled;
  @override
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  @override
  bool get isFrontCamera => _isFrontCamera;
  @override
  String? get channelId => _channelId;
  @override
  int? get localUid => _localUid;
  @override
  Set<int> get remoteUsers => _remoteUsers;
  @override
  int get callDurationSeconds => _callDurationSeconds;

  // Computed properties
  @override
  bool get hasRemoteUsers => _remoteUsers.isNotEmpty;
  @override
  String get callDurationFormatted {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Event streams
  @override
  Stream<CallEvent> get callEvents => _callEventController.stream;
  @override
  Stream<RemoteUserEvent> get remoteUserEvents => _remoteUserController.stream;

  /// Initialize Agora RTC Engine
  @override
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Check if App ID is configured
      if (_appId.isEmpty || _appId.length < 10) {
        _callEventController.add(CallEvent.error(
          'Agora App ID not configured properly. Please check your App ID in video_call_service_mobile.dart'
        ));
        return false;
      }

      // Request camera and microphone permissions (skip on web, handled by browser)
      if (!kIsWeb) {
        final cameraStatus = await Permission.camera.request();
        final microphoneStatus = await Permission.microphone.request();

        if (cameraStatus.isDenied || microphoneStatus.isDenied) {
          _callEventController.add(CallEvent.error('Camera and microphone permissions are required'));
          return false;
        }
      }

      // Create RTC engine instance
      try {
        _engine = createAgoraRtcEngine();
      } catch (e) {
        if (kIsWeb) {
          debugPrint('⚠️ Agora engine creation warning on web: $e');
          debugPrint('   This may be a non-critical initialization issue. Video calls may still work.');
          // On web, the engine might still work even if initialization shows warnings
          // Try to continue - the joinChannel might still succeed
        } else {
          rethrow;
        }
      }

      if (_engine == null) {
        if (kIsWeb) {
          debugPrint('⚠️ Agora engine is null on web. This may be expected if using web SDK directly.');
          // On web, sometimes the engine needs to be created differently
          // Mark as initialized anyway - joinChannel will handle the actual connection
          _isInitialized = true;
          _callEventController.add(CallEvent.initialized());
          notifyListeners();
          return true;
        } else {
          throw Exception('Failed to create Agora RTC engine');
        }
      }

      // Initialize with app ID
      try {
        await _engine!.initialize(const RtcEngineContext(
          appId: _appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ));
      } catch (e) {
        if (kIsWeb) {
          debugPrint('⚠️ Agora initialization warning on web: $e');
          debugPrint('   Attempting to continue - web SDK may handle initialization differently');
          // On web, initialization errors might be non-critical
          // The engine might still work for joining channels
        } else {
          rethrow;
        }
      }

      // Enable video
      try {
        await _engine!.enableVideo();
      } catch (e) {
        if (kIsWeb) {
          debugPrint('⚠️ Video enable warning on web: $e');
          // Continue anyway - video might be enabled by default on web
        } else {
          rethrow;
        }
      }

      // Note: Android may show "CameraMetadataJV: Expect face scores and rectangles to be non-null" warnings.
      // These are harmless system-level warnings from Android's Camera2 API and don't affect functionality.
      // They occur when the camera framework expects face detection metadata but it's not provided.
      // These warnings can be safely ignored as they don't impact video call functionality.

      // Set up event handlers
      try {
        _setupEventHandlers();
      } catch (e) {
        if (kIsWeb) {
          debugPrint('⚠️ Event handler setup warning on web: $e');
          // Continue - handlers might be set up differently on web
        } else {
          rethrow;
        }
      }

      _isInitialized = true;
      _callEventController.add(CallEvent.initialized());
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Agora engine: $e');
      debugPrint('📱 App ID being used: $_appId');
      debugPrint('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      // On web, allow initialization to succeed even with errors
      // The actual connection will be tested when joining a channel
      if (kIsWeb) {
        debugPrint('⚠️ Allowing initialization to continue on web despite errors');
        debugPrint('   Video calls will be attempted when joining a channel');
        _isInitialized = true;
        _callEventController.add(CallEvent.initialized());
        notifyListeners();
        return true;
      }
      
      _callEventController.add(CallEvent.error('Failed to initialize video call: $e'));
      return false;
    }
  }

  /// Join a video call channel
  @override
  Future<bool> joinChannel({
    required String channelId,
    required String token,
    int uid = 0,
  }) async {
    try {
      // On web, try to create engine if it doesn't exist
      if (kIsWeb && _engine == null) {
        try {
          _engine = createAgoraRtcEngine();
          await _engine!.initialize(const RtcEngineContext(
            appId: _appId,
            channelProfile: ChannelProfileType.channelProfileCommunication,
          ));
          await _engine!.enableVideo();
          _setupEventHandlers();
        } catch (e) {
          debugPrint('⚠️ Failed to create engine during join on web: $e');
          // Continue anyway - web SDK might work differently
        }
      }
      
      if (!_isInitialized) {
        _callEventController.add(CallEvent.error('Engine not initialized'));
        return false;
      }
      
      if (_engine == null && !kIsWeb) {
        _callEventController.add(CallEvent.error('Engine not available'));
        return false;
      }

      if (_isJoined) {
        await leaveChannel();
      }

      // On web, if engine is still null, we can't proceed
      if (_engine == null) {
        if (kIsWeb) {
          debugPrint('⚠️ Engine is null on web - video calls may not work properly');
          debugPrint('   Make sure Agora web SDK is properly loaded in index.html');
        }
        _callEventController.add(CallEvent.error('Video call engine not available'));
        return false;
      }

      // Set channel profile for video call
      await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      // Join channel
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      );

      // In production, fetch token from backend if not provided
      String tokenToUse = token;
      if (token.isEmpty) {
        debugPrint('🔄 No token provided, fetching from token service...');
        tokenToUse = await AgoraTokenService.getToken(
          channelId: channelId,
          uid: uid,
          role: 1, // Publisher role
        );
      }
      
      debugPrint('🔄 Attempting to join channel: $channelId with token: ${tokenToUse.isNotEmpty ? "provided" : "empty (token-less mode)"}');
      
      // For token-less mode, use empty string (not null)
      // Agora requires empty string for token-less authentication
      if (tokenToUse.isEmpty) {
        tokenToUse = '';
      }

      try {
        await _engine!.joinChannel(
          token: tokenToUse,
          channelId: channelId,
          uid: uid,
          options: options,
        );
      } catch (e) {
        // Handle Agora exceptions specifically
        final errorString = e.toString();
        debugPrint('❌ joinChannel exception: $e');
        
        // Check for error code -8 (ERR_INVALID_TOKEN) or -2 (ERR_INVALID_ARGUMENT)
        if (errorString.contains('-8') || errorString.contains('ERR_INVALID_TOKEN') || 
            errorString.contains('invalid token') || errorString.contains('Invalid token')) {
          debugPrint('⚠️ Invalid token error detected (code -8)');
          debugPrint('   App ID: $_appId');
          debugPrint('   Your Agora App ID requires token authentication to be disabled.');
          debugPrint('   Steps to fix:');
          debugPrint('   1. Go to https://console.agora.io/');
          debugPrint('   2. Select your project with App ID: $_appId');
          debugPrint('   3. Go to "Project Management" > "Edit" > "Security"');
          debugPrint('   4. Set "Token" to "Not enabled"');
          debugPrint('   5. Save and restart the app');
          _callEventController.add(CallEvent.error(
            'Video call authentication failed. Please check your settings or try again later.'
          ));
          return false;
        }
        
        // Re-throw if it's not a token error
        rethrow;
      }

      // Wait a moment to see if connection succeeds
      // The actual join success will be reported via onJoinChannelSuccess callback
      debugPrint('⏳ Waiting for join confirmation...');
      
      // Don't mark as joined yet - wait for onJoinChannelSuccess callback
      // This prevents false positives if joinChannel returns but connection fails
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to join channel: $e');
      debugPrint('🔍 Channel ID: $channelId, Token provided: ${token.isNotEmpty}');
      debugPrint('🔍 App ID: $_appId');
      
      final errorMessage = e.toString();
      String userMessage = 'Failed to join call';
      
      if (errorMessage.contains('-8') || errorMessage.contains('invalid token') || 
          errorMessage.contains('Invalid token')) {
        userMessage = 'Invalid token error. Please check Agora Console settings for App ID: $_appId';
      } else if (errorMessage.contains('AgoraException')) {
        userMessage = 'Agora error: $errorMessage';
      }
      
      _callEventController.add(CallEvent.error(userMessage));
      return false;
    }
  }

  /// Leave the current channel
  @override
  Future<void> leaveChannel() async {
    try {
      if (_engine != null && _isJoined) {
        await _engine!.leaveChannel();
      }

      _isJoined = false;
      _channelId = null;
      _localUid = null;
      _remoteUsers.clear();
      _stopCallTimer();
      _callDurationSeconds = 0;

      _callEventController.add(CallEvent.left());
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  /// Toggle microphone mute/unmute
  @override
  Future<void> toggleMute() async {
    try {
      if (_engine != null) {
        _isMuted = !_isMuted;
        await _engine!.muteLocalAudioStream(_isMuted);
        _callEventController.add(CallEvent.audioStateChanged(_isMuted));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  /// Toggle video on/off
  @override
  Future<void> toggleVideo() async {
    try {
      if (_engine != null) {
        _isVideoEnabled = !_isVideoEnabled;
        await _engine!.muteLocalVideoStream(_isVideoEnabled ? false : true);
        _callEventController.add(CallEvent.videoStateChanged(_isVideoEnabled));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling video: $e');
    }
  }

  /// Toggle speaker on/off
  @override
  Future<void> toggleSpeaker() async {
    try {
      if (_engine != null) {
        _isSpeakerEnabled = !_isSpeakerEnabled;
        await _engine!.setEnableSpeakerphone(_isSpeakerEnabled);
        _callEventController.add(CallEvent.speakerStateChanged(_isSpeakerEnabled));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  /// Switch camera (front/back)
  @override
  Future<void> switchCamera() async {
    try {
      if (_engine != null) {
        await _engine!.switchCamera();
        _isFrontCamera = !_isFrontCamera;
        _callEventController.add(CallEvent.cameraSwitched(_isFrontCamera));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Set up Agora event handlers
  void _setupEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        final channelId = connection.channelId ?? _channelId ?? 'unknown_channel';
        debugPrint('✅ Successfully joined channel: $channelId (elapsed: ${elapsed}ms)');
        _isJoined = true;
        _channelId = channelId;
        _localUid = connection.localUid;
        _callDurationSeconds = 0;
        
        // Start call timer only on successful join
        _startCallTimer();
        
        _callEventController.add(CallEvent.joined(channelId));
        notifyListeners();
      },

      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        debugPrint('Left channel: ${connection.channelId}');
        _isJoined = false;
        _remoteUsers.clear();
        notifyListeners();
      },

      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint('Remote user joined: $remoteUid');
        _remoteUsers.add(remoteUid);
        _remoteUserController.add(RemoteUserEvent.joined(remoteUid));
        notifyListeners();
      },

      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint('Remote user offline: $remoteUid, reason: $reason');
        _remoteUsers.remove(remoteUid);
        _remoteUserController.add(RemoteUserEvent.left(remoteUid));
        notifyListeners();
      },

      onError: (ErrorCodeType err, String msg) {
        debugPrint('Agora error: $err - $msg');
        debugPrint('   App ID: $_appId'); // Log App ID for debugging
        
        // Handle specific error types
        // Error code -8 = ERR_INVALID_TOKEN
        if (err == ErrorCodeType.errInvalidToken || 
            err == ErrorCodeType.errTokenExpired) {
          debugPrint('⚠️ Token error detected. This may be due to token authentication being required.');
          debugPrint('   For development, ensure your Agora App ID allows token-less mode in the console.');
          debugPrint('   Steps: Agora Console > Project > Edit > Security > Set Token to "Not enabled"');
          _isJoined = false;
          _callEventController.add(CallEvent.error(
            'Video call authentication failed. Please check your Agora settings or contact support.'
          ));
          notifyListeners();
        } else {
          debugPrint('⚠️ Agora error: $err, message: $msg');
          _callEventController.add(CallEvent.error('Call error: $msg'));
        }
      },

      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        debugPrint('Connection state changed: $state, reason: $reason');
        
        // Handle connection failures
        if (state == ConnectionStateType.connectionStateFailed) {
          if (reason == ConnectionChangedReasonType.connectionChangedInvalidToken) {
            debugPrint('❌ Connection failed: Invalid token');
            debugPrint('   App ID: $_appId');
            debugPrint('   Your Agora App ID may require token authentication.');
            debugPrint('   Options:');
            debugPrint('   1. Enable token-less mode in Agora Console for this App ID');
            debugPrint('   2. Generate and provide a valid token when joining channels');
            _isJoined = false;
            _callEventController.add(CallEvent.error(
              'Unable to connect to video call. Please try again or contact support.'
            ));
          } else if (reason == ConnectionChangedReasonType.connectionChangedTokenExpired) {
            debugPrint('❌ Connection failed: Token expired');
            _isJoined = false;
            _callEventController.add(CallEvent.error('Connection expired. Please try again.'));
          } else {
            debugPrint('❌ Connection failed: $reason');
            _isJoined = false;
            _callEventController.add(CallEvent.error('Connection failed. Please try again.'));
          }
          notifyListeners();
        } else if (state == ConnectionStateType.connectionStateConnected) {
          debugPrint('✅ Connection established successfully');
          _isJoined = true;
          notifyListeners();
        }
        
        _callEventController.add(CallEvent.connectionStateChanged(state, reason));
      },
    ));
  }

  /// Start call duration timer
  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  /// Stop call duration timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  /// Dispose of resources
  @override
  void dispose() {
    _stopCallTimer();
    _callEventController.close();
    _remoteUserController.close();

    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
      _engine = null;
    }

    super.dispose();
  }
}
