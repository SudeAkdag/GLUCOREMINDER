import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gluco_reminder/login_page.dart';
import 'package:gluco_reminder/bottom_nav_bar.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFF4FD2D2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'GlucoReminder',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A9D9D),
                    ),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FD2D2)),
                  ),
                ],
              ),
            ),
          );
        }

        // User is signed in
        if (snapshot.hasData) {
          return BottomNavigationSayfa();
        }

        // User is not signed in
        return LoginPage();
      },
    );
  }
}