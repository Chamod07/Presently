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

  Future<bool> checkIfEmailExists(String email) async {
    try {
      await supabase.auth.signInWithOtp(
        email: email,
      );
      return true; // If no error is thrown, email exists
    } catch (e) {
      if (e.toString().contains('Email rate limit exceeded')) {
        return true; // Email exists but rate limited
      }
      return false; // Email doesn't exist
    }
  }

  Future<void> signUpWithEmail() async {
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
      // First check if email exists
      final emailExists = await checkIfEmailExists(_emailController.text.trim());

      if (emailExists) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Account Already Exists'),
                content: const Text('An account with this email already exists. Please sign in instead.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/sign_in');
                    },
                    child: const Text('Go to Sign In'),
                  ),
                ],
              );
            },
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // If email doesn't exist, proceed with signup
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res.session == null) {
        if (mounted) {
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Verification Required'),
                content: const Text('A verification email has been sent. Please verify your email to complete Sign up'),
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
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorText = 'Sign up failed: ${e.toString()}';
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
                      borderSide: BorderSide(color: emailError ? Colors.red : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: emailError ? Colors.red : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: emailError ? Colors.red : Color(0xFF7400B8)),
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
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: passwordError ? Colors.red : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: passwordError ? Colors.red : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: passwordError ? Colors.red : Color(0xFF7400B8)),
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
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: confirmPasswordError ? Colors.red : Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: confirmPasswordError ? Colors.red : Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: confirmPasswordError ? Colors.red : Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : signUpWithEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
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