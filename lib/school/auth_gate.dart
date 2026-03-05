import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'school_dashboard.dart';
import 'school_login.dart'; // Make sure this path is correct!

class SchoolAuthGate extends StatelessWidget {
  const SchoolAuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // This listens to Supabase in real-time to check if someone is logged in
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          );
        }

        // Check if we have a valid session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // They are logged in! Send them to the dashboard.
          return const SchoolDashboardScreen();
        } else {
          // They are NOT logged in! Send them to the login screen.
          return const SchoolLoginScreen();
        }
      },
    );
  }
}