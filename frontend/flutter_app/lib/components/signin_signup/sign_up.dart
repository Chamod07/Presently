import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

final supabase = Supabase.instance.client;

class _SignUpPageState extends State<SignUpPage> {
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
    final session = supabase.auth.currentSession;
    if (session != null && mounted) {
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

      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        // Use the correct parameter format based on the Supabase SDK version
        data: {
          'email_confirmed': true,
        },
        // No need for emailRedirectTo since we're bypassing email confirmation
      );

      // Debug log after sign-up
      debugPrint('Sign-up response received:');
      debugPrint('User: ${res.user != null ? 'exists' : 'null'}');
      debugPrint('Session: ${res.session != null ? 'exists' : 'null'}');

      if (mounted) {
        // Simplified logic: consider sign-up successful if we got a response with user
        if (res.user != null) {
          debugPrint('User created successfully');

          // Always proceed to account setup regardless of session status
          // No more email verification check
          Navigator.pushReplacementNamed(context, '/account_setup_1');
        } else {
          // Instead of throwing an error, show a meaningful message
          setState(() {
            errorText = 'Unable to create account. Please try again later.';
          });
        }
      }
    } on AuthException catch (e) {
      debugPrint('AuthException during sign-up: ${e.message}');
      if (mounted) {
        setState(() {
          if (e.message.contains('email')) {
            emailError = true;
          }
          errorText = 'Sign up failed: ${e.message}';
        });
      }
    } catch (e) {
      debugPrint('Unexpected error during sign-up: $e');
      if (mounted) {
        setState(() {
          // Make the error message more user-friendly
          errorText =
              'Something went wrong. Please check your internet connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
