import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/services/chat_service.dart';
import 'package:connect_well_nepal/screens/chat_screen.dart';

/// AllDoctorsScreen - Shows all available doctors
class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  String _selectedSpecialty = 'All';
  String _searchQuery = '';
  
  // Demo doctors data
  final List<Map<String, dynamic>> _allDoctors = [
    {
      'name': 'Dr. Rajesh Sharma',
      'specialty': 'General Physician',
      'experience': '15 years',
      'rating': 4.8,
      'reviews': 245,
      'available': true,
      'fee': 'Rs. 500',
      'image': null,
    },
    {
      'name': 'Dr. Anjali Thapa',
      'specialty': 'Cardiologist',
      'experience': '12 years',
      'rating': 4.9,
      'reviews': 189,
      'available': true,
      'fee': 'Rs. 1000',
      'image': null,
    },
    {
      'name': 'Dr. Prakash Paudel',
      'specialty': 'Pediatrician',
      'experience': '10 years',
      'rating': 4.7,
      'reviews': 312,
      'available': false,
      'fee': 'Rs. 600',
      'image': null,
    },
    {
      'name': 'Dr. Sunita Gurung',
      'specialty': 'Dermatologist',
      'experience': '8 years',
      'rating': 4.6,
      'reviews': 156,
      'available': true,
      'fee': 'Rs. 800',
      'image': null,
    },
    {
      'name': 'Dr. Arun Shrestha',
      'specialty': 'Orthopedic',
      'experience': '20 years',
      'rating': 4.9,
      'reviews': 421,
      'available': true,
      'fee': 'Rs. 1200',
      'image': null,
    },
    {
      'name': 'Dr. Maya Rai',
      'specialty': 'Gynecologist',
      'experience': '14 years',
      'rating': 4.8,
      'reviews': 267,
      'available': true,
      'fee': 'Rs. 900',
      'image': null,
    },
    {
      'name': 'Dr. Bikash KC',
      'specialty': 'Neurologist',
      'experience': '18 years',
      'rating': 4.7,
      'reviews': 198,
      'available': false,
      'fee': 'Rs. 1500',
      'image': null,
    },
    {
      'name': 'Dr. Sita Maharjan',
      'specialty': 'ENT Specialist',
      'experience': '11 years',
      'rating': 4.5,
      'reviews': 134,
      'available': true,
      'fee': 'Rs. 700',
      'image': null,
    },
    {
      'name': 'Dr. Ram Bahadur',
      'specialty': 'General Physician',
      'experience': '25 years',
      'rating': 4.9,
      'reviews': 567,
      'available': true,
      'fee': 'Rs. 400',
      'image': null,
    },
    {
      'name': 'Dr. Puja Adhikari',
      'specialty': 'Psychiatrist',
      'experience': '9 years',
      'rating': 4.6,
      'reviews': 89,
      'available': true,
      'fee': 'Rs. 1100',
      'image': null,
    },
    {
      'name': 'Dr. Dipak Karki',
      'specialty': 'Cardiologist',
      'experience': '16 years',
      'rating': 4.8,
      'reviews': 234,
      'available': false,
      'fee': 'Rs. 1200',
      'image': null,
    },
    {
      'name': 'Dr. Nisha Tamang',
      'specialty': 'Pediatrician',
      'experience': '7 years',
      'rating': 4.4,
      'reviews': 98,
      'available': true,
      'fee': 'Rs. 550',
      'image': null,
    },
  ];

  List<String> get _specialties {
    final specs = _allDoctors.map((d) => d['specialty'] as String).toSet().toList();
    specs.sort();
    return ['All', ...specs];
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    return _allDoctors.where((doctor) {
      final matchesSpecialty = _selectedSpecialty == 'All' || 
          doctor['specialty'] == _selectedSpecialty;
      final matchesSearch = _searchQuery.isEmpty ||
          doctor['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor['specialty'].toLowerCase().contains(_searchQuery.toLowerCase());
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
            child: ListView.builder(
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

  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isDark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showDoctorDetails(doctor);
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
                child: Text(
                  doctor['name'].split(' ').last[0],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavyBlue,
                  ),
                ),
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
                            doctor['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: doctor['available'] 
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doctor['available'] ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: doctor['available'] 
                                  ? AppColors.successGreen 
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'],
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
                          doctor['experience'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['rating']} (${doctor['reviews']})',
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
                          doctor['fee'],
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
                              onPressed: doctor['available'] ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Booking appointment with ${doctor['name']}...')),
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

  void _showDoctorDetails(Map<String, dynamic> doctor) {
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
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Doctor header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                        child: Text(
                          doctor['name'].split(' ').last[0],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavyBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              doctor['specialty'],
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryNavyBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Experience', doctor['experience'], Icons.work),
                      _buildStat('Rating', '${doctor['rating']}★', Icons.star),
                      _buildStat('Reviews', '${doctor['reviews']}', Icons.rate_review),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Consultation Fee',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        doctor['fee'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavyBlue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: doctor['available'] ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking appointment with ${doctor['name']}...')),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        doctor['available'] ? 'Book Appointment' : 'Currently Unavailable',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Start a chat with a doctor
  Future<void> _startChat(Map<String, dynamic> doctor) async {
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
        doctorId: doctor['id'] ?? 'doc_${doctor['name'].hashCode}',
        doctorName: doctor['name'],
        doctorSpecialty: doctor['specialty'],
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

  Widget _buildStat(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryNavyBlue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
