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
          child: SingleChildScrollView( //if the page does not fit in screen it will scroll
            child: Column(
                children: [Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {Navigator.pop(context);
                      }, 
                    icon: Icon(Icons.arrow_back),
                  ),
                ),
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
                  Container(width: MediaQuery.of(context).size.width * 0.9, child:
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
                  Container(width: MediaQuery.of(context).size.width * 0.9, child:
                  TextField(
                    obscureText: true, // makes password invisible
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
                  Container(width: MediaQuery.of(context).size.width * 0.9, child:
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/account_setup_title');
                    }, style: ElevatedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
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
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/sign_in'); // Navigate to sign-in page
                          },
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                              color: Color(0xFF7400B8),
                            ),
                          ),
                        ),
                      ]
                  ),
                ]
            )
          )
        )
    );
  }
}