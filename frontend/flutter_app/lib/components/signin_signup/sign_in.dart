import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  // Use the service to access the client
  final _supabaseService = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool emailError = false;
  bool passwordError = false;
  String? errorText;

  // Add animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Check if the user is already signed in when this page loads
    _checkCurrentSession();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we got an email from arguments (from sign-up redirection)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('email')) {
      final email = args['email'] as String;
      if (email.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = email;
      }
    }
  }

  Future<void> _checkCurrentSession() async {
    final hasValidSession = await _supabaseService.hasValidSession();
    if (hasValidSession && mounted) {
      // User already has an active session
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> signInWithEmail() async {
    // Reset error states
    setState(() {
      emailError = false;
      passwordError = false;
      errorText = null;
    });

    // Validate input fields
    if (_emailController.text.isEmpty) {
      setState(() {
        emailError = true;
        errorText = 'Please enter your email';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        passwordError = true;
        errorText = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the client from the service
      final AuthResponse res =
          await _supabaseService.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res.session != null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw 'Invalid credentials';
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // More detailed error handling based on the error message
          final errorMsg = e.message.toLowerCase();

          if (errorMsg.contains('invalid login credentials')) {
            // Check if we can determine which field is incorrect
            emailError = true;
            passwordError = true;
            errorText = 'The email or password you entered is incorrect';
          } else if (errorMsg.contains('email') &&
              (errorMsg.contains('not found') ||
                  errorMsg.contains('not exist'))) {
            emailError = true;
            errorText = 'No account found with this email address';
          } else if (errorMsg.contains('password') &&
              errorMsg.contains('incorrect')) {
            passwordError = true;
            errorText = 'Incorrect password. Please try again';
          } else if (errorMsg.contains('password') &&
              (errorMsg.contains('should contain') ||
                  errorMsg.contains('at least one character'))) {
            // Handle complex password requirements with a user-friendly message
            passwordError = true;
            errorText =
                'Password must be at least 8 characters long and include lowercase, uppercase, numbers, and special characters';
          } else if (errorMsg.contains('too many requests') ||
              errorMsg.contains('rate limit')) {
            errorText = 'Too many login attempts. Please try again later';
          } else {
            errorText = 'Sign in failed. Please try again later';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // More specific network or unexpected error messages
          if (e.toString().contains('network') ||
              e.toString().contains('connection')) {
            errorText =
                'Network error. Please check your internet connection and try again';
          } else {
            errorText = 'Something went wrong. Please try again later';
          }
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
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
        if (response.session != null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
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
              ? 'Google sign-in was cancelled'
              : 'Failed to sign in with Google: ${e.toString()}';
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

  // Add this method to send password reset email
  Future<void> resetPassword() async {
    setState(() {
      emailError = false;
      errorText = null;
    });

    // Validate email first
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        emailError = true;
        errorText = 'Please enter your email address to reset your password';
      });
      return;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        emailError = true;
        errorText = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Password Reset Email Sent'),
              content: const Text(
                'We\'ve sent password reset instructions to your email address. '
                'Please check your inbox (and spam folder) for further instructions.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Handle specific error cases for password reset
          final errorMsg = e.message.toLowerCase();

          if (errorMsg.contains('no user found')) {
            emailError = true;
            errorText = 'No account found with this email address';
          } else if (errorMsg.contains('rate limit')) {
            errorText = 'Too many reset attempts. Please try again later';
          } else {
            errorText = 'Failed to send reset email: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          errorText = 'Something went wrong. Please try again later';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 0,
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 20),
                      // Logo with a subtle bounce animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Center(
                          child: Image.asset(
                            'images/SignIn_SignUp.png',
                            height: 252,
                            width: 240,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Sign In",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (errorText != null)
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFEBEE), // Light red background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFEF5350), width: 1),
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
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Enter your email",
                            labelStyle: const TextStyle(
                              fontFamily: "Roboto",
                              color: Color(0xFFBDBDBD),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: emailError
                                      ? Colors.red
                                      : Color(0x26000000)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    emailError ? Colors.red : Color(0x26000000),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    emailError ? Colors.red : Color(0xFF7400B8),
                              ),
                              borderRadius: BorderRadius.circular(10),
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
                            labelStyle: const TextStyle(
                              fontFamily: "Roboto",
                              color: Color(0xFFBDBDBD),
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
                              borderSide: BorderSide(
                                  color: passwordError
                                      ? Colors.red
                                      : Color(0x26000000)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: passwordError
                                    ? Colors.red
                                    : Color(0x26000000),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: passwordError
                                    ? Colors.red
                                    : Color(0xFF7400B8),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // Reposition the forgot password button with better alignment
                      Padding(
                        padding: EdgeInsets.only(
                            top: 8.0,
                            right: MediaQuery.of(context).size.width * 0.05,
                            bottom: 16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : resetPassword,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFF7400B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Continue with the sign in button directly
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuad,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(
                                MediaQuery.of(context).size.width * 0.9, 50),
                            backgroundColor: const Color(0xFF7400B8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const _LoadingIndicator()
                              : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontFamily: 'Roboto',
                                  ),
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
                          )),
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
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : signInWithGoogle,
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
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/sign_up');
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Color(0xFF7400B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Add a custom loading indicator with animation
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        );
      },
    );
  }
}
