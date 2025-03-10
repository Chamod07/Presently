import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Use the service to access the client
  final _supabaseService = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool emailError = false;
  bool passwordError = false;
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

      if (res.session != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.message.toLowerCase().contains('invalid login credentials')) {
            errorText = 'Invalid email or password';
            emailError = true;
            passwordError = true;
          } else {
            errorText = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorText = 'An unexpected error occurred: ${e.toString()}';
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

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      errorText = null;
    });

    try {
      debugPrint('Starting Google sign-in process');

      // Configure Google Sign-In with required scopes for token retrieval
      GoogleSignIn googleSignIn;

      // Define proper scopes needed for authentication tokens
      final List<String> scopes = [
        'email',
        'profile',
        'openid', // Important for ID tokens
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ];

      if (Platform.isAndroid) {
        debugPrint(
            'Initializing Google Sign-In for Android with enhanced scopes');
        googleSignIn = GoogleSignIn(
          scopes: scopes,
          forceCodeForRefreshToken: true,
        );

        // Log package name for debugging
        final clientId = await googleSignIn.clientId;
        debugPrint('Android clientId: ${clientId ?? "undefined"}');
      } else if (kIsWeb) {
        const webClientId =
            '54044305887-0cl2lddi9hjremm4o5evdng9d7ardjes.apps.googleusercontent.com';
        debugPrint('Initializing Google Sign-In for Web');
        googleSignIn = GoogleSignIn(
          clientId: webClientId,
          scopes: scopes,
        );
      } else if (Platform.isIOS) {
        const iosClientId =
            '54044305887-l8mqfssark4jlbsru5dt8pu85vpjvh2h.apps.googleusercontent.com';
        debugPrint('Initializing Google Sign-In for iOS');
        googleSignIn = GoogleSignIn(
          clientId: iosClientId,
          scopes: scopes,
        );
      } else {
        debugPrint('Unsupported platform for Google Sign-In');
        throw Exception('Unsupported platform for Google Sign-In');
      }

      // Clear any existing sessions
      debugPrint('Signing out of previous Google session if any');
      await googleSignIn.signOut().catchError((error) {
        debugPrint('Error during Google signOut: $error');
      });

      debugPrint('Attempting to sign in with Google');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User cancelled the Google sign-in');
        throw AuthException('User canceled Google sign-in');
      }

      debugPrint('Google sign-in successful for: ${googleUser.email}');
      debugPrint('User ID: ${googleUser.id}');
      debugPrint('Display Name: ${googleUser.displayName}');

      // More robust token retrieval with retry
      debugPrint('Retrieving Google authentication tokens...');
      GoogleSignInAuthentication? googleAuth;

      try {
        googleAuth = await googleUser.authentication;
        debugPrint('Authentication object retrieved successfully');
      } catch (e) {
        debugPrint('Error retrieving authentication: $e');
        // Try one more time after a short delay
        await Future.delayed(Duration(seconds: 1));
        debugPrint('Retrying token retrieval...');
        googleAuth = await googleUser.authentication;
      }

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      // Detailed token debugging
      if (accessToken == null) {
        debugPrint(
            '⚠️ ACCESS TOKEN IS NULL - This is required for Supabase authentication');
      } else {
        debugPrint('✓ Access token retrieved (length: ${accessToken.length})');
      }

      if (idToken == null) {
        debugPrint(
            '⚠️ ID TOKEN IS NULL - This is required for Supabase authentication');
      } else {
        debugPrint('✓ ID token retrieved (length: ${idToken.length})');
      }

      if (accessToken == null || idToken == null) {
        debugPrint(
            'Token retrieval failed. Possible OAuth configuration issues.');
        throw AuthException(
            'Failed to get authentication tokens. Please check your Google Cloud Console configuration.');
      }

      debugPrint('Signing in to Supabase with Google tokens');
      final response = await _supabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint(
          'Supabase sign-in response received: ${response.session != null ? 'session created' : 'no session'}');

      if (response.session != null && mounted) {
        debugPrint('Navigating to home after successful sign-in');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        debugPrint('No session created after Supabase sign-in');
        throw AuthException('Failed to create session');
      }
    } on AuthException catch (e) {
      debugPrint('AuthException during Google sign-in: ${e.message}');
      if (mounted) {
        setState(() {
          errorText = e.message;
        });
      }
    } catch (e) {
      debugPrint(
          'Detailed exception during Google sign-in: ${e.runtimeType} - $e');

      // Handle PlatformException specifically
      final errorMessage = e.toString();
      String detailedError;

      if (errorMessage.contains('PlatformException') &&
          errorMessage.contains('10:')) {
        // Specific handling for error code 10
        detailedError =
            'Google Sign-In configuration error (10). Please verify that:\n'
            '1. Your app\'s package name matches the one in Google Cloud Console\n'
            '2. SHA-1 certificate fingerprint is added to your Google Cloud project\n'
            '3. The OAuth consent screen is properly configured';

        // Additional debug info
        debugPrint(
            'ERROR 10: Your Android app signature might not be registered in the Google Cloud Console.');
        debugPrint(
            'Verify the SHA-1 and package name in your Google Cloud Console project.');
      } else if (errorMessage.contains('canceled') ||
          errorMessage.contains('cancelled')) {
        detailedError = 'Google sign-in was cancelled';
      } else {
        detailedError = 'Failed to sign in with Google: $e';
      }

      if (mounted) {
        setState(() {
          errorText = detailedError;
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

  String _extractPlatformExceptionMessage(String errorString) {
    // Try to extract the most meaningful part of the platform exception
    if (errorString.contains('message:')) {
      final start = errorString.indexOf('message:') + 'message:'.length;
      final end = errorString.indexOf(',', start);
      if (end > start) {
        return errorString.substring(start, end).trim();
      }
    }

    // Check for common error patterns
    if (errorString.contains('10:')) {
      return 'OAuth configuration error: The OAuth client wasn\'t properly configured. Verify SHA certificate and package name in Google Cloud Console.';
    } else if (errorString.contains('12501')) {
      return 'The user canceled the sign-in flow (error 12501)';
    } else if (errorString.contains('10')) {
      return 'There was a problem with the Google Services configuration';
    } else if (errorString.contains('network_error')) {
      return 'Network error. Please check your internet connection';
    }

    return 'Unknown error occurred. Please try again later';
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
                "Sign In",
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
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Enter your email",
                    labelStyle: const TextStyle(
                      fontFamily: "Roboto",
                      color: Color(0xFFBDBDBD),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: emailError ? Colors.red : Color(0x26000000)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: emailError ? Colors.red : Color(0x26000000),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: emailError ? Colors.red : Color(0xFF7400B8),
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
                          color:
                              passwordError ? Colors.red : Color(0x26000000)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: passwordError ? Colors.red : Color(0x26000000),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: passwordError ? Colors.red : Color(0xFF7400B8),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : signInWithEmail,
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
    );
  }
}
