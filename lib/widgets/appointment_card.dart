import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../utils/colors.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isDoctorView;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onJoin;
  final VoidCallback? onRate;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isDoctorView = false,
    this.onTap,
    this.onCancel,
    this.onReschedule,
    this.onAccept,
    this.onReject,
    this.onJoin,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                    child: Text(
                      isDoctorView
                          ? (appointment.patientName.isNotEmpty
                              ? appointment.patientName[0].toUpperCase()
                              : 'P')
                          : (appointment.doctorName.isNotEmpty
                              ? appointment.doctorName[0].toUpperCase()
                              : 'D'),
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.primaryNavyBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDoctorView ? appointment.patientName : appointment.doctorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDoctorView ? 'Patient' : appointment.doctorSpecialty,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(isDark),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                      : AppColors.backgroundOffWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today, 'Date', appointment.formattedDate, isDark),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time, 'Time', appointment.formattedTime, isDark),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.video_call, 'Type', _getConsultationType(appointment.type), isDark),
                  ],
                ),
              ),
              if (appointment.symptoms != null && appointment.symptoms!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Symptoms:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.symptoms!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (appointment.isUpcoming) ...[
                const SizedBox(height: 16),
                // Doctor view: Accept/Reject buttons for pending appointments
                if (isDoctorView && appointment.status == 'pending' && (onAccept != null || onReject != null))
                  Row(
                    children: [
                      if (onAccept != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (onAccept != null && onReject != null) const SizedBox(width: 8),
                      if (onReject != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryCrimsonRed,
                              side: const BorderSide(color: AppColors.secondaryCrimsonRed),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                // Patient view: Join/Reschedule/Cancel buttons
                else if (!isDoctorView)
                  Row(
                    children: [
                      if (appointment.canJoin && onJoin != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onJoin,
                            icon: const Icon(Icons.video_call, size: 18),
                            label: const Text('Join Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (!appointment.canJoin && onReschedule != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReschedule,
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Reschedule'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryNavyBlue,
                              side: const BorderSide(color: AppColors.primaryNavyBlue),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onCancel != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryCrimsonRed,
                              side: const BorderSide(color: AppColors.secondaryCrimsonRed),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                // Doctor view: Join button for confirmed appointments
                else if (isDoctorView && appointment.canJoin && onJoin != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.video_call, size: 18),
                      label: const Text('Join Consultation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
              if (appointment.status == 'completed' && appointment.rating == null && onRate != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('Rate Consultation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavyBlue,
                      side: const BorderSide(color: AppColors.primaryNavyBlue),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              if (appointment.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Your Rating: ', style: TextStyle(fontSize: 13)),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < appointment.rating!.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (appointment.status) {
      case 'confirmed':
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        textColor = AppColors.successGreen;
        statusText = 'Confirmed';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'completed':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        statusText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppColors.secondaryCrimsonRed.withValues(alpha: 0.1);
        textColor = AppColors.secondaryCrimsonRed;
        statusText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        statusText = appointment.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryNavyBlue),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getConsultationType(String type) {
    switch (type) {
      case 'video':
        return 'Video Call';
      case 'voice':
        return 'Voice Call';
      case 'chat':
        return 'Chat';
      default:
        return type;
    }
  }
}