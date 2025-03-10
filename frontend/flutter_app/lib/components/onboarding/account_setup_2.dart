import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSetup2 extends StatefulWidget {
  const AccountSetup2({super.key});

  @override
  State<AccountSetup2> createState() => _AccountSetup2State();
}

class _AccountSetup2State extends State<AccountSetup2> {
  String? selectedRole;

  final List<String> userStatus = [
    'Student',
    'Undergraduate',
    'Postgraduate',
    'Young Professional',
    'Other'
  ];

  void _continue() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    String firstName = args?['firstName'] ?? "";
    String lastName = args?['lastName'] ?? "";
    String? userId = args?['userId'];

    if (userId != null && selectedRole != null) {
      try {
        final response = await Supabase.instance.client.from('UserDetails').update({'role': selectedRole}).eq('userId', userId).select();

        if (response.isEmpty) {
          throw Exception('Update failed, no matching user found.');
        }
        debugPrint('Role update successful: $response');

        Navigator.pushNamed(context, '/account_setup_greeting', arguments: {
          'firstName': firstName,
          'lastName': lastName,
        });
      } catch (e) {
        debugPrint('Error updating user role: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role. Try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role before continuing.')),
      );
    }
  }

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
                  const SizedBox(height: 20),
                  Text("Tell Us More About You!",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(width: MediaQuery.of(context).size.width * 0.9,
                    child:
                    DropdownButtonFormField(
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "I describe myself as a...",
                        labelStyle: TextStyle(
                          fontFamily: "Roboto",
                          color: Color(0xFFBDBDBD),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF7400B8)),
                        )
                      ),
                      items: userStatus.map((String state){
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue){
                        setState(() {
                          selectedRole = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
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