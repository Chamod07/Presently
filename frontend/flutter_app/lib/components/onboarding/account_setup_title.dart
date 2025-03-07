import 'package:flutter/material.dart';

class AccountSetupTitle extends StatelessWidget{
  const AccountSetupTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          "Welcome to Presently",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          'images/OnboardGreet_AccountSetupTitle.png',
                          height: constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight * 0.4 : constraints.maxWidth * 0.8, // Make image responsive
                          width: constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight * 0.4 : constraints.maxWidth * 0.8,
                        ),
                        const Spacer(),
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: const Text(
                            "Tell us about yourself and we'll create your personalized path to confident, compelling presentations.",
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
                              Navigator.pushNamed(context, '/account_setup_1');
                            },
                            child: const Text(
                              "Get Started",
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