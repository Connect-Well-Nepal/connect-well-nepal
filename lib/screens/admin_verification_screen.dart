import 'package:flutter/material.dart';
import 'package:connect_well_nepal/models/user_model.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// AdminVerificationScreen - Admin interface to verify doctors
///
/// Features:
/// - View pending doctor verifications
/// - View doctor details (license, qualification, etc.)
/// - Approve or reject doctor verification
class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<UserModel> _pendingDoctors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _databaseService.getPendingDoctorVerifications();
      if (mounted) {
        setState(() {
          _pendingDoctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading pending verifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyDoctor(UserModel doctor) async {
    try {
      await _databaseService.verifyDoctor(doctor.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${doctor.name} has been verified'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadPendingVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying doctor: $e'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
      }
    }
  }

  void _showDoctorDetails(UserModel doctor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  
                  // Doctor Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                        backgroundImage: doctor.profileImageUrl != null 
                            ? NetworkImage(doctor.profileImageUrl!) 
                            : null,
                        child: doctor.profileImageUrl == null
                            ? Text(
                                doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavyBlue,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              doctor.specialty ?? 'No specialty',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryNavyBlue,
                              ),
                            ),
                            Text(
                              doctor.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Professional Details
                  _buildDetailRow('License Number', doctor.licenseNumber ?? 'Not provided', Icons.badge),
                  const SizedBox(height: 12),
                  _buildDetailRow('Qualification', doctor.qualification ?? 'Not provided', Icons.school),
                  const SizedBox(height: 12),
                  _buildDetailRow('Experience', '${doctor.yearsOfExperience ?? 0} years', Icons.work),
                  const SizedBox(height: 12),
                  _buildDetailRow('Hospital Affiliation', doctor.hospitalAffiliation ?? 'Not provided', Icons.local_hospital),
                  
                  if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Bio', doctor.bio!, Icons.description),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _verifyDoctor(doctor);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Verify Doctor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryNavyBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingVerifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingVerifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingDoctors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pending verifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All doctors have been verified',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingVerifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _pendingDoctors[index];
                          return _buildDoctorCard(doctor, isDark);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDoctorCard(UserModel doctor, bool isDark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDoctorDetails(doctor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                backgroundImage: doctor.profileImageUrl != null 
                    ? NetworkImage(doctor.profileImageUrl!) 
                    : null,
                child: doctor.profileImageUrl == null
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
                      doctor.specialty ?? 'No specialty',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryNavyBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 14,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.licenseNumber ?? 'No license',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
