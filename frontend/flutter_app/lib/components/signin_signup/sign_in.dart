import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/supabase_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> isFirstTimeLogin(String userId) async {
    try {
      final userResponse = await supabase
          .from('auth.users')
          .select('last_sign_in_at')
          .eq('id', userId)
          .single();

      return userResponse['last_sign_in_at'] == null;
    } catch (e) {
      print('Error checking first-time login status: $e');
      return true;
    }
  }

  void navigateAfterLogin(String userId) async {
    if (!mounted) return;

    try {
      final isFirstLogin = await isFirstTimeLogin(userId);

      if (isFirstLogin) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/account_setup_title');
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        emailError = _emailController.text.isEmpty;
        passwordError = _passwordController.text.isEmpty;
        errorText = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the client from the service
      final AuthResponse res = await _supabaseService.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res.session != null) {
        final userId = res.user!.id;
        navigateAfterLogin(userId);
      } else {
        throw 'Invalid credentials';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorText = e.toString();
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

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign in cancelled';
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
          final userId = response.user!.id;
          navigateAfterLogin(userId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorText = e.toString().contains('cancelled')
              ? 'Sign in cancelled'
              : 'Failed to sign in with Google';
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
                          color: emailError ? Colors.red : const Color(0x26000000)),
                      borderRadius: BorderRadius.circular(10),
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
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : signInWithEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
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
              GestureDetector(
                onTap: () {
                  signInWithGoogle();`
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),

                  Expanded(child:
                  Divider(
                    color: const Color(0xFFF5F5F7),
                    thickness: 1,
                    indent: 10,
                  )
                  ),
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
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}


