import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/supabase_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Use the service to access the client
  final _supabaseService = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool emailError = false;
  bool passwordError = false;
  bool confirmPasswordError = false;
  String? emailErrorText;
  String? passwordErrorText;
  String? confirmPasswordErrorText;

  final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  Future<void> signUpWithEmail() async {
    bool hasErrors = false;

    if (!_emailRegExp.hasMatch(_emailController.text.trim())) {
      setState(() {
        emailError = true;
        emailErrorText = 'Please enter a valid email address';
      });
      hasErrors = true;
    } else {
      setState(() {
        emailError = false;
        emailErrorText = null;
      });
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        passwordError = true;
        confirmPasswordError = true;
        passwordErrorText = 'Passwords do not match';
        confirmPasswordErrorText = 'Passwords do not match';
      });
      hasErrors = true;
    } else {
      setState(() {
        passwordError = false;
        confirmPasswordError = false;
        passwordErrorText = null;
        confirmPasswordErrorText = null;
      });
    }

    if (hasErrors) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res.user != null &&
          (res.user!.identities == null || res.user!.identities!.isEmpty)) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Account Already Exists'),
                content: const Text(
                    'An account with this email already exists. Please sign in instead.'),
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
        }
      } else if (res.session == null) {
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
                content: const Text(
                    'A verification email has been sent. Please verify your email to complete Sign up'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/account_setup_title');
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
          Navigator.pushReplacementNamed(context, '/sign_in'); // Changed from '/home'
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          if (error.message.toLowerCase().contains('password')) {
            passwordError = true;

            String formattedError = error.message;
            if (error.message.contains('at least 12 characters') ||
                error.message.contains('requirements')) {
              formattedError = 'Password must be at least 12 characters and contain lowercase, uppercase, number, and symbol';
            }

            passwordErrorText = formattedError;
          } else if (error.message.toLowerCase().contains('email')) {
            emailError = true;
            emailErrorText = error.message;
          } else {
            emailError = true;
            emailErrorText = 'Sign up failed: ${error.message}';
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          emailError = true;
          emailErrorText = 'Sign up failed: ${error.toString()}';
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
              const Text(
                "Sign Up",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 34,
                ),
              ),

              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _emailController,
                  onChanged: (value) {
                    setState(() {
                      emailError = false;
                      emailErrorText = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Enter your email",
                    labelStyle: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : const Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : const Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : const Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              if (emailErrorText != null)
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.only(top: 5, left: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    emailErrorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      passwordError = false;
                      passwordErrorText = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Enter your password",
                    labelStyle: const TextStyle(
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
                      borderSide: BorderSide(
                          color: passwordError ? Colors.red : const Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: passwordError ? Colors.red : const Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: passwordError ? Colors.red : const Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              if (passwordErrorText != null)
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.only(top: 5, left: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    passwordErrorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      confirmPasswordError = false;
                      confirmPasswordErrorText = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Confirm password",
                    labelStyle: const TextStyle(
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
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : const Color(0x26000000)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : const Color(0x26000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: confirmPasswordError
                              ? Colors.red
                              : const Color(0xFF7400B8)),
                    ),
                  ),
                ),
              ),
              if (confirmPasswordErrorText != null)
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.only(top: 5, left: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    confirmPasswordErrorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : signUpWithEmail,
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