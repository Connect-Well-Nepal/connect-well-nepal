import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/models/user_model.dart';
import 'package:connect_well_nepal/screens/main_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// DoctorRegistrationScreen - Additional registration for doctors/care providers
///
/// Collects professional information:
/// - Specialty
/// - License number
/// - Qualifications
/// - Experience
/// - Hospital affiliation
class DoctorRegistrationScreen extends StatefulWidget {
  final String verificationCode;
  final UserRole role;

  const DoctorRegistrationScreen({
    super.key,
    required this.verificationCode,
    required this.role,
  });

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();

  String? _selectedSpecialty;
  bool _isSubmitting = false;

  final List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'Psychiatrist',
    'Gynecologist',
    'ENT Specialist',
    'Ophthalmologist',
    'Dentist',
    'Physiotherapist',
    'Nutritionist',
    'Psychologist',
    'Other',
  ];

  @override
  void dispose() {
    _specialtyController.dispose();
    _licenseController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final appProvider = context.read<AppProvider>();
    bool success;

    // Check if this is a Google Sign-In user (empty verification code)
    if (widget.verificationCode.isEmpty) {
      // Google Sign-In user - use completeGoogleSignIn with doctor fields
      success = await appProvider.completeGoogleSignIn(
        role: widget.role,
        specialty: _selectedSpecialty ?? _specialtyController.text,
        licenseNumber: _licenseController.text.trim(),
        qualification: _qualificationController.text.trim(),
        yearsOfExperience: int.tryParse(_experienceController.text.trim()),
        hospitalAffiliation: _hospitalController.text.trim().isNotEmpty
            ? _hospitalController.text.trim()
            : null,
      );
    } else {
      // Email sign-up user - verify code and complete
      success = await appProvider.completeSignUp(
        verificationCode: widget.verificationCode,
        specialty: _selectedSpecialty ?? _specialtyController.text,
        licenseNumber: _licenseController.text.trim(),
        qualification: _qualificationController.text.trim(),
        yearsOfExperience: int.tryParse(_experienceController.text.trim()),
        hospitalAffiliation: _hospitalController.text.trim().isNotEmpty
            ? _hospitalController.text.trim()
            : null,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (mounted && success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
          backgroundColor: AppColors.secondaryCrimsonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDoctor = widget.role == UserRole.doctor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'Doctor Registration' : 'Care Provider Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDoctor ? Icons.medical_services : Icons.health_and_safety,
                      color: AppColors.primaryNavyBlue,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please provide your professional details for verification.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Specialty Dropdown
              Text(
                'Specialty *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialty,
                decoration: InputDecoration(
                  hintText: 'Select your specialty',
                  prefixIcon: const Icon(Icons.medical_information),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a specialty';
                  }
                  return null;
                },
              ),

              // Custom specialty if "Other" selected
              if (_selectedSpecialty == 'Other') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specialtyController,
                  label: 'Specify Specialty',
                  icon: Icons.edit,
                  validator: (value) {
                    if (_selectedSpecialty == 'Other' &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify your specialty';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 20),

              // License Number
              _buildTextField(
                controller: _licenseController,
                label: 'Medical License/Registration Number *',
                icon: Icons.badge,
                hint: 'e.g., NMC-12345',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'License number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Qualification
              _buildTextField(
                controller: _qualificationController,
                label: 'Highest Qualification *',
                icon: Icons.school,
                hint: 'e.g., MBBS, MD, PhD',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Qualification is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Years of Experience
              _buildTextField(
                controller: _experienceController,
                label: 'Years of Experience *',
                icon: Icons.work_history,
                hint: 'e.g., 5',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Experience is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Hospital Affiliation
              _buildTextField(
                controller: _hospitalController,
                label: 'Hospital/Clinic Affiliation (Optional)',
                icon: Icons.local_hospital,
                hint: 'e.g., Grande International Hospital',
              ),

              const SizedBox(height: 32),

              // Note about verification
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your credentials will be verified by our team. You\'ll receive a notification once verified.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryCrimsonRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
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
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : AppColors.dividerGray,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.secondaryCrimsonRed,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

