import 'package:flutter/material.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),
              const SizedBox(height: 20),
              Center(
                child: Image.asset('/images/SignIn_SignUp-removebg-preview.png',
                ),
              ),
              const SizedBox(height: 20),
              Text("Sign Up",
              style: TextStyle(
                fontFamily: 'Roboto-Medium.ttf',
                fontSize: 34,
              ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: "Enter your email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Enter your password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {}, style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF7400B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Continue",
              style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: Divider(thickness: 1, color: Color(0xFFF5F5F7)))
                ],
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: () {},
            icon: Image.asset('images/google_720255.png'),
            label: const Text ("Register with Google"),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
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
                  Navigator.pushNamed(context, '/sign_up'); // Navigate to sign-up page
                },
            child: const Text(
            "Sign up",
            style: TextStyle(
            color: Color(0xFF7400B8),
            ),
            ),),]
              ),]
      )
    ));
  }
}
