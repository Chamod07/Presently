import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

final supabase = Supabase.instance.client;

class _SignInPageState extends State<SignInPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
      if (_userId != null) {
        // Navigate to home page after successful sign-in
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'images/SignIn_SignUp-removebg-preview.png',
                height: 252,
                width: 240,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Sign In",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 34,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Enter your email",
                  labelStyle: TextStyle(
                    fontFamily: "Roboto",
                    color: Color(0xFFBDBDBD),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0x26000000)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 380,
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Enter your password",
                  labelStyle: TextStyle(
                    fontFamily: "Roboto",
                    color: Color(0xFFBDBDBD),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0x26000000)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(380, 50),
                backgroundColor: Color(0xFF7400B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                const webClientId =
                    '54044305887-0cl2lddi9hjremm4o5evdng9d7ardjes.apps.googleusercontent.com';
                const iosClientId =
                    '54044305887-l8mqfssark4jlbsru5dt8pu85vpjvh2h.apps.googleusercontent.com';

                final GoogleSignIn googleSignIn = GoogleSignIn(
                  clientId: iosClientId,
                  serverClientId: webClientId,
                );
                try {
                  final googleUser = await googleSignIn.signIn();
                  if (googleUser == null) return; // Sign-in failed, just return

                  final googleAuth = await googleUser.authentication;
                  final accessToken = googleAuth.accessToken;
                  final idToken = googleAuth.idToken;

                  if (accessToken != null && idToken != null) {
                    await supabase.auth.signInWithIdToken(
                      provider: OAuthProvider.google,
                      idToken: idToken,
                      accessToken: accessToken,
                    );
                  }
                } catch (e) {
                  // Silent error handling, no error shown to user
                }
              },
              icon: Image.asset('images/google_720255.png', height: 20, width: 20),
              label: const Text(
                "Continue with Google",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF333333),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(380, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Color(0x26000000)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/sign_up'); // Navigate to sign-up page
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
    );
  }
}
