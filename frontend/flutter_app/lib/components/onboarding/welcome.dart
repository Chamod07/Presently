import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math' as Math;

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7400B8),
                  Color(0xFF6930C3),
                  Color(0xFF5E60CE),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Custom pattern overlay
          CustomPaint(
            painter: PatternPainter(),
            size: Size.infinite,
          ),

          // Decorative circle at the top
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Decorative circle at the bottom
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimationLimiter(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 600),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: [
                                // SUPER PROMINENT TITLE - No logo, just the title
                                Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      children: [
                                        // Large title text - MAKE BIGGER
                                        Text(
                                          "Presently",
                                          style: TextStyle(
                                            fontSize:
                                                110, // Increase from 92 to 110
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing:
                                                3.0, // Increase letter spacing
                                            fontFamily: 'Cookie',
                                            height: 1.1,
                                            shadows: [
                                              Shadow(
                                                blurRadius:
                                                    25.0, // Bigger shadow
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                offset: Offset(0, 10.0),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        // Enhanced decorative underline
                                        Container(
                                          margin: EdgeInsets.only(
                                              top: 15), // More space
                                          height: 4, // Thicker line
                                          width: 120, // Wider line
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 50), // Reduced spacing

                                // UNIFIED SUBTITLE: Single container with both elements - MAKE LESS PROMINENT
                                Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 22,
                                        horizontal: 20), // Reduced padding
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white
                                              .withOpacity(0.15), // Less opaque
                                          Colors.white
                                              .withOpacity(0.1), // Less opaque
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(
                                            0.25), // Less opaque border
                                        width: 1.2, // Thinner border
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                              0.08), // Lighter shadow
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Icon and tagline
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(
                                                  8), // Smaller padding
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                    0.2), // Less opaque
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.mic,
                                                color: Colors.white,
                                                size: 20, // Smaller icon
                                              ),
                                            ),
                                            SizedBox(width: 12), // Less spacing
                                            Text(
                                              "Your Personal Speech Coach",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16, // Smaller font
                                                letterSpacing: 0.5,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 16), // Less spacing

                                        // Main marketing message
                                        Text(
                                          "Transform your speaking skills and captivate any audience",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16, // Smaller font
                                            color: Colors.white.withOpacity(
                                                0.9), // Slightly less opaque text
                                            letterSpacing:
                                                0.5, // Less letter spacing
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w500,
                                            height: 1.3, // Less line height
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Button section
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50,
                          delay: Duration(milliseconds: 400),
                          child: FadeInAnimation(
                            delay: Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Column(
                                children: [
                                  // Get Started button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 15,
                                          spreadRadius: 1,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, '/sign_up');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Color(0xFF7400B8),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18),
                                        minimumSize: Size(double.infinity, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Get Started",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Sign in button
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/sign_in');
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      minimumSize: Size(double.infinity, 40),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "I already have an account",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.login_rounded, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom pattern painter that creates a subtle geometric pattern
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double sw = size.width;
    final double sh = size.height;

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Create a grid of subtle geometric shapes
    double spacing = 50.0;
    for (double i = 0; i < sw; i += spacing) {
      for (double j = 0; j < sh; j += spacing) {
        // Randomize which pattern to draw
        final patternType = ((i * j) / 100).round() % 3;

        switch (patternType) {
          case 0:
            // Small circle
            canvas.drawCircle(
              Offset(i, j),
              10.0,
              paint,
            );
            break;
          case 1:
            // Small square
            canvas.drawRect(
              Rect.fromCenter(center: Offset(i, j), width: 16.0, height: 16.0),
              paint,
            );
            break;
          case 2:
            // Small cross
            canvas.drawLine(
              Offset(i - 8, j),
              Offset(i + 8, j),
              paint,
            );
            canvas.drawLine(
              Offset(i, j - 8),
              Offset(i, j + 8),
              paint,
            );
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
