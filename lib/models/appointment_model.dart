import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String? doctorPhotoUrl;
  final String doctorSpecialty;
  final DateTime dateTime;
  final String type; // 'video', 'voice', 'chat'
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? symptoms;
  final String? notes;
  final double consultationFee;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;
  final double? rating; // Patient rating after consultation (1-5)
  final String? review; // Patient review text

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhotoUrl,
    required this.doctorSpecialty,
    required this.dateTime,
    required this.type,
    required this.status,
    this.symptoms,
    this.notes,
    required this.consultationFee,
    required this.createdAt,
    this.updatedAt,
    this.cancellationReason,
    this.rating,
    this.review,
  });

  /// Convert Appointment to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhotoUrl': doctorPhotoUrl,
      'doctorSpecialty': doctorSpecialty,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'status': status,
      'symptoms': symptoms,
      'notes': notes,
      'consultationFee': consultationFee,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'rating': rating,
      'review': review,
    };
  }

  /// Create Appointment from Firestore Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    // Handle both 'dateTime' and 'appointmentTime' fields for compatibility
    final dateTimeStr = map['dateTime'] ?? map['appointmentTime'];
    if (dateTimeStr == null) {
      throw Exception('Missing dateTime or appointmentTime in appointment data');
    }
    
    // Handle Timestamp objects from Firestore
    DateTime dateTime;
    if (dateTimeStr is Timestamp) {
      dateTime = dateTimeStr.toDate();
    } else if (dateTimeStr is String) {
      dateTime = DateTime.parse(dateTimeStr);
    } else {
      throw Exception('Invalid dateTime format: $dateTimeStr');
    }
    
    // Handle createdAt (could be Timestamp or String)
    DateTime createdAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else {
      createdAt = DateTime.now();
    }
    
    // Handle updatedAt (could be Timestamp, String, or null)
    DateTime? updatedAt;
    final updatedAtValue = map['updatedAt'];
    if (updatedAtValue != null) {
      if (updatedAtValue is Timestamp) {
        updatedAt = updatedAtValue.toDate();
      } else if (updatedAtValue is String) {
        updatedAt = DateTime.parse(updatedAtValue);
      }
    }
    
    return Appointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorPhotoUrl: map['doctorPhotoUrl'],
      doctorSpecialty: map['doctorSpecialty'] ?? '',
      dateTime: dateTime,
      type: map['type'] ?? 'video',
      status: map['status'] ?? 'pending',
      symptoms: map['symptoms'],
      notes: map['notes'],
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancellationReason: map['cancellationReason'],
      rating: map['rating']?.toDouble(),
      review: map['review'],
    );
  }

  /// Create a copy with modified fields
  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorPhotoUrl,
    String? doctorSpecialty,
    DateTime? dateTime,
    String? type,
    String? status,
    String? symptoms,
    String? notes,
    double? consultationFee,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    double? rating,
    String? review,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      consultationFee: consultationFee ?? this.consultationFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    if (status == 'cancelled' || status == 'completed') {
      return false;
    }
    return dateTime.isAfter(DateTime.now());
  }
  
  /// Check if appointment is past
  bool get isPast {
    return dateTime.isBefore(DateTime.now()) || 
           status == 'completed' || 
           status == 'cancelled';
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  /// Check if can join consultation (only when appointment is confirmed/approved)
  /// Only allows joining for 'confirmed' appointments within the time window
  bool get canJoin {
    // Only allow joining if status is confirmed (approved by doctor)
    if (status != 'confirmed') return false;
    
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    // Allow joining 15 minutes before scheduled time and up to 2 hours after
    // This gives flexibility for early/late joins
    return difference.inMinutes <= 15 && difference.inMinutes >= -120;
  }

  /// Get formatted date string
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}