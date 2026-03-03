import 'dart:io'; // Needed for File handling
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // The new package
import 'package:soko_tender/pages/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soko_tender/pages/profile_sub_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Loading...';
  String _phoneNumber = 'Loading...';
  String? _avatarUrl; // Holds the image URL
  bool _isUploading = false; // Loading state for the image

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profileData = await supabase
            .from('profiles')
            .select(
                'full_name, phone_number, avatar_url') // Ask for avatar_url now!
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && profileData != null) {
          setState(() {
            _fullName = profileData['full_name'] ?? 'Unknown Farmer';
            _phoneNumber = profileData['phone_number'] ?? 'No phone provided';
            _avatarUrl = profileData['avatar_url']; // Load the saved image!
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  // --- NEW: THE IMAGE UPLOAD LOGIC ---
  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    // 1. Open the gallery
    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600, // Compress it a bit so it uploads fast
      maxHeight: 600,
    );

    if (imageFile == null) return; // User canceled

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // 2. Prepare the file and path
      final file = File(imageFile.path);
      final fileExtension = imageFile.path.split('.').last;
      // Name the file their User ID so it overwrites their old one automatically
      final fileName = '${user.id}.$fileExtension';

      // 3. Upload to Supabase Storage
      await supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true), // Replace if exists
          );

      // 4. Get the public URL of the newly uploaded image
      final String publicUrl =
          supabase.storage.from('avatars').getPublicUrl(fileName);

      // 5. Save the URL to the 'profiles' database table
      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      // 6. Update the screen to show the new image
      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          // Bypass image caching so it immediately shows the new image
          _avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Color(0xFF2E7D32)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
  // -----------------------------------

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red),
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
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: const Color(0xFF2E7D32),
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  // --- UPDATED AVATAR WIDGET ---
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : _uploadProfilePicture, // Tap to upload
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          // If we have a URL, show it. Otherwise, show default placeholder.
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : const NetworkImage(
                                      'https://i.pravatar.cc/150?img=44')
                                  as ImageProvider,
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color:
                                      Colors.white) // Spinner while uploading
                              : null,
                        ),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Color(0xFF2E7D32), size: 20),
                          ),
                      ],
                    ),
                  ),
                  // -----------------------------
                  const SizedBox(height: 16),
                  Text(
                    _fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phoneNumber,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Options List (Keep this exactly the same as before)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileMenu(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Update your personal details',
                      targetScreen: const PersonalInfoScreen()),
                  const SizedBox(height: 12),
                  _buildProfileMenu(
                      context: context,
                      icon: Icons.agriculture_outlined,
                      title: 'My Farm Details',
                      subtitle: 'Manage location and produce types',
                      targetScreen: const FarmDetailsScreen()),
                  const SizedBox(height: 12),
                  _buildProfileMenu(
                      context: context,
                      icon: Icons.payments_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage your M-Pesa numbers',
                      targetScreen: const PaymentMethodsScreen()),
                  const SizedBox(height: 12),
                  // _buildProfileMenu(
                  //   context: context,
                  //   icon: Icons.language,
                  //   title: 'Language',
                  //   subtitle: 'English / Kiswahili',
                  //   targetScreen: const LanguageScreen(),
                  // ),
                  // const SizedBox(height: 12),
                  _buildProfileMenu(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Talk to customer care',
                    targetScreen: const HelpSupportScreen(),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget stays the same
  Widget _buildProfileMenu({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? targetScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          if (targetScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Screen coming soon!')),
            );
          }
        },
      ),
    );
  }
}
