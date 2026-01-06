// lib/screens/appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../utils/colors.dart';
import '../widgets/appointment_card.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/local_notification_service.dart';
import 'booking_screen.dart';
import 'doctor_profile_screen.dart';
import 'schedule_management_screen.dart';
import 'video_call_screen.dart';

/// Main appointments screen showing upcoming and past appointments
/// Includes tabs for filtering and quick booking action
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  
  // Calendar state for doctors
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  final DatabaseService _databaseService = DatabaseService();
  final LocalNotificationService _notificationService = LocalNotificationService();

  DateTime? _lastRefreshTime;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
    _lastRefreshTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh if it's been more than 2 seconds since last refresh
    // This prevents infinite loops but allows refresh when tab is selected
    final now = DateTime.now();
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!).inSeconds > 2) {
      _lastRefreshTime = now;
      _loadAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load appointments from Firebase
  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final currentUser = appProvider.currentUser;
      
      debugPrint('📋 _loadAppointments called');
      debugPrint('📋 Current user: ${currentUser?.id ?? "null"}, isGuest: ${currentUser?.isGuest ?? "null"}');
      
      // Check if user is null or guest - use sample data
      if (currentUser == null || currentUser.isGuest) {
        debugPrint('📋 User is null or guest, loading sample appointments');
        // Load sample appointments for guests or when not logged in
        _loadSampleAppointments();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('📋 Loading appointments for user: ${currentUser.id}, isDoctor: ${currentUser.isDoctor}');
      
      // Load from Firebase only for authenticated users
      final appointmentsData = await _databaseService.getUserAppointments(
        currentUser.id,
        isDoctor: currentUser.isDoctor,
      );

      debugPrint('📋 Found ${appointmentsData.length} appointment records from Firebase');
      
      if (appointmentsData.isEmpty) {
        debugPrint('📋 No appointments found in Firebase for user ${currentUser.id}');
        _appointments = [];
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      _appointments = appointmentsData
          .map((data) {
            try {
              // Ensure id is set
              final appointmentId = data['id'] ?? '';
              if (appointmentId.isEmpty) {
                debugPrint('⚠️ Appointment missing id, skipping');
                return null;
              }
              
              // Handle both 'dateTime' and 'appointmentTime' fields
              final dateTimeValue = data['dateTime'] ?? data['appointmentTime'];
              if (dateTimeValue == null) {
                debugPrint('⚠️ Appointment $appointmentId missing dateTime, skipping');
                return null;
              }
              
              // Handle Timestamp objects from Firestore
              String dateTimeStrFinal;
              if (dateTimeValue is Timestamp) {
                dateTimeStrFinal = dateTimeValue.toDate().toIso8601String();
              } else if (dateTimeValue is String) {
                dateTimeStrFinal = dateTimeValue;
              } else {
                debugPrint('⚠️ Invalid dateTime format for $appointmentId: $dateTimeValue (${dateTimeValue.runtimeType})');
                return null;
              }
              
              // Handle createdAt
              String createdAtStr;
              final createdAtValue = data['createdAt'];
              if (createdAtValue is Timestamp) {
                createdAtStr = createdAtValue.toDate().toIso8601String();
              } else if (createdAtValue is String) {
                createdAtStr = createdAtValue;
              } else {
                createdAtStr = DateTime.now().toIso8601String();
              }
              
              // Handle updatedAt
              String? updatedAtStr;
              final updatedAtValue = data['updatedAt'];
              if (updatedAtValue != null) {
                if (updatedAtValue is Timestamp) {
                  updatedAtStr = updatedAtValue.toDate().toIso8601String();
                } else if (updatedAtValue is String) {
                  updatedAtStr = updatedAtValue;
                }
              }
              
              final appointment = Appointment.fromMap({
                ...data,
                'id': appointmentId,
                'dateTime': dateTimeStrFinal,
                'appointmentTime': dateTimeStrFinal,
                'createdAt': createdAtStr,
                'updatedAt': updatedAtStr,
              });
              
              debugPrint('✅ Parsed appointment: ${appointment.id}, patient: ${appointment.patientId}, doctor: ${appointment.doctorId}, status: ${appointment.status}, dateTime: ${appointment.dateTime}');
              return appointment;
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing appointment: $e');
              debugPrint('   Data: $data');
              debugPrint('   Stack: $stackTrace');
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();
      
      debugPrint('✅ Successfully loaded ${_appointments.length} appointments');
      
      // Log upcoming vs past breakdown
      final upcoming = _appointments.where((apt) => apt.isUpcoming).length;
      final past = _appointments.where((apt) => apt.isPast).length;
      debugPrint('📋 Breakdown: $upcoming upcoming, $past past');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading appointments: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Don't fallback to sample data - show empty state instead
      _appointments = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Load sample appointments for testing/fallback
  void _loadSampleAppointments() {
    final doctors = getSampleDoctors();
    
    _appointments = [
      // Upcoming appointment
      Appointment(
        id: 'apt1',
        patientId: 'patient1',
        patientName: 'Current User',
        doctorId: doctors[0].id,
        doctorName: doctors[0].name,
        doctorPhotoUrl: null,
        doctorSpecialty: doctors[0].specialization,
        dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
        type: 'video',
        status: 'confirmed',
        symptoms: 'Fever and headache for 3 days',
        notes: 'Please bring previous medical records',
        consultationFee: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      // Today's appointment
      Appointment(
        id: 'apt2',
        patientId: 'patient1',
        patientName: 'Current User',
        doctorId: doctors[1].id,
        doctorName: doctors[1].name,
        doctorPhotoUrl: null,
        doctorSpecialty: doctors[1].specialization,
        dateTime: DateTime.now().add(const Duration(hours: 2)),
        type: 'voice',
        status: 'confirmed',
        symptoms: 'Follow-up consultation',
        consultationFee: 600.0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      // Past completed appointment
      Appointment(
        id: 'apt3',
        patientId: 'patient1',
        patientName: 'Current User',
        doctorId: doctors[2].id,
        doctorName: doctors[2].name,
        doctorPhotoUrl: null,
        doctorSpecialty: doctors[2].specialization,
        dateTime: DateTime.now().subtract(const Duration(days: 7)),
        type: 'video',
        status: 'completed',
        symptoms: 'Skin rash on arms',
        consultationFee: 700.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        rating: 5.0,
        review: 'Excellent consultation, very helpful!',
      ),
      // Past cancelled appointment
      Appointment(
        id: 'apt4',
        patientId: 'patient1',
        patientName: 'Current User',
        doctorId: doctors[0].id,
        doctorName: doctors[0].name,
        doctorPhotoUrl: null,
        doctorSpecialty: doctors[0].specialization,
        dateTime: DateTime.now().subtract(const Duration(days: 15)),
        type: 'chat',
        status: 'cancelled',
        symptoms: 'General checkup',
        consultationFee: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        cancellationReason: 'Patient requested cancellation',
      ),
    ];
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
      ),
      Doctor(
        id: '2',
        name: 'Dr. Maya Shrestha',
        specialization: 'Dermatology',
        experience: 7,
        rating: 4.5,
      ),
      Doctor(
        id: '3',
        name: 'Dr. Suresh Thapa',
        specialization: 'Pediatrics',
        experience: 12,
        rating: 4.9,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appProvider = context.watch<AppProvider>();
    final currentUser = appProvider.currentUser;
    final isDoctor = currentUser?.isDoctor ?? false;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text(isDoctor ? 'My Schedule' : 'Appointments'),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryNavyBlue,
                labelColor: AppColors.primaryNavyBlue,
                unselectedLabelColor:
                    isDark ? Colors.grey[400] : Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(text: isDoctor ? 'Today & Upcoming' : 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // For doctors: Show calendar view, for patients: Show list
            isDoctor
                ? _buildDoctorScheduleView(isDark)
                : _buildAppointmentsList(
                    appointments: _appointments
                        .where((apt) => apt.isUpcoming)
                        .toList(),
                    emptyMessage: 'No upcoming appointments',
                    emptyIcon: Icons.calendar_today,
                    isDark: isDark,
                    isDoctor: isDoctor,
                  ),
            // Past appointments
            _buildAppointmentsList(
              appointments: _appointments
                  .where((apt) => apt.isPast)
                  .toList(),
              emptyMessage: isDoctor
                  ? 'No past appointments'
                  : 'No past appointments',
              emptyIcon: Icons.history,
              isDark: isDark,
              isDoctor: isDoctor,
            ),
          ],
        ),
      ),

      // Floating action button - show different for doctors vs patients
      floatingActionButton: isDoctor
          ? FloatingActionButton.extended(
              heroTag: 'appointment_doctor_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScheduleManagementScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primaryNavyBlue,
              icon: const Icon(Icons.schedule),
              label: const Text('Manage Schedule'),
            )
          : FloatingActionButton.extended(
              heroTag: 'appointment_patient_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingScreen(),
                  ),
                );
                
                // Reload appointments if booking was successful
                if (result == true && mounted) {
                  await _loadAppointments();
                }
              },
              backgroundColor: AppColors.primaryNavyBlue,
              icon: const Icon(Icons.add),
              label: const Text('Book Appointment'),
            ),
    );
  }

  /// Build appointments list
  Widget _buildAppointmentsList({
    required List<Appointment> appointments,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isDark,
    required bool isDoctor,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon, isDark);
    }

    // Sort appointments by date (upcoming: ascending, past: descending)
    if (appointments.isNotEmpty) {
      final isUpcomingTab = appointments.first.isUpcoming;
      appointments.sort((a, b) => isUpcomingTab 
          ? a.dateTime.compareTo(b.dateTime) 
          : b.dateTime.compareTo(a.dateTime));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          
          return AppointmentCard(
            appointment: appointment,
            isDoctorView: isDoctor,
            onTap: () {
              _showAppointmentDetails(appointment, isDoctor);
            },
            onCancel: appointment.isUpcoming && !isDoctor
                ? () => _cancelAppointment(appointment)
                : null,
            onReschedule: appointment.isUpcoming && !isDoctor
                ? () => _rescheduleAppointment(appointment)
                : null,
            onAccept: appointment.isUpcoming && isDoctor && appointment.status == 'pending'
                ? () => _acceptAppointment(appointment)
                : null,
            onReject: appointment.isUpcoming && isDoctor && appointment.status == 'pending'
                ? () => _rejectAppointment(appointment)
                : null,
            onJoin: appointment.canJoin
                ? () => _joinConsultation(appointment)
                : null,
            onRate: appointment.status == 'completed' && appointment.rating == null && !isDoctor
                ? () => _rateAppointment(appointment)
                : null,
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first appointment',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookingScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Book Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show appointment details
  void _showAppointmentDetails(Appointment appointment, bool isDoctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Doctor/Patient info card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                                backgroundImage: isDoctor
                                    ? null // Patient doesn't have photo URL in appointment
                                    : (appointment.doctorPhotoUrl != null
                                        ? NetworkImage(appointment.doctorPhotoUrl!)
                                        : null),
                                child: isDoctor
                                    ? Text(
                                        appointment.patientName.isNotEmpty
                                            ? appointment.patientName[0].toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: AppColors.primaryNavyBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : (appointment.doctorPhotoUrl == null
                                        ? Text(
                                            appointment.doctorName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: AppColors.primaryNavyBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDoctor ? appointment.patientName : appointment.doctorName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      isDoctor ? 'Patient' : appointment.doctorSpecialty,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isDoctor)
                                IconButton(
                                  onPressed: () async {
                                    // Try to get doctor from database, fallback to sample
                                    try {
                                      final doctorData = await _databaseService.getDoctor(appointment.doctorId);
                                      if (doctorData != null) {
                                        final doctor = Doctor(
                                          id: doctorData['id'] ?? appointment.doctorId,
                                          name: doctorData['name'] ?? appointment.doctorName,
                                          specialization: doctorData['specialty'] ?? appointment.doctorSpecialty,
                                          experience: doctorData['yearsOfExperience'] ?? 0,
                                          rating: (doctorData['rating'] ?? 0).toDouble(),
                                          photoUrl: doctorData['profileImageUrl'],
                                          isVerified: doctorData['isVerifiedDoctor'] ?? false,
                                          consultationFee: (doctorData['consultationFee'] ?? 500).toDouble(),
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DoctorProfileScreen(doctor: doctor),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    } catch (e) {
                                      debugPrint('Error fetching doctor: $e');
                                    }
                                    
                                    // Fallback to sample doctors
                                    final doctors = getSampleDoctors();
                                    final doctor = doctors.firstWhere(
                                      (d) => d.id == appointment.doctorId,
                                      orElse: () => doctors.first,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DoctorProfileScreen(doctor: doctor),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.info_outline),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Appointment info
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        appointment.formattedDate,
                        isDark,
                      ),
                      _buildDetailRow(
                        Icons.access_time,
                        'Time',
                        appointment.formattedTime,
                        isDark,
                      ),
                      _buildDetailRow(
                        Icons.video_call,
                        'Type',
                        _getConsultationType(appointment.type),
                        isDark,
                      ),
                      _buildDetailRow(
                        Icons.info,
                        'Status',
                        appointment.status.toUpperCase(),
                        isDark,
                      ),
                      _buildDetailRow(
                        Icons.account_balance_wallet,
                        'Fee',
                        'Rs. ${appointment.consultationFee.toStringAsFixed(0)}',
                        isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Symptoms
                      if (appointment.symptoms != null) ...[
                        Text(
                          'Symptoms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                                : AppColors.backgroundOffWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.symptoms!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      
                      // Notes
                      if (appointment.notes != null &&
                          appointment.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                                : AppColors.backgroundOffWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build detail row
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavyBlue),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Cancel appointment
  void _cancelAppointment(Appointment appointment) {
    final appProvider = context.read<AppProvider>();
    final currentUser = appProvider.currentUser;
    
    // Check if user is guest
    if (currentUser == null || currentUser.isGuest || currentUser.id == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to cancel appointments'),
          backgroundColor: AppColors.secondaryCrimsonRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              try {
                // Cancel in Firebase
                await _databaseService.cancelAppointment(
                  appointment.id,
                  'Cancelled by patient',
                );
                
                // Cancel notification reminders
                await _notificationService.cancelAppointmentReminder(appointment.id);
                
                // Reload appointments
                await _loadAppointments();
                
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: AppColors.secondaryCrimsonRed,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling appointment: $e'),
                    backgroundColor: AppColors.secondaryCrimsonRed,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.secondaryCrimsonRed),
            ),
          ),
        ],
      ),
    );
  }

  /// Reschedule appointment
  void _rescheduleAppointment(Appointment appointment) async {
    // Try to get doctor from database
    try {
      final doctorData = await _databaseService.getDoctor(appointment.doctorId);
      Doctor? doctor;
      
      if (doctorData != null) {
        // Parse available days
        List<String> availableDays = doctorData['availableDays'] != null
            ? List<String>.from(doctorData['availableDays'])
            : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
        
        // Parse time slots
        List<TimeSlot> timeSlots = [];
        if (doctorData['availableTimeStart'] != null && doctorData['availableTimeEnd'] != null) {
          timeSlots = _generateTimeSlots(
            doctorData['availableTimeStart'],
            doctorData['availableTimeEnd'],
          );
        } else {
          timeSlots = _getDefaultTimeSlots();
        }
        
        doctor = Doctor(
          id: doctorData['id'] ?? appointment.doctorId,
          name: doctorData['name'] ?? appointment.doctorName,
          specialization: doctorData['specialty'] ?? appointment.doctorSpecialty,
          experience: doctorData['yearsOfExperience'] ?? 0,
          rating: (doctorData['rating'] ?? 4.5).toDouble(),
          photoUrl: doctorData['profileImageUrl'] ?? appointment.doctorPhotoUrl,
          isVerified: doctorData['isVerifiedDoctor'] ?? false,
          consultationFee: (doctorData['consultationFee'] ?? 500).toDouble(),
          availableDays: availableDays,
          timeSlots: timeSlots,
        );
      }
      
      // Fallback to sample doctors if database fetch fails
      if (doctor == null) {
        final sampleDoctors = getSampleDoctors();
        doctor = sampleDoctors.firstWhere(
          (d) => d.id == appointment.doctorId,
          orElse: () => sampleDoctors.first,
        );
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(
              preSelectedDoctor: doctor,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading doctor for reschedule: $e');
      // Fallback to sample doctors
      final sampleDoctors = getSampleDoctors();
      final doctor = sampleDoctors.firstWhere(
        (d) => d.id == appointment.doctorId,
        orElse: () => sampleDoctors.first,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(
              preSelectedDoctor: doctor,
            ),
          ),
        );
      }
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
        slots.add(TimeSlot(startTime: slotStart, endTime: slotEnd));
      }
      return slots;
    } catch (e) {
      debugPrint('Error generating time slots: $e');
      return _getDefaultTimeSlots();
    }
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

  /// Accept appointment (doctor only)
  void _acceptAppointment(Appointment appointment) async {
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: Text(
          'Confirm appointment with ${appointment.patientName} on ${appointment.formattedDate} at ${appointment.formattedTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _databaseService.updateAppointmentStatus(
                  appointment.id,
                  'confirmed',
                );
                
                await _loadAppointments();
                
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Appointment confirmed! Status updated to Booked.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error accepting appointment: $e'),
                    backgroundColor: AppColors.secondaryCrimsonRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  /// Reject appointment (doctor only)
  void _rejectAppointment(Appointment appointment) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject appointment with ${appointment.patientName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _databaseService.updateAppointmentStatus(
                  appointment.id,
                  'cancelled',
                );
                
                await _loadAppointments();
                
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Appointment rejected'),
                    backgroundColor: AppColors.secondaryCrimsonRed,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error rejecting appointment: $e'),
                    backgroundColor: AppColors.secondaryCrimsonRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryCrimsonRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  /// Join consultation
  void _joinConsultation(Appointment appointment) {
    final appProvider = context.read<AppProvider>();
    final currentUser = appProvider.currentUser;
    
    // Check if user is authenticated
    if (currentUser == null || currentUser.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join consultations'),
          backgroundColor: AppColors.secondaryCrimsonRed,
        ),
      );
      return;
    }
    
    // Generate channel ID based on appointment ID (ensures same channel for patient and doctor)
    final String channelId = 'appointment_${appointment.id}';
    const String token = ''; // Empty token for testing (token-less mode with Agora)
    
    // Determine participant names based on user role
    String? participantName;
    String? participantSpecialty;
    
    if (currentUser.isDoctor) {
      // Doctor viewing - show patient name
      participantName = appointment.patientName;
      participantSpecialty = null;
    } else {
      // Patient viewing - show doctor name
      participantName = appointment.doctorName;
      participantSpecialty = appointment.doctorSpecialty;
    }
    
    // Navigate based on consultation type
    switch (appointment.type) {
      case 'video':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelId: channelId,
              token: token,
              doctorName: currentUser.isDoctor ? null : participantName,
              doctorSpecialty: currentUser.isDoctor ? null : participantSpecialty,
            ),
          ),
        );
        break;
      case 'voice':
        // For voice calls, use the same video call screen but could be voice-only in future
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelId: channelId,
              token: token,
              doctorName: currentUser.isDoctor ? null : participantName,
              doctorSpecialty: currentUser.isDoctor ? null : participantSpecialty,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice call feature - using video call interface'),
            backgroundColor: AppColors.primaryNavyBlue,
          ),
        );
        break;
      case 'chat':
        // Navigate to chat screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat consultation feature coming soon!'),
            backgroundColor: AppColors.primaryNavyBlue,
          ),
        );
        // TODO: Navigate to chat screen when implemented
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => ChatScreen(
        //       conversationId: channelId,
        //       participantName: participantName,
        //     ),
        //   ),
        // );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unknown consultation type: ${appointment.type}'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
    }
  }

  /// Rate appointment
  void _rateAppointment(Appointment appointment) {
    final appProvider = context.read<AppProvider>();
    final currentUser = appProvider.currentUser;
    
    // Check if user is guest
    if (currentUser == null || currentUser.isGuest || currentUser.id == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to rate appointments'),
          backgroundColor: AppColors.secondaryCrimsonRed,
        ),
      );
      return;
    }

    double rating = 5.0;
    final reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate Consultation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How was your consultation with ${appointment.doctorName}?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = (index + 1).toDouble();
                          });
                        },
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Review (Optional)',
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    
                    try {
                      // Save rating to Firebase
                      await _databaseService.addAppointmentRating(
                        appointment.id,
                        rating,
                        reviewController.text.trim().isEmpty
                            ? null
                            : reviewController.text.trim(),
                      );
                      
                      // Reload appointments
                      await _loadAppointments();
                      
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error submitting rating: $e'),
                          backgroundColor: AppColors.secondaryCrimsonRed,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Get consultation type label
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

  /// Build calendar view for doctors
  Widget _buildDoctorScheduleView(bool isDark) {
    // Get appointments for the selected day
    final selectedDayAppointments = _appointments.where((apt) {
      return apt.dateTime.year == _selectedDay.year &&
          apt.dateTime.month == _selectedDay.month &&
          apt.dateTime.day == _selectedDay.day;
    }).toList();
    
    return Column(
      children: [
        // Calendar
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (mounted) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                if (mounted) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                }
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) {
                return _appointments.where((apt) {
                  return apt.dateTime.year == day.year &&
                      apt.dateTime.month == day.month &&
                      apt.dateTime.day == day.day;
                }).map((apt) => apt.id).toList();
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
                  color: AppColors.secondaryCrimsonRed,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                disabledTextStyle: TextStyle(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
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
        
        // Appointments for selected day
        Expanded(
          child: selectedDayAppointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No appointments on ${_formatDate(_selectedDay)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedDayAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = selectedDayAppointments[index];
                    return AppointmentCard(
                      appointment: appointment,
                      isDoctorView: true,
                      onTap: () {
                        _showAppointmentDetails(appointment, true);
                      },
                      onAccept: appointment.status == 'pending'
                          ? () => _acceptAppointment(appointment)
                          : null,
                      onReject: appointment.status == 'pending'
                          ? () => _rejectAppointment(appointment)
                          : null,
                      onJoin: appointment.canJoin
                          ? () => _joinConsultation(appointment)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}