import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/settings_screen.dart';
import 'package:connect_well_nepal/screens/auth_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// ProfileScreen - User profile management screen
/// 
/// Allows users to:
/// - View and edit their profile information
/// - Access settings
/// - Logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _medicalHistoryController.text = user.medicalHistory ?? '';
    }
  }

  /// Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryNavyBlue),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCrimsonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.secondaryCrimsonRed),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Build profile image widget (handles both network and local files)
  Widget _buildProfileImage(String imageUrl) {
    if (imageUrl.startsWith('file://')) {
      // Local file
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        fit: BoxFit.cover,
        width: 112,
        height: 112,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60);
        },
      );
    } else {
      // Network URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 112,
        height: 112,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60);
        },
      );
    }
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploadingImage = true;
        });

        // Update profile image via AppProvider
        // Capture context-dependent objects before async operation
        // ignore: use_build_context_synchronously
        final appProvider = context.read<AppProvider>();
        // ignore: use_build_context_synchronously
        final messenger = ScaffoldMessenger.of(context);
        await appProvider.updateProfileImage(pickedFile.path);

        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update picture: $e'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }
  
  /// Handles the save profile action
  void _saveProfile() {
    final appProvider = context.read<AppProvider>();

    appProvider.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
    );

    setState(() {
      _isEditing = false;
    });
    
    // Show confirmation to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully!'),
        backgroundColor: AppColors.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Capture references before popping
                final navigator = Navigator.of(context);
                final appProvider = context.read<AppProvider>();
                
                Navigator.pop(dialogContext);
                await appProvider.logout();
                
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryCrimsonRed,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // Profile Avatar with Edit Button
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
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
                radius: 60,
                      backgroundColor:
                          isDark ? const Color(0xFF1E2A3A) : Colors.white,
                      child: user?.profileImageUrl != null
                          ? ClipOval(
                              child: _buildProfileImage(user!.profileImageUrl!),
                            )
                          : Text(
                              user?.initials ?? 'G',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryNavyBlue,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _showImagePickerOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCrimsonRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // User Name Display
              Text(
                user?.isHealthcareProfessional == true
                    ? (user?.doctorTitle ?? 'Doctor')
                    : (user?.name ?? 'Guest User'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Role Badge for doctors
              if (user?.isHealthcareProfessional == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCrimsonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user?.isVerifiedDoctor == true
                            ? Icons.verified
                            : Icons.pending,
                        size: 16,
                        color: user?.isVerifiedDoctor == true
                            ? AppColors.successGreen
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user?.specialty ?? user?.roleDisplayName ?? 'Doctor',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryCrimsonRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Email Display
              Text(
                user?.email ?? 'guest@connectwell.np',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Edit Profile Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _loadUserData(); // Reset if cancelled
                        }
                      });
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white70
                          : AppColors.primaryNavyBlue,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : AppColors.primaryNavyBlue,
                      ),
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                ),
              ),
              
              const SizedBox(height: 20),
              
                    // Full Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 16),

                    // Email Field (Read-only)
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),

                    const SizedBox(height: 16),

                    // Phone Field
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Show different fields based on user role
                    if (user?.isHealthcareProfessional != true) ...[
                      // Patient: Medical History Field
                      _buildTextField(
                        controller: _medicalHistoryController,
                        label: 'Medical History',
                        icon: Icons.medical_services_outlined,
                        enabled: _isEditing,
                        maxLines: 4,
                        hintText: 'Add any relevant medical history...',
                  ),
                    ],

                    if (_isEditing) ...[
                      const SizedBox(height: 24),
              
                      // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryCrimsonRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Doctor Professional Information Card
              if (user?.isHealthcareProfessional == true) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_information,
                            color: isDark ? Colors.white70 : AppColors.primaryNavyBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Professional Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Specialty', user?.specialty ?? 'Not specified'),
                      _buildInfoRow('License No.', user?.licenseNumber ?? 'Not specified'),
                      _buildInfoRow('Qualification', user?.qualification ?? 'Not specified'),
                      _buildInfoRow('Experience', user?.yearsOfExperience != null
                          ? '${user!.yearsOfExperience} years'
                          : 'Not specified'),
                      if (user?.hospitalAffiliation != null)
                        _buildInfoRow('Hospital', user!.hospitalAffiliation!),
                      if (user?.consultationFee != null)
                        _buildInfoRow('Consultation Fee', 'NPR ${user!.consultationFee!.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Quick Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Different actions for doctors vs patients
                    if (user?.isHealthcareProfessional == true) ...[
                      _buildQuickAction(
                        icon: Icons.schedule,
                        iconColor: Colors.blue,
                        title: 'Manage Schedule',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Schedule management coming soon!'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildQuickAction(
                        icon: Icons.people,
                        iconColor: Colors.green,
                        title: 'My Patients',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Patient list coming soon!'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildQuickAction(
                        icon: Icons.analytics,
                        iconColor: Colors.purple,
                        title: 'Earnings & Analytics',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analytics coming soon!'),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      _buildQuickAction(
                        icon: Icons.history,
                        iconColor: Colors.blue,
                        title: 'Appointment History',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment history coming soon!'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildQuickAction(
                        icon: Icons.favorite,
                        iconColor: Colors.red,
                        title: 'Saved Doctors',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved doctors coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                    const Divider(height: 1),
                    _buildQuickAction(
                      icon: Icons.payment,
                      iconColor: Colors.green,
                      title: 'Payment Methods',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment methods coming soon!'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildQuickAction(
                      icon: Icons.settings,
                      iconColor: Colors.grey,
                      title: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout, color: AppColors.secondaryCrimsonRed),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryCrimsonRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondaryCrimsonRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled
              ? (isDark ? Colors.white54 : AppColors.textSecondary)
              : (isDark ? Colors.white24 : AppColors.dividerGray),
        ),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: enabled
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.backgroundOffWhite)
            : (isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.grey.withValues(alpha: 0.1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.dividerGray,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryCrimsonRed,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.dividerGray,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
