import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _supabaseService = SupabaseService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool passwordError = false;
  bool confirmPasswordError = false;
  String? errorText;
  String? _token;

  @override
  void initState() {
    super.initState();
    // Check if we already have an active session (from deep link)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentSession();
    });
  }

  Future<void> _checkCurrentSession() async {
    final hasValidSession = await _supabaseService.hasValidSession();
    if (hasValidSession) {
      debugPrint(
          'Valid session found in ResetPasswordPage - we can reset password');

      // Check if this is an OAuth user
      final currentUser = await _supabaseService.client.auth.currentUser;
      if (currentUser != null) {
        final identities = currentUser.identities;
        final isOAuthOnlyUser = identities != null &&
            identities.length == 1 &&
            identities[0].provider != 'email';

        if (isOAuthOnlyUser) {
          debugPrint('This is an OAuth-only user, cannot reset password');
          // Show error and redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Password Reset Not Available'),
                  content: const Text(
                    'You signed up using Google, not with an email and password. '
                    'Please continue to use Google to sign in to your account.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/sign_in');
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          });
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the token from the route arguments if available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('token')) {
      _token = args['token'];
      debugPrint(
          'Reset password page received token: ${_token != null ? 'Yes (${_token!.length} chars)' : 'No'}');

      // Try to verify the token is valid
      _verifyToken();
    } else {
      debugPrint('No token received in ResetPasswordPage arguments');
      // We may not have a token in args but might have a valid session from the deep link code
    }
  }

  Future<void> _verifyToken() async {
    if (_token == null) return;

    try {
      // Try to set the session with the token to verify it's valid
      await _supabaseService.client.auth.setSession(_token!);
      debugPrint('Token successfully verified');
    } catch (e) {
      debugPrint('Error verifying token: $e');
      setState(() {
        errorText =
            'Invalid or expired reset token. Please request a new password reset link.';
      });
    }
  }

  Future<void> _resetPassword() async {
    // Clear previous errors
    setState(() {
      passwordError = false;
      confirmPasswordError = false;
      errorText = null;
    });

    // Validate passwords
    if (_newPasswordController.text.isEmpty) {
      setState(() {
        passwordError = true;
        errorText = 'Please enter a new password';
      });
      return;
    }

    // Enhanced password validation
    final String password = _newPasswordController.text;
    if (password.length < 8) {
      setState(() {
        passwordError = true;
        errorText = 'Password must be at least 8 characters long';
      });
      return;
    }

    // Check for lowercase, uppercase, digits, and symbols
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasLowercase || !hasUppercase || !hasDigit || !hasSpecialChar) {
      setState(() {
        passwordError = true;
        errorText =
            'Password must include lowercase, uppercase, numbers, and special characters';
      });
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        confirmPasswordError = true;
        errorText = 'Please confirm your new password';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        passwordError = true;
        confirmPasswordError = true;
        errorText = 'Passwords do not match';
      });
      return;
    }

    // If token is missing, show an error
    if (_token == null) {
      setState(() {
        errorText = 'Invalid reset link. Please request a new password reset.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the password - we don't necessarily need a token if we have a valid session
      final res = await _supabaseService.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (res.user != null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show success message and redirect to sign in
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Password Reset Successful'),
                content: const Text(
                  'Your password has been reset successfully. You can now sign in with your new password.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/sign_in');
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              );
            },
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // More specific error messages
          final errorMsg = e.message.toLowerCase();

          if (errorMsg.contains('password') &&
              (errorMsg.contains('should contain') ||
                  errorMsg.contains('at least one character') ||
                  errorMsg.contains('weak'))) {
            passwordError = true;
            errorText =
                'Password must include lowercase, uppercase, numbers, and special characters';
          } else if (errorMsg.contains('expired')) {
            errorText =
                'The reset link has expired. Please request a new password reset.';
          } else if (errorMsg.contains('invalid')) {
            errorText =
                'Invalid reset link. Please request a new password reset.';
          } else {
            errorText = 'Failed to reset password: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          errorText =
              'Something went wrong. Please try again or request a new reset link.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7400B8),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "Create New Password",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Your new password must be different from previously used passwords.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (errorText != null)
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE), // Light red background
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFEF5350), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD32F2F),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontFamily: 'Roboto',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "New password",
                    labelStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                    ),
                    helperText:
                        "8+ chars with lowercase, uppercase, numbers & symbols",
                    helperStyle: TextStyle(
                      color: Color(0xFF757575),
                      fontFamily: "Roboto",
                      fontSize: 12,
                    ),
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color:
                              passwordError ? Colors.red : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color:
                              passwordError ? Colors.red : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color:
                              passwordError ? Colors.red : Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm new password",
                    labelStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(MediaQuery.of(context).size.width * 0.9, 50),
                  backgroundColor: const Color(0xFF7400B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Reset Password",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/sign_in');
                },
                child: const Text(
                  "Back to Sign In",
                  style: TextStyle(
                    color: Color(0xFF7400B8),
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
