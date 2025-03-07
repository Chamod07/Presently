import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase: supabase);
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Add a short delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final hasValidSession = await _authService.hasValidSession();

    if (hasValidSession) {
      // User is signed in, navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is not signed in, navigate to welcome/onboarding screen
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your app logo
            Image.asset(
              'images/SignIn_SignUp.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF7400B8),
            ),
          ],
        ),
      ),
    );
  }
}
