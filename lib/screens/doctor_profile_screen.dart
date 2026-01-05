// lib/screens/doctor_profile_screen.dart

import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../utils/colors.dart';
import 'booking_screen.dart';

/// Detailed doctor profile screen showing all information
/// Including reviews, experience, availability, and booking option
class DoctorProfileScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfileScreen({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with doctor image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryNavyBlue,
                          Color(0xFF2A4470),
                        ],
                      ),
                    ),
                  ),
                  // Doctor photo
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        backgroundImage: doctor.photoUrl != null
                            ? NetworkImage(doctor.photoUrl!)
                            : null,
                        child: doctor.photoUrl == null
                            ? Text(
                                doctor.name.isNotEmpty
                                    ? doctor.name[0].toUpperCase()
                                    : 'D',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: AppColors.primaryNavyBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Verified badge - positioned at bottom right of avatar
                  if (doctor.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor name and specialty
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        doctor.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (doctor.qualifications != null && doctor.qualifications!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          doctor.qualifications!.join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[500]
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stats row
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                        : AppColors.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.people,
                        '${doctor.totalReviews}+',
                        'Patients',
                        isDark,
                      ),
                      _buildDivider(isDark),
                      _buildStatItem(
                        Icons.star,
                        doctor.rating.toString(),
                        'Rating',
                        isDark,
                      ),
                      _buildDivider(isDark),
                      _buildStatItem(
                        Icons.work,
                        '${doctor.experienceYears}+ yrs',
                        'Experience',
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About section
                if (doctor.bio != null) ...[
                  _buildSectionTitle('About', isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      doctor.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? Colors.grey[300] : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Clinic information
                if (doctor.clinicName != null) ...[
                  _buildSectionTitle('Clinic', isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_hospital,
                                  color: AppColors.primaryNavyBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doctor.clinicName!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (doctor.clinicAddress != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.secondaryCrimsonRed,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      doctor.clinicAddress!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Languages
                _buildSectionTitle('Languages', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: doctor.languages.isEmpty
                      ? Text(
                          'Not specified',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: doctor.languages.map((lang) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryNavyBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                lang,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryNavyBlue,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 24),

                // Available days
                _buildSectionTitle('Available Days', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getAllDays().map((day) {
                      final isAvailable = doctor.availableDays.contains(day);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.successGreen.withValues(alpha: 0.1)
                              : isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAvailable
                                ? AppColors.successGreen
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          day.substring(0, 3),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? AppColors.successGreen
                                : isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Available time slots
                _buildSectionTitle('Available Time Slots', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: doctor.timeSlots.isEmpty
                      ? Text(
                          'No time slots available',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: doctor.timeSlots.map((slot) {
                            final isPast = slot.isPast(DateTime.now());
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : slot.isAvailable
                                        ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPast
                                      ? Colors.grey
                                      : slot.isAvailable
                                          ? AppColors.primaryNavyBlue
                                          : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isPast
                                        ? Colors.grey
                                        : slot.isAvailable
                                            ? AppColors.primaryNavyBlue
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${slot.startTime} - ${slot.endTime}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isPast
                                          ? Colors.grey
                                          : slot.isAvailable
                                              ? AppColors.primaryNavyBlue
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 24),

                // Consultation fee
                _buildSectionTitle('Consultation Fee', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primaryNavyBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rs. ${doctor.consultationFee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavyBlue,
                                ),
                              ),
                              Text(
                                'Per consultation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Reviews section
                _buildSectionTitle('Patient Reviews', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                doctor.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavyBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < doctor.rating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 24,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Based on ${doctor.totalReviews} reviews',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRatingBar('5', 0.7, isDark),
                          _buildRatingBar('4', 0.2, isDark),
                          _buildRatingBar('3', 0.05, isDark),
                          _buildRatingBar('2', 0.03, isDark),
                          _buildRatingBar('1', 0.02, isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),

      // Book appointment button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: (doctor.isAvailable || doctor.isAvailableNow)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          preSelectedDoctor: doctor,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: doctor.isAvailableNow 
                  ? AppColors.successGreen 
                  : AppColors.primaryNavyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (doctor.isAvailableNow) ...[
                  const Icon(Icons.flash_on, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  doctor.isAvailableNow
                      ? 'Book Now - Available'
                      : doctor.isAvailable
                          ? 'Book Appointment'
                          : 'Currently Unavailable',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryNavyBlue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build divider
  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  /// Build rating bar
  Widget _buildRatingBar(String stars, double percentage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              stars,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor:
                    isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get all days of week
  List<String> _getAllDays() {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
  }
}