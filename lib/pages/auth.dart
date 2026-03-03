import 'package:flutter/material.dart';
import 'package:soko_tender/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:soko_tender/pages/home_page.dart'; // Uncomment to link to your HomePage

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Toggle between Login and Sign Up mode
  bool _isLogin = true;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmpincontroller = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // Only for Sign Up

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _confirmpincontroller.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _obsecurePin = true;
  bool _obescureConfirmPin = true;
  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      final pin = _pinController.text.trim();
      final name = _nameController.text.trim();

      // converting phone to a dummy email for supabase
      final dummyemail = '$phone@sokotender.com';

      if (_isLogin) {
        // login flow
        await Supabase.instance.client.auth.signInWithPassword(
          email: dummyemail,
          password: pin,
        );
      } else {
        // sign up
        if (pin != _confirmpincontroller.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs do not match')),
          );
          return;
        }

        // create the user in supabase auth
        final AuthResponse res = await Supabase.instance.client.auth.signUp(
          email: dummyemail,
          password: pin,
        );

        final User? user = res.user;

        if (user != null) {
          // ssave the info into profiles tab
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'full_name': name,
            'phone_number': phone,
            'user_type': 'farmer'
          });
        }
      }

      // success, navigate to the home page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (error) {
      // show the error to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Improved Header Logo/Icon
              Center(
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x402E7D32),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .eco, // Swapped 'agriculture' for 'eco' which looks more like a modern logo
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Dynamic Greeting
              Text(
                textAlign: TextAlign.center,
                _isLogin ? 'Welcome Back!' : 'Create Account',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                textAlign: TextAlign.center,
                _isLogin
                    ? 'Enter your phone number and PIN to access your account.'
                    : 'Join SokoTender to find buyers and sell your produce faster.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Sign Up Only: Full Name Field
              if (!_isLogin) ...[
                _buildInputField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Mama Kevin',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 20),
              ],

              // Phone Number Field
              _buildInputField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '712 345 678',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                prefixText: '+254 ', // Pre-filled for convenience
              ),

              const SizedBox(height: 20),

              // PIN Field
              _buildInputField(
                controller: _pinController,
                label: '6-Digit PIN',
                hint: '• • • • • •',
                icon: Icons.lock_outline,
                keyboardType: TextInputType.number,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obsecurePin ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obsecurePin = !_obsecurePin;
                    });
                  },
                ),
                isPassword: _obsecurePin,
                maxLength: 6,
              ),
              // Confirm PIN Field (Only for Sign Up)
              if (!_isLogin) ...[
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _confirmpincontroller,
                  label: 'Confirm 6-Digit PIN',
                  hint: '• • • • • •',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  isPassword: _obescureConfirmPin,
                  maxLength: 6,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obescureConfirmPin
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obescureConfirmPin = !_obescureConfirmPin;
                      });
                    },
                  ),
                ),
              ],

              // Login Only: Forgot PIN?
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot PIN flow
                    },
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // TODO: Connect to Supabase Auth here
                  onPressed: _isLoading ? null : _submit,

                  // For now, this just routes to the Home Page

                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const HomePage(),
                  //   ),
                  // );

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeAlign: 2.5,
                          ),
                        )
                      : Text(
                          _isLogin ? 'LOG IN ' : 'SIGN UP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle between Login and Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? "Don't have an account? "
                        : "Already have an account? ",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      // This flips the screen between Login and Sign Up
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Log In',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to keep our text fields clean and consistent
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    bool isPassword = false,
    String? prefixText,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            counterText: "", // Hides the max length counter text
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
