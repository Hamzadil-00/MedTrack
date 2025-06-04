import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medtrack/services/auth_service.dart';
import 'package:medtrack/utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? 'Not available'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: const Text('Email Verified'),
                      subtitle: Text(user?.emailVerified.toString() ?? 'false'),
                      trailing: user?.emailVerified == false
                          ? TextButton(
                              onPressed: () async {
                                await user?.sendEmailVerification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Verification email sent'),
                                  ),
                                );
                              },
                              child: const Text('Verify'),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () async {
                  await authService.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}