import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/profile_screen.dart';
import 'package:connect_well_nepal/screens/appointments_screen.dart';
import 'package:connect_well_nepal/screens/resources_screen.dart';
import 'package:connect_well_nepal/screens/settings_screen.dart';
import 'package:connect_well_nepal/screens/doctor_dashboard_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/models/place_model.dart';
import 'package:connect_well_nepal/services/location_service.dart';
import 'package:connect_well_nepal/services/places_service.dart';

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
  final PlacesService _placesService = PlacesService();

  // Places data
  List<PlaceModel> _nearbyHospitals = [];
  List<PlaceModel> _nearbyClinics = [];
  bool _isLoadingPlaces = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  /// Load nearby hospitals and clinics
  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
      _locationError = null;
    });

    try {
      // Get location first
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _locationError = 'Could not get your location';
          _isLoadingPlaces = false;
        });
        // Still load demo data
        _loadDemoData();
        return;
      }

      // Fetch nearby places
      final hospitals = await _placesService.getNearbyHospitals();
      final clinics = await _placesService.getNearbyClinics();

      setState(() {
        _nearbyHospitals = hospitals;
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
    setState(() {
      _nearbyHospitals = _placesService.cachedHospitals.isNotEmpty
          ? _placesService.cachedHospitals
          : PlacesService().getNearbyHospitals().then((v) => v).toString().isEmpty
              ? []
              : [];
      _nearbyClinics = _placesService.cachedClinics;
    });

    // Force load demo data
    _placesService.getNearbyHospitals().then((hospitals) {
      if (mounted) {
        setState(() {
          _nearbyHospitals = hospitals;
        });
      }
    });

    _placesService.getNearbyClinics().then((clinics) {
      if (mounted) {
        setState(() {
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Connect Well Nepal Logo Icon
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
            const Text('Connect Well Nepal'),
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
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
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
                    // TODO: Navigate to all doctors
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Doctor Cards
          _buildDoctorCard(
            name: 'Dr. Rajesh Sharma',
            specialty: 'General Physician',
            experience: '15 years',
            rating: 4.8,
            available: true,
          ),
          _buildDoctorCard(
            name: 'Dr. Anjali Thapa',
            specialty: 'Cardiologist',
            experience: '12 years',
            rating: 4.9,
            available: true,
          ),
          _buildDoctorCard(
            name: 'Dr. Prakash Paudel',
            specialty: 'Pediatrician',
            experience: '10 years',
            rating: 4.7,
            available: false,
          ),
          _buildDoctorCard(
            name: 'Dr. Sunita Gurung',
            specialty: 'Dermatologist',
            experience: '8 years',
            rating: 4.6,
            available: true,
          ),

          const SizedBox(height: 24),

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
                    // TODO: Navigate to all healthcare facilities
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
          else
            ..._getCombinedHealthcareFacilities().take(5).map((place) => _buildPlaceCard(place)),

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

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String experience,
    required double rating,
    required bool available,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to doctor profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $name\'s profile...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Doctor Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryNavyBlue.withValues(alpha: 0.3)
                      : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: isDark
                      ? const Color(0xFF5A7BC0)
                      : AppColors.primaryNavyBlue,
                ),
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

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
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
