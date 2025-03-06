import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class AccountSetup2 extends StatefulWidget {
  const AccountSetup2({super.key});

  @override
  State<AccountSetup2> createState() => _AccountSetup2State();
}

class _AccountSetup2State extends State<AccountSetup2> {
  String? selectDropDown;

  final List<String> userStatus = [
    'Student',
    'Undergraduate',
    'Postgraduate',
    'Young Professional',
    'Other'
  ];
  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    String firstName = args?['firstName'] ?? "";
    String lastName = args?['lastName'] ?? "";

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
                  const SizedBox(height: 20),
                  Text("I am a ...",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(width: MediaQuery.of(context).size.width * 0.9,
                    child:
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Select one from the given list",
                        labelStyle: TextStyle(
                          fontFamily: "Roboto",
                          color: Color(0xFFBDBDBD),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: userStatus.map((String state){
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue){
                        setState(() {
                          selectDropDown = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/account_setup_greeting', arguments: {'firstName': firstName, 'lastName': lastName});
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