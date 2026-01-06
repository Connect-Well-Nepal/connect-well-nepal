import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// VideoCallService - Manages video calling functionality using Agora RTC Engine
///
/// Features:
/// - Initialize Agora RTC Engine
/// - Join/leave video call channels
/// - Audio/video controls (mute, camera toggle, speaker toggle)
/// - Camera switching (front/back)
/// - Call state management
/// - Event callbacks for UI updates
class VideoCallService extends ChangeNotifier {
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
  static const String _appId = "023887d77f714564850ef34e9c993659"; // Replace with actual App ID

  // Getters
  bool get isInitialized => _isInitialized;
  RtcEngine? get engine => _engine;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  bool get isFrontCamera => _isFrontCamera;
  String? get channelId => _channelId;
  int? get localUid => _localUid;
  Set<int> get remoteUsers => _remoteUsers;
  int get callDurationSeconds => _callDurationSeconds;

  // Computed properties
  bool get hasRemoteUsers => _remoteUsers.isNotEmpty;
  String get callDurationFormatted {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Event streams
  Stream<CallEvent> get callEvents => _callEventController.stream;
  Stream<RemoteUserEvent> get remoteUserEvents => _remoteUserController.stream;

  /// Initialize Agora RTC Engine
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Check if App ID is configured
      if (_appId.isEmpty || _appId.length < 10) {
        _callEventController.add(CallEvent.error(
          'Agora App ID not configured properly. Please check your App ID in video_call_service.dart'
        ));
        return false;
      }

      // Request camera and microphone permissions
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || microphoneStatus.isDenied) {
        _callEventController.add(CallEvent.error('Camera and microphone permissions are required'));
        return false;
      }

      // Create RTC engine instance
      _engine = createAgoraRtcEngine();

      // Initialize with app ID
      await _engine!.initialize(const RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Enable video
      await _engine!.enableVideo();

      // Set up event handlers
      _setupEventHandlers();

      _isInitialized = true;
      _callEventController.add(CallEvent.initialized());
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Agora engine: $e');
      debugPrint('📱 App ID being used: $_appId');
      _callEventController.add(CallEvent.error('Failed to initialize video call: $e'));
      return false;
    }
  }

  /// Join a video call channel
  Future<bool> joinChannel({
    required String channelId,
    required String token,
    int uid = 0,
  }) async {
    try {
      if (!_isInitialized || _engine == null) {
        _callEventController.add(CallEvent.error('Engine not initialized'));
        return false;
      }

      if (_isJoined) {
        await leaveChannel();
      }

      // Set channel profile for video call
      await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      // Join channel
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      );

      debugPrint('🔄 Attempting to join channel: $channelId with token: ${token.isNotEmpty ? "provided" : "empty (token-less mode)"}');

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: options,
      );

      debugPrint('✅ Successfully joined channel: $channelId');
      _channelId = channelId;
      _localUid = uid;
      _callDurationSeconds = 0;

      // Start call timer
      _startCallTimer();

      _callEventController.add(CallEvent.joined(channelId));
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to join channel: $e');
      debugPrint('🔍 Channel ID: $channelId, Token provided: ${token.isNotEmpty}');
      _callEventController.add(CallEvent.error('Failed to join call: $e'));
      return false;
    }
  }

  /// Leave the current channel
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
        debugPrint('Successfully joined channel: ${connection.channelId}');
        _isJoined = true;
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
        _callEventController.add(CallEvent.error('Call error: $msg'));
      },

      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        debugPrint('Connection state changed: $state, reason: $reason');
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

/// Call event types for UI updates
class CallEvent {
  final CallEventType type;
  final dynamic data;
  final String? errorMessage;

  CallEvent._(this.type, {this.data, this.errorMessage});

  factory CallEvent.initialized() => CallEvent._(CallEventType.initialized);
  factory CallEvent.joined(String channelId) => CallEvent._(CallEventType.joined, data: channelId);
  factory CallEvent.left() => CallEvent._(CallEventType.left);
  factory CallEvent.audioStateChanged(bool isMuted) => CallEvent._(CallEventType.audioStateChanged, data: isMuted);
  factory CallEvent.videoStateChanged(bool isEnabled) => CallEvent._(CallEventType.videoStateChanged, data: isEnabled);
  factory CallEvent.speakerStateChanged(bool isEnabled) => CallEvent._(CallEventType.speakerStateChanged, data: isEnabled);
  factory CallEvent.cameraSwitched(bool isFront) => CallEvent._(CallEventType.cameraSwitched, data: isFront);
  factory CallEvent.connectionStateChanged(ConnectionStateType state, ConnectionChangedReasonType reason) =>
      CallEvent._(CallEventType.connectionStateChanged, data: {'state': state, 'reason': reason});
  factory CallEvent.error(String message) => CallEvent._(CallEventType.error, errorMessage: message);
}

enum CallEventType {
  initialized,
  joined,
  left,
  audioStateChanged,
  videoStateChanged,
  speakerStateChanged,
  cameraSwitched,
  connectionStateChanged,
  error,
}

/// Remote user event types
class RemoteUserEvent {
  final RemoteUserEventType type;
  final int userId;

  RemoteUserEvent._(this.type, this.userId);

  factory RemoteUserEvent.joined(int userId) => RemoteUserEvent._(RemoteUserEventType.joined, userId);
  factory RemoteUserEvent.left(int userId) => RemoteUserEvent._(RemoteUserEventType.left, userId);
}

enum RemoteUserEventType {
  joined,
  left,
}
