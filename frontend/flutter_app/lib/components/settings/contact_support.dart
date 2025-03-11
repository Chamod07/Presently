import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: 'chamodkarunathilake@gmail.com',
          query:
              'subject=Presently Support Request&body=Name: ${_nameController.text}\nEmail: ${_emailController.text}\n\n${_messageController.text}',
        );

        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending email: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
              subtitle: const Text('chamodkarunathilake@gmail.com',
                  style: TextStyle(fontFamily: 'Roboto')),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'chamodkarunathilake@gmail.com',
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
