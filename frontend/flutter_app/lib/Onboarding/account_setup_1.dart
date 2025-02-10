import 'package:flutter/material.dart';


class AccountSetup1 extends StatefulWidget {
  const AccountSetup1({super.key});

  @override
  State<AccountSetup1> createState() => _AccountSetup2State();
}

class _AccountSetup2State extends State<AccountSetup1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                        'images/SignIn_SignUp-removebg-preview.png',
                        height: 252,
                        width: 240),
                  ),
                  const SizedBox(height: 20),
                  Text("What shall we call you?",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(width: MediaQuery.of(context).size.width * 0.9,
                    child:
                    TextField(
                      decoration: InputDecoration(
                        labelText: "First Name",
                        labelStyle: TextStyle(
                          fontFamily: "Roboto",
                          color: Color(0xFFBDBDBD),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(width: MediaQuery.of(context).size.width * 0.9,
                    child:
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Last Name",
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
                      Navigator.pushNamed(context, '/account_setup_2');
                    }, style: ElevatedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                    backgroundColor: Color(0xFF7400B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                    child: const Text("Continue",
                      style: TextStyle(fontSize: 17,
                          color: Colors.white,
                          fontFamily: 'Roboto'),
                    ),
                  ),
                ]
            )
        )
    );
  }
}
