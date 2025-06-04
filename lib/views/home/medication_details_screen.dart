import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medtrack/models/medication_model.dart';
import 'package:medtrack/views/widgets/schedule_item.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:medtrack/services/reminder_manager.dart';
import 'dart:io';

class MedicationDetailsScreen extends StatefulWidget {
  final Medication medication;
  final String documentId;

  const MedicationDetailsScreen({
    Key? key,
    required this.medication,
    required this.documentId,
  }) : super(key: key);

  @override
  _MedicationDetailsScreenState createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Colors
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF3F3D56);
  final Color accentColor = const Color(0xFFF8F9FA);
  final Color errorColor = const Color(0xFFE57373);
  final Color successColor = const Color(0xFF4CAF50);

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;

  // Form values
  late String _form;
  late DateTime _startDate;
  late DateTime? _endDate;
  late List<Map<String, dynamic>> _schedule;
  late bool _isActive;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  bool _isImageUpdated = false;

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }

  void _initializeFormValues() {
    _nameController = TextEditingController(text: widget.medication.name);
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _instructionsController = TextEditingController(text: widget.medication.instructions ?? '');
    _form = widget.medication.form;
    _startDate = widget.medication.startDate;
    _endDate = widget.medication.endDate;
    _schedule = List.from(widget.medication.schedule);
    _isActive = widget.medication.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isImageUpdated = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to pick image: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: errorColor,
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _isImageUpdated = true;
    });
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final userId = _auth.currentUser!.uid;
      final ref = _storage.ref()
          .child('medication_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to upload image: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: errorColor,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Medication Details'),
        backgroundColor: primaryColor,
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Image
                    _buildImageSection(),
                    const SizedBox(height: 20),

                    // Medication Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Medication Name',
                        prefixIcon: const Icon(Icons.medication),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: !_isEditing,
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
                        labelText: 'Dosage',
                        prefixIcon: const Icon(Icons.exposure),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Form (Dropdown)
                    _isEditing
                        ? DropdownButtonFormField<String>(
                            value: _form,
                            decoration: InputDecoration(
                              labelText: 'Form',
                              prefixIcon: const Icon(Icons.medical_services),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              'tablet',
                              'capsule',
                              'liquid',
                              'injection',
                              'inhaler',
                              'cream',
                              'drops',
                              'other'
                            ].map((String value) {
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
                          )
                        : _buildReadOnlyField(
                            label: 'Form',
                            value: _form.capitalize(),
                            icon: Icons.medical_services,
                          ),
                    const SizedBox(height: 20),

                    // Start Date
                    _buildDateField(
                      label: 'Start Date',
                      date: _startDate,
                      isEditing: _isEditing,
                      onTap: () => _selectDate(context, isStartDate: true),
                    ),
                    const Divider(),

                    // End Date (optional)
                    _buildDateField(
                      label: 'End Date',
                      date: _endDate,
                      isEditing: _isEditing,
                      isOptional: true,
                      onTap: () => _selectDate(context, isStartDate: false),
                      onClear: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
                    const Divider(),

                    // Active Status
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      activeColor: primaryColor,
                      onChanged: _isEditing
                          ? (bool value) {
                              setState(() {
                                _isActive = value;
                              });
                            }
                          : null,
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
                          onDelete: _isEditing
                              ? () => _removeScheduleItem(item)
                              : null,
                          onEdit: _isEditing
                              ? () => _editScheduleItem(item)
                              : null,
                        )),
                    if (_isEditing) ...[
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
                    ],
                    const SizedBox(height: 20),

                    // Instructions
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Special Instructions',
                        prefixIcon: const Icon(Icons.note),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 30),

                    // Save Button (only visible in edit mode)
                    if (_isEditing)
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
                            'Save Changes',
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

  Widget _buildImageSection() {
    final currentImageUrl = widget.medication.imageUrl;
    final hasImage = _imageFile != null || (currentImageUrl != null && !_isImageUpdated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medication Image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildImageContent(hasImage, currentImageUrl),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              if (_isEditing && hasImage)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: errorColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: _removeImage,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(bool hasImage, String? currentImageUrl) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(currentImageUrl!, fit: BoxFit.cover),
      );
    } else {
      return const Center(
        child: Icon(Icons.medication, size: 60, color: Colors.grey),
      );
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_isEditing) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isEditing = false;
              _initializeFormValues();
              _imageFile = null;
              _isImageUpdated = false;
            });
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
      ];
    }
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(value),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isEditing,
    bool isOptional = false,
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    return ListTile(
      leading: Icon(Icons.calendar_today, color: primaryColor),
      title: Text(label),
      subtitle: Text(date != null
          ? DateFormat('MMM d, y').format(date)
          : isOptional
              ? 'Not set'
              : ''),
      trailing: isEditing && ((isOptional && date != null) || !isOptional)
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: onClear,
            )
          : null,
      onTap: isEditing ? onTap : null,
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
        return _ScheduleEditor(
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
        return _ScheduleEditor(
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
        Fluttertoast.showToast(
          msg: 'Please add at least one schedule',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: errorColor,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        
        // Handle image upload if updated
        if (_isImageUpdated) {
          if (_imageFile != null) {
            imageUrl = await _uploadImage();
          } else {
            imageUrl = null;
          }
        } else {
          imageUrl = widget.medication.imageUrl;
        }

        final updatedMedication = Medication(
          medicationId: widget.medication.medicationId,
          userId: _auth.currentUser!.uid,
          name: _nameController.text,
          dosage: _dosageController.text,
          form: _form,
          schedule: _schedule,
          startDate: _startDate,
          endDate: _endDate,
          instructions: _instructionsController.text.isEmpty
              ? null
              : _instructionsController.text,
          imageUrl: imageUrl,
          isActive: _isActive,
        );

        // First cancel all existing reminders
        await ReminderManager.cancelMedicationReminders(widget.medication);

        // Update medication in Firestore
        await _firestore
            .collection('medications')
            .doc(widget.documentId)
            .update(updatedMedication.toMap());

        // Schedule new reminders if medication is active
        if (_isActive) {
          await ReminderManager.scheduleMedicationReminders(updatedMedication);
        }

        Fluttertoast.showToast(
          msg: 'Medication updated successfully',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: successColor,
        );

        setState(() {
          _isEditing = false;
          _isImageUpdated = false;
          widget.medication
            ..name = updatedMedication.name
            ..dosage = updatedMedication.dosage
            ..form = updatedMedication.form
            ..schedule = updatedMedication.schedule
            ..startDate = updatedMedication.startDate
            ..endDate = updatedMedication.endDate
            ..instructions = updatedMedication.instructions
            ..imageUrl = updatedMedication.imageUrl
            ..isActive = updatedMedication.isActive;
        });
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error updating medication: $e',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: errorColor,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _ScheduleEditor extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final Function(Map<String, dynamic>) onSave;

  const _ScheduleEditor({
    Key? key,
    this.schedule,
    required this.onSave,
  }) : super(key: key);

  @override
  __ScheduleEditorState createState() => __ScheduleEditorState();
}

class __ScheduleEditorState extends State<_ScheduleEditor> {
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}