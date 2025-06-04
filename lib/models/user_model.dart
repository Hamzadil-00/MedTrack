import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser  {
  final String userId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String? profileImageUrl;

  AppUser ({
    required this.userId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.createdAt,
    required this.lastLogin,
    this.profileImageUrl,
  });

  factory AppUser .fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser (
      userId: doc.id,
      email: data['email'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toUtc(),
      'lastLogin': lastLogin.toUtc(),
      'profileImageUrl': profileImageUrl,
    };
  }
}