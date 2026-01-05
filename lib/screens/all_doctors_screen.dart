import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/services/chat_service.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:connect_well_nepal/models/doctor_model.dart';
import 'package:connect_well_nepal/screens/chat_screen.dart';
import 'package:connect_well_nepal/screens/booking_screen.dart';
import 'package:connect_well_nepal/screens/doctor_profile_screen.dart';

/// AllDoctorsScreen - Shows all available doctors
class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  String _selectedSpecialty = 'All';
  String _searchQuery = '';
  List<Doctor> _allDoctors = [];
  bool _isLoading = true;
  
  final DatabaseService _databaseService = DatabaseService();
  
  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }
  
  /// Load real doctors from database
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final doctors = await _databaseService.getVerifiedDoctors();
      
      // Convert UserModel to Doctor model
      _allDoctors = doctors.map((user) {
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
          isAvailable: true,
          isAvailableNow: user.isAvailableNow,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      // Show empty state if error
      _allDoctors = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  List<String> get _specialties {
    final specs = _allDoctors.map((d) => d.specialization).toSet().toList();
    specs.sort();
    return ['All', ...specs];
  }

  List<Doctor> get _filteredDoctors {
    return _allDoctors.where((doctor) {
      final matchesSpecialty = _selectedSpecialty == 'All' || 
          doctor.specialization == _selectedSpecialty;
      final matchesSearch = _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.specialization.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSpecialty && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Doctors'),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Specialty filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _specialties.length,
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                final isSelected = specialty == _selectedSpecialty;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(specialty),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSpecialty = specialty);
                    },
                    selectedColor: AppColors.primaryNavyBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryNavyBlue,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? AppColors.primaryNavyBlue 
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredDoctors.length} doctors found',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Doctors list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No doctors found',
                              style: TextStyle(
                                fontSize: 16,
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          return _buildDoctorCard(doctor, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, bool isDark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                backgroundImage: doctor.photoUrl != null ? NetworkImage(doctor.photoUrl!) : null,
                child: doctor.photoUrl == null
                    ? Text(
                        doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavyBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
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
                            color: (doctor.isAvailable || doctor.isAvailableNow)
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
                                  color: (doctor.isAvailable || doctor.isAvailableNow)
                                      ? AppColors.successGreen
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (doctor.isAvailable || doctor.isAvailableNow) ? 'Available' : 'Busy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: (doctor.isAvailable || doctor.isAvailableNow)
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
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryNavyBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.experienceYears} yrs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating} (${doctor.totalReviews})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${doctor.consultationFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavyBlue,
                          ),
                        ),
                        Row(
                          children: [
                            // Chat button
                            OutlinedButton.icon(
                              onPressed: () => _startChat(doctor),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text('Chat', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryNavyBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(color: AppColors.primaryNavyBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Book button
                            ElevatedButton(
                              onPressed: (doctor.isAvailable || doctor.isAvailableNow) ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(preSelectedDoctor: doctor),
                                  ),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavyBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Book', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Start a chat with a doctor
  Future<void> _startChat(Doctor doctor) async {
    final appProvider = context.read<AppProvider>();
    final currentUser = appProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat with doctors')),
      );
      return;
    }

    try {
      final chatService = ChatService();
      
      // Create or get existing conversation
      final conversation = await chatService.getOrCreateConversation(
        patientId: currentUser.id,
        patientName: currentUser.name,
        patientImage: currentUser.profileImageUrl,
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorSpecialty: doctor.specialization,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

}
