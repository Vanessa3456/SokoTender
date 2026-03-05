import 'package:flutter/material.dart';
import 'package:soko_tender/pages/auth.dart';
import 'package:soko_tender/pages/auth_gate.dart';
import 'package:soko_tender/pages/home_page.dart';
import 'package:soko_tender/pages/onboarding.dart';
import 'package:soko_tender/school/auth_gate.dart';
import 'package:soko_tender/school/school_dashboard.dart';
import 'package:soko_tender/school/verify_lpo_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Ensure Flutter is fully initialized before loading assets
  WidgetsFlutterBinding.ensureInitialized();

  // Load your .env file containing your API keys
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with your environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SokoTender',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      //  Removed the accidental duplicate line here!
      onGenerateRoute: (settings) {
        // 1. Check if the web URL starts with '/verify/'
        if (settings.name != null && settings.name!.startsWith('/verify/')) {
          // 2. Extract the ID from the end of the URL
          final tenderId = settings.name!.replaceFirst('/verify/', '');

          // 3. Send them to the Verify Screen instead of the Dashboard
          return MaterialPageRoute(
            builder: (context) => VerifyLpoScreen(tenderId: tenderId),
          );
        }

        // THE DEVICE SPLIT (Web vs Mobile) ---
        if (kIsWeb) {
          return MaterialPageRoute(
            builder: (context) => const SchoolAuthGate(),
          );
        } else {
          return MaterialPageRoute(
            builder: (context) => const AuthGate(),
          );
        }
      },
    );
  }
}
