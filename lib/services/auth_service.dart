import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔄 Stream for auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // 🧭 Get current user
  User? get currentUser => _auth.currentUser;

  // 🚪 Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (!userCredential.user!.emailVerified) {
        await sendEmailVerification();
        await signOut();
        throw AuthException('email-not-verified', 'Please verify your email first');
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  // 📝 Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // 🔔 Send email verification after successful registration
      await sendEmailVerification();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  // 🔑 Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 📧 Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message);
    }
  }

  // ✅ Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // 🧐 Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }
}

// 🔥 Custom Auth Exception
class AuthException implements Exception {
  final String code;
  final String? message;

  AuthException(this.code, this.message);

  String get userFriendlyMessage {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'email-not-verified':
        return message ?? 'Please verify your email first. Check your inbox.';
      default:
        return message ?? 'An unknown error occurred.';
    }
  }

  @override
  String toString() => 'AuthException: $code - ${message ?? 'No message'}';
}