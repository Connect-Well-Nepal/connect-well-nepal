class Doctor {
  final String id;
  final String name;
  final String specialization;
  final int experience;
  final double rating;
  final String? photoUrl;
  final bool isVerified;
  final String? bio;
  final List<String>? qualifications;
  final String? clinicName;
  final String? clinicAddress;
  final List<String> languages;
  final List<String> availableDays;
  final List<TimeSlot> timeSlots;
  final int totalReviews;
  final double consultationFee;
  final bool isAvailable;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.rating,
    this.photoUrl,
    this.isVerified = true,
    this.bio,
    this.qualifications,
    this.clinicName,
    this.clinicAddress,
    this.languages = const ['English', 'Nepali'],
    this.availableDays = const [],
    this.timeSlots = const [],
    this.totalReviews = 0,
    this.consultationFee = 500.0,
    this.isAvailable = true,
  });

  // Aliases for compatibility
  String get specialty => specialization;
  int get experienceYears => experience;
}

/// TimeSlot model
class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  bool isPast(DateTime date) {
    try {
      final parts = startTime.split(':');
      if (parts.length < 2) return false;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
      final now = DateTime.now();
      // Only consider past if the slot time is before now (with 5 minute buffer)
      return slotTime.isBefore(now.subtract(const Duration(minutes: 5)));
    } catch (e) {
      return false;
    }
  }

  TimeSlot copyWith({bool? isAvailable}) {
    return TimeSlot(
      startTime: startTime,
      endTime: endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
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
      photoUrl: null,
      isVerified: true,
      bio: 'Experienced cardiologist specializing in heart disease prevention.',
      qualifications: ['MBBS', 'MD (Cardiology)'],
      clinicName: 'Heart Care Center',
      clinicAddress: 'Kathmandu, Nepal',
      languages: ['English', 'Nepali', 'Hindi'],
      availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      timeSlots: _getDefaultTimeSlots(),
      totalReviews: 120,
      consultationFee: 500.0,
      isAvailable: true,
    ),
    Doctor(
      id: '2',
      name: 'Dr. Maya Shrestha',
      specialization: 'Dermatology',
      experience: 7,
      rating: 4.5,
      photoUrl: null,
      isVerified: true,
      bio: 'Skin specialist with expertise in cosmetic dermatology.',
      qualifications: ['MBBS', 'MD (Dermatology)'],
      clinicName: 'Skin Care Clinic',
      clinicAddress: 'Lalitpur, Nepal',
      languages: ['English', 'Nepali'],
      availableDays: ['Monday', 'Wednesday', 'Friday', 'Saturday'],
      timeSlots: _getDefaultTimeSlots(),
      totalReviews: 85,
      consultationFee: 600.0,
      isAvailable: true,
    ),
    Doctor(
      id: '3',
      name: 'Dr. Suresh Thapa',
      specialization: 'Pediatrics',
      experience: 12,
      rating: 4.9,
      photoUrl: null,
      isVerified: true,
      bio: 'Child health specialist providing quality pediatric care.',
      qualifications: ['MBBS', 'MD (Pediatrics)', 'DCH'],
      clinicName: 'Children\'s Hospital',
      clinicAddress: 'Kathmandu, Nepal',
      languages: ['English', 'Nepali', 'Newari'],
      availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      timeSlots: _getDefaultTimeSlots(),
      totalReviews: 200,
      consultationFee: 700.0,
      isAvailable: false,
    ),
  ];
}

/// Default time slots
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