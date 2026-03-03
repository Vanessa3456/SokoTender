import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// 1. PERSONAL INFORMATION SCREEN
// ==========================================
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers to hold the text the user types
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPersonalInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _countyController.dispose();
    super.dispose();
  }

  // 1. Fetch the data when the screen loads
  Future<void> _fetchPersonalInfo() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profileData = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && profileData != null) {
          setState(() {
            _nameController.text = profileData['full_name'] ?? '';
            _phoneController.text = profileData['phone_number'] ?? '';
            // If you add these columns to Supabase later, they will automatically populate!
            _idController.text = profileData['national_id']?.toString() ?? '';
            _countyController.text = profileData['home_county'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching personal info: $e');
      setState(() => _isLoading = false);
    }
  }

  // 2. Save the data back to Supabase when they hit the button
  Future<void> _savePersonalInfo() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.from('profiles').update({
          'full_name': _nameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'national_id': _idController.text.trim(),
          'home_county': _countyController.text.trim(),
        }).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Details saved successfully!'),
                backgroundColor: Color(0xFF2E7D32)),
          );
          Navigator.pop(context); // Go back to profile menu
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving details: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Personal Information',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileEditField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildProfileEditField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildProfileEditField(
                      label: 'National ID Number',
                      controller: _idController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildProfileEditField(
                      label: 'Home County',
                      controller: _countyController,
                      icon: Icons.location_city_outlined),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePersonalInfo,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE CHANGES',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Updated to use TextEditingController instead of initialValue
  Widget _buildProfileEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2E7D32), width: 2)),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. MY FARM DETAILS SCREEN
// ==========================================
// ==========================================
// 2. MY FARM DETAILS SCREEN
// ==========================================
class FarmDetailsScreen extends StatefulWidget {
  const FarmDetailsScreen({Key? key}) : super(key: key);

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  // List to keep track of which chips are selected
  List<String> _selectedProduce = [];

  // Master list of all possible produce options
  final List<String> _allProduceOptions = [
    'Cabbages',
    'Tomatoes',
    'Maize',
    'Beans',
    'Potatoes',
    'Onions',
    'Eggs',
    'Milk'
  ];

  @override
  void initState() {
    super.initState();
    _fetchFarmDetails();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarmDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profileData = await supabase
            .from('profiles')
            .select('farm_location, farm_size, main_produce')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && profileData != null) {
          setState(() {
            _locationController.text = profileData['farm_location'] ?? '';
            _sizeController.text = profileData['farm_size']?.toString() ?? '';

            // Safely cast the Postgres Array into a Dart List<String>
            if (profileData['main_produce'] != null) {
              _selectedProduce = List<String>.from(profileData['main_produce']);
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching farm details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFarmDetails() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.from('profiles').update({
          'farm_location': _locationController.text.trim(),
          'farm_size': double.tryParse(_sizeController.text.trim()),
          'main_produce':
              _selectedProduce, // Supabase handles the array conversion automatically!
        }).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Farm details updated!'),
                backgroundColor: Color(0xFF2E7D32)),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving details: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Helper method to toggle chips on and off
  void _toggleProduce(String item) {
    setState(() {
      if (_selectedProduce.contains(item)) {
        _selectedProduce.remove(item);
      } else {
        _selectedProduce.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('My Farm Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Farm Location',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.map_outlined,
                                color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            hintText: 'e.g. Limuru, Kiambu County',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Farm Size (Acres)',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.landscape_outlined,
                                color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            hintText: 'e.g. 2.5',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Main Produce',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text(
                      'Select the main items you grow/sell to get matched with the right buyers.',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),

                  // Dynamically generate the chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allProduceOptions.map((produceName) {
                      final isSelected = _selectedProduce.contains(produceName);
                      return _buildProduceChip(produceName, isSelected);
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveFarmDetails,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE FARM DETAILS',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProduceChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        _toggleProduce(label);
      },
      selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E7D32),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300),
      ),
    );
  }
}

// ==========================================
// 3. PAYMENT METHODS SCREEN
// ==========================================
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _fullName = 'Loading...';
  String _phoneNumber = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profileData = await supabase
            .from('profiles')
            .select('full_name, phone_number')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && profileData != null) {
          setState(() {
            _fullName = profileData['full_name'] ?? 'Unknown Farmer';
            _phoneNumber = profileData['phone_number'] ?? 'No phone provided';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching payment data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Payment Methods',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receiving Payments',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text(
                      'Your earnings will be sent to your primary M-Pesa number.',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),

                  // M-Pesa Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFF2E7D32), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.phone_android,
                              color: Color(0xFF2E7D32), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('M-Pesa (Primary)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(_fullName, // <-- DYNAMIC
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(_phoneNumber, // <-- DYNAMIC
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            color: Color(0xFF2E7D32)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Add New Number Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Color(0xFF2E7D32)),
                      label: const Text('Add Another Number',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// 4. LANGUAGE SCREEN
// ==========================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // Currently selected language
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Language',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Language',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Choose the language you prefer to use in the app.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildLanguageOption('English', 'English'),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildLanguageOption('Kiswahili', 'Swahili'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String subtitle) {
    bool isSelected = _selectedLanguage == title;

    return ListTile(
      onTap: () {
        setState(() {
          _selectedLanguage = title;
        });
        // You could add a slight delay here before popping the screen automatically
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
          : const Icon(Icons.circle_outlined, color: Colors.grey),
    );
  }
}

// ==========================================
// 5. HELP & SUPPORT SCREEN
// ==========================================
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  // Helper function to launch URLs (Phone dialer & WhatsApp)
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the application.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Help & Support',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How can we help you?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text('Get in touch with our support team or read our FAQs.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),

            // Contact Options
            _buildContactCard(
              icon: Icons.support_agent,
              title: 'Call Customer Care',
              subtitle: 'Available Mon-Fri, 8 AM to 5 PM',
              iconColor: Colors.blue,
              bgColor: Colors.blue.shade50,
              onTap: () => _launchURL('tel:+254700000000', context), // Replace with real SokoTender number
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Us',
              subtitle: 'Fastest way to get help',
              iconColor: Colors.green,
              bgColor: Colors.green.shade50,
              onTap: () => _launchURL('https://wa.me/254717052716', context), // Replace with real WhatsApp link
            ),

            const SizedBox(height: 32),
            const Text('Frequently Asked Questions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 16),

            // FAQs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildFaqTile(
                    'How do I get paid?', 
                    'Once a school accepts your delivery, the payment is processed and sent directly to your registered M-Pesa number within 24 hours.'
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildFaqTile(
                    'What happens if I reject a tender?', 
                    'If you win a tender but cannot fulfill it, please cancel it in the "My Bids" tab immediately. Frequent cancellations may affect your seller rating.'
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildFaqTile(
                    'How do I update my M-Pesa number?', 
                    'Go to your Profile, select "Payment Methods", and tap "Add Another Number" to update your primary receiving account.'
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap, // Added onTap parameter
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap, // Connected the tap action
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      iconColor: const Color(0xFF2E7D32),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ),
      ],
    );
  }
}