import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medtrack/views/home/add_medication_screen.dart';
import 'package:medtrack/views/home/medication_details_screen.dart';
import 'package:medtrack/views/profile/profile_screen.dart';
import 'package:medtrack/models/medication_model.dart';
import 'package:medtrack/services/notification_service.dart';
import 'package:medtrack/views/widgets/schedule_item.dart';  // Corrected import path

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colors
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color secondaryColor = const Color(0xFF3F3D56);
  final Color accentColor = const Color(0xFFF8F9FA);
  final Color successColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);

  // Date formatter
  final DateFormat timeFormat = DateFormat('h:mm a');
  final DateFormat dayFormat = DateFormat('EEEE');

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    NotificationService.onNotifications.listen((payload) async {
      if (payload != null && mounted) {
        // Navigate to medication details when notification is tapped
        final medication = await _getMedicationById(payload);
        if (medication != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailsScreen(
                medication: medication,
                documentId: payload,
              ),
            ),
          );
        }
      }
    });
  }

  Future<Medication?> _getMedicationById(String medicationId) async {
    final doc = await _firestore
        .collection('medications')
        .doc(medicationId)
        .get();
        
    if (doc.exists) {
      return Medication.fromFirestore(doc);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        title: const Text('My Medications'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('medications')
            .where('userId', isEqualTo: user?.uid)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/no_meds.png',
                    height: 150,
                    color: secondaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No medications added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: secondaryColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap the + button to add your first medication',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data?.docs[index];
              final med = Medication.fromFirestore(doc!);
              
              return _buildMedicationCard(med, doc.id);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard(Medication med, String docId) {
    final now = DateTime.now();
    final currentDay = dayFormat.format(now);
    
    // Get next scheduled time
    final nextDose = _getNextDoseTime(med, now, currentDay);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailsScreen(
                medication: med,
                documentId: docId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  Chip(
                    backgroundColor: med.isActive ? successColor : Colors.grey,
                    label: Text(
                      med.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(color: Colors.white),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${med.dosage} ${med.form}',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              if (nextDose != null)
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: warningColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next dose: ${timeFormat.format(nextDose)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              if (med.instructions != null && med.instructions!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Instructions: ${med.instructions}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _getNextDoseTime(Medication med, DateTime now, String currentDay) {
    try {
      for (var schedule in med.schedule) {
        final timeParts = schedule['time'].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Check if this schedule applies today
        if (schedule['days'] == 'daily' || 
            (schedule['days'] is List && schedule['days'].contains(currentDay))) {
          
          var nextDose = DateTime(now.year, now.month, now.day, hour, minute);
          
          // If time already passed today, check next occurrence
          if (nextDose.isBefore(now)) {
            if (schedule['days'] == 'daily') {
              nextDose = nextDose.add(const Duration(days: 1));
            } else {
              // Find next scheduled day
              final days = List<String>.from(schedule['days']);
              final currentIndex = days.indexOf(currentDay);
              final nextDayIndex = (currentIndex + 1) % days.length;
              final daysToAdd = (nextDayIndex - currentIndex + 7) % 7;
              nextDose = nextDose.add(Duration(days: daysToAdd));
            }
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