import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/profile_screen.dart';
import 'package:connect_well_nepal/screens/appointment_screen.dart';
import 'package:connect_well_nepal/screens/resources_screen.dart';
import 'package:connect_well_nepal/screens/doctor_dashboard_screen.dart';
import 'package:connect_well_nepal/screens/ai_assistant_screen.dart';
import 'package:connect_well_nepal/screens/all_doctors_screen.dart';
import 'package:connect_well_nepal/screens/all_healthcare_screen.dart';
import 'package:connect_well_nepal/screens/doctor_profile_screen.dart';
import 'package:connect_well_nepal/screens/chat_list_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/models/doctor_model.dart';
import 'package:connect_well_nepal/models/place_model.dart';
import 'package:connect_well_nepal/services/location_service.dart';
import 'package:connect_well_nepal/services/osm_places_service.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// MainScreen - Primary navigation shell of the app
/// 
/// This screen manages the bottom navigation bar and displays:
/// 1. Home Tab: List of nearby clinics + quick actions
/// 2. Appointments Tab: Manage appointments
/// 3. Resources Tab: Health education content
/// 4. Profile Tab: User profile management
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Track currently selected tab (0: Home, 1: Appointments, 2: Resources, 3: Profile)
  int _currentIndex = 0;

  // Services
  final LocationService _locationService = LocationService();
  final OSMPlacesService _placesService = OSMPlacesService();
  final DatabaseService _databaseService = DatabaseService();

  // Places data
  List<PlaceModel> _nearbyHospitals = [];
  List<PlaceModel> _nearbyClinics = [];
  bool _isLoadingPlaces = true;
  String? _locationError;
  
  // Doctors data
  List<Doctor> _availableDoctors = [];
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
    _loadDoctors();
  }
  
  /// Load real doctors from database
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
    });
    
    try {
      final doctors = await _databaseService.getVerifiedDoctors();
      
      // Convert UserModel to Doctor model
      _availableDoctors = await Future.wait(doctors.map((user) async {
        // Parse available days
        List<String> availableDays = [];
        if (user.availableDays != null) {
          availableDays = user.availableDays!;
        } else {
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
        
        // Check if doctor has confirmed appointments happening now
        bool isBusyNow = false;
        try {
          final appointmentsData = await _databaseService.getUserAppointments(
            user.id,
            isDoctor: true,
          );
          
          final now = DateTime.now();
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
              
              final status = aptData['status'] ?? 'pending';
              // Check if there's a confirmed appointment happening now (within 30 minutes)
              if (status == 'confirmed') {
                final difference = aptDateTime.difference(now);
                if (difference.inMinutes >= -15 && difference.inMinutes <= 30) {
                  isBusyNow = true;
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error checking appointment time: $e');
            }
          }
        } catch (e) {
          debugPrint('Error checking doctor busy status: $e');
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
          languages: ['English', 'Nepali'],
          availableDays: availableDays,
          timeSlots: timeSlots,
          totalReviews: 0,
          consultationFee: user.consultationFee ?? 500.0,
          isAvailable: !isBusyNow && (user.isAvailableNow || true), // Available if not busy and has availability set
          isAvailableNow: user.isAvailableNow && !isBusyNow, // Available now only if not busy
        );
      }));
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      // Show empty list if error
      _availableDoctors = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDoctors = false;
        });
      }
    }
  }
  
  /// Generate time slots from time range
  List<TimeSlot> _generateTimeSlots(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) {
        return _getDefaultTimeSlots();
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
          isAvailable: true,
        ));
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

  /// Load nearby hospitals and clinics using OSM (FREE - no billing required!)
  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
      _locationError = null;
    });

    try {
      // Fetch nearby healthcare facilities from OpenStreetMap
      final places = await _placesService.getNearbyHealthcare();
      
      // Separate hospitals and clinics
      final hospitals = places.where((p) => 
        p.types.contains('hospital')
      ).toList();
      final clinics = places.where((p) => 
        p.types.contains('clinic') || !p.types.contains('hospital')
      ).toList();

      setState(() {
        _nearbyHospitals = hospitals.isNotEmpty ? hospitals : places;
        _nearbyClinics = clinics;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error loading nearby places';
        _isLoadingPlaces = false;
      });
      _loadDemoData();
    }
  }

  /// Load demo data when location is unavailable
  void _loadDemoData() {
    // Force load data from OSM (will return demo data if API fails)
    _placesService.getNearbyHealthcare().then((places) {
      if (mounted) {
        final hospitals = places.where((p) => p.types.contains('hospital')).toList();
        final clinics = places.where((p) => !p.types.contains('hospital')).toList();
        setState(() {
          _nearbyHospitals = hospitals.isNotEmpty ? hospitals : places;
          _nearbyClinics = clinics;
          _isLoadingPlaces = false;
        });
      }
    });
  }
  
  /// Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get combined list of clinics and hospitals sorted by distance
  List<PlaceModel> _getCombinedHealthcareFacilities() {
    final combined = [..._nearbyHospitals, ..._nearbyClinics];
    combined.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    return combined;
  }

  /// Show self-care options bottom sheet
  void _showSelfCareOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Self-Care Hub',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Take care of your wellbeing',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Self-care options grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSelfCareOption(
                    icon: Icons.self_improvement,
                    label: 'Meditation',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.fitness_center,
                    label: 'Exercise',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.restaurant,
                    label: 'Nutrition',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.bedtime,
                    label: 'Sleep',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.psychology,
                    label: 'Mental Health',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.favorite,
                    label: 'Heart Health',
                    color: AppColors.secondaryCrimsonRed,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.water_drop,
                    label: 'Hydration',
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hydration tracking coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.mood,
                    label: 'Mood Journal',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mood Journal coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildSelfCareOption(
                    icon: Icons.timer,
                    label: 'Breathing',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      _showBreathingExercise();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: AppColors.primaryNavyBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Taking just 5 minutes for yourself can improve your whole day!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : AppColors.primaryNavyBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelfCareOption({
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreathingExercise() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.timer, color: Colors.teal),
              SizedBox(width: 8),
              Text('Breathing Exercise'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '4-7-8 Breathing Technique',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Breathe in through your nose for 4 seconds'),
              SizedBox(height: 8),
              Text('2. Hold your breath for 7 seconds'),
              SizedBox(height: 8),
              Text('3. Exhale slowly through your mouth for 8 seconds'),
              SizedBox(height: 16),
              Text(
                'Repeat 3-4 times for best results.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the Home tab with greeting, self-care, and doctors
  Widget _buildHomeTab() {
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Well Nepal'),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'assets/logos/logo_icon.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_hospital);
            },
          ),
          onPressed: () {
            // Logo is just decorative, can navigate to home or do nothing
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
            tooltip: 'Messages',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Greeting Section with Profile Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Greeting text
                Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appProvider.displayName,
                        style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.primaryNavyBlue,
                  ),
                ),
                const SizedBox(height: 4),
                      Text(
                  'How can we help you today?',
                  style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Avatar on right
                GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = 3);
                  },
                  child: Container(
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
                      backgroundColor:
                          isDark ? const Color(0xFF1E2A3A) : Colors.white,
                      child: appProvider.currentUser?.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                appProvider.currentUser!.profileImageUrl!,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                              ),
                            )
                          : Text(
                              appProvider.currentUser?.initials ?? 'G',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryNavyBlue,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Self-Care Quick Access Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: _showSelfCareOptions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.purple.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.spa,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Self-Care Hub',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Meditation, Exercise, Nutrition & more',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Self-Care Options Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quick Self-Care',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryNavyBlue,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Self-Care Cards (4 options in a row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSelfCareCard(
                  icon: Icons.self_improvement,
                  label: 'Meditation',
                  color: Colors.purple,
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelfCareCard(
                  icon: Icons.fitness_center,
                  label: 'Exercise',
                  color: Colors.orange,
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelfCareCard(
                  icon: Icons.restaurant,
                  label: 'Nutrition',
                  color: Colors.green,
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelfCareCard(
                  icon: Icons.psychology,
                  label: 'Mental Health',
                  color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Available Doctors Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Doctors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllDoctorsScreen(),
                      ),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Doctor Cards - Load from database
          if (_isLoadingDoctors)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableDoctors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No doctors available',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadDoctors,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableDoctors.take(4).map((doctor) {
              return _buildDoctorCardFromModel(doctor, isDark);
            }),

          // See more doctors button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllDoctorsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryNavyBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See more doctors',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavyBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primaryNavyBlue,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nearby Healthcare Section (Clinics & Hospitals)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Nearby Healthcare',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                      ),
                    ),
                    if (_locationService.hasLocation) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.successGreen,
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllHealthcareScreen(
                          initialPlaces: _getCombinedHealthcareFacilities(),
                        ),
                      ),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Healthcare facilities list (combined clinics & hospitals)
          if (_isLoadingPlaces)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nearbyHospitals.isEmpty && _nearbyClinics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      size: 48,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationError ?? 'No healthcare facilities found nearby',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loadNearbyPlaces,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ..._getCombinedHealthcareFacilities().take(5).map((place) => _buildPlaceCard(place)),
            
            // See more healthcare button
            if (_getCombinedHealthcareFacilities().length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllHealthcareScreen(
                          initialPlaces: _getCombinedHealthcareFacilities(),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryNavyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See more healthcare facilities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavyBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.primaryNavyBlue,
                      ),
                    ],
                  ),
                ),
              ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Build a place card for clinics/hospitals
  Widget _buildPlaceCard(PlaceModel place) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHospital = place.isHospital;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${place.name}...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Place Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isHospital
                      ? AppColors.secondaryCrimsonRed.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHospital ? Icons.local_hospital : Icons.medical_services,
                  size: 28,
                  color: isHospital ? AppColors.secondaryCrimsonRed : Colors.blue,
                ),
              ),

              const SizedBox(width: 14),

              // Place Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Open Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Open/Closed Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: place.isOpen
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: place.isOpen
                                  ? AppColors.successGreen
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isHospital
                            ? AppColors.secondaryCrimsonRed.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        place.typeDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isHospital
                              ? AppColors.secondaryCrimsonRed
                              : Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Rating and Distance Row
                    Row(
                      children: [
                        // Rating
                        if (place.rating != null) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${place.rating}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${place.totalRatings ?? 0})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Distance
                        if (place.distanceText != null) ...[
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            place.distanceText!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Address
                    Text(
                      place.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelfCareCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
        elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            setState(() => _currentIndex = 2); // Go to Resources tab
          },
        borderRadius: BorderRadius.circular(16),
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                child: Icon(icon, size: 28, color: color),
                ),
              const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
          ),
        ),
      ),
    );
  }
  
  /// Build doctor card from Doctor model
  Widget _buildDoctorCardFromModel(Doctor doctor, bool isDark) {
    final available = doctor.isAvailable || doctor.isAvailableNow;
    
    return _buildDoctorCard(
      name: doctor.name,
      specialty: doctor.specialization,
      experience: '${doctor.experienceYears} years',
      rating: doctor.rating,
      available: available,
      doctor: doctor,
    );
  }
  
  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String experience,
    required double rating,
    required bool available,
    Doctor? doctor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final doctorToShow = doctor ?? Doctor(
            id: name.toLowerCase().replaceAll(' ', '_').replaceAll('.', ''),
            name: name,
            specialization: specialty,
            experience: int.tryParse(experience.split(' ')[0]) ?? 0,
            rating: rating,
            isAvailable: available,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(doctor: doctorToShow),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Doctor Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? AppColors.primaryNavyBlue.withValues(alpha: 0.3)
                    : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                backgroundImage: doctor?.photoUrl != null ? NetworkImage(doctor!.photoUrl!) : null,
                child: doctor?.photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 32,
                        color: isDark
                            ? const Color(0xFF5A7BC0)
                            : AppColors.primaryNavyBlue,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Availability
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Availability Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: available 
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: available 
                                      ? AppColors.successGreen 
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                available ? 'Available' : 'Busy',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: available 
                                      ? AppColors.successGreen 
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Specialty
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryCrimsonRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Experience and Rating
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 14,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          experience,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Book Appointment Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: available
                        ? () {
                            final doctorToShow = doctor ?? Doctor(
                              id: name.toLowerCase().replaceAll(' ', '_').replaceAll('.', ''),
                              name: name,
                              specialization: specialty,
                              experience: int.tryParse(experience.split(' ')[0]) ?? 0,
                              rating: rating,
                              isAvailable: available,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorProfileScreen(doctor: doctorToShow),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: available
                          ? AppColors.primaryNavyBlue
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(100, 36),
                    ),
                    child: const Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Returns the appropriate widget based on selected tab
  Widget _getSelectedScreen() {
    final appProvider = context.watch<AppProvider>();
    final isDoctor = appProvider.isHealthcareProfessional;

    switch (_currentIndex) {
      case 0:
        // Show doctor dashboard for doctors, patient home for patients
        return isDoctor ? const DoctorDashboardScreen() : _buildHomeTab();
      case 1:
        return const AppointmentsScreen();
      case 2:
        return const ResourcesScreen();
      case 3:
        return const ProfileScreen();
      default:
        return isDoctor ? const DoctorDashboardScreen() : _buildHomeTab();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Display the selected screen
      body: _getSelectedScreen(),

      // AI Assistant Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
          );
        },
        backgroundColor: AppColors.primaryNavyBlue,
        elevation: 4,
        tooltip: 'AI Health Assistant',
        child: const Icon(
          Icons.psychology_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final isDoctor = appProvider.isHealthcareProfessional;

          return BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh appointments when appointments tab is selected
          if (index == 1) {
            // Trigger refresh by rebuilding the appointments screen
            // The screen will refresh in didChangeDependencies
          }
        },
        type: BottomNavigationBarType.fixed,
            selectedItemColor:
                isDark ? const Color(0xFF5A7BC0) : AppColors.primaryNavyBlue,
            unselectedItemColor: isDark ? Colors.white54 : AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            backgroundColor: isDark ? const Color(0xFF1B263B) : Colors.white,
            items: [
          BottomNavigationBarItem(
                icon: Icon(isDoctor ? Icons.dashboard_outlined : Icons.home_outlined),
                activeIcon: Icon(isDoctor ? Icons.dashboard : Icons.home),
                label: isDoctor ? 'Dashboard' : 'Home',
          ),
          BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                activeIcon: const Icon(Icons.calendar_today),
                label: isDoctor ? 'Schedule' : 'Appointments',
          ),
          BottomNavigationBarItem(
                icon: Icon(isDoctor ? Icons.people_outline : Icons.library_books_outlined),
                activeIcon: Icon(isDoctor ? Icons.people : Icons.library_books),
                label: isDoctor ? 'Patients' : 'Resources',
          ),
              const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
          );
        },
      ),
    );
  }
}
