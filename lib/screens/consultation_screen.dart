import 'package:flutter/material.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/screens/video_call_screen.dart';
import 'package:connect_well_nepal/services/video_call_service.dart';
import 'package:provider/provider.dart';

/// ConsultationScreen - Video consultation interface (Week 1-3)
///
/// Week 1-3 Tasks - Video Call Integration:
/// - Research and integrate video SDK (Agora)
/// - Create video_call_screen.dart ✓
/// - Implement video controls (mute, video on/off, flip camera) ✓
/// - Add in-call UI (timer, participant info) ✓
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  
  @override
  Widget build(BuildContext context) {
    return _ConsultationScreenContent();
  }
}

class _ConsultationScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultation'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Video Consultation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavyBlue,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'Connect face-to-face with your doctor through secure video calling',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Video Consultation Card
            _buildConsultationCard(
              context,
              icon: Icons.video_call,
              title: 'Start Video Call',
              description: 'Begin your video consultation with the doctor',
              color: AppColors.primaryNavyBlue,
              onTap: () {
                _startVideoConsultation(context);
              },
            ),

            const Spacer(),

            // Info Text
            const Text(
              'Make sure you have a stable internet connection and are in a quiet environment for the best experience.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConsultationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startVideoConsultation(BuildContext context) {
    // Week 1-3: Video Call Integration
    // Using Agora RTC SDK for video calling

    // For demo purposes - in production, these would come from:
    // - Appointment booking system
    // - Doctor selection
    // - Server-generated tokens
    const String channelId = 'demo_channel_123';
    const String token = ''; // Empty token for testing (token-less mode)
    const String doctorName = 'Dr. Sarita Sharma';
    const String doctorSpecialty = 'General Physician';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelId: channelId,
          token: token,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
        ),
      ),
    );
  }
}

