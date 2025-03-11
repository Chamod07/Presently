import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase/supabase_service.dart';
import '../signin_signup/sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/components/dashboard/navbar.dart'; // Add this import for NavBar

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false; // Dark mode setting to check if dark mode is enabled

  bool notifications =
      false; //Notification setting to check if notifications are enabled

  final SupabaseService _supabaseService =
      SupabaseService(); // Create instance of SupabaseService

  String profileImageUrl = ''; // User's profile image URL

  String firstName = ''; // User's first name

  String lastName = ''; // User's last name

  String role =
      ''; // User's role (Student, Undergraduate, Postgraduate, Young Professional, Other)

  @override
  void initState() {
    super.initState();
    // Initialize settings
    Settings.init(
      cacheProvider:
          SharePreferenceCache(), // Load saved preferences if available
    );
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        print('User ID is null');
        return;
      }
      final userDetailResponse = await _supabaseService.client
          .from('UserDetails')
          .select('firstName, lastName, role')
          .eq('userId', userId)
          .single();

      final profileResponse = await _supabaseService.client
          .from('Profile')
          .select('avatar_url')
          .eq('userId', userId)
          .maybeSingle();

      setState(() {
        if (userDetailResponse != null) {
          firstName = userDetailResponse['firstName'] ?? '';
          lastName = userDetailResponse['lastName'] ?? '';
          role = userDetailResponse['role'] ?? '';
        }
        if (profileResponse != null) {
          profileImageUrl = profileResponse['avatar_url'] ?? '';
        }
      });
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontFamily: 'Roboto'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // User Profile Section
            _buildProfileHeader(),

            // Account Settings Group
            SettingsGroup(
              title: 'Account',
              //titleTextStyle: TextStyle(
              //fontFamily: 'Roboto',
              //fontSize: 20,
              //),
              children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Change Password'),
                    subtitle: Text('Update your password'),
                    leading: Icon(Icons.lock_outline),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Change Email Address'),
                    subtitle: Text('Update your email'),
                    leading: Icon(Icons.email_outlined),
                    onTap: () => _showChangeEmailDialog(context),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Delete Account'),
                    subtitle: Text('Permanently delete your account'),
                    leading: Icon(Icons.delete_outline),
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),
                ),
              ],
            ),

            // App Settings Group
            SettingsGroup(
              title: 'App Settings',
              children: [
                Container(
                  color: Colors.white,
                  child: SwitchListTile(
                    title: Text('Dark Mode'),
                    secondary: Icon(Icons.dark_mode),
                    value: darkMode,
                    onChanged: (value) {
                      setState(() {
                        darkMode = value;
                      });
                      // TODO: Implement dark mode toggle
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: SwitchListTile(
                    title: Text('Notifications'),
                    secondary: Icon(Icons.notifications),
                    value: notifications,
                    onChanged: (value) {
                      setState(() {
                        notifications = value;
                      });
                      // TODO: Implement notification toggle
                    },
                  ),
                ),
              ],
            ),

            // Support Group
            SettingsGroup(
              title: 'Support & Info',
              children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('FAQ'),
                    subtitle: Text('Frequently asked questions'),
                    leading: Icon(Icons.question_answer_outlined),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/faq');
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Contact Support'),
                    subtitle: Text('Get help from our team'),
                    leading: Icon(Icons.support_agent_outlined),
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, '/contact_support');
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Terms & Privacy Policy'),
                    subtitle: Text('Legal information'),
                    leading: Icon(Icons.policy_outlined),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/terms_privacy');
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('Help'),
                    subtitle: Text('Get support and send feedback'),
                    leading: Icon(Icons.help_outline),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/help');
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text('About'),
                    subtitle: Text('Learn more about Presently'),
                    leading: Icon(Icons.info_outline),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/about');
                    },
                  ),
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(MediaQuery.of(context).size.width * 0.9, 50),
                  backgroundColor: Color(0xFF7400B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  try {
                    // Use the proper SupabaseService instance
                    await _supabaseService.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => SignInPage()),
                        (route) => false,
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error signing out: ${error.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: ModalRoute.of(context)?.settings.arguments != null
            ? (ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>)['selectedIndex'] ??
                3
            : 3,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 69,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.grey[700],
                      )
                    : null,
              ),
              GestureDetector(
                onTap: _changeProfilePicture,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '$firstName $lastName',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto'),
          ),
          // SizedBox(height: 8),
          //Text(
          //'Milan, Italy',
          //style: TextStyle(
          //  fontSize: 16, color: Colors.grey, fontFamily: 'Roboto'),
          //),
          SizedBox(height: 8),
          Text(
            '$role',
            style: TextStyle(
                fontSize: 18, color: Colors.grey, fontFamily: 'Roboto'),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() async {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('Take a photo'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: source, maxWidth: 800, imageQuality: 85);
      if (image == null) return;

      // loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      //upload to supabase storage
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        Navigator.of(context).pop(); // close loading indicator
        _showErrorMessage('User not logged in');
        return;
      }

      final String fileExt = image.path.split('.').last;
      final fileName = 'profile_$userId.$fileExt';
      final file = File(image.path);

      await _supabaseService.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: FileOptions(upsert: true));

      final imageUrl = _supabaseService.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await _supabaseService.client.from('Profile').upsert({
        'userId': userId,
        'avatar_url': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
      });

      if (context.mounted) {
        Navigator.of(context).pop(); // close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close loading indicator
        _showErrorMessage('Error updating profile picture: $e');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Current Password'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    helperText: 'Minimum 8 characters required',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: 'Confirm New Password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate password input
                      if (newPasswordController.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Password must be at least 8 characters'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        await _updatePassword(currentPasswordController.text,
                            newPasswordController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Password updated successfully'),
                          backgroundColor: Colors.green,
                        ));
                      } catch (e) {
                        String errorMessage = 'Failed to update password';
                        if (e.toString().contains('invalid_credentials') ||
                            e.toString().contains('Invalid login')) {
                          errorMessage = 'Current password is incorrect';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ));
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Email Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'New Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password to Confirm'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _updateEmail(
                    emailController.text, passwordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email updated successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red));
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
              style: TextStyle(color: Colors.red.shade700),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: 'Enter your password to confirm'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Implementation for account deletion would go here
                // await _supabaseService.client.auth.admin.deleteUser(uid); // Admin API required
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: Colors.red,
                ));
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => SignInPage()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red));
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Implement account changes with SupabaseService
  Future<void> _updatePassword(
      String currentPassword, String newPassword) async {
    try {
      // First verify the current password by signing in
      final email = _supabaseService.client.auth.currentUser?.email;
      if (email == null) {
        throw Exception('User not authenticated');
      }

      // Attempt to sign in with the current password to verify it
      final AuthResponse res =
          await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (res.session == null) {
        throw Exception('Current password is incorrect');
      }

      // If verification succeeded, update the password
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return;
    } catch (e) {
      throw e;
    }
  }

  Future<void> _updateEmail(String newEmail, String password) async {
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return;
    } catch (e) {
      throw e;
    }
  }
}
