import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/supabase_service.dart';
import '../signin_signup/sign_in.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Create instance of SupabaseService
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    // Initialize settings
    Settings.init(cacheProvider: SharePreferenceCache());

    // Load saved preferences if available
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
          style: TextStyle(
              fontSize: 20,
              fontFamily: 'Roboto'
          ),
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
              titleTextStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
              ),
              children: [
                SimpleSettingsTile(
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  leading: Icon(Icons.lock_outline),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                SimpleSettingsTile(
                  title: 'Change Email Address',
                  subtitle: 'Update your email',
                  leading: Icon(Icons.email_outlined),
                  onTap: () => _showChangeEmailDialog(context),
                ),
                SimpleSettingsTile(
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  onTap: () => _showDeleteAccountConfirmation(context),
                ),
              ],
            ),

            // App Settings Group
            SettingsGroup(
              title: 'App Settings',
              children: [
                SwitchSettingsTile(
                  settingKey: 'dark_mode',
                  title: 'Dark Mode',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: Icon(Icons.dark_mode),
                  onChange: (value) {
                    setState(() {});
                    // TODO: Implement dark mode toggle
                  },
                ),
                SwitchSettingsTile(
                  settingKey: 'notifications',
                  title: 'Notifications',
                  enabledLabel: 'Enabled',
                  disabledLabel: 'Disabled',
                  leading: Icon(Icons.notifications),
                  onChange: (value) {
                    setState(() {});
                    // TODO: Implement notification toggle
                  },
                ),
              ],
            ),

            // Support Group
            SettingsGroup(
              title: 'Support & Info',
              children: [
                SimpleSettingsTile(
                  title: 'FAQ',
                  subtitle: 'Frequently asked questions',
                  leading: Icon(Icons.question_answer_outlined),
                  onTap: () {
                    // Navigate to FAQ page
                  },
                ),
                SimpleSettingsTile(
                  title: 'Contact Support',
                  subtitle: 'Get help from our team',
                  leading: Icon(Icons.support_agent_outlined),
                  onTap: () {
                    // Navigate to support page or open email
                  },
                ),
                SimpleSettingsTile(
                  title: 'Terms & Privacy Policy',
                  subtitle: 'Legal information',
                  leading: Icon(Icons.policy_outlined),
                  onTap: () {
                    // Navigate to terms page
                  },
                ),
                SimpleSettingsTile(
                  title: 'Help',
                  subtitle: 'Get support and send feedback',
                  leading: Icon(Icons.help_outline),
                  onTap: () {
                    // TODO: Implement help section
                  },
                ),
                SimpleSettingsTile(
                  title: 'About',
                  subtitle: 'Learn more about Presently',
                  leading: Icon(Icons.info_outline),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/about');
                  },
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
                backgroundImage: AssetImage('assets/profile_placeholder.png'),
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
            'Given name of user',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto'
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Milan, Italy',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Roboto'
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Given ',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontFamily: 'Roboto'
            ),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() async {
    // TODO Implement image picker and upload
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile picture change will be implemented soon')));
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
    TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
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
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                try {
                  await _updatePassword(currentPasswordController.text,
                      newPasswordController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password updated successfully')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red));
              }
            },
            child: Text('Update'),
          ),
        ],
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
