import 'package:flutter/material.dart';
import 'package:medtrack/models/medication_model.dart';
import 'package:medtrack/services/notification_service.dart';
import 'package:intl/intl.dart';

class ReminderManager {
  static Future<void> scheduleMedicationReminders(Medication medication) async {
    // Cancel existing reminders for this medication
    await cancelMedicationReminders(medication);

    // Schedule new reminders
    for (final schedule in medication.schedule) {
      final timeParts = schedule['time'].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);

      // Generate unique base ID for this medication's reminders
      final baseId = medication.medicationId.hashCode;

      if (schedule['days'] == 'daily') {
        // Schedule daily (all days)
        await NotificationService.scheduleDailyNotification(
          id: baseId,
          title: 'Time to take your medication',
          body: '${medication.name} - ${medication.dosage}',
          time: time,
          days: List.generate(7, (i) => i + 1), // All days 1-7
          payload: medication.medicationId,
        );
      } else {
        // Schedule on specific days
        final dayNumbers = (schedule['days'] as List<String>).map((day) {
          return _dayNameToNumber(day);
        }).toList();

        await NotificationService.scheduleDailyNotification(
          id: baseId,
          title: 'Time to take your medication',
          body: '${medication.name} - ${medication.dosage}',
          time: time,
          days: dayNumbers,
          payload: medication.medicationId,
        );
      }
    }
  }

  static Future<void> cancelMedicationReminders(Medication medication) async {
    // Generate the same base ID used for scheduling
    final baseId = medication.medicationId.hashCode;
    
    // Cancel all possible day variations (1-7)
    for (int day = 1; day <= 7; day++) {
      await NotificationService.cancelNotification(baseId + day);
    }
  }

  static int _dayNameToNumber(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }

  static Future<void> showImmediateReminderNotification({
    required Medication medication,
    String? customMessage,
  }) async {
    await NotificationService.scheduleSingleNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Medication Reminder',
      body: customMessage ?? 
          'Reminder: ${medication.name} - ${medication.dosage}',
      date: DateTime.now().add(const Duration(seconds: 1)),
      payload: medication.medicationId,
    );
  }
}