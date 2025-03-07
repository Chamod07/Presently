import 'package:flutter/material.dart';

class AccountSetupGreeting extends StatelessWidget{
  const AccountSetupGreeting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    String firstName = args?['firstName'] ?? "User";
    String lastName = args?['lastName'] ?? "";
    String displayName = lastName.isNotEmpty ? "$firstName" : firstName;

    return Scaffold(
      backgroundColor: Color(0x96B843FE),
      body: SafeArea(
          child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40.0),
                      Text(
                        "Hello $displayName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const Spacer(),
                      Image.asset(
                        'images/OnboardGreet_AccountSetupTitle.png',
                        height: constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight * 0.4 : constraints.maxWidth * 0.8,
                        width: constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight * 0.4 : constraints.maxWidth * 0.8,
                      ),
                      const Spacer(),
                      const SizedBox(height: 20.0),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          "Your journey to becoming a confident and captivating presenter starts now.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/home');
                          },
                          child: const Text(
                            "I am ready!",
                            style: TextStyle(
                              color: Color(0xDB7400B8),
                              fontSize: 17,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}