import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Medication {
  final String medicationId;
  final String userId;
  String name;
  String dosage;
  String form;
  List<Map<String, dynamic>> schedule;
  DateTime startDate;
  DateTime? endDate;
  String? instructions;
  String? imageUrl;
  bool isActive;

  Medication({
    required this.medicationId,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.form,
    required this.schedule,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.imageUrl,
    required this.isActive,
  });

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medication(
      medicationId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      form: data['form'] ?? '',
      schedule: List<Map<String, dynamic>>.from(data['schedule'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      instructions: data['instructions'],
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'form': form,
      'schedule': schedule,
      'startDate': startDate,
      'endDate': endDate,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
