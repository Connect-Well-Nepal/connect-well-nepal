// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import '../widgets/time_selector.dart';
import '../utils/colors.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/local_notification_service.dart';

/// Complete appointment booking flow screen
/// Steps: Select Date → Select Time → Enter Details → Confirm
class BookingScreen extends StatefulWidget {
  final Doctor? preSelectedDoctor;

  const BookingScreen({
    super.key,
    this.preSelectedDoctor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  String _selectedConsultationType = 'video';
  Doctor? _selectedDoctor;
  
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  final DatabaseService _databaseService = DatabaseService();
  final LocalNotificationService _notificationService = LocalNotificationService();
  
  // Track booked time slots for the selected doctor and date
  List<String> _bookedTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.preSelectedDoctor;
    if (_selectedDoctor != null) {
      _currentStep = 1; // Skip doctor selection if pre-selected
      _loadBookedTimeSlots();
    }
  }
  
  /// Load booked time slots for the selected doctor and date
  Future<void> _loadBookedTimeSlots() async {
    if (_selectedDoctor == null) return;
    
    try {
      // Get all appointments for this doctor
      final appointmentsData = await _databaseService.getUserAppointments(
        _selectedDoctor!.id,
        isDoctor: true,
      );
      
      // Filter appointments for the selected date
      final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      _bookedTimeSlots = [];
      for (final aptData in appointmentsData) {
        try {
          final dateTimeStr = aptData['dateTime'] ?? aptData['appointmentTime'];
          if (dateTimeStr == null) continue;
          
          DateTime aptDateTime;
          if (dateTimeStr is Timestamp) {
            aptDateTime = dateTimeStr.toDate();
          } else if (dateTimeStr is String) {
            aptDateTime = DateTime.parse(dateTimeStr);
          } else {
            continue;
          }
          
          // Check if appointment is on the selected date
          final aptDateStr = '${aptDateTime.year}-${aptDateTime.month.toString().padLeft(2, '0')}-${aptDateTime.day.toString().padLeft(2, '0')}';
          if (aptDateStr == selectedDateStr) {
            // Only mark as booked if status is pending or confirmed
            final status = aptData['status'] ?? 'pending';
            if (status == 'pending' || status == 'confirmed') {
              final hour = aptDateTime.hour.toString().padLeft(2, '0');
              final minute = aptDateTime.minute.toString().padLeft(2, '0');
              _bookedTimeSlots.add('$hour:$minute');
            }
          }
        } catch (e) {
          debugPrint('Error parsing appointment date: $e');
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading booked time slots: $e');
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(isDark),
          
          // Content
          Expanded(
            child: _buildStepContent(isDark),
          ),
          
          // Bottom navigation buttons
          _buildBottomButtons(isDark),
        ],
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator(bool isDark) {
    final steps = _selectedDoctor != null 
        ? ['Date', 'Time', 'Details', 'Confirm']
        : ['Doctor', 'Date', 'Time', 'Details', 'Confirm'];
    
    final adjustedStep = _selectedDoctor != null ? _currentStep : _currentStep;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == adjustedStep;
          final isCompleted = index < adjustedStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? AppColors.primaryNavyBlue
                              : isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? AppColors.primaryNavyBlue
                              : isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isCompleted
                        ? AppColors.primaryNavyBlue
                        : isDark
                            ? Colors.grey[700]
                            : Colors.grey[300],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Build step content
  Widget _buildStepContent(bool isDark) {
    if (_selectedDoctor == null && _currentStep == 0) {
      return _buildDoctorSelectionStep(isDark);
    }

    final adjustedStep = _selectedDoctor != null ? _currentStep : _currentStep - 1;

    switch (adjustedStep) {
      case 0:
        return _buildDateSelectionStep(isDark);
      case 1:
        return _buildTimeSelectionStep(isDark);
      case 2:
        return _buildDetailsStep(isDark);
      case 3:
        return _buildConfirmationStep(isDark);
      default:
        return const SizedBox();
    }
  }

  /// Step 1: Doctor Selection (if not pre-selected)
  Widget _buildDoctorSelectionStep(bool isDark) {
    return FutureBuilder<List<Doctor>>(
      future: _loadDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading doctors'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No doctors available',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check back later',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select a Doctor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose from available healthcare providers',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            
            ...doctors.map((doctor) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDoctor = doctor;
                  _currentStep++;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                      backgroundImage: doctor.photoUrl != null 
                          ? NetworkImage(doctor.photoUrl!) 
                          : null,
                      child: doctor.photoUrl == null
                          ? Text(
                              doctor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppColors.primaryNavyBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor.specialty,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor.rating} (${doctor.totalReviews} reviews)',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${doctor.experienceYears} yrs exp',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        }),
          ],
        );
      },
    );
  }

  /// Load doctors from database
  Future<List<Doctor>> _loadDoctors() async {
    try {
      final doctors = await _databaseService.getVerifiedDoctors();
      
      // Convert UserModel to Doctor model
      return doctors.map((user) {
        // Parse available days
        List<String> availableDays = [];
        if (user.availableDays != null) {
          availableDays = user.availableDays!;
        } else {
          // Default to weekdays if not specified
          availableDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
        }
        
        // Parse time slots from available time range
        List<TimeSlot> timeSlots = [];
        if (user.availableTimeStart != null && user.availableTimeEnd != null) {
          timeSlots = _generateTimeSlots(
            user.availableTimeStart!,
            user.availableTimeEnd!,
          );
        } else {
          timeSlots = _getDefaultTimeSlots();
        }
        
        return Doctor(
          id: user.id,
          name: user.name,
          specialization: user.specialty ?? 'General Physician',
          experience: user.yearsOfExperience ?? 0,
          rating: 4.5, // Default rating, should be calculated from reviews
          photoUrl: user.profileImageUrl,
          isVerified: user.isVerifiedDoctor,
          bio: user.bio,
          qualifications: user.qualification != null ? [user.qualification!] : null,
          clinicName: user.hospitalAffiliation,
          languages: ['English', 'Nepali'], // Default, should be stored in user model
          availableDays: availableDays,
          timeSlots: timeSlots,
          totalReviews: 0, // Should be calculated from reviews
          consultationFee: user.consultationFee ?? 500.0,
          isAvailable: true,
          isAvailableNow: user.isAvailableNow,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      // Fallback to sample doctors
      return getSampleDoctors();
    }
  }

  /// Generate time slots from time range
  List<TimeSlot> _generateTimeSlots(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) {
        throw Exception('Invalid time format');
      }
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      final start = startHour * 60 + startMinute;
      final end = endHour * 60 + endMinute;
      
      List<TimeSlot> slots = [];
      for (int time = start; time < end; time += 30) {
        final hour = (time ~/ 60).toString().padLeft(2, '0');
        final minute = (time % 60).toString().padLeft(2, '0');
        final slotStart = '$hour:$minute';
        final slotEnd = '${((time + 30) ~/ 60).toString().padLeft(2, '0')}:${((time + 30) % 60).toString().padLeft(2, '0')}';
        slots.add(TimeSlot(
          startTime: slotStart,
          endTime: slotEnd,
          isAvailable: true, // Explicitly set as available
        ));
      }
      return slots;
    } catch (e) {
      debugPrint('Error generating time slots: $e');
      return _getDefaultTimeSlots();
    }
  }

  /// Step 2: Date Selection
  Widget _buildDateSelectionStep(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose an available date for your appointment',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        
        // Calendar view
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDate, selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTimeSlot = null; // Reset time slot
                  });
                  // Reload booked time slots for the new date
                  if (_selectedDoctor != null) {
                    _loadBookedTimeSlots();
                  }
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.all,
              enabledDayPredicate: (day) {
                if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                  return false;
                }
                if (_selectedDoctor == null) return true;
                final dayName = _getDayName(day.weekday);
                return _selectedDoctor!.availableDays.contains(dayName);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
                defaultTextStyle: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: TextStyle(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Selected date display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primaryNavyBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 3: Time Selection
  Widget _buildTimeSelectionStep(bool isDark) {
    // If doctor is available now, show immediate booking option
    final canBookNow = _selectedDoctor?.isAvailableNow ?? false;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Select Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          canBookNow
              ? 'Doctor is available now! You can book immediately or choose a time slot'
              : 'Choose an available time slot',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        
        // Immediate booking option
        if (canBookNow) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppColors.successGreen.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = TimeSlot(
                    startTime: DateTime.now().toString().substring(11, 16),
                    endTime: DateTime.now().add(const Duration(minutes: 30)).toString().substring(11, 16),
                    isAvailable: true,
                  );
                  _selectedDate = DateTime.now();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start consultation immediately',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _selectedTimeSlot != null && _selectedTimeSlot!.startTime == DateTime.now().toString().substring(11, 16)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: AppColors.successGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
        ],
        
        // Time slots selector
        if (_selectedDoctor != null)
          TimeSlotSelector(
            timeSlots: _getAvailableTimeSlots(),
            selectedDate: _selectedDate,
            selectedSlot: _selectedTimeSlot,
            onSlotSelected: (slot) {
              setState(() {
                _selectedTimeSlot = slot;
              });
            },
          ),
      ],
    );
  }

  /// Step 4: Enter Details
  Widget _buildDetailsStep(bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Consultation Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about your health concern',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Consultation Type
          Text(
            'Consultation Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildConsultationTypeChip('video', 'Video Call', Icons.videocam, isDark),
              const SizedBox(width: 8),
              _buildConsultationTypeChip('voice', 'Voice Call', Icons.phone, isDark),
              const SizedBox(width: 8),
              _buildConsultationTypeChip('chat', 'Chat', Icons.chat, isDark),
            ],
          ),
          const SizedBox(height: 24),
          
          // Symptoms
          TextFormField(
            controller: _symptomsController,
            decoration: InputDecoration(
              labelText: 'Symptoms *',
              hintText: 'Describe your symptoms',
              prefixIcon: const Icon(Icons.healing),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your symptoms';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Additional Notes
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any other information',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// Build consultation type chip
  Widget _buildConsultationTypeChip(String type, String label, IconData icon, bool isDark) {
    final isSelected = _selectedConsultationType == type;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedConsultationType = type;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNavyBlue
                : isDark
                    ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                    : AppColors.backgroundOffWhite,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNavyBlue
                  : isDark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primaryNavyBlue,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 5: Confirmation
  Widget _buildConfirmationStep(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Confirm Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review your appointment details',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        
        // Doctor info
        if (_selectedDoctor != null) ...[
          _buildConfirmationSection(
            'Doctor Information',
            [
              _buildConfirmationRow(Icons.person, 'Name', _selectedDoctor!.name, isDark),
              _buildConfirmationRow(Icons.medical_services, 'Specialty', _selectedDoctor!.specialty, isDark),
              _buildConfirmationRow(Icons.star, 'Rating', '${_selectedDoctor!.rating} (${_selectedDoctor!.totalReviews} reviews)', isDark),
            ],
            isDark,
          ),
          const SizedBox(height: 16),
        ],
        
        // Appointment details
        _buildConfirmationSection(
          'Appointment Details',
          [
            _buildConfirmationRow(Icons.calendar_today, 'Date', _formatDate(_selectedDate), isDark),
            _buildConfirmationRow(Icons.access_time, 'Time', _selectedTimeSlot?.startTime ?? 'Not selected', isDark),
            _buildConfirmationRow(Icons.video_call, 'Type', _getConsultationTypeLabel(), isDark),
          ],
          isDark,
        ),
        const SizedBox(height: 16),
        
        // Symptoms
        _buildConfirmationSection(
          'Symptoms',
          [
            Text(
              _symptomsController.text.trim(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
          isDark,
        ),
        
        if (_notesController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildConfirmationSection(
            'Additional Notes',
            [
              Text(
                _notesController.text.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
            isDark,
          ),
        ],
        
        // Fee
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consultation Fee',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rs. ${_selectedDoctor?.consultationFee.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavyBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build confirmation section
  Widget _buildConfirmationSection(String title, List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Build confirmation row
  Widget _buildConfirmationRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryNavyBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom buttons
  Widget _buildBottomButtons(bool isDark) {
    return Container(
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_getNextButtonLabel()),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if can proceed to next step
  bool _canProceed() {
    if (_isLoading) return false;
    
    final adjustedStep = _selectedDoctor != null ? _currentStep : _currentStep - 1;
    
    switch (adjustedStep) {
      case -1: // Doctor selection
        return _selectedDoctor != null;
      case 0: // Date selection
        return true;
      case 1: // Time selection
        return _selectedTimeSlot != null;
      case 2: // Details
        return _symptomsController.text.trim().isNotEmpty;
      case 3: // Confirmation
        return true;
      default:
        return false;
    }
  }

  /// Get next button label
  String _getNextButtonLabel() {
    final totalSteps = _selectedDoctor != null ? 4 : 5;
    if (_currentStep == totalSteps - 1) {
      return 'Confirm Booking';
    }
    return 'Continue';
  }

  /// Handle next button press
  Future<void> _handleNext() async {
    final totalSteps = _selectedDoctor != null ? 4 : 5;
    
    // Load booked time slots when moving to date/time selection steps
    if (_currentStep == 0 && _selectedDoctor != null) {
      // Moving from doctor selection to date selection
      await _loadBookedTimeSlots();
    } else if (_currentStep == 1 && _selectedDoctor != null) {
      // Moving from date selection to time selection
      await _loadBookedTimeSlots();
    }
    
    if (_currentStep == totalSteps - 1) {
      // Last step - book appointment
      await _bookAppointment();
    } else {
      // Move to next step
      setState(() {
        _currentStep++;
      });
    }
  }

  /// Book appointment
  Future<void> _bookAppointment() async {
    if (_selectedDoctor == null || _selectedTimeSlot == null) return;
    
    // Validate form if form key is available
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      // Go back to details step if validation fails
      setState(() {
        _currentStep = _selectedDoctor != null ? 2 : 3;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final currentUser = appProvider.currentUser;
      
      // Check if user is logged in and not a guest
      if (currentUser == null || currentUser.isGuest || currentUser.id == 'guest') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to book an appointment'),
              backgroundColor: AppColors.secondaryCrimsonRed,
            ),
          );
          // Navigate to auth screen
          Navigator.of(context).pop();
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Combine date and time
      final timeParts = _selectedTimeSlot!.startTime.split(':');
      if (timeParts.length < 2) {
        throw Exception('Invalid time slot format');
      }
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Create appointment data (use both dateTime and appointmentTime for compatibility)
      final dateTimeStr = appointmentDateTime.toIso8601String();
      final appointmentData = {
        'patientId': currentUser.id,
        'patientName': currentUser.name,
        'doctorId': _selectedDoctor!.id,
        'doctorName': _selectedDoctor!.name,
        'doctorPhotoUrl': _selectedDoctor!.photoUrl,
        'doctorSpecialty': _selectedDoctor!.specialization,
        'dateTime': dateTimeStr, // Primary field
        'appointmentTime': dateTimeStr, // Backward compatibility
        'type': _selectedConsultationType,
        'status': 'pending',
        'symptoms': _symptomsController.text.trim(),
        'notes': _notesController.text.trim(),
        'consultationFee': _selectedDoctor!.consultationFee,
      };

      // Save to Firebase
      debugPrint('💾 Saving appointment to Firebase...');
      final appointmentId = await _databaseService.createAppointment(appointmentData);
      debugPrint('✅ Appointment saved with ID: $appointmentId');

      // Schedule notification reminders
      try {
        await _notificationService.initialize();
        await _notificationService.scheduleAppointmentReminders(
          appointmentId: appointmentId,
          doctorName: _selectedDoctor!.name,
          appointmentDateTime: appointmentDateTime,
        );
      } catch (e) {
        debugPrint('⚠️ Error scheduling notifications: $e');
        // Don't fail the booking if notifications fail
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a moment before navigating to ensure data is saved
        await Future.delayed(const Duration(milliseconds: 500));
        
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get sample doctors for testing
  List<Doctor> getSampleDoctors() {
    return [
      Doctor(
        id: '1',
        name: 'Dr. Rajesh Kumar',
        specialization: 'Cardiology',
        experience: 10,
        rating: 4.8,
        totalReviews: 120,
        consultationFee: 500.0,
        availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        timeSlots: _getDefaultTimeSlots(),
        languages: ['English', 'Nepali', 'Hindi'],
      ),
      Doctor(
        id: '2',
        name: 'Dr. Maya Shrestha',
        specialization: 'Dermatology',
        experience: 7,
        rating: 4.5,
        totalReviews: 85,
        consultationFee: 600.0,
        availableDays: ['Monday', 'Wednesday', 'Friday', 'Saturday'],
        timeSlots: _getDefaultTimeSlots(),
        languages: ['English', 'Nepali'],
      ),
      Doctor(
        id: '3',
        name: 'Dr. Suresh Thapa',
        specialization: 'Pediatrics',
        experience: 12,
        rating: 4.9,
        totalReviews: 200,
        consultationFee: 700.0,
        availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        timeSlots: _getDefaultTimeSlots(),
        languages: ['English', 'Nepali', 'Newari'],
      ),
    ];
  }
  
  /// Get available time slots (filter out booked ones)
  List<TimeSlot> _getAvailableTimeSlots() {
    final allSlots = _selectedDoctor?.timeSlots.isNotEmpty == true
        ? _selectedDoctor!.timeSlots
        : _getDefaultTimeSlots();
    
    // Mark booked slots as unavailable
    return allSlots.map((slot) {
      final isBooked = _bookedTimeSlots.contains(slot.startTime);
      return slot.copyWith(isAvailable: !isBooked);
    }).toList();
  }

  /// Get default time slots
  List<TimeSlot> _getDefaultTimeSlots() {
    return [
      TimeSlot(startTime: '09:00', endTime: '09:30', isAvailable: true),
      TimeSlot(startTime: '09:30', endTime: '10:00', isAvailable: true),
      TimeSlot(startTime: '10:00', endTime: '10:30', isAvailable: true),
      TimeSlot(startTime: '10:30', endTime: '11:00', isAvailable: true),
      TimeSlot(startTime: '11:00', endTime: '11:30', isAvailable: true),
      TimeSlot(startTime: '11:30', endTime: '12:00', isAvailable: true),
      TimeSlot(startTime: '14:00', endTime: '14:30', isAvailable: true),
      TimeSlot(startTime: '14:30', endTime: '15:00', isAvailable: true),
      TimeSlot(startTime: '15:00', endTime: '15:30', isAvailable: true),
      TimeSlot(startTime: '15:30', endTime: '16:00', isAvailable: true),
      TimeSlot(startTime: '16:00', endTime: '16:30', isAvailable: true),
      TimeSlot(startTime: '16:30', endTime: '17:00', isAvailable: true),
    ];
  }

  /// Helper methods
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getConsultationTypeLabel() {
    switch (_selectedConsultationType) {
      case 'video':
        return 'Video Call';
      case 'voice':
        return 'Voice Call';
      case 'chat':
        return 'Chat';
      default:
        return _selectedConsultationType;
    }
  }
}