/// UserRole - Defines the type of user
enum UserRole {
  patient,
  doctor,
  careProvider,
  guest,
}

/// UserModel - Represents user data in Connect Well Nepal
///
/// This model stores user information including:
/// - Basic profile information
/// - Role (patient/doctor/care provider)
/// - Medical history (for patients)
/// - Professional info (for doctors)
/// - Account settings
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final UserRole role;
  final bool isEmailVerified;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;

  // Patient-specific fields
  final String? medicalHistory;
  final String? bloodType;
  final String? allergies;
  final String? emergencyContact;

  // Doctor/Care Provider specific fields
  final String? specialty;
  final String? licenseNumber;
  final String? qualification;
  final int? yearsOfExperience;
  final String? hospitalAffiliation;
  final String? bio;
  final double? consultationFee;
  final bool isVerifiedDoctor;
  final bool isAdmin; // Admin role for verifying doctors
  final List<String>? availableDays;
  final String? availableTimeStart;
  final String? availableTimeEnd;
  final bool isAvailableNow; // Current availability status

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.role = UserRole.patient,
    this.isEmailVerified = false,
    this.dateOfBirth,
    this.gender,
    DateTime? createdAt,
    // Patient fields
    this.medicalHistory,
    this.bloodType,
    this.allergies,
    this.emergencyContact,
    // Doctor fields
    this.specialty,
    this.licenseNumber,
    this.qualification,
    this.yearsOfExperience,
    this.hospitalAffiliation,
    this.bio,
    this.consultationFee,
    this.isVerifiedDoctor = false,
    this.isAdmin = false,
    this.availableDays,
    this.availableTimeStart,
    this.availableTimeEnd,
    this.isAvailableNow = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if user is a patient
  bool get isPatient => role == UserRole.patient;

  /// Check if user is a doctor
  bool get isDoctor => role == UserRole.doctor;

  /// Check if user is a care provider
  bool get isCareProvider => role == UserRole.careProvider;

  /// Check if user is a guest
  bool get isGuest => role == UserRole.guest;

  /// Check if user is a healthcare professional
  bool get isHealthcareProfessional =>
      role == UserRole.doctor || role == UserRole.careProvider;

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.careProvider:
        return 'Care Provider';
      case UserRole.guest:
        return 'Guest';
    }
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    bool? isEmailVerified,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    String? medicalHistory,
    String? bloodType,
    String? allergies,
    String? emergencyContact,
    String? specialty,
    String? licenseNumber,
    String? qualification,
    int? yearsOfExperience,
    String? hospitalAffiliation,
    String? bio,
    double? consultationFee,
    bool? isVerifiedDoctor,
    bool? isAdmin,
    List<String>? availableDays,
    String? availableTimeStart,
    String? availableTimeEnd,
    bool? isAvailableNow,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      qualification: qualification ?? this.qualification,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      hospitalAffiliation: hospitalAffiliation ?? this.hospitalAffiliation,
      bio: bio ?? this.bio,
      consultationFee: consultationFee ?? this.consultationFee,
      isVerifiedDoctor: isVerifiedDoctor ?? this.isVerifiedDoctor,
      isAdmin: isAdmin ?? this.isAdmin,
      availableDays: availableDays ?? this.availableDays,
      availableTimeStart: availableTimeStart ?? this.availableTimeStart,
      availableTimeEnd: availableTimeEnd ?? this.availableTimeEnd,
      isAvailableNow: isAvailableNow ?? this.isAvailableNow,
    );
  }

  /// Convert UserModel to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
      'medicalHistory': medicalHistory,
      'bloodType': bloodType,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'qualification': qualification,
      'yearsOfExperience': yearsOfExperience,
      'hospitalAffiliation': hospitalAffiliation,
      'bio': bio,
      'consultationFee': consultationFee,
      'isVerifiedDoctor': isVerifiedDoctor,
      'isAdmin': isAdmin,
      'availableDays': availableDays,
      'availableTimeStart': availableTimeStart,
      'availableTimeEnd': availableTimeEnd,
      'isAvailableNow': isAvailableNow,
    };
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      isEmailVerified: map['isEmailVerified'] ?? false,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      gender: map['gender'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      medicalHistory: map['medicalHistory'],
      bloodType: map['bloodType'],
      allergies: map['allergies'],
      emergencyContact: map['emergencyContact'],
      specialty: map['specialty'],
      licenseNumber: map['licenseNumber'],
      qualification: map['qualification'],
      yearsOfExperience: map['yearsOfExperience'],
      hospitalAffiliation: map['hospitalAffiliation'],
      bio: map['bio'],
      consultationFee: map['consultationFee']?.toDouble(),
      isVerifiedDoctor: map['isVerifiedDoctor'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      availableDays: map['availableDays'] != null
          ? List<String>.from(map['availableDays'])
          : null,
      availableTimeStart: map['availableTimeStart'],
      availableTimeEnd: map['availableTimeEnd'],
      isAvailableNow: map['isAvailableNow'] ?? false,
    );
  }

  /// Get user's first name
  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  /// Get user's initials
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Get doctor's display title
  String get doctorTitle {
    if (!isHealthcareProfessional) return name;
    return 'Dr. $name';
  }

  /// Get doctor's credential summary
  String get credentialSummary {
    if (!isHealthcareProfessional) return '';
    final parts = <String>[];
    if (specialty != null) parts.add(specialty!);
    if (qualification != null) parts.add(qualification!);
    return parts.join(' • ');
  }
}
