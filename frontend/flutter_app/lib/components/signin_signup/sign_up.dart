import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

    // Add email format validation
    final emailRegex = RegExp(r'^[a-z0-9.-]+@([a-z0-9-]+\.)+[a-z]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        emailError = true;
        errorText = 'Please enter a valid email address';
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

    // Enhanced password validation
    final String password = _passwordController.text;
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
          final errorMsg = e.message.toLowerCase();

          // Handle existing user case
          if (errorMsg.contains('user already registered') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('already in use') ||
              errorMsg.contains('taken')) {
            debugPrint('Detected existing user case, showing dialog');
            emailError = true;
            errorText = 'This email is already registered';

            // We'll use Future.delayed to ensure setState has completed
            Future.delayed(Duration.zero, () {
              _showExistingUserDialog();
            });
          } else if (errorMsg.contains('password') &&
              (errorMsg.contains('should contain') ||
                  errorMsg.contains('at least one character') ||
                  errorMsg.contains('weak'))) {
            // Handle complex password requirements with a user-friendly message
            passwordError = true;
            errorText =
                'Password must be at least 8 characters long and include lowercase, uppercase, numbers, and special characters';
          } else if (errorMsg.contains('email') &&
              errorMsg.contains('invalid')) {
            emailError = true;
            errorText = 'Please enter a valid email address';
          } else if (errorMsg.contains('too many requests') ||
              errorMsg.contains('rate limit')) {
            errorText = 'Too many signup attempts. Please try again later';
          } else {
            errorText =
                'Sign up failed. Please check your information and try again';
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

  void _showExistingUserDialog() {
    debugPrint('Showing existing user dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: const Text(
              'An account with this email already exists. Would you like to sign in instead?'),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('Cancel button pressed');
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint('Sign In button pressed');
                Navigator.of(dialogContext).pop();

                // Use Navigator.of(context) not dialogContext for this navigation
                Navigator.of(context).pushReplacementNamed('/sign_in',
                    arguments: {'email': _emailController.text.trim()});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7400B8),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add signUpWithGoogle method after signUpWithEmail
  Future<void> signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      errorText = null;
    });

    try {
      const webClientId =
          '54044305887-0cl2lddi9hjremm4o5evdng9d7ardjes.apps.googleusercontent.com';
      const iosClientId =
          '54044305887-l8mqfssark4jlbsru5dt8pu85vpjvh2h.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      // Sign out first to ensure we get the sign-in dialog
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('User canceled Google sign-in');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken != null && idToken != null) {
        // Use the client from the service
        final response = await _supabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (response.session != null) {
          // Check if this is a new user by checking if user details exist
          final user = response.user;
          if (user != null) {
            try {
              final existingDetails = await _supabaseService.client
                  .from('UserDetails')
                  .select()
                  .eq('userId', user.id)
                  .maybeSingle();

              if (existingDetails == null) {
                // New user - create user details
                await _supabaseService.client.from('UserDetails').insert({
                  'userId': user.id,
                  'email': user.email,
                  'firstName': '', // Empty but will be filled during onboarding
                  'lastName': '', // Empty but will be filled during onboarding
                  'role': '', // Empty but will be filled during onboarding
                  'createdAt': DateTime.now().toIso8601String(),
                });

                if (mounted) {
                  // Navigate to account setup for new users
                  Navigator.pushReplacementNamed(
                    context,
                    '/account_setup',
                    arguments: {'userId': user.id},
                  );
                }
              } else {
                // Existing user, go to home
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            } catch (dbError) {
              debugPrint('Error checking/creating user details: $dbError');
              // Still redirect to account setup as fallback
              if (mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/account_setup',
                  arguments: {'userId': user.id},
                );
              }
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          errorText = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorText = e.toString().contains('canceled') ||
                  e.toString().contains('cancelled')
              ? 'Google sign-up was cancelled'
              : 'Failed to sign up with Google: ${e.toString()}';
        });
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
                children: [
                  Expanded(
                    child: Divider(
                      color: const Color(0xFFF5F5F7),
                      thickness: 1,
                      endIndent: 10,
                    ),
                  ),
                  Text(
                    'or',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: const Color(0xFFF5F5F7),
                      thickness: 1,
                      indent: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : signUpWithGoogle,
                icon: Image.asset('images/google_720255.png',
                    height: 20, width: 20),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF333333),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      Size(MediaQuery.of(context).size.width * 0.9, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0x26000000)),
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
