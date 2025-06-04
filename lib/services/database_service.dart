import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/models/user_model.dart';
import 'package:medtrack/models/medication_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User-related methods
  Future<void> createUser (UserModel user) async {
    await _firestore.collection('users').doc(user.userId).set(user.toMap());
  }

  Future<void> updateUser LastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Medication-related methods
  Stream<List<Medication>> getMedications(String userId) {
    return _firestore
        .collection('medications')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medication.fromFirestore(doc))
            .toList());
  }

  Future<void> addMedication(Medication medication) async {
    await _firestore
        .collection('medications')
        .add(medication.toMap());
  }

  Future<void> updateMedication(String docId, Medication medication) async {
    await _firestore
        .collection('medications')
        .doc(docId)
        .update(medication.toMap());
  }

  Future<void> deleteMedication(String docId) async {
    await _firestore
        .collection('medications')
        .doc(docId)
        .delete();
  }
}