import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleItem extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ScheduleItem({
    Key? key,
    required this.schedule,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeParts = schedule['time'].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.orange),
        title: Text(time.format(context)),
        subtitle: Text(
          schedule['days'] == 'daily'
              ? 'Every day'
              : (schedule['days'] as List).join(', '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}