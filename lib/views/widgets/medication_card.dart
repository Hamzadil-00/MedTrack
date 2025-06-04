import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medtrack/models/medication_model.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Color cardColor;

  const MedicationCard({
    Key? key,
    required this.medication,
    required this.onTap,
    this.onDelete,
    this.cardColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextDose = _getNextDoseTime(medication);

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${medication.dosage} • ${medication.form}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              if (nextDose != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notifications, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Next dose: ${DateFormat('h:mm a').format(nextDose)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (medication.instructions?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  'Instructions: ${medication.instructions}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _getNextDoseTime(Medication medication) {
    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now);

      for (var schedule in medication.schedule) {
        final timeParts = schedule['time'].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        if (schedule['days'] == 'daily' || 
            (schedule['days'] is List && schedule['days'].contains(currentDay))) {
          
          var nextDose = DateTime(now.year, now.month, now.day, hour, minute);
          
          if (nextDose.isBefore(now)) {
            nextDose = nextDose.add(const Duration(days: 1));
          }
          
          return nextDose;
        }
      }
    } catch (e) {
      debugPrint('Error calculating next dose time: $e');
    }
    return null;
  }
}