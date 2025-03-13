import 'package:flutter/material.dart';

class AccountSetupGreeting extends StatefulWidget {
  const AccountSetupGreeting({Key? key}) : super(key: key);

  @override
  State<AccountSetupGreeting> createState() => _AccountSetupGreetingState();
}

class _AccountSetupGreetingState extends State<AccountSetupGreeting> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    String firstName = args?['firstName'] ?? "User";
    String displayName = firstName.isNotEmpty ? firstName : "User";

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
                      const SizedBox(height: 20),
                      // Progress indicator row - completed
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildProgressDot(true),
                            _buildProgressLine(true),
                            _buildProgressDot(true),
                            _buildProgressLine(true),
                            _buildProgressDot(true),
                            _buildProgressLine(true),
                            _buildProgressDot(true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      Text(
                        "Hello $displayName!",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Setup Complete",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Hero(
                        tag: 'onboarding_image',
                        child: Image.asset(
                          'images/OnboardGreet_AccountSetupTitle.png',
                          height: constraints.maxWidth > constraints.maxHeight
                              ? constraints.maxHeight * 0.4
                              : constraints.maxWidth * 0.7,
                          width: constraints.maxWidth > constraints.maxHeight
                              ? constraints.maxHeight * 0.4
                              : constraints.maxWidth * 0.7,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 20.0),
                      // Updated text
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35.0),
                        child: Text(
                          "Time to Master Presentations!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      // Updated description
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35.0),
                        child: Text(
                          "Your personalized journey begins now. Presently will guide you in developing confident speaking skills, creating engaging content, and captivating any audience.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Roboto',
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(
                                MediaQuery.of(context).size.width * 0.9, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 100, vertical: 16),
                            elevation: 3,
                          ),
                          onPressed: () {
                            debugPrint('Navigation button pressed');
                            // Force immediate navigation to home
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              (_) => false, // Remove all previous routes
                            );
                          },
                          // Updated button text
                          child: const Text(
                            "Let's Begin!",
                            style: TextStyle(
                              color: Color(0xDB7400B8),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                              letterSpacing: 0.5,
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

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 30,
      height: 2,
      color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
    );
  }
}
