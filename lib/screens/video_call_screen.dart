import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:connect_well_nepal/services/video_call_service_base.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// VideoCallScreen - Video consultation interface
///
/// Features:
/// - Video call with Agora RTC Engine
/// - Local and remote video views
/// - Call controls (mute, video toggle, camera switch, speaker)
/// - Call timer
/// - Participant information
class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String? doctorName;
  final String? doctorSpecialty;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    this.doctorName,
    this.doctorSpecialty,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isInitializing = true;
  String? _errorMessage;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final videoCallService = context.read<VideoCallServiceBase>();

    // Listen to remote user events
    videoCallService.remoteUserEvents.listen((event) {
      if (mounted) {
        setState(() {
          if (event.type == RemoteUserEventType.joined) {
            _remoteUid = event.userId;
          } else if (event.type == RemoteUserEventType.left) {
            _remoteUid = null;
          }
        });
      }
    });

    // Listen to call events
    videoCallService.callEvents.listen((event) {
      if (mounted) {
        if (event.type == CallEventType.error) {
          setState(() {
            _errorMessage = event.errorMessage;
            _isInitializing = false;
          });
        } else if (event.type == CallEventType.joined) {
          setState(() {
            _isInitializing = false;
          });
        }
      }
    });

    // Initialize and join channel
    try {
      final initialized = await videoCallService.initialize();
      if (!initialized) {
        setState(() {
          _errorMessage = 'Failed to initialize video call';
          _isInitializing = false;
        });
        return;
      }

      final joined = await videoCallService.joinChannel(
        channelId: widget.channelId,
        token: widget.token,
        uid: 0, // Use 0 for auto-generated UID
      );

      if (!joined) {
        setState(() {
          _errorMessage = 'Failed to join video call';
          _isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _endCall() async {
    final videoCallService = context.read<VideoCallServiceBase>();
    await videoCallService.leaveChannel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // Note: We don't dispose the service here as it's managed by Provider
    // The service will handle cleanup when leaving the channel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<VideoCallServiceBase>(
          builder: (context, videoCallService, child) {
            if (_isInitializing) {
              return _buildLoadingView();
            }

            if (_errorMessage != null) {
              return _buildErrorView();
            }

            return _buildCallView(videoCallService);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Connecting...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _endCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryCrimsonRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallView(VideoCallServiceBase videoCallService) {
    return Stack(
      children: [
        // Video views
        _buildVideoViews(videoCallService),

        // Top info bar
        _buildTopInfoBar(videoCallService),

        // Bottom controls
        _buildBottomControls(videoCallService),
      ],
    );
  }

  Widget _buildVideoViews(VideoCallServiceBase videoCallService) {
    final engine = videoCallService.engine;
    
    return Stack(
      children: [
        // Remote video (full screen)
        if (_remoteUid != null && engine != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine as RtcEngine,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: widget.channelId),
            ),
          )
        else
          _buildPlaceholderView(
            widget.doctorName ?? 'Doctor',
            isRemote: true,
          ),

        // Local video (picture-in-picture)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: videoCallService.isVideoEnabled && engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine as RtcEngine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : _buildPlaceholderView('You', isRemote: false),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderView(String name, {required bool isRemote}) {
    return Container(
      color: AppColors.primaryNavyBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: isRemote ? 60 : 30,
              backgroundColor: Colors.white24,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: isRemote ? 48 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar(VideoCallServiceBase videoCallService) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _endCall,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName ?? 'Doctor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.doctorSpecialty != null)
                    Text(
                      widget.doctorSpecialty!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: videoCallService.isJoined
                    ? Colors.green
                    : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    videoCallService.callDurationFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoCallServiceBase videoCallService) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: videoCallService.isMuted
                  ? Icons.mic_off
                  : Icons.mic,
              label: videoCallService.isMuted ? 'Unmute' : 'Mute',
              color: videoCallService.isMuted
                  ? AppColors.secondaryCrimsonRed
                  : Colors.white,
              onPressed: () => videoCallService.toggleMute(),
            ),

            // Video toggle button
            _buildControlButton(
              icon: videoCallService.isVideoEnabled
                  ? Icons.videocam
                  : Icons.videocam_off,
              label: videoCallService.isVideoEnabled
                  ? 'Video Off'
                  : 'Video On',
              color: videoCallService.isVideoEnabled
                  ? Colors.white
                  : AppColors.secondaryCrimsonRed,
              onPressed: () => videoCallService.toggleVideo(),
            ),

            // Camera switch button
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Switch',
              color: Colors.white,
              onPressed: () => videoCallService.switchCamera(),
            ),

            // Speaker button
            _buildControlButton(
              icon: videoCallService.isSpeakerEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
              label: videoCallService.isSpeakerEnabled
                  ? 'Speaker'
                  : 'Earpiece',
              color: Colors.white,
              onPressed: () => videoCallService.toggleSpeaker(),
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'End',
              color: AppColors.secondaryCrimsonRed,
              onPressed: _endCall,
              isEndCall: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isEndCall ? 64 : 56,
          height: isEndCall ? 64 : 56,
          decoration: BoxDecoration(
            color: isEndCall
                ? AppColors.secondaryCrimsonRed
                : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: isEndCall ? 28 : 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
