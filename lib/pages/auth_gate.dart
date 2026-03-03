import 'package:flutter/material.dart';
import 'package:soko_tender/pages/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soko_tender/pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // StreamBuilder constantly listens to Supabase's authentication state
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show a loading spinner while it checks the phone's memory
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          );
        }

        // Check if there is an active, unexpired session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const HomePage(); // They are logged in, send them straight to the app!
        } else {
          return const AuthScreen(); // No session found, send them to Login!
        }
      },
    );
  }
}