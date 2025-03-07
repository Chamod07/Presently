import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSetup1 extends StatefulWidget {
  const AccountSetup1({super.key});

  @override
  State<AccountSetup1> createState() => _AccountSetup1State();
}

class _AccountSetup1State extends State<AccountSetup1> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _firstNameError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() {
      if (_firstNameError && _firstNameController.text.trim().isNotEmpty) {
        setState(() {
          _firstNameError = false;
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _continue() async{
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty;
      _errorMessage = _firstNameError ? 'First name is required' : null;
    });

    if (!_firstNameError) {
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        try {
          // Update UserDetails table
          final response = await Supabase.instance.client
              .from('UserDetails')
              .update({'firstName': firstName, 'lastName': lastName})
              .eq('userId', user.id);

          if (response.error != null) {
            throw response.error!;
          }

          Navigator.pushNamed(
            context,
            '/account_setup_2',
            arguments: {'firstName': firstName, 'lastName': lastName},
          );
        } catch (e) {
          debugPrint('Error updating user details: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update details. Try again.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
      }
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
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        labelStyle: TextStyle(
                          fontFamily: "Roboto",
                          color: Color(0xFFBDBDBD),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _firstNameError ? Colors.red : Color(0x26000000),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF7400B8)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        errorText: _errorMessage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(width: MediaQuery.of(context).size.width * 0.9,
                    child:
                    TextField(
                      controller: _lastNameController,
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
