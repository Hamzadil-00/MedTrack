class AppConstants {
  static const String appName = 'MedTrack';
  static const String medicationCollection = 'medications';
  static const String usersCollection = 'users';

  // Notification channels
  static const String reminderChannelId = 'medtrack_reminders';
  static const String reminderChannelName = 'Medication Reminders';
  static const String reminderChannelDesc = 'Notifications for medication reminders';

  // Time formats
  static const String timeFormat = 'h:mm a';
  static const String dateFormat = 'MMM d, yyyy';

  // Colors
  static const int primaryColorValue = 0xFF6C63FF;
  static const int secondaryColorValue = 0xFF3F3D56;
  static const int accentColorValue = 0xFFF8F9FA;
}

class FirestorePaths {
  static String userDocument(String uid) => 'users/$uid';
  static String medicationsCollection(String uid) => 'users/$uid/medications';
}