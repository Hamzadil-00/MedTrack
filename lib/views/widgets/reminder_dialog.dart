import 'package:flutter/material.dart';
import 'package:medtrack/utils/helpers.dart';

class ReminderDialog extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;

  const ReminderDialog({
    Key? key,
    required this.medicationName,
    required this.dosage,
    required this.onTaken,
    required this.onSnooze,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Medication Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time to take:',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          const SizedBox(height: 8),
          Text(
            medicationName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(dosage),
          const SizedBox(height: 16),
          Text(
            'Time: ${Helpers.formatTime(TimeOfDay.now())}',
            style: Theme.of(context).textTheme.caption,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onSnooze,
          child: const Text('Snooze (10 min)'),
        ),
        ElevatedButton(
          onPressed: onTaken,
          child: const Text('Mark as Taken'),
        ),
      ],
    );
  }
}