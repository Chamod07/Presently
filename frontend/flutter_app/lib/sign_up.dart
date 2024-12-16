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
            children: [Align(
                alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back),
              ),),
                const SizedBox(height: 20),
              Center(
                child: Image.asset('images/SignIn_SignUp-removebg-preview.png',
                    height: 252,
                    width: 240),
              ),
              const SizedBox(height: 20),
              Text("Sign Up",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 34,
              ),
              ),
              const SizedBox(height: 20),
              Container(width: 380, child:
              TextField(
                decoration: InputDecoration(
                  labelText: "Enter your email",
                  labelStyle:
                  TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontFamily: "Roboto",
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0x26000000))
                  ),
                ),
              ),
            ),
              const SizedBox(height: 20),
              Container(width: 380, child:
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Enter your password",
                  labelStyle: TextStyle(color: Color(0xFFBDBDBD),fontFamily: "Roboto"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0x26000000))
                  ),
                ),
              ),
              ),
              const SizedBox(height: 20),
              Container(width: 380, child:
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm password",
                  labelStyle: TextStyle(color: Color(0xFFBDBDBD),fontFamily: "Roboto"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0x26000000))
                  ),
                ),
              ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {}, style: ElevatedButton.styleFrom(
                minimumSize: Size(380, 50),
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
            OutlinedButton.icon(onPressed: () {},
            icon: Image.asset('images/google_720255.png',
                height: 20,
                width: 20),
            label: const Text ("Register with Google"),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(380, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account? "),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/sign_in'); // Navigate to sign-up page
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
