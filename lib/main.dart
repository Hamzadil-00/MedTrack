import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medtrack/services/notification_service.dart';
import 'package:medtrack/views/auth/login_screen.dart';
import 'package:medtrack/views/home/home_screen.dart';
import 'package:medtrack/utils/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service
    await NotificationService.initialize();
    
    runApp(const MedTrackApp());
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTrack',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final user = snapshot.data;
        
        if (user != null) {
          // Check if email is verified
          if (user.emailVerified) {
            return const HomeScreen();
          } else {
            // If email is not verified, send verification email and show message
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await user.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent. Please verify your email to login.'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send verification email: $e'),
                  ),
                );
              }
              // Sign out the user until they verify their email
              await _auth.signOut();
            });
            return const LoginScreen();
          }
        }
        
        return const LoginScreen();
      },
    );
  }
}