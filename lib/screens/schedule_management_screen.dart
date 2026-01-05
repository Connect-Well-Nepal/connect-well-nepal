// lib/screens/schedule_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../utils/colors.dart';

/// Schedule Management Screen for Doctors
/// Allows doctors to:
/// - View calendar with appointments
/// - Manage availability status (Available/Busy)
/// - Set available time slots
/// - Manage schedule for specific dates
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  bool _isAvailableNow = false;
  bool _isLoading = false;
  
  List<String> _selectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  String _startTime = '09:00';
  String _endTime = '17:00';
  
  @override
  void initState() {
    super.initState();
    _loadDoctorAvailability();
  }
  
  /// Load doctor's current availability status
  Future<void> _loadDoctorAvailability() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appProvider = context.read<AppProvider>();
      final user = appProvider.currentUser;
      
      if (user != null && user.isHealthcareProfessional) {
        setState(() {
          _isAvailableNow = user.isAvailableNow;
          _selectedDays = user.availableDays ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
          _startTime = user.availableTimeStart ?? '09:00';
          _endTime = user.availableTimeEnd ?? '17:00';
        });
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Toggle availability status
  Future<void> _toggleAvailability() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appProvider = context.read<AppProvider>();
      final user = appProvider.currentUser;
      
      if (user == null || !user.isHealthcareProfessional) {
        return;
      }
      
      final newStatus = !_isAvailableNow;
      
      // Update in database
      await _databaseService.updateUser(user.id, {
        'isAvailableNow': newStatus,
      });
      
      // Provider will be updated on next user data fetch
      
      setState(() {
        _isAvailableNow = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus 
                  ? 'You are now available for immediate consultations'
                  : 'You are now busy',
            ),
            backgroundColor: newStatus 
                ? AppColors.successGreen 
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Save schedule settings
  Future<void> _saveSchedule() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appProvider = context.read<AppProvider>();
      final user = appProvider.currentUser;
      
      if (user == null || !user.isHealthcareProfessional) {
        return;
      }
      
      // Update in database
      await _databaseService.updateUser(user.id, {
        'availableDays': _selectedDays,
        'availableTimeStart': _startTime,
        'availableTimeEnd': _endTime,
      });
      
      // Update in provider - reload user data
      final updatedUser = await _databaseService.getUser(user.id);
      if (updatedUser != null) {
        // The provider will be updated when user data is reloaded
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule updated successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: AppColors.secondaryCrimsonRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Show time picker
  Future<void> _selectTime(bool isStartTime) async {
    final timeString = isStartTime ? _startTime : _endTime;
    final timeParts = timeString.split(':');
    final initialHour = int.parse(timeParts[0]);
    final initialMinute = int.parse(timeParts[1]);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour,
        minute: initialMinute,
      ),
    );
    
    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _startTime = timeString;
        } else {
          _endTime = timeString;
        }
      });
      await _saveSchedule();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedule'),
        centerTitle: true,
      ),
      body: _isLoading && _isAvailableNow == false
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Availability Status Toggle
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isAvailableNow ? Icons.check_circle : Icons.cancel,
                              color: _isAvailableNow 
                                  ? AppColors.successGreen 
                                  : Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark 
                                          ? Colors.white54 
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isAvailableNow 
                                        ? 'Available Now' 
                                        : 'Busy',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark 
                                          ? Colors.white 
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAvailableNow,
                              onChanged: _isLoading ? null : (value) => _toggleAvailability(),
                              activeColor: AppColors.successGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isAvailableNow
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: _isAvailableNow
                                    ? AppColors.successGreen
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isAvailableNow
                                      ? 'Patients can book appointments and start consultations immediately'
                                      : 'Patients can only book appointments for your scheduled time slots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? Colors.white70 
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Calendar View
                Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                        ),
                        defaultTextStyle: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primaryNavyBlue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primaryNavyBlue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        disabledTextStyle: TextStyle(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Available Days Selection
                Text(
                  'Available Days',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAllDays().map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                            _saveSchedule();
                          },
                          selectedColor: AppColors.successGreen.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.successGreen,
                          labelStyle: TextStyle(
                            color: isSelected 
                                ? AppColors.successGreen 
                                : (isDark ? Colors.white : AppColors.textPrimary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Time Range Selection
                Text(
                  'Available Time Range',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.primaryNavyBlue,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark 
                                          ? Colors.white54 
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _startTime,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark 
                                          ? Colors.white 
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryCrimsonRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.secondaryCrimsonRed,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark 
                                          ? Colors.white54 
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _endTime,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark 
                                          ? Colors.white 
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
    );
  }
  
  List<String> _getAllDays() {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
  }
}
