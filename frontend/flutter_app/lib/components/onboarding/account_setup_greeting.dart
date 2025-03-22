import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AccountSetupGreeting extends StatefulWidget {
  const AccountSetupGreeting({Key? key}) : super(key: key);

  @override
  State<AccountSetupGreeting> createState() => _AccountSetupGreetingState();
}

class _AccountSetupGreetingState extends State<AccountSetupGreeting>
    with SingleTickerProviderStateMixin {
  // Simple animation controller for fade-in effects
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Flag for button visibility
  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Initialize simple fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Start fade animation
    _animationController.forward();

    // Show button after a short delay
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get user's name from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    String firstName = args?['firstName'] ?? "Friend";
    String displayName = firstName.isNotEmpty ? firstName : "Friend";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7400B8),
              Color(0xFF6930C3),
              Color(0xFF5E60CE),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Simple progress indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: _buildCompletionIndicator(),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: AnimationLimiter(
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 600),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              horizontalOffset: 0,
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: widget,
                              ),
                            ),
                            children: [
                              SizedBox(height: 40),

                              // Greeting text
                              Text(
                                "Congratulations,\n$displayName!",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 20),

                              // Completion badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Account Setup Complete",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 40),

                              // Hero image with simple scale animation
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.9, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Hero(
                                  tag: 'onboarding_image',
                                  child: Image.asset(
                                    'images/OnboardGreet_AccountSetupTitle.png',
                                    height: 220,
                                  ),
                                ),
                              ),

                              SizedBox(height: 40),

                              // Description text
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  children: [
                                    Text(
                                      "You're All Set!",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Your personalized journey begins now. Presently will guide you in developing confident speaking skills, creating engaging content, and captivating any audience.",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        height: 1.5,
                                        letterSpacing: 0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Simple animated button
                  AnimatedOpacity(
                    opacity: _showButton ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: _buildBeginButton(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 4; i++) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  size: 10,
                  color: Color(0xFF7400B8),
                ),
              ),
            ),
            if (i < 3)
              Container(
                width: 30,
                height: 2,
                color: Colors.white,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBeginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (_) => false, // Remove all previous routes
            );
          },
          splashColor: Colors.purple.withOpacity(0.1),
          highlightColor: Colors.purple.withOpacity(0.05),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Start My Journey",
                  style: TextStyle(
                    color: Color(0xFF7400B8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF7400B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
