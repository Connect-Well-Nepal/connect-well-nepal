import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../utils/colors.dart';

class TimeSlotSelector extends StatelessWidget {
  final List<TimeSlot> timeSlots;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final Function(TimeSlot) onSlotSelected;

  const TimeSlotSelector({
    super.key,
    required this.timeSlots,
    required this.selectedDate,
    this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableSlots = timeSlots.where((slot) {
      return slot.isAvailable && !slot.isPast(selectedDate);
    }).toList();

    if (availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No available time slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a different date',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${availableSlots.length} slots available',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSlots.map((slot) {
              final isSelected = selectedSlot?.startTime == slot.startTime;
              return _TimeSlotChip(
                slot: slot,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onSlotSelected(slot),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNavyBlue
              : isDark
                  ? AppColors.primaryNavyBlue.withValues(alpha: 0.1)
                  : AppColors.backgroundOffWhite,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryNavyBlue
                : isDark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.grey[400]
                      : AppColors.primaryNavyBlue,
            ),
            const SizedBox(width: 6),
            Text(
              slot.startTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}