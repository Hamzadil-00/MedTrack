import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medtrack/models/medication_model.dart';
import 'package:medtrack/views/widgets/schedule_item.dart';
import 'package:medtrack/services/reminder_manager.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Colors
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF3F3D56);
  final Color accentColor = const Color(0xFFF8F9FA);
  final Color errorColor = const Color(0xFFE57373);

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  // Form values
  String _form = 'tablet';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<Map<String, dynamic>> _schedule = [];
  bool _isActive = true;

  // Available medication forms
  final List<String> _forms = [
    'tablet',
    'capsule',
    'liquid',
    'injection',
    'inhaler',
    'cream',
    'drops',
    'other'
  ];

  // Days of week
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medication Name',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage (e.g., 500mg, 1 tablet)',
                  prefixIcon: Icon(Icons.exposure),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Form (Dropdown)
              DropdownButtonFormField<String>(
                value: _form,
                decoration: InputDecoration(
                  labelText: 'Form',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                items: _forms.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalize()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _form = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Start Date
              ListTile(
                leading: Icon(Icons.calendar_today, color: primaryColor),
                title: Text('Start Date'),
                subtitle: Text(DateFormat('MMM d, y').format(_startDate)),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              const Divider(),

              // End Date (optional)
              ListTile(
                leading: Icon(Icons.calendar_today, color: primaryColor),
                title: Text('End Date (optional)'),
                subtitle: Text(_endDate == null
                    ? 'Not set'
                    : DateFormat('MMM d, y').format(_endDate!)),
                trailing: _endDate != null
                    ? IconButton(
                        icon: Icon(Icons.clear, color: errorColor),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      )
                    : null,
                onTap: () => _selectDate(context, isStartDate: false),
              ),
              const Divider(),

              // Active Status
              SwitchListTile(
                title: Text('Active'),
                value: _isActive,
                activeColor: primaryColor,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const Divider(),

              // Schedule Section
              const Text(
                'Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._schedule.map((item) => ScheduleItem(
                    schedule: item,
                    onDelete: () => _removeScheduleItem(item),
                    onEdit: () => _editScheduleItem(item),
                  )),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                 backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _addScheduleItem,
                child: const Text('Add Schedule'),
              ),
              const SizedBox(height: 20),

              // Instructions
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Special Instructions (optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                   backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _saveMedication,
                  child: const Text(
                    'Save Medication',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate ?? DateTime.now(),
      firstDate: isStartDate ? DateTime(2000) : _startDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addScheduleItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ScheduleEditor(
          onSave: (newSchedule) {
            setState(() {
              _schedule.add(newSchedule);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _editScheduleItem(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ScheduleEditor(
          schedule: item,
          onSave: (updatedSchedule) {
            setState(() {
              final index = _schedule.indexOf(item);
              _schedule[index] = updatedSchedule;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _removeScheduleItem(Map<String, dynamic> item) {
    setState(() {
      _schedule.remove(item);
    });
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      if (_schedule.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one schedule')),
        );
        return;
      }

      try {
        final medication = Medication(
          medicationId: '',
          userId: _auth.currentUser !.uid,
          name: _nameController.text,
          dosage: _dosageController.text,
          form: _form,
          schedule: _schedule,
          startDate: _startDate,
          endDate: _endDate,
          instructions: _instructionsController.text.isEmpty
              ? null
              : _instructionsController.text,
          imageUrl: null,
          isActive: _isActive,
        );

        await _firestore.collection('medications').add(medication.toMap());

        // Schedule reminders for the medication
        if (medication.isActive) {
          await ReminderManager.scheduleMedicationReminders(medication);
        }
        // Cancel all reminders for this medication
        await ReminderManager.cancelMedicationReminders(medication);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication saved successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medication: $e')),
        );
      }
    }
  }
}

class ScheduleEditor extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final Function(Map<String, dynamic>) onSave;

  const ScheduleEditor({
    Key? key,
    this.schedule,
    required this.onSave,
  }) : super(key: key);

  @override
  _ScheduleEditorState createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  TimeOfDay _time = TimeOfDay.now();
  List<String> _selectedDays = [];
  bool _isDaily = true;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _time = _parseTime(widget.schedule!['time']);
      _isDaily = widget.schedule!['days'] == 'daily';
      if (!_isDaily) {
        _selectedDays = List<String>.from(widget.schedule!['days']);
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(_time.format(context)),
              onTap: () => _selectTime(context),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Daily'),
              value: _isDaily,
              onChanged: (value) {
                setState(() {
                  _isDaily = value;
                  if (_isDaily) {
                    _selectedDays = [];
                  }
                });
              },
            ),
            if (!_isDaily) ...[
              const SizedBox(height: 10),
              const Text('Select days:'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ].map((day) {
                  return FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: _selectedDays.contains(day),
                    onSelected: (selected) => _toggleDay(day),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (!_isDaily && _selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select at least one day')),
                      );
                      return;
                    }

                    widget.onSave({
                      'time': '${_time.hour}:${_time.minute}',
                      'days': _isDaily ? 'daily' : _selectedDays,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ScheduleItem({
    Key? key,
    required this.schedule,
    required this.onDelete,
    required this.onEdit,
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
        leading: Icon(Icons.notifications, color: Colors.orange),
        title: Text(time.format(context)),
        subtitle: Text(
          schedule['days'] == 'daily'
              ? 'Every day'
              : (schedule['days'] as List).join(', '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}