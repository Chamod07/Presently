import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Use the service to access the client consistently
  final _supabaseService = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool emailError = false;
  bool passwordError = false;
  bool confirmPasswordError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    // Check if the user is already signed in when this page loads
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    final hasValidSession = await _supabaseService.hasValidSession();
    if (hasValidSession && mounted) {
      // User already has an active session
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> signUpWithEmail() async {
    // Clear previous errors
    setState(() {
      emailError = false;
      passwordError = false;
      confirmPasswordError = false;
      errorText = null;
    });

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        emailError = true;
        errorText = 'Please enter an email address';
      });
      return;
    }

    // Validate passwords
    if (_passwordController.text.isEmpty) {
      setState(() {
        passwordError = true;
        errorText = 'Please enter a password';
      });
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        confirmPasswordError = true;
        errorText = 'Please confirm your password';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        passwordError = true;
        confirmPasswordError = true;
        errorText = 'Passwords do not match';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Debug log before sign-up
      debugPrint(
          'Attempting to sign up with email: ${_emailController.text.trim()}');

      // Sign up with Supabase
      final AuthResponse res = await _supabaseService.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Debug logs
      debugPrint('Sign-up response received');
      debugPrint('User: ${res.user != null ? "created" : "null"}');
      debugPrint('Session: ${res.session != null ? "active" : "null"}');

      // Check if sign-up was successful
      if (res.user != null) {
        debugPrint('User ID: ${res.user!.id}');

        try {
          // Create user details record with all required fields
          // Include empty defaults for fields that will be populated later
          final userDetailsResponse =
              await _supabaseService.client.from('UserDetails').insert({
            'userId': res.user!.id,
            'email': _emailController.text.trim(),
            'firstName': '', // Empty but will be filled during onboarding
            'lastName': '', // Empty but will be filled during onboarding
            'role': '', // Empty but will be filled during onboarding
            'createdAt': DateTime.now().toIso8601String(),
          }).select();

          debugPrint('User details created: $userDetailsResponse');

          if (mounted) {
            // Navigate to combined account setup
            Navigator.pushReplacementNamed(
              context,
              '/account_setup',
              arguments: {'userId': res.user!.id},
            );
          }
        } catch (dbError) {
          debugPrint('Error creating user details: $dbError');

          // Try a more detailed approach to diagnose the issue
          try {
            // First check if a record already exists
            final existingRecord = await _supabaseService.client
                .from('UserDetails')
                .select()
                .eq('userId', res.user!.id)
                .maybeSingle();

            if (existingRecord != null) {
              debugPrint('Record already exists, proceeding to onboarding');
              if (mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/account_setup',
                  arguments: {'userId': res.user!.id},
                );
              }
              return;
            }

            // If no record exists, show the error
            if (mounted) {
              setState(() {
                errorText = 'Profile setup failed. Please try signing in.';
                _isLoading = false;
              });
            }
          } catch (retryError) {
            debugPrint('Error during recovery attempt: $retryError');
            if (mounted) {
              setState(() {
                errorText =
                    'Account created but profile setup failed. Please sign in with your new account.';
                _isLoading = false;
              });
            }
          }
        }
      } else {
        // If auth succeeded but no user was returned
        if (mounted) {
          setState(() {
            errorText = 'Unable to create account. Please try again later.';
            _isLoading = false;
          });
        }
      }
    } on AuthException catch (e) {
      debugPrint('AuthException during sign-up: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;

          // More specific error messages based on the error type
          if (e.message.toLowerCase().contains('email') &&
              e.message.toLowerCase().contains('taken')) {
            emailError = true;
            errorText = 'This email is already in use. Please sign in instead.';
          } else if (e.message.toLowerCase().contains('weak password')) {
            passwordError = true;
            errorText = 'Password is too weak. Please use a stronger password.';
          } else {
            errorText = 'Sign up failed: ${e.message}';
          }
        });
      }
    } catch (e) {
      debugPrint('Unexpected error during sign-up: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Provide more specific error message if possible
          if (e.toString().contains('network')) {
            errorText =
                'Network error. Please check your internet connection and try again.';
          } else {
            errorText =
                'Something went wrong. Please try again or contact support.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'images/SignIn_SignUp.png',
                  height: 252,
                  width: 240,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Sign Up",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 10),
              if (errorText != null)
                Text(
                  errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Roboto',
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Enter your email",
                    labelStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Enter your password",
                    labelStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                    ),
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
                    labelText: "Confirm password",
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : signUpWithEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(MediaQuery.of(context).size.width * 0.9, 50),
                  backgroundColor: Color(0xFF7400B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/sign_in'),
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: Color(0xFF7400B8),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
