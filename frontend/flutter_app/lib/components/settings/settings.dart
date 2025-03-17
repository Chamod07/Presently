import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/settings/about_page.dart';
import 'package:flutter_app/components/settings/contact_support.dart';
import 'package:flutter_app/components/settings/faq.dart';
import 'package:flutter_app/components/settings/help_page.dart';
import 'package:flutter_app/components/settings/terms_privacy.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase/supabase_service.dart';
import '../signin_signup/sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:http/http.dart' as http;

// Custom exception to handle partial success
class DatabaseUpdateSuccess implements Exception {
  final String message;
  DatabaseUpdateSuccess([this.message = 'Database updated but auth failed']);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  String profileImageUrl = '';
  String firstName = '';
  String lastName = '';
  String role = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize settings
    Settings.init(
      cacheProvider: SharePreferenceCache(),
    );
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        debugPrint('User ID is null');
        return;
      }
      final userDetailResponse = await _supabaseService.client
          .from('UserDetails')
          .select('firstName, lastName, role')
          .eq('userId', userId)
          .single();

      if (userDetailResponse != null) {
        firstName = userDetailResponse['firstName'] ?? '';
        lastName = userDetailResponse['lastName'] ?? '';
        role = userDetailResponse['role'] ?? '';
      }

      final extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      String? avatarUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get avatar URL
      for (final ext in extensions) {
        try {
          final url =
              '${_supabaseService.client.storage.from('avatars').getPublicUrl('avatar_$userId.$ext')}?t=$timestamp';

          // Test if URL exists
          final response = await http.head(Uri.parse(url));
          if (response.statusCode == 200) {
            avatarUrl = url;
            break;
          }
        } catch (_) {
          // Continue trying other extensions
        }
      }

      if (avatarUrl != null) {
        debugPrint('Found avatar URL: $avatarUrl');
        profileImageUrl = avatarUrl;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7400B8)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7400B8),
              fontFamily: 'Roboto'),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7400B8)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Improved profile section
                  _buildImprovedProfileSection(),

                  const SizedBox(height: 20),

                  // Account Settings
                  _buildSettingsHeader("Account Settings"),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'Change Name',
                      icon: Icons.person_outline,
                      onTap: () => _showChangeNameDialog(context),
                    ),
                    _buildSettingItem(
                      title: 'Change Password',
                      icon: Icons.lock_outline,
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    _buildSettingItem(
                      title: 'Change Email Address',
                      icon: Icons.email_outlined,
                      onTap: () => _showChangeEmailDialog(context),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Support & Help
                  _buildSettingsHeader("Support & Help"),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'FAQ',
                      icon: Icons.question_answer_outlined,
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => FAQPage()));
                      },
                    ),
                    _buildSettingItem(
                      title: 'Contact Support',
                      icon: Icons.support_agent_outlined,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ContactSupportPage()));
                      },
                    ),
                    _buildSettingItem(
                      title: 'Help',
                      icon: Icons.help_outline,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HelpPage()));
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Legal & Info
                  _buildSettingsHeader("Legal & Info"),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'Terms & Privacy Policy',
                      icon: Icons.policy_outlined,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TermsPrivacyPage()));
                      },
                    ),
                    _buildSettingItem(
                      title: 'About Presently',
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AboutPage()));
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Danger Zone
                  _buildSettingsHeader("Danger Zone",
                      textColor: Colors.red[700]),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'Delete Account',
                      icon: Icons.delete_outline,
                      iconColor: Colors.red[700],
                      textColor: Colors.red[700],
                      onTap: () => _showDeleteAccountConfirmation(context),
                    ),
                  ], borderColor: Colors.red[100]),

                  // Sign out button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        try {
                          await _supabaseService.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => SignInPage()),
                              (route) => false,
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error signing out: ${error.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildImprovedProfileSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          // subtle and professional color scheme
          color: Colors.white),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Profile image with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 136, 60, 179),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl,
                          headers: {'Cache-Control': 'no-cache'})
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF7400B8),
                        )
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _changeProfilePicture,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7400B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // User name
          Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          // User role in a container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7400B8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.isNotEmpty ? role : 'No role specified',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                color: Color(0xFF7400B8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Email with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _supabaseService.client.auth.currentUser?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(String title, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF333333),
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, {Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? const Color(0xFF7400B8),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  color: textColor ?? const Color(0xFF333333),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Update Profile Picture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7400B8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF7400B8),
                  ),
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7400B8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Color(0xFF7400B8),
                  ),
                ),
                title: const Text('Take a photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7400B8),
            ),
          );
        },
      );

      //upload to supabase storage
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
          _showErrorMessage('User not logged in');
        }
        return;
      }

      await _deleteExistingProfileImages(userId);

      final file = File(image.path);
      final String fileExt = image.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName = 'avatar_${userId}_$timestamp.$fileExt';

      debugPrint('Uploading new avatar: $fileName');

      await _supabaseService.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: FileOptions(upsert: true));

      final imageUrl =
          '${_supabaseService.client.storage.from('avatars').getPublicUrl(fileName)}?t=$timestamp';

      debugPrint('Uploaded image URL with cache-buster: $imageUrl');

      await precacheImage(NetworkImage(imageUrl), context);

      setState(() {
        profileImageUrl = imageUrl;
      });

      if (context.mounted) {
        Navigator.of(context).pop(); // close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorMessage('Error updating profile picture: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteExistingProfileImages(String userId) async {
    try {
      // List all files in the avatars bucket
      debugPrint('Listing all files in avatars bucket for user $userId');
      final listResponse =
          await _supabaseService.client.storage.from('avatars').list();

      debugPrint('Total files in bucket: ${listResponse.length}');

      // Print all file names for debugging
      for (var file in listResponse) {
        debugPrint('Found file: ${file.name}');
      }

      // Filter files that match this user's avatar pattern
      final userFiles = listResponse.where((file) {
        final isMatch = file.name.contains('avatar_$userId');
        if (isMatch) debugPrint('Matching file found: ${file.name}');
        return isMatch;
      }).toList();

      if (userFiles.isNotEmpty) {
        final filesToDelete = userFiles.map((file) => file.name).toList();
        debugPrint('Found files to delete: ${filesToDelete.join(', ')}');

        // Delete files one by one to identify any specific issues
        for (var fileName in filesToDelete) {
          try {
            debugPrint('Attempting to delete: $fileName');
            await _supabaseService.client.storage
                .from('avatars')
                .remove([fileName]);
            debugPrint('Successfully deleted: $fileName');
          } catch (e) {
            debugPrint('Error deleting file $fileName: $e');
          }
        }

        debugPrint('Deletion process completed');
      } else {
        debugPrint('No existing avatar files found for user $userId');
      }
    } catch (e) {
      debugPrint('Error during avatar deletion: $e');
      // Continue with upload even if deletion fails
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    helperText: 'Minimum 8 characters required',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validate password input
                              if (newPasswordController.text.length < 8) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Password must be at least 8 characters'),
                                  backgroundColor: Colors.red,
                                ));
                                return;
                              }

                              if (newPasswordController.text !=
                                  confirmPasswordController.text) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Passwords do not match'),
                                  backgroundColor: Colors.red,
                                ));
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                await _updatePassword(
                                    currentPasswordController.text,
                                    newPasswordController.text);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text('Password updated successfully'),
                                  backgroundColor: Colors.green,
                                ));
                              } catch (e) {
                                String errorMessage =
                                    'Failed to update password';
                                if (e
                                        .toString()
                                        .contains('invalid_credentials') ||
                                    e.toString().contains('Invalid login')) {
                                  errorMessage =
                                      'Current password is incorrect';
                                }
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ));
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Email Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'New Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validate email format
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                              if (!emailRegex
                                  .hasMatch(emailController.text.trim())) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Please enter a valid email address'),
                                  backgroundColor: Colors.red,
                                ));
                                return;
                              }

                              if (passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Please enter your current password'),
                                  backgroundColor: Colors.red,
                                ));
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                await _updateEmail(emailController.text.trim(),
                                    passwordController.text);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Email update initiated. Please check your new email inbox for verification.'),
                                  backgroundColor: Colors.green,
                                ));
                              } catch (e) {
                                String errorMessage = 'Failed to update email';
                                if (e
                                        .toString()
                                        .contains('invalid_credentials') ||
                                    e.toString().contains('Invalid login')) {
                                  errorMessage =
                                      'Current password is incorrect';
                                } else if (e
                                    .toString()
                                    .contains('already in use')) {
                                  errorMessage = 'This email is already in use';
                                }
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ));
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter your password to confirm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Delete'),
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

  // Add this new method for the name change dialog
  void _showChangeNameDialog(BuildContext context) {
    final TextEditingController firstNameController =
        TextEditingController(text: firstName);
    final TextEditingController lastNameController =
        TextEditingController(text: lastName);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Name',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validate name input
                              final String newFirstName =
                                  firstNameController.text.trim();
                              final String newLastName =
                                  lastNameController.text.trim();

                              if (newFirstName.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('First name cannot be empty'),
                                  backgroundColor: Colors.red,
                                ));
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                await _updateName(newFirstName, newLastName);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Name updated successfully'),
                                  backgroundColor: Colors.green,
                                ));
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Failed to update name: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ));
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to update the name in Supabase
  Future<void> _updateName(String newFirstName, String newLastName) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update the user details in the database
      await _supabaseService.client.from('UserDetails').update({
        'firstName': newFirstName,
        'lastName': newLastName,
      }).eq('userId', userId);

      // Update the local state
      setState(() {
        firstName = newFirstName;
        lastName = newLastName;
      });
    } catch (e) {
      debugPrint('Error updating name: $e');
      throw e;
    }
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
      // First verify the current password by signing in
      final currentEmail = _supabaseService.client.auth.currentUser?.email;
      final userId = _supabaseService.currentUserId;

      if (currentEmail == null || userId == null) {
        throw Exception('User not authenticated');
      }

      // Attempt to sign in with the current password to verify it
      final AuthResponse res =
          await _supabaseService.client.auth.signInWithPassword(
        email: currentEmail,
        password: password,
      );

      if (res.session == null) {
        throw Exception('Current password is incorrect');
      }

      try {
        // Update the authentication email - this will send a verification email
        await _supabaseService.client.auth.updateUser(
          UserAttributes(email: newEmail),
        );

        debugPrint('Auth email update successful');
        return;
      } catch (e) {
        debugPrint('Error during email update: $e');
        throw e;
      }
    } catch (e) {
      throw e;
    }
  }
}
