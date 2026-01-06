import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Event types for UI updates
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
  factory CallEvent.connectionStateChanged(dynamic state, dynamic reason) =>
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

// Remote user event types
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

/// VideoCallServiceBase - Abstract base class for video calling functionality
abstract class VideoCallServiceBase extends ChangeNotifier {
  bool get isInitialized;
  bool get isJoined;
  bool get isMuted;
  bool get isVideoEnabled;
  bool get isSpeakerEnabled;
  bool get isFrontCamera;
  String? get channelId;
  int? get localUid;
  Set<int> get remoteUsers;
  int get callDurationSeconds;
  bool get hasRemoteUsers;
  String get callDurationFormatted;

  Stream<CallEvent> get callEvents;
  Stream<RemoteUserEvent> get remoteUserEvents;

  Future<bool> initialize();
  Future<bool> joinChannel({required String channelId, required String token, int uid = 0});
  Future<void> leaveChannel();
  Future<void> toggleMute();
  Future<void> toggleVideo();
  Future<void> toggleSpeaker();
  Future<void> switchCamera();

  // Optional: Getters for platform-specific engines if needed by UI (e.g., AgoraVideoView)
  dynamic getEngine();
  dynamic get engine => getEngine();
}

