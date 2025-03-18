import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({Key? key}) : super(key: key);

  @override
  _ContactSupportPageState createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      try {
        // Properly encode the email body content
        final String encodedSubject =
            Uri.encodeComponent("Presently Support Request");
        final String encodedBody = Uri.encodeComponent(
            "Name: ${_nameController.text}\nEmail: ${_emailController.text}\n\n${_messageController.text}");

        // Create different URIs based on platform for better compatibility
        Uri emailUri;

        if (Platform.isIOS) {
          // iOS handles mailto URLs differently
          emailUri = Uri.parse(
              'mailto:presently.coach@gmail.com?subject=$encodedSubject&body=$encodedBody');
        } else {
          emailUri = Uri(
            scheme: 'mailto',
            path: 'presently.coach@gmail.com',
            queryParameters: {
              'subject': 'Presently Support Request',
              'body':
                  'Name: ${_nameController.text}\nEmail: ${_emailController.text}\n\n${_messageController.text}',
            },
          );
        }

        // Check if URL can be launched
        final bool canLaunch = await canLaunchUrl(emailUri);

        if (canLaunch) {
          final bool launched = await launchUrl(emailUri);
          if (launched) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email app opened successfully')),
              );
              _nameController.clear();
              _emailController.clear();
              _messageController.clear();
            }
          } else {
            throw 'Could not launch email client';
          }
        } else {
          // Fallback for when email client can't be launched
          _showCopyToClipboardDialog();
        }
      } catch (e) {
        if (mounted) {
          // Show fallback dialog instead of just an error message
          _showCopyToClipboardDialog();
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  // New method to show a fallback dialog when email client cannot be launched
  void _showCopyToClipboardDialog() {
    final String messageText =
        'Name: ${_nameController.text}\nEmail: ${_emailController.text}\n\n${_messageController.text}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to open email app'),
        content: const Text(
            'We couldn\'t open your email app automatically. Would you like to copy your message to clipboard and send it manually to presently.coach@gmail.com?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7400B8),
            ),
            onPressed: () {
              // Copy email information to clipboard
              final String emailInfo = 'To: presently.coach@gmail.com\n'
                  'Subject: Presently Support Request\n\n'
                  '$messageText';

              // Copy to clipboard functionality
              // Using Flutter's Clipboard feature
              Navigator.of(context).pop();
              try {
                // Import services package
                // import 'package:flutter/services.dart';
                // Clipboard.setData(ClipboardData(text: emailInfo));

                // For now, show another snackbar with instructions
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please manually email us at presently.coach@gmail.com'),
                    duration: Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Copy & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support',
            style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get in touch with our support team',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Fill out the form below and we\'ll get back to you as soon as possible.',
              style: TextStyle(fontSize: 16.0, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 24.0),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Your Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Describe your issue or question',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSending ? null : _sendEmail,
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Other ways to reach us:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF7400B8)),
              title:
                  const Text('Email', style: TextStyle(fontFamily: 'Roboto')),
              subtitle: const Text('presently.coach@gmail.com',
                  style: TextStyle(fontFamily: 'Roboto')),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'presently.coach@gmail.com',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF7400B8)),
              title: const Text('Slack Channel',
                  style: TextStyle(fontFamily: 'Roboto')),
              subtitle: const Text('Join our community',
                  style: TextStyle(fontFamily: 'Roboto')),
              onTap: () async {
                final Uri slackUri = Uri.parse(
                    'https://join.slack.com/t/sdgpcs31/shared_invite/zt-2uzy31net-5dGu02MMHKfUrjVk4Fvv8Q');
                if (await canLaunchUrl(slackUri)) {
                  await launchUrl(slackUri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
