import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/settings_screen.dart';
import 'package:connect_well_nepal/screens/appointment_screen.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:connect_well_nepal/models/appointment_model.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// DoctorDashboardScreen - Home screen for doctors/care providers
///
/// Shows:
/// - Today's appointments
/// - Patient requests
/// - Schedule overview
/// - Quick stats
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Appointment> _todayAppointments = [];
  List<Appointment> _pendingRequests = [];
  bool _isLoadingAppointments = true;
  int _totalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  /// Load appointments for doctor
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final currentUser = appProvider.currentUser;
      
      if (currentUser == null || currentUser.isGuest || currentUser.id == 'guest') {
        setState(() {
          _todayAppointments = [];
          _pendingRequests = [];
          _isLoadingAppointments = false;
        });
        return;
      }

      final appointmentsData = await _databaseService.getUserAppointments(
        currentUser.id,
        isDoctor: true,
      );

      final appointments = appointmentsData
          .map((data) {
            try {
              final dateTimeStr = data['dateTime'] ?? data['appointmentTime'];
              if (dateTimeStr == null) return null;
              
              return Appointment.fromMap({
                ...data,
                'dateTime': dateTimeStr,
                'appointmentTime': dateTimeStr,
                'createdAt': data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
                'updatedAt': data['updatedAt']?.toString(),
              });
            } catch (e) {
              debugPrint('Error parsing appointment: $e');
              return null;
            }
          })
          .whereType<Appointment>()
          .toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Today's appointments (confirmed and upcoming)
      _todayAppointments = appointments
          .where((apt) => 
              apt.status == 'confirmed' && 
              apt.dateTime.isAfter(now) &&
              apt.dateTime.isBefore(tomorrow))
          .toList();
      _todayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Pending requests
      _pendingRequests = appointments
          .where((apt) => apt.status == 'pending')
          .toList();
      _pendingRequests.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Count unique patients
      final patientIds = appointments
          .map((apt) => apt.patientId)
          .toSet();
      _totalPatients = patientIds.length;

    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  /// Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = appProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logos/logo_icon.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Doctor Portal'),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.doctorTitle ?? 'Doctor',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                      ),
                    ),
                    if (user?.specialty != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCrimsonRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user!.specialty!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryCrimsonRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Profile Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryNavyBlue,
                      AppColors.secondaryCrimsonRed,
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                  child: Text(
                    user?.initials ?? 'D',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Verification Status Banner
          if (user?.isVerifiedDoctor != true)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your credentials are being verified. You\'ll receive full access once approved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  value: '${_todayAppointments.length}',
                  label: "Today's\nAppointments",
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_actions,
                  value: '${_pendingRequests.length}',
                  label: 'Pending\nRequests',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  value: '$_totalPatients',
                  label: 'Total\nPatients',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Today's Schedule Section
          _buildSectionHeader('Today\'s Schedule', onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            );
          }),
          const SizedBox(height: 12),

          // Appointment Cards
          if (_isLoadingAppointments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_todayAppointments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No appointments today',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._todayAppointments.take(3).map((appointment) {
              return _buildAppointmentCardFromModel(appointment, isDark);
            }),

          const SizedBox(height: 24),

          // Patient Requests Section
          _buildSectionHeader('New Patient Requests', onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            );
          }),
          const SizedBox(height: 12),

          if (_pendingRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.pending_outlined,
                    size: 48,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._pendingRequests.take(2).map((appointment) {
              return _buildPatientRequestCardFromAppointment(appointment, isDark);
            }),

          const SizedBox(height: 24),

          // Quick Actions
          _buildSectionHeader('Quick Actions', onSeeAll: null),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.schedule,
                  label: 'Manage\nSchedule',
                  color: AppColors.primaryNavyBlue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule management coming soon!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.videocam,
                  label: 'Start Video\nConsultation',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video consultation coming soon!')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.note_add,
                  label: 'Write\nPrescription',
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription feature coming soon!')),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Earnings Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryNavyBlue,
                  const Color(0xFF2A4A7F),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'This Month\'s Earnings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'NPR 45,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+12%',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'from last month',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primaryNavyBlue,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build appointment card from Appointment model
  Widget _buildAppointmentCardFromModel(Appointment appointment, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to appointment details or start consultation
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                child: Text(
                  appointment.patientName.isNotEmpty 
                      ? appointment.patientName[0].toUpperCase() 
                      : 'P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavyBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.formattedTime,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          appointment.type == 'video' 
                              ? Icons.videocam 
                              : appointment.type == 'voice'
                                  ? Icons.phone
                                  : Icons.chat,
                          size: 14,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.type == 'video' 
                              ? 'Video' 
                              : appointment.type == 'voice'
                                  ? 'Voice'
                                  : 'Chat',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: appointment.canJoin 
                    ? () {
                        // TODO: Navigate to consultation screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Starting ${appointment.type} consultation...'),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appointment.canJoin 
                      ? AppColors.successGreen 
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  appointment.canJoin ? 'Start' : 'Upcoming',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Build patient request card from Appointment model
  Widget _buildPatientRequestCardFromAppointment(Appointment appointment, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                  child: Text(
                    appointment.patientName.isNotEmpty 
                        ? appointment.patientName[0].toUpperCase() 
                        : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavyBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.symptoms ?? 'No symptoms provided',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${appointment.formattedDate} at ${appointment.formattedTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await _databaseService.updateAppointmentStatus(
                          appointment.id,
                          'confirmed',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment confirmed'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                          await _loadAppointments();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.secondaryCrimsonRed,
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGreen,
                      side: const BorderSide(color: AppColors.successGreen),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await _databaseService.cancelAppointment(
                          appointment.id,
                          'Declined by doctor',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment declined'),
                              backgroundColor: AppColors.secondaryCrimsonRed,
                            ),
                          );
                          await _loadAppointments();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.secondaryCrimsonRed,
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryCrimsonRed,
                      side: const BorderSide(color: AppColors.secondaryCrimsonRed),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

